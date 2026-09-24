import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:katex/katex.dart';
import 'package:katex_dart/katex_dart.dart' show BoxNode;
import 'package:niman/src/preview/math_box_painter.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/math_line_break.dart';
import 'package:niman/src/preview/math_raster.dart';

/// Defers math typesetting while the preview is scrolling (T-PP-22).
///
/// A scroll lays out dozens of blocks per frame, and a math-heavy note
/// typesets a formula in each of them: on the 934 KB geometry note the
/// preview spent 5-6 ms per block, most of a frame's budget, which is what
/// made scrolling stutter. While [deferring] is on, a math view keeps its
/// placeholder and re-requests its box when the flag flips back (settle),
/// so the gesture stays cheap and the typesetting happens between
/// gestures.
final class MathDeferScope extends InheritedWidget {
  /// Creates the scope; [deferring] is the preview's scroll state.
  const new({required this.deferring, required super.child, super.key});

  /// Whether math views below should hold their placeholders.
  final bool deferring;

  /// The nearest scope's flag, or null outside a preview.
  static MathDeferScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MathDeferScope>();

  @override
  bool updateShouldNotify(MathDeferScope oldWidget) =>
      oldWidget.deferring != deferring;
}

/// Visual style for the preview's math (text size in px-per-em, color).
final class MathStyle {
  /// Creates the style.
  const new({this.fontSize = 15, this.color});

  /// Logical pixels per em (match the surrounding text's font size).
  final double fontSize;

  /// The math color; null inherits the ambient text color.
  final Color? color;
}

/// A baselined inline math widget, rendering from [cache].
final class InlineMathView extends StatefulWidget {
  /// Creates the inline view.
  const new({
    required this.cache,
    required this.tex,
    required this.style,
    super.key,
  });

  /// The render cache this view serves from.
  final MathCache cache;

  /// The LaTeX source.
  final String tex;

  /// The math style (size/color).
  final MathStyle style;

  @override
  State<InlineMathView> createState() => _InlineMathViewState();
}

class _InlineMathViewState extends State<InlineMathView> {
  /// Bumped per request so a stale completion never rebuilds a recycled
  /// view.
  int _revision = 0;

  /// Whether the preview is scrolling: the render waits for the settle.
  bool _deferring = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _deferring = MathDeferScope.of(context)?.deferring ?? false;
    if (!_deferring) _request();
  }

  @override
  void didUpdateWidget(InlineMathView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cache != widget.cache || oldWidget.tex != widget.tex) {
      _request();
    }
  }

  /// Renders this span through the cache and rebuilds only this view when
  /// it lands. A listener on the shared cache would rebuild every mounted
  /// formula on every other formula's render — the scroll-time storm on
  /// math-heavy notes (T-PP-22); the cache's own dedupe still shares one
  /// render between views of the same tex.
  void _request() {
    final revision = ++_revision;
    if (widget.cache.boxFor(widget.tex, displayMode: false) != null) {
      // Count the reuse (the edit-reuse AC's measurement) without a
      // rebuild: the box is already in hand.
      unawaited(widget.cache.ensure(widget.tex, displayMode: false));
      return;
    }
    if (_deferring) return; // didChangeDependencies re-runs on settle
    unawaited(
      widget.cache.ensure(widget.tex, displayMode: false).then((_) {
        if (mounted && revision == _revision) setState(() {});
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.cache.boxFor(widget.tex, displayMode: false);
    if (box != null) {
      return Text.rich(
        TextSpan(
          children: <InlineSpan>[
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: _InlineMathBox(box: box, style: widget.style),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      );
    }
    if (widget.cache.isError(widget.tex, displayMode: false)) {
      return Text.rich(
        TextSpan(
          text: widget.tex,
          style: const TextStyle(color: Color(0xFFCC0000)),
        ),
      );
    }
    // Pending render: a small placeholder box (design.md).
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: SizedBox(
              width: widget.style.fontSize * 0.7,
              height: widget.style.fontSize * 0.9,
              child: const Center(
                child: Text('…', style: TextStyle(color: Color(0xFF9E9E9E))),
              ),
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    );
  }
}

/// A centered display-math box, rendering from [cache].
final class BlockMathView extends StatefulWidget {
  /// Creates the display view.
  const new({
    required this.cache,
    required this.tex,
    required this.style,
    this.maxWidth,
    super.key,
  });

  /// The render cache this view serves from.
  final MathCache cache;

  /// The LaTeX source.
  final String tex;

  /// The math style (size/color).
  final MathStyle style;

  /// How wide a pane this formula has to fit, or null for "as wide as it
  /// needs".
  ///
  /// A display formula wider than the pane is broken at its own operators
  /// (`preview/math_line_break.dart`, #257); null keeps the old behaviour of
  /// drawing it whole, which is what a caller that does not know a width — a
  /// test, an intrinsic pass — is asking for.
  final double? maxWidth;

  @override
  State<BlockMathView> createState() => _BlockMathViewState();
}

class _BlockMathViewState extends State<BlockMathView> {
  /// Bumped per request so a stale completion never rebuilds a recycled
  /// view.
  int _revision = 0;

  /// Whether the preview is scrolling: the render waits for the settle.
  bool _deferring = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _deferring = MathDeferScope.of(context)?.deferring ?? false;
    if (!_deferring) _request();
  }

  @override
  void didUpdateWidget(BlockMathView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cache != widget.cache || oldWidget.tex != widget.tex) {
      _request();
    }
  }

  /// The smallest a formula is shrunk to before it is drawn as it is: half the
  /// note's own size, which is 7.5 px for the default 15. It is a floor rather
  /// than a rule because the measurements say it is enough — of the geometry
  /// note's 824 display formulas, the widest *piece* left over after breaking
  /// needs 1.45× a phone pane, i.e. 0.69 of the size it was written at.
  static const double minimumDisplayScale = 0.5;

  /// The formula, broken across lines when the pane is narrower than it is and
  /// shrunk when breaking was not enough.
  ///
  /// Full size on two lines beats shrunk onto one: a reader studying from a
  /// phone can follow `a =` / `b + c`, and 60 % of a 15 px formula cannot be
  /// read at all. What breaking cannot help with is the tail — a matrix, an
  /// `aligned` block, a stretched delimiter pair — and there the answer is to
  /// shrink the whole formula until it fits, floored at
  /// [minimumDisplayScale], rather than to cut it (#257).
  Widget _fitted(BuildContext context, BoxNode box) {
    final available = widget.maxWidth;
    if (available == null || !available.isFinite || available <= 0) {
      return _mathBoxFromCache(context, box: box, style: widget.style);
    }
    var style = widget.style;
    final pad = kInkOverflowPadEm * style.fontSize;
    final lines = boxSizePxPadded(box, style.fontSize).width <= available
        ? <BoxNode>[box]
        : breakDisplayMath(box, maxEm: (available - 2 * pad) / style.fontSize);
    final widest = lines
        .map((line) => boxSizePxPadded(line, style.fontSize).width)
        .reduce(math.max);
    if (widest > available) {
      final scale = (available / widest).clamp(minimumDisplayScale, 1.0);
      style = MathStyle(fontSize: style.fontSize * scale, color: style.color);
    }
    if (lines.length < 2) {
      return _mathBoxFromCache(context, box: lines.single, style: style);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (var at = 0; at < lines.length; at++) ...<Widget>[
          if (at > 0) SizedBox(height: style.fontSize * 0.4),
          _mathBoxFromCache(context, box: lines[at], style: style),
        ],
      ],
    );
  }

  /// See [_InlineMathViewState._request]: one render, one rebuild of the
  /// view that asked for it.
  void _request() {
    final revision = ++_revision;
    if (widget.cache.boxFor(widget.tex, displayMode: true) != null) {
      unawaited(widget.cache.ensure(widget.tex, displayMode: true));
      return;
    }
    if (_deferring) return; // didChangeDependencies re-runs on settle
    unawaited(
      widget.cache.ensure(widget.tex, displayMode: true).then((_) {
        if (mounted && revision == _revision) setState(() {});
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.cache.boxFor(widget.tex, displayMode: true);
    if (box != null) {
      return _fitted(context, box);
    }
    if (widget.cache.isError(widget.tex, displayMode: true)) {
      return Text(widget.tex, style: const TextStyle(color: Color(0xFFCC0000)));
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '…',
        style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Paints a cached box with the katex box painter, sized with the same ink
/// pad the katex `Math` widget uses (so glyph overflow is never clipped).
///
/// The color follows the ambient text style (dark mode!): an explicit
/// [MathStyle.color] wins, the surrounding [BuildContext]'s default text
/// color is inherited otherwise, and black is only the last resort.
Widget _mathBoxFromCache(
  BuildContext context, {
  required BoxNode box,
  required MathStyle style,
}) {
  final size = boxSizePxPadded(box, style.fontSize);
  return SizedBox.fromSize(
    size: size,
    child: CustomPaint(
      size: size,
      painter: MathBoxPainter(
        box,
        fontSize: style.fontSize,
        color: _resolveColor(context, style),
        devicePixelRatio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
        inkPadEm: kInkOverflowPadEm,
      ),
    ),
  );
}

/// The leaf that reports its alphabetic baseline (box.height x fontSize
/// below the top), so inline math rests on the text baseline — the katex
/// package's own inline strategy, implemented on its public painter APIs.
final class _InlineMathBox extends LeafRenderObjectWidget {
  const new({required this.box, required this.style});

  final BoxNode box;
  final MathStyle style;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderInlineMath(box, style, _resolveColor(context, style))
      ..devicePixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderInlineMath renderObject,
  ) {
    renderObject
      ..box = box
      ..style = style
      ..color = _resolveColor(context, style)
      ..devicePixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
  }
}

/// The math color for [style] in [context]: an explicit [MathStyle.color]
/// wins, the ambient default text color (dark mode!) is inherited
/// otherwise, and black is only the last resort.
Color _resolveColor(BuildContext context, MathStyle style) =>
    style.color ??
    DefaultTextStyle.of(context).style.color ??
    const Color(0xFF000000);

final class _RenderInlineMath extends RenderBox {
  new(this.box, this.style, this.color);

  BoxNode box;
  MathStyle style;
  Color color;

  Size _measure() => boxSizePx(box, style.fontSize);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(_measure());

  @override
  void performLayout() {
    size = constraints.constrain(_measure());
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      box.height * style.fontSize;

  /// The same baseline, without laying out — the question a `WidgetSpan` is
  /// asked wherever sizes are intrinsic.
  ///
  /// A table's `IntrinsicColumnWidth` asks a cell's paragraph for its intrinsic
  /// size, and that asks its placeholders for a *dry* baseline. Flutter treats
  /// a `RenderBox` that answers only the laid-out one as broken:
  /// an assertion in debug, a wrong baseline in release. So a table cell
  /// holding inline math threw — the engine's geometry gate found it (§8.4.4),
  /// and this is the half that was missing.
  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => computeDistanceToActualBaseline(baseline);

  /// The screen's pixels per logical pixel, for a formula drawn through an
  /// image (`paintMath`).
  double devicePixelRatio = 1;

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    paintMath(
      context.canvas,
      size,
      box,
      fontSize: style.fontSize,
      color: color,
      devicePixelRatio: devicePixelRatio,
    );
    context.canvas.restore();
  }
}
