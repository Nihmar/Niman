// #169: the title bar's caption buttons, told to the Windows runner.
//
// Windows offers the Snap Layouts flyout only to a window that answers
// `WM_NCHITTEST` with `HTMAXBUTTON` over its maximize button, and it takes
// the minimize and close buttons from the same answer. The title bar is
// drawn in Flutter (`title_bar.dart`), so the runner cannot work the
// rectangles out for itself: whatever it derived would be a constant that
// the first change to the bar — the tabs (#23), a different button width,
// another scale factor — turns into a lie. This carries the rectangles the
// bar actually laid out instead, in physical pixels from the window's
// client origin: the space the runner's hit test works in.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:niman/src/core/logging.dart';

/// Reports the caption buttons' rectangles to the Windows runner.
final class CaptionButtonsChannel {
  /// Creates the reporter.
  ///
  /// [channel] and [windows] are seams for tests: outside Windows there is
  /// no runner on the other end, so nothing is sent.
  new({MethodChannel? channel, bool? windows})
    : _channel = channel ?? const MethodChannel(channelName),
      _windows = windows ?? Platform.isWindows;

  /// The channel the runner listens on.
  static const String channelName = 'niman/window';

  /// The method carrying the three rectangles.
  static const String method = 'setCaptionButtons';

  static const AppLogger _log = AppLogger(name: 'window');

  final MethodChannel _channel;
  final bool _windows;

  /// Where the three buttons lie, each in physical pixels from the
  /// window's client origin.
  ///
  /// Fire and forget: the bar reports on every layout it changes, and a
  /// report that never arrives only leaves the hit test answering the way
  /// it did before the buttons were reported.
  void report({
    required Rect minimize,
    required Rect maximize,
    required Rect close,
  }) {
    if (!_windows) return;
    unawaited(_send(minimize: minimize, maximize: maximize, close: close));
  }

  Future<void> _send({
    required Rect minimize,
    required Rect maximize,
    required Rect close,
  }) async {
    try {
      await _channel.invokeMethod<void>(method, {
        'minimize': _bounds(minimize),
        'maximize': _bounds(maximize),
        'close': _bounds(close),
      });
    } on MissingPluginException {
      // No runner on the other end (a test host, a build older than the
      // runner's side of this channel).
    } on PlatformException catch (error) {
      _log.warning('caption buttons not reported ($error)');
    }
  }

  /// One button's bounds in whole pixels.
  static Map<String, int> _bounds(Rect rect) => {
    'left': rect.left.round(),
    'top': rect.top.round(),
    'right': rect.right.round(),
    'bottom': rect.bottom.round(),
  };
}
