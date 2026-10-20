/// ⌘Q on a Mac: the runner asks before it terminates (decision 11 of
/// docs/records/apple-platforms.md).
///
/// The × hides the window there, so a quit is the only real close: ⌘Q, the
/// app menu's Quit, the Dock's Quit and a logout all end in the app
/// delegate's `applicationShouldTerminate`. It holds the terminate and
/// sends `requested` over this channel; the close guard runs the same close
/// the tray's Quit does, asking about unsaved notes, and answers with
/// `confirm`, which lets the terminate through. A runner nobody answers —
/// the app still starting, the guard gone — terminates at once.
library;

import 'dart:io';

import 'package:flutter/services.dart';

/// The runner's quit channel.
final class MacQuit {
  const new _();

  static const MethodChannel _channel = MethodChannel('niman/quit');

  /// Hands the runner's quit requests to [onRequested]; nothing off macOS.
  static void listen(void Function() onRequested) {
    if (!Platform.isMacOS) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'requested') onRequested();
    });
  }

  /// Stops listening: a quit asked for afterwards goes straight through.
  static void stop() {
    if (!Platform.isMacOS) return;
    _channel.setMethodCallHandler(null);
  }

  /// Lets the held quit through: the runner terminates the app.
  static Future<void> confirm() => _channel.invokeMethod<void>('confirm');
}
