import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/links/mention_reader.dart';
import 'package:niman/src/links/mentions.dart';

/// The notes that link to one note (#842), kept current for the surfaces that
/// list them — the note view's section, the dock's pane, the phone's sheet.
///
/// One indexed lookup of a page ([MentionSource.referrersOf]) when the note
/// or the library changes, and again a pause after the library's index moves
/// (a note elsewhere that gained or lost a link to this one); [loadMore] adds
/// the next page, and a reload reads again as many pages as were shown, so
/// the rows stay where they were. Nothing is read from the notes themselves
/// here: the rows ask for the line they show as they are drawn.
final class LinksToNoteController extends ChangeNotifier {
  /// A controller that waits [delay] after the index moves before it asks
  /// again.
  new({this.delay = const Duration(milliseconds: 400)});

  /// How long the library's index has to be still before the list is asked
  /// for again.
  final Duration delay;

  MentionSource? _source;
  String? _path;
  Referrers? _referrers;
  int _pages = 1;
  bool _loadingMore = false;
  StreamSubscription<void>? _changes;
  Timer? _timer;
  int _run = 0;
  bool _disposed = false;

  /// The library the list is read from, or null while none is open.
  MentionSource? get source => _source;

  /// The library-relative path of the note the list is for, or null.
  String? get path => _path;

  /// The notes that link to the note, or null before the first answer.
  Referrers? get referrers => _referrers;

  /// How many notes link here, as the lookup counted them (`truncated` when
  /// there are more than it holds); zero before an answer.
  int get count => _referrers?.items.length ?? 0;

  /// Whether the list stops short of everyone who links here: [loadMore]
  /// reads on.
  bool get truncated => _referrers?.truncated ?? false;

  /// Points the list at the note at library-relative [path] in [source]; the
  /// answer is asked for again only if either changed.
  void target(MentionSource? source, String? path) {
    if (identical(source, _source) && path == _path) return;
    if (!identical(source, _source)) {
      unawaited(_changes?.cancel());
      _changes = source?.changes.listen((_) => _later());
    }
    _source = source;
    _path = path;
    _referrers = null;
    _pages = 1;
    reload();
  }

  void _later() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(delay, reload);
  }

  /// Asks for the notes that link here now, as many pages as are shown. Only
  /// the newest answer lands.
  void reload() {
    if (_disposed) return;
    _timer?.cancel();
    final source = _source;
    final path = _path;
    final run = ++_run;
    _loadingMore = false;
    if (source == null || path == null) {
      _referrers = null;
      notifyListeners();
      return;
    }
    unawaited(() async {
      try {
        final items = <Referrer>[];
        int? next;
        for (var page = 0; page < _pages; page++) {
          final found = await source.referrersOf(path, after: next);
          if (_disposed || run != _run) return;
          items.addAll(found.items);
          next = found.next;
          if (next == null) break;
        }
        _referrers = Referrers(items, next: next);
      } on Object {
        // An index closing under the question: the list keeps what it had.
        return;
      }
      notifyListeners();
    }());
  }

  /// Adds the next page of the notes that link here, when there is one and
  /// it is not being read already.
  void loadMore() {
    final shown = _referrers;
    final source = _source;
    final path = _path;
    final after = shown?.next;
    if (_disposed || _loadingMore || after == null) return;
    if (source == null || path == null) return;
    final run = _run;
    _loadingMore = true;
    unawaited(() async {
      try {
        final found = await source.referrersOf(path, after: after);
        if (_disposed || run != _run) return;
        _pages++;
        _referrers = Referrers([
          ...shown!.items,
          ...found.items,
        ], next: found.next);
      } on Object {
        return;
      } finally {
        if (run == _run) _loadingMore = false;
      }
      notifyListeners();
    }());
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_changes?.cancel());
    super.dispose();
  }
}
