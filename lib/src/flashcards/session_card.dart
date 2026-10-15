import 'package:meta/meta.dart';
import 'package:niman/src/flashcards/flash_card.dart';

/// One card of a session: where it is from, and the card.
@immutable
final class SessionCard {
  /// [card] of the deck at [deckPath].
  const new(this.deckPath, this.card);

  /// The deck note's library-relative path.
  final String deckPath;

  /// The card.
  final FlashCard card;

  /// The card's identity in a library: its deck and its key.
  ({String deck, String key}) get id => (deck: deckPath, key: card.key);
}
