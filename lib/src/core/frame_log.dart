import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart' show State;
import 'package:niman/src/core/logging.dart';

/// Logs one line when the next UI frame lands.
///
/// A [State.setState] (or an awaited load followed by one) only becomes
/// visible when the next frame is drawn, so the delta between the call and
/// the callback is the time the action took to reach the pixels — the
/// number a user feels — while the line's own timestamp says when the
/// engine actually drew it. Call it right after a state change to measure
/// the action's time-to-visible, e.g. "how long after a tab tap did the
/// first new frame (and the navigation-bar animation) paint".
///
/// If no frame is pending it requests one (a single frame, no visible
/// effect); a call made mid-frame reports the following frame.
void logNextFrame(String name, String what) {
  final started = DateTime.now();
  SchedulerBinding.instance.scheduleFrameCallback((details) {
    final delta = DateTime.now().difference(started);
    AppLogger(name: name).debug(
      '$what: first frame '
      '${(delta.inMicroseconds / 1000).toStringAsFixed(2)}ms after call',
    );
  });
}
