import 'dart:async';

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
/// A card the view holds says where it stood in the text it was read from,
/// and the note may have moved since (a sync pull, another pane, a sheet
/// held open, a long deck whose re-read has not landed). So an edit never
/// splices at the card's own offsets: it reads the deck of the note's
/// current text, finds the card again by its key, and drops the edit when
/// the card is gone.
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
  Future<void> rewrite(
    FlashCard card, {
    required String question,
    required String answer,
  }) => _edit(
    card,
    (text, deck, found) =>
        rewriteCard(text, found!, question: question, answer: answer),
    prune: (found) => question.trim() != found.question,
  );

  /// The cloze [card]'s paragraph, as [sentence].
  Future<void> rewriteSentence(FlashCard card, String sentence) => _edit(
    card,
    (text, deck, found) => rewriteCloze(text, found!, sentence),
    prune: (_) => true,
  );

  /// The note without [card]; a cloze keeps its words.
  Future<void> delete(FlashCard card) =>
      _edit(card, (text, deck, found) => deleteCard(text, found!));

  /// A card asking [question] and answering [answer], added to the deck.
  Future<void> add({required String question, required String answer}) => _edit(
    null,
    (text, deck, _) => addCard(text, deck, question: question, answer: answer),
  );

  /// Builds the new text from the deck of the note as it is now, with
  /// [card] as that deck holds it, and applies it; nothing happens when
  /// [card] is no longer there.
  Future<void> _edit(
    FlashCard? card,
    String Function(String text, Deck deck, FlashCard? found) build, {
    bool Function(FlashCard found)? prune,
  }) async {
    while (true) {
      final text = host.text;
      final read = Deck.readOffUi(text);
      final deck = read is Deck ? read : await read;
      // The note moved while a long deck was being read: read it again.
      if (host.text != text) continue;
      FlashCard? found;
      if (card != null) {
        found = _find(deck, card);
        if (found == null) return;
      }
      final next = build(text, deck, found);
      if (next == text) return;
      host.applyEdit(next);
      if (prune != null && prune(found!)) unawaited(_prune(next));
      return;
    }
  }

  static FlashCard? _find(Deck deck, FlashCard card) {
    for (final candidate in deck.cards) {
      if (candidate.key == card.key) return candidate;
    }
    return null;
  }

  Future<void> _prune(String text) async {
    final root = host.libraryRoot;
    final path = root == null ? null : pathInLibrary(root, host.notePath);
    if (root == null || path == null) return;
    final deck = await Deck.readOffUi(text);
    final keys = {for (final card in deck.cards) card.key};
    await reviews.prune(root, path, keys);
  }
}
