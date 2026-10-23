/// One card of a rastered kanban board (#1170), drawn with no window and no
/// theme: a box, the title with its task box, the chips and the body.
///
/// The interactive board's card face leans on the app's `Theme` and on
/// controls; this one needs only the export's [MarkdownTheme], as the
/// raster fallback's offscreen tree has nothing else. Its look follows the
/// printed card (`kanban_style.dart`): a rounded line round the card, the
/// tags and the due date as chips under the title, the body as blocks.
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/export/board_raster_context.dart';
import 'package:niman/src/kanban/card_text.dart';
import 'package:niman/src/kanban/kanban_card.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';

/// The padding inside a card, in logical pixels: about 0.5em by 0.7em of
/// the printed page's type.
const EdgeInsets boardCardPadding = EdgeInsets.symmetric(
  horizontal: 10,
  vertical: 7,
);

/// The space under a card, in logical pixels.
const double boardCardGap = 8;

/// The side of a task box, in logical pixels.
const double _boxSide = 13;

/// A card of the board, [width] wide counting its padding and its line.
final class BoardRasterCard extends StatelessWidget {
  /// Draws [card] [width] wide.
  const new({
    required this.card,
    required this.width,
    required this.context,
    super.key,
  });

  /// The card.
  final KanbanCard card;

  /// How wide the card is, its line and padding in.
  final double width;

  /// What the board is drawn with: the type, and the note's definitions.
  final BoardRasterContext context;

  MarkdownTheme get _theme => context.theme;

  @override
  Widget build(BuildContext buildContext) {
    final theme = _theme;
    final done = card.checked ?? false;
    final inner = width - boardCardPadding.horizontal - 2;
    final base = theme.body.copyWith(
      decoration: done ? TextDecoration.lineThrough : null,
      color: done ? theme.markerDim : null,
    );
    final body = _body(card.body);
    return Padding(
      padding: const EdgeInsets.only(bottom: boardCardGap),
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: theme.tableBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: boardCardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (card.hasBox)
                      Padding(
                        padding: const EdgeInsets.only(top: 3, right: 6),
                        child: _TaskBox(
                          checked: done,
                          color: theme.body.color ?? const Color(0xFF000000),
                        ),
                      ),
                    Expanded(
                      child: Text.rich(
                        context.inline(cardShownTitle(card.title), base: base),
                      ),
                    ),
                  ],
                ),
                if (card.tags.isNotEmpty || card.due != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: [
                        for (final tag in card.tags) _Chip('#$tag', theme),
                        if (card.due case final due?)
                          _Chip(cardDueText(due), theme, muted: true),
                      ],
                    ),
                  ),
                if (body != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: context.blocks(body, inner),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The lines under the title without the blank ones round them, or null
  /// when there is nothing to draw.
  static String? _body(List<String> lines) {
    var from = 0;
    var to = lines.length;
    while (from < to && lines[from].trim().isEmpty) {
      from++;
    }
    while (to > from && lines[to - 1].trim().isEmpty) {
      to--;
    }
    final body = lines.sublist(from, to);
    // A card that holds only definitions has no body to draw.
    return onlyDefinitions(body) ? null : body.join('\n');
  }
}

/// A tag or a due date.
final class _Chip extends StatelessWidget {
  const new(this.text, this.theme, {this.muted = false});

  final String text;
  final MarkdownTheme theme;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final size = (theme.body.fontSize ?? 14) * 0.8;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.codeBackground,
        border: Border.all(color: theme.tableBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          text,
          style: theme.body.copyWith(
            fontSize: size,
            height: 1.3,
            color: muted ? theme.markerDim : theme.tag.color,
          ),
        ),
      ),
    );
  }
}

/// A task box: a square, ticked when the card is done.
final class _TaskBox extends StatelessWidget {
  const new({required this.checked, required this.color});

  final bool checked;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _boxSide,
    height: _boxSide,
    child: CustomPaint(
      painter: _BoxPainter(checked: checked, color: color),
    ),
  );
}

final class _BoxPainter extends CustomPainter {
  const new({required this.checked, required this.color});

  final bool checked;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(0.6),
        const Radius.circular(3),
      ),
      line,
    );
    if (!checked) return;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.25, size.height * 0.52)
        ..lineTo(size.width * 0.43, size.height * 0.72)
        ..lineTo(size.width * 0.76, size.height * 0.28),
      line..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(_BoxPainter old) =>
      old.checked != checked || old.color != color;
}
