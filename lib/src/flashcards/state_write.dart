import 'package:meta/meta.dart';
import 'package:niman/src/flashcards/review_state.dart';

/// A change of a card's state for the caller to write: [state] null takes
/// the card back to never reviewed (`ReviewStore.write`).
@immutable
final class StateWrite {
  /// Sets [key] of the deck at [path] to [state].
  const new(this.path, this.key, this.state);

  /// The deck note's library-relative path.
  final String path;

  /// The card's key.
  final String key;

  /// The state to write; null for none.
  final ReviewState? state;
}
