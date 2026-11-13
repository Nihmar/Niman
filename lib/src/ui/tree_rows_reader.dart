import 'dart:async';

import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter/widgets.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/tree_listing.dart';
import 'package:niman/src/ui/tree_pages.dart';
import 'package:niman/src/ui/tree_rows.dart';
import 'package:niman/src/ui/tree_walk.dart';

/// What the note tree reads (#1200): the rows of the visible tree for a
/// revision, read once however often the tree rebuilds, the pages of rows
/// around the viewport as the list scrolls, and the pinned block's roll-up.
final class TreeRowsReader {
  /// Reads the tree of [session] with [expanded] folders, in [sort] order,
  /// into [pages]; [scroll] and [walk] say what is on screen, [dropMarks]
  /// runs after each read and [onPageLanded] after a page read later lands.
  new({
    required this.pages,
    required this.scroll,
    required this.walk,
    required this.session,
    required this.expanded,
    required this.sort,
    required this.dropMarks,
    required this.onPageLanded,
  });

  /// What the tree has read: the pages of rows around the viewport and the
  /// counts that say how many rows there are (#1200).
  final TreePages pages;

  /// The tree's scroll: where the list is, for the pages it draws.
  final ScrollController scroll;

  /// The rows of the last build, whose listing the pages read later go to.
  final TreeWalk walk;

  /// The session providing the index, as the tree has it now.
  final LibrarySession Function() session;

  /// The paths of the expanded folders, as the tree has them now.
  final Set<String> Function() expanded;

  /// The order the rows come in, as the tree has it now.
  final TreeSort Function() sort;

  /// Lets go of the marks on rows a read found gone; runs once per read.
  final Future<void> Function() dropMarks;

  /// Draws the rows again: a page asked for after a frame has landed.
  final VoidCallback onPageLanded;

  /// Whether the tree is gone: nothing read after it lands anywhere.
  bool _disposed = false;

  /// The rows currently being shown, and the inputs they were built from.
  ///
  /// The read runs a few counts per expanded folder and a page of rows, so it
  /// must not be restarted by every rebuild: selecting a note, toggling a
  /// button — any `setState` above this widget — used to re-query the
  /// whole visible tree, over a hundred queries a second on a real
  /// library. Reusing the same future also keeps `FutureBuilder` from
  /// flashing its spinner between rebuilds.
  Future<TreeRows>? _rows;
  int? _rowsRevision;

  /// Which counter [_rowsRevision] came from: the library's revision when
  /// true, its tree revision when false. The two count apart, so the same
  /// number from each is not the same index (#760).
  bool _rowsFollowContents = false;
  Set<String> _rowsExpanded = const <String>{};

  /// The sort direction the cached rows were read with. It decides the
  /// order the index is asked for, so a change of direction alone must
  /// rebuild the rows — a revision bump does not necessarily follow, and
  /// never does when the settings write that would have caused it fails.
  TreeSort _rowsSort = TreeSort.nameAsc;

  /// Whether the pinned section is rolled up, once the library has been
  /// asked. Null until then, and the section builds expanded — the common
  /// answer, and the one that does not make the tree jump when the real
  /// value lands.
  bool? _pinnedCollapsed;

  /// Whether the pinned section is rolled up: as the library said, or as
  /// it was rolled since; false until the library has been asked.
  bool get collapsed => _pinnedCollapsed ?? false;
  set collapsed(bool collapsed) => _pinnedCollapsed = collapsed;

  /// The row height the next read works the window out with, with
  /// [viewportHint], before the list has been laid out to say: the pages it
  /// reads are the ones the first frame draws.
  double rowHeightHint = 0;

  /// The screen's height, the room the list can take before it is laid out.
  double viewportHint = 0;

  /// The pages the build asked for since the last frame, to read after it.
  final Set<TreePageKey> _wanted = <TreePageKey>{};
  bool _askScheduled = false;

  /// The first and the last index the list laid out last, and whether the
  /// pages are to be matched to them after this frame.
  (int, int)? _laidOut;
  bool _syncScheduled = false;

  /// Forgets what was read of the library: the rows, the pages and the
  /// roll-up, which belong to it — a new library asks for all three again.
  void reset() {
    _rows = null;
    pages.clear();
    _pinnedCollapsed = null;
  }

  /// Stops: a read that lands after it draws nothing.
  void dispose() => _disposed = true;

  /// The rows for [revision], recomputed only when the index revision, the
  /// sort direction or the set of expanded folders changed.
  ///
  /// The direction is part of the key: the read feeds it to the index, so
  /// reusing rows across a direction change would show the old order — the
  /// chevron flips and the list stays put.
  ///
  /// So is the counter [revision] was read from ([followsContents]): a
  /// save bumps one and not the other, so a number from each can match
  /// while the index between them moved (#760).
  Future<TreeRows> rowsFor(int revision, {required bool followsContents}) {
    final cached = _rows;
    if (cached != null &&
        _rowsRevision == revision &&
        _rowsFollowContents == followsContents &&
        _rowsSort == sort() &&
        _setEquals(_rowsExpanded, expanded())) {
      return cached;
    }
    // The rows on screen are drawn from pages that are about to be forgotten
    // or dropped: they keep the ones they have until the new rows land, or
    // the tree would blank for each change.
    walk.rows?.listing.freeze();
    // A new order makes what was read of the folders stale, and so does a
    // revision — of the folders it moved rows in, when it says which: a
    // note's new title re-reads its own folder, not every open one (#1132).
    // A folder opened or closed does not: the rows of the others stand, and
    // closing one reads nothing (#1064).
    final since = _rowsRevision;
    if (_rowsFollowContents != followsContents || _rowsSort != sort()) {
      pages.clear();
    } else if (since != revision) {
      final moved = since == null
          ? null
          : session().foldersMovedSince(since, tree: !followsContents);
      if (moved == null) {
        pages.clear();
      } else {
        pages.forget(moved);
      }
    }
    _rowsRevision = revision;
    _rowsFollowContents = followsContents;
    _rowsExpanded = Set<String>.of(expanded());
    _rowsSort = sort();
    return _rows = _flattenOnce();
  }

  /// The flatten running now, if any.
  Future<TreeRows>? _flattening;

  /// The one flatten waiting behind it (#1064).
  Completer<TreeRows>? _flattenNext;

  /// [_flatten], with at most one in flight and one waiting: the changes that
  /// arrive while the rows are being read share one more read, which starts
  /// when the first ends and takes the expanded folders and the order as they
  /// are then. Each caller gets the rows of the read that answers it, so a
  /// burst of tree changes is two reads, not one per change.
  Future<TreeRows> _flattenOnce() {
    if (_flattening != null) {
      return (_flattenNext ??= Completer<TreeRows>()).future;
    }
    return _flattenNow();
  }

  Future<TreeRows> _flattenNow() {
    final running = _flatten();
    _flattening = running;
    return running.whenComplete(() {
      _flattening = null;
      final next = _flattenNext;
      _flattenNext = null;
      if (next != null) {
        unawaited(
          _flattenNow().then(next.complete, onError: next.completeError),
        );
      }
    });
  }

  /// Reads the model of the visible tree from the index and the pages the
  /// first frame draws, and the pinned notes alongside — one revision, one
  /// build, so the three never disagree.
  ///
  /// The three waits are timed apart (#315): the first read after a library
  /// opens is where a cold index connection's open used to land, and the
  /// line has to say whether it is the query, the pinned read or the
  /// settings file that a frame waited for.
  Future<TreeRows> _flatten() async {
    final started = DateTime.now();
    final sort = this.sort();
    final session = this.session();
    final model = await pages.visible(session, expanded(), sort);
    final treeMs = DateTime.now().difference(started).inMilliseconds;
    final pinnedAt = DateTime.now();
    final pinned = await pages.pinnedNotes(session);
    final pinnedMs = DateTime.now().difference(pinnedAt).inMilliseconds;
    // Asked once per session, not per flatten: after the first answer the
    // state lives here, so a toggle repaints instead of round-tripping
    // through the settings file.
    final settingsAt = DateTime.now();
    _pinnedCollapsed ??= await session.librarySettings.pinnedCollapsed;
    final settingsMs = DateTime.now().difference(settingsAt).inMilliseconds;

    final listing = TreeListing(
      session: session,
      model: model,
      pages: pages,
      sort: sort,
    );
    final pagesAt = DateTime.now();
    final header = TreeWalk.pinnedHeightsOf(
      pinned,
      rowHeightHint,
      collapsed: collapsed,
    ).fold<double>(0, (total, height) => total + height);
    await _loadWindow(listing, header);
    final pagesMs = DateTime.now().difference(pagesAt).inMilliseconds;
    await dropMarks();

    const AppLogger(name: 'tree.ui').debug(
      'flatten: ${DateTime.now().difference(started).inMilliseconds}ms '
      '(${model.length} rows, ${pinned.length} pinned) '
      '[tree $treeMs, pinned $pinnedMs, settings $settingsMs, '
      'pages $pagesMs]',
    );
    return TreeRows(pinned: pinned, listing: listing);
  }

  /// Reads the pages the list will draw first for [listing] — the ones under
  /// the viewport and the list's own cache extent as it is scrolled now, or
  /// from the top before it has been laid out — so that the rows land with
  /// their notes, and lets go of the pages that are no longer wanted.
  /// [header] is the height of the pinned block above the tree.
  Future<void> _loadWindow(TreeListing listing, double header) async {
    final model = listing.model;
    if (model.length == 0 || rowHeightHint <= 0) return;
    const cache = RenderAbstractViewport.defaultCacheExtent;
    final scrolled = scroll.hasClients ? scroll.position.pixels : 0.0;
    // The screen is as tall as the list can be, until it has been laid out.
    final extent = scroll.hasClients
        ? scroll.position.viewportDimension
        : viewportHint;
    final last = model.length - 1;
    final first = ((scrolled - cache - header) / rowHeightHint).floor().clamp(
      0,
      last,
    );
    final end = ((scrolled + extent + cache - header) / rowHeightHint)
        .ceil()
        .clamp(first, last);
    await Future.wait([
      for (final (parent, page) in pages.drawnPages(model, first, end))
        pages.load(session(), parent, page, listing.sort),
    ]);
    pages.keepOnly(pages.pagesFor(model, first, end));
  }

  /// Asks for the page of a row the build found empty, after the frame:
  /// the page read adds rows, which a build must not ask for.
  void wantPage(TreePageKey key) {
    _wanted.add(key);
    if (_askScheduled) return;
    _askScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _askPages());
  }

  /// Reads the pages the last build asked for, and draws the rows again as
  /// each lands (#1200).
  void _askPages() {
    _askScheduled = false;
    final keys = _wanted.toList();
    _wanted.clear();
    final listing = walk.rows?.listing;
    if (_disposed || listing == null || listing.isFrozen) return;
    for (final (parent, page) in keys) {
      unawaited(
        pages.load(session(), parent, page, listing.sort).then((added) {
          if (!added || _disposed) return;
          _syncWindow();
          onPageLanded();
        }),
      );
    }
  }

  /// The list laid out the rows from [first] to [last]: the pages held are
  /// matched to them after the frame.
  void onLaidOut(int first, int last) {
    if (last < first || _laidOut == (first, last)) return;
    _laidOut = (first, last);
    if (_syncScheduled) return;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      _syncWindow();
    });
  }

  /// Keeps the pages the rows last laid out are drawn from, and the page
  /// either side of each, and lets go of the others.
  void _syncWindow() {
    final range = _laidOut;
    final listing = walk.rows?.listing;
    if (_disposed || range == null || listing == null || listing.isFrozen) {
      return;
    }
    final last = listing.modelLength - 1;
    if (last < 0) return;
    // The row being made is no row of the model: the range is cut to it.
    final first = (listing.modelIndexOf(range.$1) ?? range.$1).clamp(0, last);
    final end = (listing.modelIndexOf(range.$2) ?? range.$2 - 1).clamp(
      first,
      last,
    );
    pages.keepOnly(pages.pagesFor(listing.model, first, end));
    listing.prune();
  }
}

bool _setEquals(Set<String> a, Set<String> b) {
  if (a.length != b.length) return false;
  for (final e in a) {
    if (!b.contains(e)) return false;
  }
  return true;
}
