/// What launches ask of the running app (#41): the file the app started
/// with, and every later launch the first instance was handed.
///
/// Files are opened by whoever is on screen to open them: the library's
/// shell, or, with no library, the screen that opens one. The quick
/// actions a later launch carries go the way the launch flags always
/// went, through the shortcut service.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/launch_args.dart';

/// The launches that reach the app.
final class LaunchRequests {
  /// Requests for an app that started with `file` (null for none) and is
  /// handed [later] launches afterwards.
  new({this._file, Stream<LaunchArgs> later = const Stream.empty()})
    : _later = later.asBroadcastStream();

  String? _file;
  final Stream<LaunchArgs> _later;

  /// The file the app was started with, once; then null.
  String? consumeFile() {
    final file = _file;
    _file = null;
    return file;
  }

  /// Files later launches asked to open.
  Stream<String> get files => _later
      .map((launch) => launch.openPath)
      .where((path) => path != null)
      .cast<String>();

  /// Every later launch: the window should come to the front for each,
  /// whatever it asked.
  Stream<void> get arrivals => _later.map((_) {});
}

/// The app's launch requests; empty unless `main` hands some in.
final launchRequestsProvider = Provider<LaunchRequests>(
  (ref) => LaunchRequests(),
);
