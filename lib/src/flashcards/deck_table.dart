/// A table of a deck note, as far as adding a card to it needs (#533).
library;

import 'package:meta/meta.dart';
import 'package:niman/src/flashcards/flash_card.dart';

/// A table that holds cards, found even when it has no row yet: the place
/// **Add card** appends to.
@immutable
final class DeckTable {
  /// A table with [headers] whose question and answer columns are [question]
  /// and [answer].
  const new({
    required this.headers,
    required this.question,
    required this.answer,
    required this.template,
    required this.last,
  });

  /// What its head says of each column, as plain text: the names `front:`
  /// and `back:` pick the question and answer columns by.
  final List<String> headers;

  /// How many columns its head has.
  int get columns => headers.length;

  /// The column the questions are read from, counting from 0.
  final int question;

  /// The column the answers are read from.
  final int answer;

  /// The row a new one is written like: the last body row, else the head.
  /// Its content, from the first pipe to the last.
  final NoteRange template;

  /// The table's last line, whole: where a new row goes after, with the
  /// container's prefix (a quote's `> `) the rows of the table share. The
  /// `content` is what that prefix ends before.
  final ({NoteRange lines, NoteRange content}) last;
}
