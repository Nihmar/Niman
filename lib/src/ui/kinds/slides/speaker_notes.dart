import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// A slide's speaker notes, in a card: shown in the working views, never
/// on the projected screen nor in the PDF.
final class SpeakerNotes extends StatelessWidget {
  /// Shows [notes].
  const new({required this.notes, this.large = false, super.key});

  /// The notes' text.
  final String notes;

  /// The presenter view's size, read from a step back.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      key: const Key('speaker-notes'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  AppStrings.slidesSpeakerNotes,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  notes,
                  style: large
                      ? theme.textTheme.headlineSmall
                      : theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
