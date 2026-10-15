import 'package:meta/meta.dart';
import 'package:niman/src/flashcards/flash_card.dart';
import 'package:niman/src/flashcards/review_state.dart';

/// A deck as a session takes it: its cards, read, and their states.
@immutable
final class SessionDeck {
  /// The deck at [path] with [cards] in note order, and [states] by key.
  const new({
    required this.path,
    required this.cards,
    this.states = const <String, ReviewState>{},
  });

  /// The note's library-relative path.
  final String path;

  /// Its cards, in note order.
  final List<FlashCard> cards;

  /// Their review states, by key; a card with none is new.
  final Map<String, ReviewState> states;
}
