/// A Windows session ending — shutdown, restart, logoff — waits for the notes
/// to be written (#1364).
///
/// The close guard vetoes a window close while saves are pending, but a
/// session end is not a window close: Windows sends the window
/// `WM_QUERYENDSESSION` and then `WM_ENDSESSION`, the veto is not asked, and
/// the process is gone a moment later. The edits of the last debounce — up to
/// five seconds of typing, twenty or thirty on a big note — were lost.
///
/// The runner (`windows/runner/flutter_window.cpp`) answers
/// `WM_QUERYENDSESSION` by sending `flush` over this channel and not
/// replying to Windows until the answer comes back; the answer is sent when
/// the disk holds the latest text of every note, or when a write failed. The
/// runner gives up after its own deadline, so a note that cannot be written
/// never holds the machine.
library;

import 'package:flutter/services.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

/// The runner's session-end channel: the Dart side of it.
final class SessionEnd {
  /// Answers the runner's `flush` by writing what [tracker] holds unsaved.
  /// [channel] is a seam for tests.
  new({required this.tracker, MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  /// The channel's name, the one `flutter_window.cpp` opens.
  static const String channelName = 'niman/session';

  /// The method the runner calls when the session is ending.
  static const String flushMethod = 'flush';

  static const AppLogger _log = AppLogger(name: 'session-end');

  /// The notes' registry whose unsaved text is written.
  final UnsavedTracker tracker;

  final MethodChannel _channel;

  /// Starts answering the runner. Nothing calls it off Windows.
  void listen() => _channel.setMethodCallHandler(_onCall);

  /// Stops answering: a session end afterwards goes through at once.
  void stop() => _channel.setMethodCallHandler(null);

  Future<Object?> _onCall(MethodCall call) async {
    if (call.method != flushMethod) {
      throw MissingPluginException('no ${call.method} on $channelName');
    }
    return await flush();
  }

  /// Writes every unsaved note and answers whether the disk holds them all:
  /// false when a write failed, which the runner takes as no reason to hold
  /// the session any longer.
  Future<bool> flush() async {
    if (!tracker.hasUnsaved) return true;
    _log.info('session ending: writing the unsaved notes first');
    try {
      await tracker.saveAll();
      return true;
    } on Object catch (error) {
      _log.warning('session end: a note could not be written ($error)');
      return false;
    }
  }
}
