import 'package:flutter/widgets.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_note_view.dart';

/// The `flashcard` note kind (#533): a deck, questions with their answers
/// read from the note's own Markdown and reviewed with spaced repetition.
final class FlashcardKindGui implements NoteKindGUI {
  @override
  String get type => 'flashcard';

  @override
  LibraryFeature get feature => LibraryFeature.kindFlashcards;

  @override
  Widget buildBody(BuildContext context, NoteKindHost host) =>
      DeckNoteView(text: host.text, host: host);
}
