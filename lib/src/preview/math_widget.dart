import 'dart:async';

import 'package:copist/src/preview/math_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:katex/katex.dart';
import 'package:katex_dart/katex_dart.dart' show BoxNode;
import 'package:markdown/markdown.dart' as md;

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

/// The inline-math builder: renders the `math` element (from
/// splitInlineMath) as a baselined inline widget. The box is cached per
/// tex — no re-parse on rebuild; a placeholder box shows while the render
/// is in flight.
final class MathInlineBuilder extends MarkdownElementBuilder {
  /// Creates an inline builder over [cache] with [style].
  new({required this.cache, required this.style});

  /// The render cache the builder serves from.
  final MathCache cache;

  /// The math style (size/color).
  final MathStyle style;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return InlineMathView(cache: cache, tex: _latexOf(element), style: style);
  }
}

/// The display-math block builder: renders the `mathblock` element (from
/// MathBlockSyntax) centered, as its own block widget.
final class MathBlockBuilder extends MarkdownElementBuilder {
  /// Creates a block builder over [cache] with [style].
  new({required this.cache, required this.style});

  /// The cache the block builder serves from.
  final MathCache cache;

  /// The math style (size/color).
  final MathStyle style;

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: BlockMathView(
          cache: cache,
          tex: _latexOf(element),
          style: style,
        ),
      ),
    );
  }
}

String _latexOf(md.Element element) {
  final attr = element.attributes['latex'];
  if (attr != null) return attr;
  final children = element.children;
  if (children != null && children.isNotEmpty && children.first is md.Text) {
    return (children.first as md.Text).text;
  }
  return '';
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
    super.key,
  });

  /// The render cache this view serves from.
  final MathCache cache;

  /// The LaTeX source.
  final String tex;

  /// The math style (size/color).
  final MathStyle style;

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
      return _mathBoxFromCache(context, box: box, style: widget.style);
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
      painter: KatexBoxPainter(
        box,
        fontSize: style.fontSize,
        color: _resolveColor(context, style),
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
    return _RenderInlineMath(box, style, _resolveColor(context, style));
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderInlineMath renderObject,
  ) {
    renderObject
      ..box = box
      ..style = style
      ..color = _resolveColor(context, style);
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

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    KatexBoxPainter(
      box,
      fontSize: style.fontSize,
      color: color,
    ).paint(context.canvas, size);
    context.canvas.restore();
  }
}
