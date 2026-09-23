/// What `live` mode draws *around* a line's text: a list item's bullet, its
/// number or its checkbox, a quote's bar, a thematic break's rule.
///
/// Approach B (`docs/dev/unified-surface.md` §8.6.0) keeps the line's text the
/// source, character for character, and hides a marker by style — so what the
/// marker *stood for* is not in the text and has to be drawn beside it. It is
/// painted behind the line rather than laid out as widgets, which keeps the
/// paragraph the only thing the caret, the hit test and the selection measure:
/// nothing here moves an offset.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';

/// The shape a line has in its block: what `live` draws beside its text.
@immutable
final class LineShape {
  /// Creates a shape.
  const new({
    this.quoteDepth = 0,
    this.marker,
    this.ordinal,
    this.task,
    this.rule = false,
  });

  /// The shape of [line], whose block is [block] and whose index is [index].
  factory of(StyledLine line, Block? block, int index) {
    var markers = 0;
    int? marker;
    bool? task;
    var rule = false;
    for (final token in line.tokens) {
      final kind = token.kind;
      if (kind == TokenKind.blockquote) {
        markers++;
      } else if (kind == TokenKind.listMarker) {
        marker ??= token.start;
      } else if (kind == TokenKind.taskBox) {
        final box = line.text.substring(token.start, token.end);
        task = box.contains('x') || box.contains('X');
      } else if (kind == TokenKind.horizontalRule) {
        rule = true;
      }
    }
    // A lazy line of a quote carries no `>` of its own, and is still quoted.
    final quoteDepth = markers > 0 ? markers : (block?.quoteDepth ?? 0);
    final ordinal =
        marker != null &&
            block != null &&
            block.startLine == index &&
            block.listOrdinal > 0
        ? block.listOrdinal
        : null;
    if (quoteDepth == 0 && marker == null && !rule) return none;
    return LineShape(
      quoteDepth: quoteDepth,
      marker: marker,
      ordinal: ordinal,
      task: task,
      rule: rule,
    );
  }

  /// How many quote levels the line is in.
  final int quoteDepth;

  /// Where the line's list marker starts, when it opens a list item.
  final int? marker;

  /// The item's number, for an ordered item: the list's count, which is
  /// CommonMark's (`1. 1. 1.` reads 1, 2, 3) and the read view's.
  final int? ordinal;

  /// Whether the item's checkbox is ticked, for a task item; null for any
  /// other line.
  final bool? task;

  /// Whether the line is a thematic break.
  final bool rule;

  /// A line with no shape to draw.
  static const LineShape none = LineShape();

  @override
  bool operator ==(Object other) =>
      other is LineShape &&
      other.quoteDepth == quoteDepth &&
      other.marker == marker &&
      other.ordinal == ordinal &&
      other.task == task &&
      other.rule == rule;

  @override
  int get hashCode => Object.hash(quoteDepth, marker, ordinal, task, rule);
}

/// Where a list item's bullet, number or checkbox sits, in its paragraph's
/// coordinates: the indent one list level takes, ending where the item's
/// text begins — its (hidden) marker at [marker] — and one row tall.
///
/// One answer for the painter that draws there and the tap that toggles a
/// checkbox there, so the two cannot disagree about where the box is.
///
/// The row is read off the item's first character of text, not off the
/// marker: the marker is hidden, set in a hundredth of a size, and a caret
/// at it stands on the baseline with next to no height — the bullets and the
/// numbers were drawn that far below the text they belong to. An item with
/// no text yet is one row, the paragraph's own height.
Rect liveItemSlot(RenderParagraph box, int marker, MarkdownTheme theme) {
  final at = box.getOffsetForCaret(TextPosition(offset: marker), Rect.zero);
  final slot = theme.listIndentPerLevel;
  final text = box.text.toPlainText(includeSemanticsLabels: false);
  final first = _itemTextStart(text, marker);
  if (first >= text.length) {
    return Rect.fromLTWH(at.dx - slot, 0, slot, box.size.height);
  }
  final position = TextPosition(offset: first);
  final top = box.getOffsetForCaret(position, Rect.zero).dy;
  return Rect.fromLTWH(
    at.dx - slot,
    top,
    slot,
    box.getFullHeightForCaret(position),
  );
}

/// Where the text of the item whose marker starts at [marker] begins: past
/// the marker, the spaces after it and a task box.
int _itemTextStart(String text, int marker) {
  bool space(int at) => text[at] == ' ' || text[at] == '\t';
  var at = marker;
  while (at < text.length && !space(at)) {
    at++;
  }
  while (at < text.length && space(at)) {
    at++;
  }
  if (at + 2 < text.length && text[at] == '[' && text[at + 2] == ']') {
    at += 3;
    while (at < text.length && space(at)) {
      at++;
    }
  }
  return at;
}

/// Paints a line's [shape] behind it.
///
/// The painter covers the line from the pane's text edge; the paragraph
/// starts [textLeft] into it. The bullet, the number or the checkbox sits in
/// the room just before the (hidden) marker, read from the paragraph itself,
/// so an item indented by spaces has its bullet where its text begins.
final class LiveDecorationPainter extends CustomPainter {
  /// Creates the painter.
  const new({
    required this.shape,
    required this.theme,
    required this.paragraph,
    required this.textLeft,
    required this.revealed,
    required this.color,
  });

  /// What to draw.
  final LineShape shape;

  /// The note's theme: the bar's colour and width, the indents, the rule.
  final MarkdownTheme theme;

  /// The line's paragraph, for where its marker is.
  final GlobalKey paragraph;

  /// Where the paragraph starts, from the painter's left edge.
  final double textLeft;

  /// Whether the caret is on the line: its markers are drawn as written, so
  /// nothing stands in for them.
  final bool revealed;

  /// The colour of a bullet, a number and a checkbox.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    _paintQuoteBars(canvas, size);
    if (revealed) return;
    if (shape.rule) _paintRule(canvas, size);
    final marker = shape.marker;
    if (marker != null) _paintItem(canvas, marker);
  }

  void _paintQuoteBars(Canvas canvas, Size size) {
    final paint = Paint()..color = theme.quoteBar;
    for (var level = 0; level < shape.quoteDepth; level++) {
      final left = level * theme.quoteIndentPerLevel;
      canvas.drawRect(
        Rect.fromLTWH(left, 0, theme.quoteBarWidth, size.height),
        paint,
      );
    }
  }

  void _paintRule(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawRect(
      Rect.fromLTWH(
        textLeft,
        y - theme.ruleThickness / 2,
        size.width - textLeft,
        theme.ruleThickness,
      ),
      Paint()..color = theme.rule,
    );
  }

  void _paintItem(Canvas canvas, int marker) {
    final box = paragraph.currentContext?.findRenderObject();
    if (box is! RenderParagraph || !box.hasSize) return;
    final place = liveItemSlot(box, marker, theme).shift(Offset(textLeft, 0));
    final right = place.right;
    final slot = place.width;
    final middle = place.center.dy;
    final task = shape.task;
    if (task != null) {
      _paintCheckbox(canvas, place.left, middle, slot, ticked: task);
      return;
    }
    final ordinal = shape.ordinal;
    if (ordinal != null) {
      _paintText(canvas, '$ordinal.', right, middle);
      return;
    }
    canvas.drawCircle(
      Offset(right - slot / 2, middle),
      2.5,
      Paint()..color = color,
    );
  }

  void _paintCheckbox(
    Canvas canvas,
    double left,
    double middle,
    double slot, {
    required bool ticked,
  }) {
    const side = 12.0;
    final rect = Rect.fromCenter(
      center: Offset(left + slot / 2, middle),
      width: side,
      height: side,
    );
    final frame = RRect.fromRectAndRadius(rect, const Radius.circular(2));
    if (ticked) {
      canvas.drawRRect(frame, Paint()..color = color);
      final tick = Path()
        ..moveTo(rect.left + 2.5, rect.center.dy)
        ..lineTo(rect.left + side * 0.42, rect.bottom - 3)
        ..lineTo(rect.right - 2.5, rect.top + 3);
      canvas.drawPath(
        tick,
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      return;
    }
    canvas.drawRRect(
      frame,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  /// Paints [text] right-aligned to [right], centred on [middle].
  void _paintText(Canvas canvas, String text, double right, double middle) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: theme.body.copyWith(color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(right - painter.width - 4, middle - painter.height / 2),
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(LiveDecorationPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.revealed != revealed ||
      oldDelegate.textLeft != textLeft ||
      oldDelegate.color != color ||
      oldDelegate.theme != theme;
}
