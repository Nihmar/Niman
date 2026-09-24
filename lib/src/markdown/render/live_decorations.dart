/// What `live` mode draws *around* a line's text: a list item's bullet, its
/// number or its checkbox, a quote's bar, a thematic break's rule, a code
/// block's box.
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
import 'package:niman/src/markdown/render/item_marks.dart';
import 'package:niman/src/markdown/render/live_quote_content.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';

/// Where a line stands in a code block's box: which of its corners are the
/// box's.
enum CodeRow {
  /// The block's first row, and not its last: the box's top.
  top,

  /// A row between the block's first and last.
  middle,

  /// The block's last row, and not its first: the box's bottom.
  bottom,

  /// A block of one row: the whole box.
  only;

  /// The row [index] is of [block], a code block.
  factory of(Block block, int index) {
    final top = index == block.startLine;
    final bottom = index == block.endLine - 1;
    return top && bottom
        ? only
        : top
        ? CodeRow.top
        : bottom
        ? CodeRow.bottom
        : middle;
  }

  /// Whether the row has the box's top corners.
  bool get opens => this == top || this == only;

  /// Whether the row has the box's bottom corners.
  bool get closes => this == bottom || this == only;
}

/// The shape a line has in its block: what `live` draws beside its text.
@immutable
final class LineShape {
  /// Creates a shape.
  const new({
    this.quoteDepth = 0,
    this.marker,
    this.listDepth = 0,
    this.continued = false,
    this.box,
    this.ordinal,
    this.task,
    this.rule = false,
    this.code,
    this.codeIndented = false,
    this.codeFence = false,
    this.heading = 0,
  });

  /// The shape of [line], whose block is [block] and whose index is [index];
  /// [quoted] is what the line is inside its quote, for a quote's line —
  /// which is drawn as that block, as the read view draws it.
  factory of(StyledLine line, Block? block, int index, {QuotedLine? quoted}) {
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
    // Inside a quote, the block the line is in there, and its index in it.
    final inner = quoted?.block ?? block;
    final at = quoted?.line ?? index;
    final ordinal =
        marker != null &&
            inner != null &&
            inner.startLine == at &&
            inner.listOrdinal > 0
        ? inner.listOrdinal
        : null;
    // A line the item's block goes on to: under the item's text, lazy or not.
    final continued =
        marker == null &&
        inner != null &&
        inner.kind == BlockKind.listItem &&
        at > inner.startLine;
    // An HTML block is drawn in a code block's box too, as the read view
    // draws it.
    final code =
        inner != null &&
            (inner.kind == BlockKind.fencedCode ||
                inner.kind == BlockKind.indentedCode ||
                inner.kind == BlockKind.html)
        ? CodeRow.of(inner, at)
        : null;
    // A fence of a code block inside a quote: the styler reads the quote's
    // lines as its prose, so what is a fence there is said here.
    final codeFence =
        quoted != null &&
        inner!.kind == BlockKind.fencedCode &&
        (at == inner.startLine ||
            (at == inner.endLine - 1 &&
                _closesFence(quoted.lines[at].trimLeft())));
    final heading = quoted != null && inner!.kind == BlockKind.heading
        ? inner.headingLevel
        : 0;
    if (quoteDepth == 0 &&
        marker == null &&
        !continued &&
        !rule &&
        code == null &&
        heading == 0) {
      return none;
    }
    return LineShape(
      quoteDepth: quoteDepth,
      marker: marker,
      // A line the scan has not reached yet is at the top level.
      listDepth: marker == null && !continued
          ? 0
          : math.max(0, inner?.listDepth ?? 0),
      continued: continued,
      box: box,
      ordinal: ordinal,
      task: task,
      rule: rule,
      code: code,
      codeIndented: inner?.kind == BlockKind.indentedCode,
      codeFence: codeFence,
      heading: heading,
    );
  }

  static bool _closesFence(String text) =>
      text.startsWith('```') || text.startsWith('~~~');

  /// How many quote levels the line is in.
  final int quoteDepth;

  /// Where the line's list marker starts, when it opens a list item.
  final int? marker;

  /// How many list levels deep the item is, 0 at the top: the columns its
  /// text is set in by, as the read view sets it.
  final int listDepth;

  /// Whether the line goes on an item a line above opened: its text is set
  /// on the item's column, with nothing drawn beside it.
  final bool continued;

  /// Whether the line's text is an item's: set on the item's column.
  bool get listed => marker != null || continued;

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

  /// Where the line stands in a code block's box — fence or code — or null
  /// for a line of no code block.
  final CodeRow? code;

  /// Whether the line is an indented code block's: its first four columns
  /// are the block's indent, hidden as a list's marker is, and not code.
  final bool codeIndented;

  /// Whether the line is a fence of a code block inside a quote, drawn
  /// hidden as a fence is.
  final bool codeFence;

  /// The level of the heading the line is inside its quote, or 0: a quoted
  /// heading is set at its size, as the read view sets it.
  final int heading;

  /// A line with no shape to draw.
  static const LineShape none = LineShape();

  @override
  bool operator ==(Object other) =>
      other is LineShape &&
      other.quoteDepth == quoteDepth &&
      other.marker == marker &&
      other.listDepth == listDepth &&
      other.continued == continued &&
      other.box == box &&
      other.ordinal == ordinal &&
      other.task == task &&
      other.rule == rule &&
      other.code == code &&
      other.codeIndented == codeIndented &&
      other.codeFence == codeFence &&
      other.heading == heading;

  @override
  int get hashCode => Object.hash(
    quoteDepth,
    marker,
    listDepth,
    continued,
    box,
    ordinal,
    task,
    rule,
    code,
    codeIndented,
    codeFence,
    heading,
  );
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
    double? restingLeft,
  }) : restingLeft = restingLeft ?? textLeft;

  /// What to draw.
  final LineShape shape;

  /// The note's theme: the bar's colour and width, the indents, the rule.
  final MarkdownTheme theme;

  /// The line's paragraph, for where its marker is.
  final GlobalKey paragraph;

  /// Where the paragraph starts, from the painter's left edge.
  final double textLeft;

  /// Where the paragraph starts when the caret is not on the line: where a
  /// code block's box is drawn from, which does not move when the caret
  /// shows an indented block's spaces into it.
  final double restingLeft;

  /// Whether the caret is on the line: its markers are drawn as written, so
  /// nothing stands in for them.
  final bool revealed;

  /// The colour of a bullet, a number and a checkbox.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    _paintQuoteBars(canvas, size);
    // The box stays under a revealed fence: the fence is written inside it.
    _paintCode(canvas, size);
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

  /// The line's part of its code block's box: from a padding before the
  /// code to the pane's edge, rounded where the box starts and ends — the
  /// box the read view draws, the fences' rows its top and bottom.
  void _paintCode(Canvas canvas, Size size) {
    final row = shape.code;
    if (row == null) return;
    final left = restingLeft - theme.codePadding;
    const round = Radius.circular(4);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(left, 0, size.width - left, size.height),
        topLeft: row.opens ? round : Radius.zero,
        topRight: row.opens ? round : Radius.zero,
        bottomLeft: row.closes ? round : Radius.zero,
        bottomRight: row.closes ? round : Radius.zero,
      ),
      Paint()..color = theme.codeBackground,
    );
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
    // The size the item's text is drawn at: a bullet, a box and a number
    // grow with the note's text, which is scaled as it is laid out.
    final em = box.textScaler.scale(theme.body.fontSize!);
    final task = shape.task;
    if (task != null) {
      paintCheckbox(
        canvas,
        Offset(place.left + slot / 2, middle),
        em,
        color,
        ticked: task,
      );
      return;
    }
    final ordinal = shape.ordinal;
    if (ordinal != null) {
      _paintText(canvas, '$ordinal.', right - em * numberGapEm, middle, box);
      return;
    }
    paintBullet(canvas, Offset(right - slot / 2, middle), em, color);
  }

  /// Paints [text] ending at [right], centred on [middle], at the size and
  /// the scale [box]'s text is drawn at.
  void _paintText(
    Canvas canvas,
    String text,
    double right,
    double middle,
    RenderParagraph box,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: theme.body.copyWith(color: color),
      ),
      textDirection: TextDirection.ltr,
      textScaler: box.textScaler,
    )..layout();
    painter.paint(
      canvas,
      Offset(right - painter.width, middle - painter.height / 2),
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(LiveDecorationPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.revealed != revealed ||
      oldDelegate.textLeft != textLeft ||
      oldDelegate.restingLeft != restingLeft ||
      oldDelegate.color != color ||
      oldDelegate.theme != theme;
}
