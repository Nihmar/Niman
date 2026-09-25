/// The marks of the file a pane shows (#285), kept current: asked when the
/// pane opens the file, and again a moment after a note changes — a
/// companion edited, an annotation written — so the file shows what its
/// notes say without being reopened.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/annotations/annotation_mark.dart';
import 'package:niman/src/annotations/annotation_mark_source.dart';
import 'package:niman/src/core/logging.dart';

/// The marks of the file at one path.
final class FileMarks extends ChangeNotifier {
  /// Follows the marks of the file at library-relative [path].
  new(this.source, this.path) {
    _changes = source.changes.listen((_) {
      _timer?.cancel();
      _timer = Timer(settleDelay, () => unawaited(_load()));
    });
    unawaited(_load());
  }

  /// How long the notes rest before the marks are asked again: a note
  /// being typed in saves often.
  static const Duration settleDelay = Duration(milliseconds: 500);

  static const AppLogger _log = AppLogger(name: 'annotations');

  /// Where the marks come from.
  final AnnotationMarkSource source;

  /// The file, library-relative.
  final String path;

  /// The marks, as last read; none until they are.
  List<AnnotationMark> get marks => _marks;
  List<AnnotationMark> _marks = const [];

  late final StreamSubscription<Object?> _changes;
  Timer? _timer;
  int _loads = 0;
  bool _disposed = false;

  Future<void> _load() async {
    final load = ++_loads;
    try {
      final marks = await source.marksOf(path);
      if (_disposed || load != _loads || listEquals(marks, _marks)) return;
      _marks = marks;
      notifyListeners();
    } on Object catch (error) {
      _log.warning('could not read the marks of $path: $error');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_changes.cancel());
    super.dispose();
  }
}
