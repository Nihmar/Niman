import 'package:flutter/material.dart';
import 'package:niman/src/spellcheck/spell_check_sheet.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/strings.dart';

/// The dock's spelling (#712): the note's misspelled words beside it, the
/// review a phone gets as a sheet, kept open while the note is edited.
final class SpellingDockPane extends StatelessWidget {
  /// The spelling of [note]; null when no note is open.
  const new({required this.note, super.key});

  /// The note shown beside.
  final NoteViewHandle? note;

  @override
  Widget build(BuildContext context) {
    final note = this.note;
    if (note == null) return const SizedBox.shrink();
    final review = note.spellReview;
    if (review == null) {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          AppStrings.spellCheckUnavailable,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return SpellCheckSheet(
      // Another note is another pass.
      key: ValueKey(note.notePath),
      docked: true,
      start: review.start,
      suggest: review.suggest,
      apply: review.apply,
      reveal: review.reveal,
      addWord: review.addWord,
      edited: review.edited,
      available: review.available,
    );
  }
}
