/// Characters of a block tinted as a highlighter marks them: the part of a
/// book's paragraph that was annotated (#283, #285), or highlighted (#626),
/// an annotation underlined besides, as a note is behind it.
///
/// The ranges are offsets into the block's text as drawn — its paragraphs'
/// text in order, one after the other — which is what a selection of the
/// read view reports (`ReadSelection`). They are painted behind the text,
/// from the boxes its paragraphs lay out, so the block keeps its own layout
/// and a range follows the text wherever it wraps.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/render/mark_highlight.dart';

/// A character range of a block's text, the end excluded.
typedef CharRange = ({int start, int end});

/// A block's mark: the line it falls on, the characters of the block's
/// text it covers, or null for the whole block, and a highlight's colour —
/// null for an annotation.
typedef BlockMark = ({int line, CharRange? chars, HighlightColour? highlight});

/// Paints [ranges] of [child]'s text in [color], behind it, and a dotted
/// [underline] under them when there is one.
final class RangeHighlight extends SingleChildRenderObjectWidget {
  /// Tints [ranges] of [child]'s text.
  const new({
    required this.ranges,
    required this.color,
    this.underline,
    super.child,
    super.key,
  });

  /// The ranges, in the block's text.
  final List<CharRange> ranges;

  /// Their tint.
  final Color color;

  /// The colour of a dotted line under them; null draws none.
  final Color? underline;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderRangeHighlight(ranges, color, underline);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderRangeHighlight renderObject,
  ) {
    renderObject
      ..ranges = ranges
      ..color = color
      ..underline = underline;
  }
}

/// The render object of [RangeHighlight].
final class RenderRangeHighlight extends RenderProxyBox {
  /// Tints [ranges] of its child's text in [color], underlined in
  /// [underline] when it is given.
  new(this._ranges, this._color, [this._underline]);

  /// The ranges tinted.
  List<CharRange> get ranges => _ranges;
  List<CharRange> _ranges;
  set ranges(List<CharRange> value) {
    if (_ranges == value) return;
    _ranges = value;
    markNeedsPaint();
  }

  /// Their tint.
  Color get color => _color;
  Color _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }

  /// The colour of the dotted line under them, or null.
  Color? get underline => _underline;
  Color? _underline;
  set underline(Color? value) {
    if (_underline == value) return;
    _underline = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child != null && _ranges.isNotEmpty) {
      final paint = Paint()..color = _color;
      final underline = _underline;
      var base = 0;
      for (final paragraph in _paragraphsOf(child)) {
        final length = paragraph.text.toPlainText().length;
        final transform = paragraph.getTransformTo(this);
        for (final range in _ranges) {
          final start = math.max(range.start - base, 0);
          final end = math.min(range.end - base, length);
          if (start >= end) continue;
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: start, extentOffset: end),
          );
          for (final box in boxes) {
            final rect = MatrixUtils.transformRect(transform, box.toRect());
            final shifted = rect.shift(offset);
            context.canvas.drawRRect(
              RRect.fromRectAndRadius(
                shifted.inflate(1),
                const Radius.circular(2),
              ),
              paint,
            );
            if (underline != null) {
              paintDottedUnderline(context.canvas, shifted, underline);
            }
          }
        }
        base += length;
      }
    }
    super.paint(context, offset);
  }

  /// The paragraphs under [root], in the order their text is read.
  static List<RenderParagraph> _paragraphsOf(RenderObject root) {
    final out = <RenderParagraph>[];
    void visit(RenderObject node) {
      if (node is RenderParagraph) {
        out.add(node);
        return;
      }
      node.visitChildren(visit);
    }

    visit(root);
    return out;
  }
}
