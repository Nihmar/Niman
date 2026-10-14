import 'dart:async';
import 'dart:isolate';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/flashcards/card_edits.dart';
import 'package:niman/src/flashcards/deck.dart';
import 'package:niman/src/flashcards/flash_card.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_review_source.dart';

/// What the deck view does to its note (#533): each card edit is the note's
/// text rewritten by `card_edits.dart` and handed to the host as one
/// undoable edit.
///
/// A question that changed is a new card (`docs/records/flashcards.md`),
/// and the state its old key had is an orphan: the review store drops it
/// once the note is written.
final class DeckCardEdits {
  /// The edits of the note [host] holds.
  const new(this.host, this.reviews);

  /// The note.
  final NoteKindHost host;

  /// Where the review states are kept.
  final DeckReviewSource reviews;

  /// [card] asking [question] and answering [answer].
  void rewrite(
    FlashCard card, {
    required String question,
    required String answer,
  }) {
    final next = rewriteCard(
      host.text,
      card,
      question: question,
      answer: answer,
    );
    _apply(next, prune: question.trim() != card.question);
  }

  /// The cloze [card]'s paragraph, as [sentence].
  void rewriteSentence(FlashCard card, String sentence) =>
      _apply(rewriteCloze(host.text, card, sentence), prune: true);

  /// The note without [card]; a cloze keeps its words.
  void delete(FlashCard card) => _apply(deleteCard(host.text, card));

  /// A card asking [question] and answering [answer], added to [deck].
  void add(Deck deck, {required String question, required String answer}) =>
      _apply(addCard(host.text, deck, question: question, answer: answer));

  void _apply(String next, {bool prune = false}) {
    if (next == host.text) return;
    host.applyEdit(next);
    if (prune) unawaited(_prune(next));
  }

  Future<void> _prune(String text) async {
    final root = host.libraryRoot;
    final path = root == null ? null : pathInLibrary(root, host.notePath);
    if (root == null || path == null) return;
    final keys = text.length < _isolateFrom
        ? _keysOf(text)
        : await Isolate.run(() => _keysOf(text));
    await reviews.prune(root, path, keys);
  }

  /// From this length on, the keys are read on a background isolate: a deck
  /// can be a novel-length note.
  static const int _isolateFrom = 64 * 1024;
}

Set<String> _keysOf(String text) => {
  for (final card in Deck.read(text).cards) card.key,
};
