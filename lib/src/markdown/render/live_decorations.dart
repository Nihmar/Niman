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

import 'dart:math' as math;

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
    this.listDepth = 0,
    this.box,
    this.ordinal,
    this.task,
    this.rule = false,
  });

  /// The shape of [line], whose block is [block] and whose index is [index].
  factory of(StyledLine line, Block? block, int index) {
    var markers = 0;
    int? marker;
    int? box;
    bool? task;
    var rule = false;
    for (final token in line.tokens) {
      final kind = token.kind;
      if (kind == TokenKind.blockquote) {
        markers++;
      } else if (kind == TokenKind.listMarker) {
        marker ??= token.start;
      } else if (kind == TokenKind.taskBox) {
        box = token.start;
        final written = line.text.substring(token.start, token.end);
        task = written.contains('x') || written.contains('X');
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
      // A line the scan has not reached yet is at the top level.
      listDepth: marker == null ? 0 : math.max(0, block?.listDepth ?? 0),
      box: box,
      ordinal: ordinal,
      task: task,
      rule: rule,
    );
  }

  /// How many quote levels the line is in.
  final int quoteDepth;

  /// Where the line's list marker starts, when it opens a list item.
  final int? marker;

  /// How many list levels deep the item is, 0 at the top: the columns its
  /// text is set in by, as the read view sets it.
  final int listDepth;

  /// Where the item's task box (`[ ]`) starts, for a task item: its text
  /// starts past the box, and the box is drawn where a bullet would be.
  final int? box;

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
      other.listDepth == listDepth &&
      other.box == box &&
      other.ordinal == ordinal &&
      other.task == task &&
      other.rule == rule;

  @override
  int get hashCode =>
      Object.hash(quoteDepth, marker, listDepth, box, ordinal, task, rule);
}

/// Where a list item's bullet, number or checkbox sits, in its paragraph's
/// coordinates: the column one list level takes, one row tall, ending where
/// the item's text begins — which is where the read view's column ends.
///
/// One answer for the painter that draws there and the tap that toggles a
/// checkbox there, so the two cannot disagree about where the box is.
///
/// The row is read off the item's first character of text, not off the
/// marker: the marker is hidden, set in a hundredth of a size, and a caret
/// at it stands on the baseline with next to no height — the bullets and the
/// numbers were drawn that far below the text they belong to. An item with
/// no text yet is one row, the paragraph's own height.
Rect liveItemSlot(RenderParagraph box, LineShape shape, MarkdownTheme theme) {
  final text = box.text.toPlainText(includeSemanticsLabels: false);
  final taskBox = shape.box;
  final first = taskBox == null
      ? _pastSpaces(text, _pastMark(text, shape.marker ?? 0))
      : _pastSpaces(text, taskBox + 3);
  final position = TextPosition(offset: first);
  final right = box.getOffsetForCaret(position, Rect.zero).dx;
  final slot = theme.listIndentPerLevel;
  if (first >= text.length) {
    return Rect.fromLTWH(right - slot, 0, slot, box.size.height);
  }
  final top = box.getOffsetForCaret(position, Rect.zero).dy;
  return Rect.fromLTWH(
    right - slot,
    top,
    slot,
    box.getFullHeightForCaret(position),
  );
}

bool _space(String text, int at) => text[at] == ' ' || text[at] == '\t';

/// Past the mark that starts at [from]: the characters up to a space.
int _pastMark(String text, int from) {
  var at = from;
  while (at < text.length && !_space(text, at)) {
    at++;
  }
  return at;
}

/// Past the spaces that start at [from], and never past the text.
int _pastSpaces(String text, int from) {
  var at = math.min(from, text.length);
  while (at < text.length && _space(text, at)) {
    at++;
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
    if (shape.marker != null) _paintItem(canvas);
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

  void _paintItem(Canvas canvas) {
    final box = paragraph.currentContext?.findRenderObject();
    if (box is! RenderParagraph || !box.hasSize) return;
    final place = liveItemSlot(box, shape, theme).shift(Offset(textLeft, 0));
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
