import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/links/mentions.dart';
import 'package:niman/src/links/resolver.dart';

/// The notes that link to one note (#842), kept current for the surfaces that
/// list them — the note view's section, the dock's pane, the phone's sheet.
///
/// One indexed lookup ([LinkSource.referrersOf]) when the note or the library
/// changes, and again a pause after the library's index moves (a note
/// elsewhere that gained or lost a link to this one). Nothing is read from the
/// notes themselves here: the rows ask for the line they show as they are
/// drawn.
final class LinksToNoteController extends ChangeNotifier {
  /// A controller that waits [delay] after the index moves before it asks
  /// again.
  new({this.delay = const Duration(milliseconds: 400)});

  /// How long the library's index has to be still before the list is asked
  /// for again.
  final Duration delay;

  LinkSource? _source;
  String? _path;
  Referrers? _referrers;
  StreamSubscription<void>? _changes;
  Timer? _timer;
  int _run = 0;
  bool _disposed = false;

  /// The library the list is read from, or null while none is open.
  LinkSource? get source => _source;

  /// The library-relative path of the note the list is for, or null.
  String? get path => _path;

  /// The notes that link to the note, or null before the first answer.
  Referrers? get referrers => _referrers;

  /// How many notes link here, as the lookup counted them (`truncated` when
  /// there are more than it holds); zero before an answer.
  int get count => _referrers?.items.length ?? 0;

  /// Whether the list stops short of everyone who links here.
  bool get truncated => _referrers?.truncated ?? false;

  /// Points the list at the note at library-relative [path] in [source]; the
  /// answer is asked for again only if either changed.
  void target(LinkSource? source, String? path) {
    if (identical(source, _source) && path == _path) return;
    if (!identical(source, _source)) {
      unawaited(_changes?.cancel());
      _changes = source?.changes.listen((_) => _later());
    }
    _source = source;
    _path = path;
    _referrers = null;
    reload();
  }

  void _later() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(delay, reload);
  }

  /// Asks for the notes that link here now. Only the newest answer lands.
  void reload() {
    if (_disposed) return;
    _timer?.cancel();
    final source = _source;
    final path = _path;
    final run = ++_run;
    if (source == null || path == null) {
      _referrers = null;
      notifyListeners();
      return;
    }
    unawaited(() async {
      try {
        final found = await source.referrersOf(path);
        if (_disposed || run != _run) return;
        _referrers = found;
      } on Object {
        // An index closing under the question: the list keeps what it had.
        return;
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
