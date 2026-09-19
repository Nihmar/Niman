/// What reaches the running app from outside it (#41, #75): the file the
/// app started with, the later launches the first instance was handed,
/// and what is dropped on the window.
///
/// Files are opened by whoever is on screen to open them: the library's
/// shell, or, with no library, the screen that opens one. Folders the
/// same. The quick actions a later launch carries go the way the launch
/// flags always went, through the shortcut service.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/launch_args.dart';

/// The requests that reach the app.
final class LaunchRequests {
  /// Requests for an app that started with `file` (null for none) and is
  /// handed [later] launches afterwards.
  new({this._file, Stream<LaunchArgs> later = const Stream.empty()})
    : _later = later.asBroadcastStream() {
    _laterFiles = _later.listen((launch) {
      if (launch.openPath case final path?) _files.add(path);
    });
  }

  String? _file;
  final Stream<LaunchArgs> _later;
  late final StreamSubscription<LaunchArgs> _laterFiles;
  final StreamController<String> _files = StreamController.broadcast();
  final StreamController<String> _folders = StreamController.broadcast();

  /// The file the app was started with, once; then null.
  String? consumeFile() {
    final file = _file;
    _file = null;
    return file;
  }

  /// Files to open: the ones later launches asked for, and the ones
  /// dropped on the window.
  Stream<String> get files => _files.stream;

  /// Folders dropped on the window (#75).
  Stream<String> get folders => _folders.stream;

  /// Every later launch: the window should come to the front for each,
  /// whatever it asked. A drop needs no such thing — the window is
  /// where it landed.
  Stream<void> get arrivals => _later.map((_) {});

  /// Asks for the file at [path] (absolute) to be opened.
  void openFile(String path) => _files.add(path);

  /// Asks for the folder at [path] (absolute) to be opened.
  void openFolder(String path) => _folders.add(path);

  /// Stops taking requests.
  Future<void> dispose() async {
    await _laterFiles.cancel();
    await _files.close();
    await _folders.close();
  }
}

/// The app's launch requests; none unless `main` hands some in.
final launchRequestsProvider = Provider<LaunchRequests>((ref) {
  final requests = LaunchRequests();
  ref.onDispose(() => unawaited(requests.dispose()));
  return requests;
});
