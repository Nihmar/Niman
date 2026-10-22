import 'package:flutter/widgets.dart';
import 'package:niman/src/kanban/board_parser.dart';

/// TEMPORARY, read-only: the columns of a board with their cards' titles,
/// as plain text. The wide board and the phone board take its place in the
/// phases that follow the kind's registration (#1166).
final class KanbanPlaceholderView extends StatelessWidget {
  /// Creates the placeholder over the note [text].
  const new({required this.text, super.key});

  /// The full note text (frontmatter + body).
  final String text;

  @override
  Widget build(BuildContext context) {
    final board = parseKanban(text);
    return ListView(
      key: const Key('kanban-placeholder'),
      padding: const EdgeInsets.all(16),
      children: [
        for (final column in board.columns) ...[
          Text(column.name),
          for (final card in column.cards) Text(card.title),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
