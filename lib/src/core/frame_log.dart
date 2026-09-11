import 'dart:async';

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

/// Summarises the frames that follow an action, attributing them to it.
///
/// [logNextFrame] answers "when did the first new frame land"; this answers
/// "what did the frames after it cost", which is the question a tab switch
/// or a preview build actually raises. The app-wide slow-frame log
/// (`_reportSlowFrames` in `main.dart`) reports the cost but flushes in
/// batches, so nothing in an exported log says which action caused which
/// frame — which is how three tab-switch hypotheses were "confirmed" and
/// then measured away (#46, #48).
///
/// One line per window, never one per frame: formatting per frame charges
/// the very frames it measures and fills the buffer in minutes, which is
/// why the app does not time every frame. A window opened while another is
/// running supersedes it, so a rapid double-tap reports once, for the last
/// action — a stale window would otherwise blame its frames on the wrong
/// one.
final class FrameProbe {
  const new _();

  static int _revision = 0;
  static TimingsCallback? _attached;

  /// Watches the frames for [window] from now, then logs one summary line
  /// under [name] describing [what].
  static void watch(
    String name,
    String what, {
    Duration window = const Duration(milliseconds: 400),
    Duration budget = const Duration(milliseconds: 16),
  }) {
    final token = ++_revision;
    _detach();
    var frames = 0;
    var over = 0;
    var worstBuild = Duration.zero;
    var worstRaster = Duration.zero;
    var buildTotal = Duration.zero;
    void collect(List<FrameTiming> timings) {
      for (final timing in timings) {
        frames++;
        buildTotal += timing.buildDuration;
        if (timing.buildDuration > worstBuild) {
          worstBuild = timing.buildDuration;
        }
        if (timing.rasterDuration > worstRaster) {
          worstRaster = timing.rasterDuration;
        }
        if (timing.totalSpan >= budget) over++;
      }
    }

    _attached = collect;
    SchedulerBinding.instance.addTimingsCallback(collect);
    Timer(window, () {
      if (token != _revision) return;
      _detach();
      AppLogger(name: name).debug(
        '$what: $frames frame(s) in ${window.inMilliseconds}ms, '
        '$over over budget, worst build ${_ms(worstBuild)}, '
        'worst raster ${_ms(worstRaster)}, build total ${_ms(buildTotal)}',
      );
    });
  }

  static void _detach() {
    final attached = _attached;
    if (attached == null) return;
    SchedulerBinding.instance.removeTimingsCallback(attached);
    _attached = null;
  }

  static String _ms(Duration d) =>
      '${(d.inMicroseconds / 1000).toStringAsFixed(1)}ms';
}
