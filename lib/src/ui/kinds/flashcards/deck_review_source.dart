import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:niman/src/flashcards/review_store.dart';

/// Where the deck view gets, and keeps, the review states of its cards
/// (#533): `.niman/review.json` of the library at `root`, the note at
/// library-relative `path`.
///
/// The seam a widget test replaces, since the file's reads and writes run on
/// a real clock; the unit tests of `ReviewStore` cover the file itself.
abstract interface class DeckReviewSource {
  /// The states of the note's cards, by key.
  Future<Map<String, ReviewState>> read(String root, String path);

  /// Forgets every card of the note: **Reset the review of this deck**.
  Future<void> reset(String root, String path);

  /// Records that the card [key] of the note is now in [state]; null takes
  /// it back to never reviewed: a grade of a study, and its undo.
  Future<void> write(String root, String path, String key, ReviewState? state);

  /// Fires with the library root after the file was written.
  Stream<String> get changes;
}

/// The source over the library's own file.
final class FileDeckReviewSource implements DeckReviewSource {
  /// A source over `ReviewStore`.
  const new();

  @override
  Future<Map<String, ReviewState>> read(String root, String path) =>
      ReviewStore(root).read(path);

  @override
  Future<void> reset(String root, String path) =>
      ReviewStore(root).resetNote(path);

  @override
  Future<void> write(
    String root,
    String path,
    String key,
    ReviewState? state,
  ) => ReviewStore(root).write(path, key, state);

  @override
  Stream<String> get changes => ReviewStore.changes;
}

/// The review states the deck view reads and writes.
final deckReviewSourceProvider = Provider<DeckReviewSource>(
  (ref) => const FileDeckReviewSource(),
);
