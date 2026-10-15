import 'package:flutter/material.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/flashcards/deck.dart';
import 'package:niman/src/frontmatter/edit.dart';
import 'package:niman/src/frontmatter/yaml_scalar.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_columns_dialog.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_review_source.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/strings.dart';

/// What the deck's ⋮ menu and the palette do to the note on screen beyond
/// what its view does (#533): pick the question and answer columns, and
/// reset the review.
final class DeckMenuFlow {
  /// The flow over the review states [reviews] keeps.
  const new(this.reviews);

  /// Where the review states are kept.
  final DeckReviewSource reviews;

  /// Asks which columns of the deck's first table of more than two are the
  /// question and the answer, and writes `front:` and `back:` into the
  /// frontmatter as one undoable edit of [note].
  Future<void> chooseColumns(BuildContext context, NoteViewHandle note) async {
    final text = note.currentText;
    final deck = await Deck.readOffUi(text);
    if (!context.mounted) return;
    final wide = deck.tables.where((table) => table.columns > 2);
    if (wide.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.flashcardsColumnsNone)));
      return;
    }
    final table = wide.first;
    final picked = await showDeckColumnsDialog(context, table);
    if (picked == null) return;
    // The text may have moved while the dialog was open.
    var next = note.currentText;
    next = setFrontmatterKey(
      next,
      'front',
      yamlString(table.headers[picked.question]),
    );
    next = setFrontmatterKey(
      next,
      'back',
      yamlString(table.headers[picked.answer]),
    );
    note.applyKindEdit(next);
  }

  /// Asks, and forgets the review of every card of the note at [notePath]
  /// in the library at [root]. The note itself is not touched.
  Future<void> resetReview(
    BuildContext context, {
    required String? root,
    required String notePath,
  }) async {
    final path = root == null ? null : pathInLibrary(root, notePath);
    if (root == null || path == null) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.flashcardsResetTitle),
        content: Text(AppStrings.flashcardsResetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.actionCancel),
          ),
          FilledButton(
            key: const Key('deck-reset-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.flashcardsResetConfirm),
          ),
        ],
      ),
    );
    if (sure ?? false) await reviews.reset(root, path);
  }
}
