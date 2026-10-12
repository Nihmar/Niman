/// The files a view keeps open, and the order an operation on them
/// keeps (#833): every view holding the file, or a file under the folder,
/// lets go of it first, the operation runs, and the views take it back.
///
/// A PDF on screen is open in pdfium for as long as its tab lives, and a
/// clip being played is open in the platform's player. Windows refuses to
/// rename, move or delete a file another handle holds (a sharing
/// violation, errno 32); Linux and Android do not care. So the order is
/// kept on every platform, and a view of a file behaves the same on all
/// three: it goes blank while its file is moved, then shows it again.
library;

import 'dart:async';

import 'package:path/path.dart' as p;

/// What a view does to let go of its file: closes it, and completes once
/// the handle is really closed.
typedef FileRelease = Future<void> Function();

/// The views holding files open, by absolute path.
final class FileHolds {
  /// An empty registry; [instance] is the app's.
  new();

  /// The app's registry: a file handle is the process's, whichever
  /// library or window opened it.
  static final FileHolds instance = FileHolds();

  final Set<FileHold> _holds = {};

  /// Records that a view holds the file at [path] (absolute) open:
  /// [release] closes it, [resume] opens it again (where the view now
  /// points — a rename has moved it on by then). The view drops the
  /// returned hold when it lets go for good.
  FileHold hold(
    String path, {
    required FileRelease release,
    void Function()? resume,
  }) {
    final hold = FileHold._(this, path, release, resume);
    _holds.add(hold);
    return hold;
  }

  /// The holds on [path] (absolute), or on any file under it.
  List<FileHold> holding(String path) => [
    for (final hold in _holds)
      if (p.equals(hold.path, path) || p.isWithin(path, hold.path)) hold,
  ];

  /// Runs [operation] on the files at [paths] (absolute, a folder covering
  /// what is under it) once every view holding one has let go of it, and
  /// hands the files back to the views after it, whether it succeeded or
  /// failed.
  Future<T> around<T>(
    Iterable<String> paths,
    Future<T> Function() operation,
  ) async {
    final affected = {for (final path in paths) ...holding(path)};
    try {
      await Future.wait([for (final hold in affected) hold._release()]);
      return await operation();
    } finally {
      for (final hold in affected) {
        hold._resume();
      }
    }
  }
}

/// One view's hold on one file ([FileHolds.hold]).
final class FileHold {
  new _(this._owner, this.path, this._close, this._onResume);

  final FileHolds _owner;

  /// The file held, absolute.
  final String path;

  final FileRelease _close;
  final void Function()? _onResume;

  /// How many operations have the file let go of: two at once (a file
  /// and its folder) release it once and give it back once.
  int _released = 0;

  /// The release under way or done, which a second operation waits on.
  Future<void>? _releasing;

  /// Whether the view has the file let go of, for an operation.
  bool get released => _released > 0;

  Future<void> _release() {
    _released++;
    return _releasing ??= _close();
  }

  void _resume() {
    if (--_released > 0) return;
    _releasing = null;
    if (!_owner._holds.contains(this)) return;
    _onResume?.call();
  }

  /// Drops the hold: the view let go of the file for good.
  void drop() => _owner._holds.remove(this);
}
