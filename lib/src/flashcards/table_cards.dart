/// The cards of one table (#533): each body row, its question and answer
/// cells chosen by the deck's `front:` and `back:`.
library;

import 'package:niman/src/flashcards/card_keys.dart';
import 'package:niman/src/flashcards/card_ranges.dart';
import 'package:niman/src/flashcards/deck_meta.dart';
import 'package:niman/src/flashcards/deck_table.dart';
import 'package:niman/src/flashcards/flash_card.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The cards of the table [leaf], row by row; none for a table of a single
/// column, or one that continues a table a block above opened and has no
/// head to name its columns.
List<FlashCard> tableCards(ReadLeaf leaf, SourceBuffer buffer, DeckMeta meta) {
  if (leaf.continued || leaf.rows.length < 2) return const [];
  final head = leaf.rows.first;
  if (head.length < 2) return const [];
  final (:question, :answer) = _columns(head, meta);
  final cards = <FlashCard>[];
  for (var at = 1; at < leaf.rows.length; at++) {
    final row = leaf.rows[at];
    final asked = row[question];
    final key = plainKey(asked.nodes);
    if (key.isEmpty) continue;
    final replied = row[answer];
    // The head is the first line, the delimiter the second.
    final span = leaf.node.lines[at + 1];
    cards.add(
      FlashCard(
        kind: CardKind.tableRow,
        question: asked.text.trim(),
        answer: replied.text.trim(),
        key: key,
        source: sourceOf(
          buffer,
          [span],
          question: noteRange(
            asked.map,
            buffer,
            asked.text,
            0,
            asked.text.length,
          ),
          answer: noteRange(
            replied.map,
            buffer,
            replied.text,
            0,
            replied.text.length,
          ),
          questionColumn: question,
          answerColumn: answer,
        ),
      ),
    );
  }
  return cards;
}

/// The table [leaf] as a place to add cards to; null for a table that has
/// no head of its own or a single column, as [tableCards] reads none.
DeckTable? deckTable(ReadLeaf leaf, SourceBuffer buffer, DeckMeta meta) {
  if (leaf.continued || leaf.rows.isEmpty) return null;
  final head = leaf.rows.first;
  if (head.length < 2) return null;
  final (:question, :answer) = _columns(head, meta);
  final lines = leaf.node.lines;
  final last = sourceOf(buffer, [lines.last]);
  final body = lines.length > 2 ? lines.last : lines.first;
  return DeckTable(
    headers: [for (final cell in head) cell.plainText.trim()],
    question: question,
    answer: answer,
    template: sourceOf(buffer, [body]).content,
    last: (lines: last.lines, content: last.content),
  );
}

/// The question and answer columns of a table whose head is [head]: the two
/// of a two-column table; of a wider one the columns named by the deck's
/// `front:` and `back:` when both are there, else the first two.
({int question, int answer}) _columns(List<ReadInline> head, DeckMeta meta) {
  const fallback = (question: 0, answer: 1);
  final front = meta.front?.trim().toLowerCase();
  final back = meta.back?.trim().toLowerCase();
  if (head.length == 2 || front == null || back == null) return fallback;
  int find(String name) =>
      head.indexWhere((cell) => cell.plainText.trim().toLowerCase() == name);
  final question = find(front);
  final answer = find(back);
  if (question < 0 || answer < 0 || question == answer) return fallback;
  return (question: question, answer: answer);
}
