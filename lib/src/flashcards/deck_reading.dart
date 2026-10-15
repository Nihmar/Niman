/// A deck note as its own view reads it (#533): the cards, the review
/// states they stand in and the day they are counted for.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/flashcards/deck.dart';
import 'package:niman/src/flashcards/deck_summary.dart';
import 'package:niman/src/flashcards/flash_card.dart';
import 'package:niman/src/flashcards/review_state.dart';

/// The words after a repeated question's key: ` (2)`, ` (3)`.
final RegExp _repeatedKey = RegExp(r' \((?:[2-9]|\d\d+)\)$');

/// What the deck view shows of a deck on one study day.
@immutable
final class DeckReading {
  /// [deck], the note at library-relative [path], with the review [states]
  /// of its cards counted for [today] under the library's [newPerDay].
  const new({
    required this.deck,
    required this.path,
    required this.states,
    required this.today,
    required this.newPerDay,
  });

  /// The cards, as the note holds them.
  final Deck deck;

  /// The note's library-relative path.
  final String path;

  /// The review states of its cards, by key.
  final Map<String, ReviewState> states;

  /// The study day, a date at midnight.
  final DateTime today;

  /// The limit of new cards per deck per day.
  final int newPerDay;

  /// The deck's counts: what a study of it shows today, and all its cards.
  DeckSummary get summary => DeckInfo(
    path: path,
    modified: DateTime.fromMillisecondsSinceEpoch(0),
    meta: deck.meta,
    keys: [for (final card in deck.cards) card.key],
  ).summary(states, today, newPerDay);

  /// The state of [card], or null for one never reviewed.
  ReviewState? stateOf(FlashCard card) => states[card.key];

  /// Whether [card] asks what an earlier card of the deck asks (its key
  /// carries a `(2)`, `(3)`).
  bool isRepeated(FlashCard card) => _repeatedKey.hasMatch(card.key);

  /// How many cards are written as [kind].
  int countOf(CardKind kind) =>
      deck.cards.where((card) => card.kind == kind).length;
}
