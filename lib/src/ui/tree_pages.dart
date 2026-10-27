import 'dart:async';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/tree_folder_facts.dart';
import 'package:niman/src/ui/tree_read_guard.dart';
import 'package:niman/src/ui/visible_tree.dart';

/// A page of the tree: the folder's id and the page's number in it.
typedef TreePageKey = (int parent, int page);

/// What the tree holds of its rows: the pages around the viewport, and the
/// counts and ranks that say how many rows there are (#1200).
///
/// It replaces `TreeChildCache`, which appended every page it was asked for
/// and kept them until the library closed. A page here is [pageSize]
/// consecutive positions of one folder in the tree's order, keyed
/// `(folder, page)`, and the pages held are the ones the list can draw: the
/// widget works the window out with [pagesFor] and hands it to [keepOnly].
///
/// Everything is read from one [LibrarySession] in the `sort` the reads are
/// given. Ranks and pages are positions in an order, so a [visible] model in
/// another order than the last one [clear]s what was held, and a [load] in
/// an order that is no longer the current one reads nothing. A revision that
/// moved rows [forget]s the folders it names, and a read that lands after the
/// revision outdated it adds nothing (see [TreeReadGuard]).
final class TreePages {
  /// Pages of [pageSize] rows.
  new({required this.pageSize}) : assert(pageSize > 0, 'a page has rows');

  /// How many consecutive positions of a folder one page holds.
  final int pageSize;

  final TreeReadGuard _guard = TreeReadGuard();
  final TreeFolderFacts _facts = TreeFolderFacts();

  /// The loaded pages, by folder id and then page number.
  final Map<int, Map<int, List<Note>>> _pages = <int, Map<int, List<Note>>>{};

  /// The reads under way, so that asking for a page twice reads it once.
  final Map<TreePageKey, Future<bool>> _loading = <TreePageKey, Future<bool>>{};

  /// The order the held ranks and pages are in.
  TreeSort? _sort;

  /// Counts the calls to [visible]: only the latest may drop the pages of
  /// closed folders.
  int _visibleCalls = 0;

  /// The folders of the last [visible] model, by id.
  Map<int, Note> _folders = const <int, Note>{};

  /// The pinned notes of this revision, once read: the widget's slot, as in
  /// `TreeChildCache`. Dropped by [clear] and [forget].
  List<Note>? pinned;

  /// Counts the times everything was dropped by [clear].
  int get epoch => _guard.epoch;

  /// How many pages are held.
  int get pageCount {
    var count = 0;
    for (final pages in _pages.values) {
      count += pages.length;
    }
    return count;
  }

  /// Whether the page [key] is held.
  bool hasPage(TreePageKey key) => _pages[key.$1]?.containsKey(key.$2) ?? false;

  /// The row of the expanded folder with id [folderId] in the last
  /// [visible] model, or null: the widget needs its path to know which rows
  /// are open.
  Note? folderOf(int folderId) => _folders[folderId];

  /// The model of the rows [expandedPaths] shows in [sort]'s order: the
  /// root's child count and, for each expanded folder that is reached
  /// through expanded folders, its place among its siblings and its child
  /// count.
  ///
  /// A folder's row, rank and count are read once and held until a [forget]
  /// drops them. A folder the model does not show, because it was closed or
  /// lies under a closed one, loses its pages here and any read of them still
  /// out; its count and rank stay, being small. Reopening it is then one
  /// page read, which is what #1064 measured as cheap — what that change
  /// guarded against, every open folder read again on each toggle, stays
  /// fixed.
  Future<VisibleTree> visible(
    LibrarySession session,
    Set<String> expandedPaths,
    TreeSort sort,
  ) async {
    _adopt(sort);
    final call = ++_visibleCalls;
    final stamp = _guard.stamp();
    final held = _facts.count(VisibleTree.rootId);
    final (rootCount, folders) = await (
      held != null
          ? Future<int>.value(held)
          : session.childCount(VisibleTree.rootId),
      Future.wait([
        for (final path in _reachable(expandedPaths))
          _facts.read(session, path, sort, _guard, stamp),
      ]),
    ).wait;
    if (_guard.holds(stamp, VisibleTree.rootId)) {
      _facts.keepCount(VisibleTree.rootId, rootCount);
    }
    final shown = [for (final folder in folders) ?folder];
    final tree = VisibleTree(
      rootCount: rootCount,
      expanded: [
        for (final folder in shown)
          (
            id: folder.note.id,
            parentId: folder.note.parent,
            rank: folder.rank,
            childCount: folder.count,
          ),
      ],
    );
    // A model that a later call or a clear has overtaken does not say what is
    // open now.
    if (call == _visibleCalls && stamp.epoch == _guard.epoch) {
      _folders = {
        for (final folder in shown)
          if (tree.isVisibleFolder(folder.note.id)) folder.note.id: folder.note,
      };
      _dropHiddenPages(tree);
    }
    return tree;
  }

  /// The pinned notes of this revision: the ones held, else read from
  /// [session]'s fields.
  ///
  /// The read is stamped like a page's. A [clear] or a [forget] while it is
  /// out outdates it (a pin changed, or an indexing burst moved the rows), so
  /// it is answered to the flatten that asked but not held: the next flatten
  /// reads again (#1231).
  Future<List<Note>> pinnedNotes(LibrarySession session) async {
    final held = pinned;
    if (held != null) return held;
    final stamp = _guard.stamp();
    final fields = await session.fieldSource;
    final read = await fields?.pinnedNotes() ?? const <Note>[];
    if (_guard.untouched(stamp)) pinned = read;
    return read;
  }

  /// The paths of [expandedPaths] whose ancestors are all expanded too: a
  /// folder under a closed one is not in the list, so it is not read.
  Iterable<String> _reachable(Set<String> expandedPaths) sync* {
    for (final path in expandedPaths) {
      if (path.isEmpty) continue;
      var open = true;
      for (var cut = path.lastIndexOf('/'); cut > 0;) {
        if (!expandedPaths.contains(path.substring(0, cut))) {
          open = false;
          break;
        }
        cut = path.lastIndexOf('/', cut - 1);
      }
      if (open) yield path;
    }
  }

  /// Lets go of the pages of the folders [tree] does not show, and voids the
  /// reads of theirs still out.
  void _dropHiddenPages(VisibleTree tree) {
    final held = {..._pages.keys, for (final key in _loading.keys) key.$1};
    final hidden = {
      for (final id in held)
        if (!tree.isVisibleFolder(id)) id,
    };
    if (hidden.isEmpty) return;
    _guard.forget(hidden);
    _pages.removeWhere((id, _) => hidden.contains(id));
    _loading.removeWhere((key, _) => hidden.contains(key.$1));
  }

  /// The row at [position] of the folder with id [parent], or null when its
  /// page is not loaded. Reads nothing.
  Note? rowAt(int parent, int position) {
    final rows = pageRows(parent, position ~/ pageSize);
    final offset = position % pageSize;
    return rows != null && offset < rows.length ? rows[offset] : null;
  }

  /// The rows of page [page] of the folder with id [parent], in the tree's
  /// order, or null when it is not loaded: for the widget to nest a page's
  /// sidecars within it.
  List<Note>? pageRows(int parent, int page) => _pages[parent]?[page];

  /// Reads page [page] of the folder with id [parent] and holds it. Answers
  /// whether rows were added: a page already held, one that came back empty
  /// and one a revision outdated while it was read answer false.
  ///
  /// The page is read from a neighbour whenever one is held: by keyset after
  /// the last row of the page before, else before the first row of the page
  /// after, which costs the same however far down the folder it is. Only a
  /// page with no neighbour is read by position, an index walk to its offset
  /// paid once for a jump. A keyset page is the page at its position because
  /// its neighbour is, and a revision that moved rows forgot the neighbour
  /// with them.
  Future<bool> load(
    LibrarySession session,
    int parent,
    int page,
    TreeSort sort,
  ) {
    if (!_isCurrent(sort)) return Future<bool>.value(false);
    final key = (parent, page);
    if (hasPage(key)) return Future<bool>.value(false);
    final running = _loading[key];
    if (running != null) return running;
    final read = _readOrNothing(session, parent, page, sort);
    _loading[key] = read;
    unawaited(
      read.whenComplete(() {
        // A clear or a forget may have started another read of the key.
        _loading.removeWhere(
          (k, running) => k == key && identical(running, read),
        );
      }),
    );
    return read;
  }

  /// [_read], except that a read that fails answers false, as a page that
  /// came back empty does: the page is simply not loaded, and asking for it
  /// again reads it afresh (#1233).
  ///
  /// The reads are started by callers that do not wait for them — the list
  /// asking after a frame, a key handler — and a failure that reached none
  /// of them (the connection closing while the library does) was an
  /// unhandled error in the zone.
  Future<bool> _readOrNothing(
    LibrarySession session,
    int parent,
    int page,
    TreeSort sort,
  ) async {
    try {
      return await _read(session, parent, page, sort);
    } on Object catch (error) {
      const AppLogger(name: 'tree.pages')
          .debug('page $page of folder $parent not read ($error)');
      return false;
    }
  }

  Future<bool> _read(
    LibrarySession session,
    int parent,
    int page,
    TreeSort sort,
  ) async {
    final stamp = _guard.stamp();
    final previous = pageRows(parent, page - 1);
    final next = pageRows(parent, page + 1);
    final List<Note> rows;
    if (previous != null && previous.isNotEmpty) {
      rows = await session.childrenPage(
        parent,
        limit: pageSize,
        sort: sort,
        after: previous.last,
      );
    } else if (next != null && next.isNotEmpty) {
      rows = await session.childrenPage(
        parent,
        limit: pageSize,
        sort: sort,
        before: next.first,
      );
    } else {
      rows = await session.childrenAt(
        parent,
        offset: page * pageSize,
        limit: pageSize,
        sort: sort,
      );
    }
    assert(rows.length <= pageSize, 'a page of $pageSize read ${rows.length}');
    if (!_guard.holds(stamp, parent) || rows.isEmpty) return false;
    (_pages[parent] ??= <int, List<Note>>{})[page] = rows;
    return true;
  }

  /// The pages the rows from index [firstIndex] to [lastIndex] of [tree],
  /// both included, are drawn from — the range the list can draw, which the
  /// widget works out from the viewport and the list's cache extent — and
  /// the page either side of each, when the folder has one.
  ///
  /// This is the window, not an LRU of a chosen size: what is held follows
  /// the screen and the row height, so a taller window or a smaller row holds
  /// more pages and no number of them is picked. The neighbours are held
  /// because they are where the next read starts from (see [load]): without
  /// them each page scrolled to would cost an offset read instead of a keyset
  /// one.
  ///
  /// The range is clamped to the list, and walked row by row: it is a screen
  /// of them.
  Set<TreePageKey> pagesFor(VisibleTree tree, int firstIndex, int lastIndex) {
    final drawn = drawnPages(tree, firstIndex, lastIndex);
    final window = {...drawn};
    for (final (parent, page) in drawn) {
      if (page > 0) window.add((parent, page - 1));
      if ((page + 1) * pageSize < tree.childCount(parent)!) {
        window.add((parent, page + 1));
      }
    }
    return window;
  }

  /// The pages the rows from index [firstIndex] to [lastIndex] of [tree],
  /// both included, are in — the ones to read, where [pagesFor] adds the
  /// neighbours to keep.
  Set<TreePageKey> drawnPages(VisibleTree tree, int firstIndex, int lastIndex) {
    final drawn = <TreePageKey>{};
    final last = lastIndex < tree.length ? lastIndex : tree.length - 1;
    for (var i = firstIndex < 0 ? 0 : firstIndex; i <= last; i++) {
      final slot = tree.slotAt(i);
      drawn.add((slot.parent, slot.position ~/ pageSize));
    }
    return drawn;
  }

  /// The pages held, by key, with their rows: a copy, so that what a caller
  /// keeps of it is not changed when a page is dropped or lands. The widget
  /// draws the last rows it had from one while a newer read is out, and
  /// looks a row up by its path in one.
  Map<TreePageKey, List<Note>> held() => {
    for (final MapEntry(key: parent, value: pages) in _pages.entries)
      for (final MapEntry(key: page, value: rows) in pages.entries)
        (parent, page): rows,
  };

  /// Drops every loaded page that is not in [wanted]: call it with
  /// [pagesFor] when the window moves or a page lands.
  void keepOnly(Iterable<TreePageKey> wanted) {
    final keep = wanted.toSet();
    for (final entry in _pages.entries) {
      entry.value.removeWhere((page, _) => !keep.contains((entry.key, page)));
    }
    _pages.removeWhere((_, pages) => pages.isEmpty);
  }

  /// Forgets everything: the index moved, or the order changed.
  void clear() {
    _guard.clear();
    _pages.clear();
    _loading.clear();
    _facts.clear();
    _folders = const <int, Note>{};
    _sort = null;
    pinned = null;
  }

  /// Forgets the folders with ids [parents], whose rows moved: their pages
  /// and count, and the row and rank of the folders in them. The pinned
  /// notes go too, whose titles and pins may have changed. Every other
  /// folder's pages stand.
  void forget(Iterable<int> parents) {
    final ids = parents.toSet();
    _guard.forget(ids);
    _pages.removeWhere((id, _) => ids.contains(id));
    _loading.removeWhere((key, _) => ids.contains(key.$1));
    _facts.forget(ids);
    pinned = null;
  }

  /// Starts afresh when [sort] is not the order what is held is in: the
  /// widget's new read of the tree, [visible], is what changes the order.
  void _adopt(TreeSort sort) {
    if (_sort != null && _sort != sort) clear();
    _sort = sort;
  }

  /// Whether a read in [sort] belongs with what is held: it is in the order
  /// the model was last built in, or nothing is held yet to be in an order.
  ///
  /// A read carries the sort of the `TreeListing` that asked, and a listing
  /// outlives the order it was made for: a keyboard move or a jump still
  /// under way when the order flips asks with the old one. It must not
  /// clear the new order's counts and pages, or leave a page of the old
  /// order in their cache (#1232), so it reads nothing.
  bool _isCurrent(TreeSort sort) {
    _sort ??= sort;
    return _sort == sort;
  }
}
