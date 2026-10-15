/// One flashcard as a deck note holds it (#533): what it asks and answers,
/// the key its review state is kept under, and where it stands in the note.
///
/// A card is read from the note, never stored: `docs/records/flashcards.md`.
library;

import 'package:meta/meta.dart';

/// Where a card is written.
enum CardKind {
  /// A body row of a table.
  tableRow,

  /// A paragraph or a list item of one line holding ` :: `.
  line,

  /// A `==highlight==` of any other paragraph or list item.
  cloze,
}

/// A stretch of the note, in characters (UTF-16 code units) from its start.
typedef NoteRange = ({int start, int end});

/// Where a card stands in its note: enough to rewrite or delete it without
/// touching a byte outside it.
@immutable
final class CardSource {
  /// A source over [firstLine] to [lastLine].
  const new({
    required this.firstLine,
    required this.lastLine,
    required this.content,
    required this.lines,
    this.question,
    this.answer,
    this.questionColumn,
    this.answerColumn,
    this.lineContents = const <NoteRange>[],
  });

  /// The first line of the card's source, counting from 0.
  final int firstLine;

  /// The last line of the card's source, inclusive: the same as
  /// [firstLine] but for a cloze in a paragraph of several lines.
  final int lastLine;

  /// The source without what its containers add to each line — a table
  /// row from its first `|` to its last, a `::` line or a paragraph from
  /// its first word, after an item's `- ` or a quote's `> `.
  final NoteRange content;

  /// Whole lines, from the start of [firstLine] to the end of [lastLine]'s
  /// text (its line ending not included): what deleting the card removes,
  /// with one line ending.
  final NoteRange lines;

  /// The question as written: a table row's first cell and a `::` line's
  /// words before it, trimmed. A cloze has none, its question being the
  /// paragraph around the gap; so does a card whose question is empty.
  final NoteRange? question;

  /// The answer as written: a row's answer cell, a `::` line's words after
  /// it, or a cloze's whole `==highlight==`, delimiters included. Null when
  /// an empty cell has no characters to point at.
  final NoteRange? answer;

  /// For a table row, the column the question was read from, counting from
  /// 0 among the row's cells; null for any other card. Known even when the
  /// cell is empty, so an edit can write into it.
  final int? questionColumn;

  /// For a table row, the column of the answer; null for any other card.
  final int? answerColumn;

  /// For a source of several lines, each line's content: [content] cut at
  /// the lines, a container's prefix (`> `, a list item's indent) left out
  /// of every one. Empty for a source of one line.
  final List<NoteRange> lineContents;
}

/// One card of a deck.
@immutable
final class FlashCard {
  /// A card of [kind].
  const new({
    required this.kind,
    required this.question,
    required this.answer,
    required this.key,
    required this.source,
  });

  /// Where it is written.
  final CardKind kind;

  /// The question as Markdown, to be drawn with the read view's inline
  /// renderer. A cloze's is its paragraph with the hidden highlight a gap
  /// ([clozeGap]) and the other highlights plain text.
  final String question;

  /// The answer as Markdown: a cell, the words after ` :: `, a cloze's
  /// hidden text.
  final String answer;

  /// What the review state is kept under: the question as plain text,
  /// `(2)`, `(3)` after a question the note asks again.
  final String key;

  /// Where it stands in the note.
  final CardSource source;

  /// The same card under [key].
  FlashCard withKey(String key) => FlashCard(
    kind: kind,
    question: question,
    answer: answer,
    key: key,
    source: source,
  );

  /// What stands where a cloze hides its answer.
  static const String clozeGap = '[…]';
}
