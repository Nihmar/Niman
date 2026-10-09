import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/core/logging.dart';

/// Whether the frame instrumentation runs: `--dart-define=NIMAN_FRAMES=true`
/// in a profiling build, and off in every other one (#362).
///
/// What a frame cost is read off `Stopwatch`es allocated on the path being
/// measured — one for the build, one in `performLayout` and one in `paint`
/// per wrapped subtree — so a release build runs none of it: the timers
/// inside the frames #316 is about were charged to those frames. The flag
/// covers all of it, `_reportSlowFrames` (main.dart) included.
const bool nimanFrames = bool.fromEnvironment('NIMAN_FRAMES');

/// The region a frame the two panes are silent in is reported under (#324):
/// the shell — the title bar, the tabs, the rail, the tree and the settings
/// page — which is everything above the editor and the read pane.
const String shellFrameLabel = 'shell';

/// A [FrameCost] for the shell: the region above the two panes (#324).
///
/// The editor and the read pane each name their own share of a frame (#316,
/// #323). A frame that misses *outside* them used to have no line of its own
/// — the app-wide `[frames] slow frame` (main.dart) names no region, and a
/// pane under its bar says nothing at all, so silence read the same at 2 ms
/// and at 15.9 ms. This wraps the shell so those frames are named too, under
/// [shellFrameLabel] rather than nothing.
///
/// The bar is a whole frame ([FrameCost.paneBarMicros]), as for a pane: what
/// the shell's line adds is the frame at its top, the panes' own lines being
/// the shares inside it.
FrameCost shellFrameCost({AppLogger log = const AppLogger(name: 'shell')}) =>
    FrameCost(
      label: shellFrameLabel,
      log: log,
      barMicros: FrameCost.paneBarMicros,
    );

/// What one frame of a view cost, in parts, and the line it is reported in
/// (#316).
///
/// Microseconds, accumulated while the frame is built, laid out and painted,
/// and reported once, after the frame, when the view's own share misses
/// [barMicros] — or when the edit path alone misses [editBarMicros].
///
/// One line per frame, and only for the frames that missed it: a line per frame
/// would charge the frames it measures, the same reason `_reportSlowFrames`
/// (main.dart) logs the slow ones alone.
///
/// The app's own `[frames] slow frame` line reports a frame's `build`, which
/// Flutter counts as build + layout + paint together; a view's line and that
/// one together split a frame into what this view spent and what the rest of
/// the app spent.
final class FrameCost {
  /// A cost reported as `[log] [label] frame: …`.
  new({
    required this.label,
    required this.log,
    this.barMicros = frameBarMicros,
  });

  /// This view's name in the line, e.g. `note pane`; empty for a view the
  /// logger's own name already names — the source view's `[edit] frame: …`.
  final String label;

  /// The bar this view's own share of a frame is held to.
  final int barMicros;

  /// Half of a 60 Hz frame: the bar a view whose inside has no line of its own
  /// is held to.
  static const int frameBarMicros = 8000;

  /// A whole 60 Hz frame: the bar a pane is held to, because the view inside
  /// it already reports at half of one — what the pane's line adds is the rest
  /// of the pane.
  static const int paneBarMicros = 16000;

  /// Half of the view's own bar: an edit path that costs four milliseconds
  /// before anything is drawn is worth naming on its own.
  static const int editBarMicros = 4000;

  /// The logger the line goes to, e.g. `AppLogger(name: 'read')`.
  final AppLogger log;

  /// The synchronous edit path: the delta applied, the styler told, the rows
  /// spliced, the caret scheduled. Zero on a frame no keystroke arrived in.
  int edit = 0;

  /// The view's own `build`.
  int build = 0;

  /// Laying the view's lines out.
  int layout = 0;

  /// Recording their paint.
  int paint = 0;

  /// The four parts together.
  int get total => edit + build + layout + paint;

  Stopwatch? _editClock;
  bool _booked = false;

  /// Opens the edit clock: the tokenizer callback of an edit calls this.
  void startEdit() {
    if (!nimanFrames) return;
    _editClock = Stopwatch()..start();
  }

  /// Closes the edit clock and books this frame's report.
  void endEdit() {
    if (!nimanFrames) return;
    final clock = _editClock;
    if (clock != null) {
      edit += clock.elapsedMicroseconds;
      _editClock = null;
    }
    book();
  }

  /// Runs [build], times it, and wraps what it returned so the layout and the
  /// paint under it are timed too.
  ///
  /// Off, this is [build] and nothing else: no clock, and no render object
  /// around it to time its layout and its paint.
  Widget timed(Widget Function() build) {
    if (!nimanFrames) return build();
    final clock = Stopwatch()..start();
    final child = build();
    this.build += clock.elapsedMicroseconds;
    return _TimedSubtree(cost: this, onSlow: book, child: child);
  }

  /// Books this frame's one report, to run after the frame.
  ///
  /// Called from the edit path and from the render object that times the layout
  /// and the paint: a frame no keystroke caused still has to be bookable, and a
  /// widget does not build on a scroll.
  void book() {
    if (!nimanFrames || _booked) return;
    _booked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _booked = false;
      report();
    });
  }

  /// Writes the measured parts of a frame this view drew, when they together
  /// miss [barMicros], or when the edit path alone misses [editBarMicros],
  /// and zeroes them for the next frame.
  ///
  /// [book] runs this after the frame it is about. It is visible to tests so
  /// the name a region reports a frame under can be read without a frame the
  /// test harness could make miss the bar.
  @visibleForTesting
  void report() {
    final sum = total;
    if (sum >= barMicros || edit >= editBarMicros) {
      final named = label.isEmpty ? '' : '$label ';
      log.debug(
        '${named}frame: edit ${_ms(edit)}, build ${_ms(build)}, '
        'layout ${_ms(layout)}, paint ${_ms(paint)} (${_ms(sum)} here)',
      );
    }
    edit = 0;
    build = 0;
    layout = 0;
    paint = 0;
  }

  static String _ms(int micros) => '${(micros / 1000).toStringAsFixed(1)} ms';
}

/// Times the layout and paint of the subtree under it into the cost it carries,
/// and says so when a frame's own share of the work grows past the bar.
final class _TimedSubtree extends SingleChildRenderObjectWidget {
  const new({required this.cost, required this.onSlow, required super.child});

  final FrameCost cost;

  /// Called during the frame when [cost] passes its bar, so a frame the widget
  /// did not build in — a scroll, a resize — still gets its report.
  final VoidCallback onSlow;

  @override
  _RenderTimedSubtree createRenderObject(BuildContext context) =>
      _RenderTimedSubtree(cost, onSlow);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTimedSubtree renderObject,
  ) {
    renderObject
      ..cost = cost
      ..onSlow = onSlow;
  }
}

final class _RenderTimedSubtree extends RenderProxyBox {
  new(this.cost, this.onSlow);

  FrameCost cost;
  VoidCallback onSlow;

  @override
  void performLayout() {
    final clock = Stopwatch()..start();
    super.performLayout();
    cost.layout += clock.elapsedMicroseconds;
    _noteIfSlow();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final clock = Stopwatch()..start();
    super.paint(context, offset);
    cost.paint += clock.elapsedMicroseconds;
    _noteIfSlow();
  }

  void _noteIfSlow() {
    if (cost.total >= cost.barMicros) onSlow();
  }
}
