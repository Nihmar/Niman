import 'package:niman/src/flashcards/card_edits.dart';
import 'package:niman/src/flashcards/deck.dart';
import 'package:niman/src/flashcards/flash_card.dart';
import 'package:niman/src/frontmatter/note_kind.dart';

/// What an editor of a card opens with: the `question` and the `answer` as
/// the note holds the card now. A cloze is one field, its whole sentence as
/// the note writes it, in `question`, with no `answer`.
typedef CardDraft = ({String question, String answer});

/// What the deck view does to its note (#533): each card edit is the note's
/// text rewritten by `card_edits.dart` and handed to the host as one
/// undoable edit.
///
/// A card the view holds says where it stood in the text it was read from,
/// and the note may have moved since (a sync pull, another pane, a sheet
/// held open, a long deck whose re-read has not landed). So an edit never
/// splices at the card's own offsets: it reads the deck of the note's
/// current text, finds the card again by its key, and drops the edit when
/// the card is gone. What an editor opens with is read the same way
/// ([open]), so it never shows the text of an older note, nor reads past the
/// end of a note that shrank.
///
/// A question that changed is a new card (`docs/records/flashcards.md`),
/// and the state its old key had is an orphan that stays: the text change
/// is undoable, and an Undo brings the card back with its state.
final class DeckCardEdits {
  /// The edits of the note [host] holds.
  const new(this.host);

  /// The note.
  final NoteKindHost host;

  /// [card] asking [question] and answering [answer].
  Future<void> rewrite(
    FlashCard card, {
    required String question,
    required String answer,
  }) => _edit(
    card,
    (text, deck, found) =>
        rewriteCard(text, found!, question: question, answer: answer),
  );

  /// The cloze [card]'s paragraph, as [sentence].
  Future<void> rewriteSentence(FlashCard card, String sentence) =>
      _edit(card, (text, deck, found) => rewriteCloze(text, found!, sentence));

  /// The note without [card]; a cloze keeps its words.
  Future<void> delete(FlashCard card) =>
      _edit(card, (text, deck, found) => deleteCard(text, found!));

  /// A card asking [question] and answering [answer], added to the deck.
  Future<void> add({required String question, required String answer}) => _edit(
    null,
    (text, deck, _) => addCard(text, deck, question: question, answer: answer),
  );

  /// What the editor of [card] opens with, from [card] as the note holds it
  /// now; null when the note no longer has it, and the editor does not open.
  Future<CardDraft?> open(FlashCard card) async {
    final (:text, :deck) = await _current();
    final found = _find(deck, card);
    if (found == null) return null;
    return found.kind == CardKind.cloze
        ? (question: clozeSentence(text, found), answer: '')
        : (question: found.question, answer: found.answer);
  }

  /// Builds the new text from the deck of the note as it is now, with
  /// [card] as that deck holds it, and applies it; nothing happens when
  /// [card] is no longer there.
  Future<void> _edit(
    FlashCard? card,
    String Function(String text, Deck deck, FlashCard? found) build,
  ) async {
    final (:text, :deck) = await _current();
    FlashCard? found;
    if (card != null) {
      found = _find(deck, card);
      if (found == null) return;
    }
    final next = build(text, deck, found);
    if (next == text) return;
    host.applyEdit(next);
  }

  /// The note's text and the deck read from it, the two of one moment.
  Future<({String text, Deck deck})> _current() async {
    while (true) {
      final text = host.text;
      final read = Deck.readOffUi(text);
      final deck = read is Deck ? read : await read;
      // The note moved while a long deck was being read: read it again.
      if (host.text == text) return (text: text, deck: deck);
    }
  }

  static FlashCard? _find(Deck deck, FlashCard card) {
    for (final candidate in deck.cards) {
      if (candidate.key == card.key) return candidate;
    }
    return null;
  }
}
