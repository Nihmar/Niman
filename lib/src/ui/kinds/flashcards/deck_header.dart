import 'package:flutter/material.dart';
import 'package:niman/src/flashcards/deck_summary.dart';
import 'package:niman/src/ui/strings.dart';

/// A deck's place, as the header writes it: its categories, or **No
/// category**.
String deckPlace(List<String> category) =>
    category.isEmpty ? AppStrings.flashcardsNoCategory : category.join(' › ');

/// A deck's counts on one line: `9 due · 5 new · 42 cards`.
String deckCounts(DeckSummary summary) => [
  AppStrings.flashcardsDueCount(summary.due),
  AppStrings.flashcardsNewCount(summary.newAvailable),
  AppStrings.flashcardsCardCount(summary.total),
].join(' · ');

/// The head of the deck view on a wide window (mockup D1): the deck's
/// place, its name, its counts, its tags and **Study**.
final class DeckHeader extends StatelessWidget {
  /// The header of the deck [summary] counts.
  const new({required this.summary, required this.onStudy, super.key});

  /// The deck, counted.
  final DeckSummary summary;

  /// What **Study** does, or null while it cannot (the button stays, grey).
  final VoidCallback? onStudy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            deckPlace(summary.category),
            key: const Key('deck-place'),
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 4),
          Text(
            summary.name,
            key: const Key('deck-name'),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontFamily: 'Literata',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            deckCounts(summary),
            key: const Key('deck-counts'),
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          if (summary.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final tag in summary.tags)
                  Chip(
                    label: Text('#$tag'),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('deck-study'),
            onPressed: summary.toStudy > 0 ? onStudy : null,
            icon: const Icon(Icons.style_outlined),
            label: Text(AppStrings.flashcardsStudyCount(summary.toStudy)),
          ),
        ],
      ),
    );
  }
}
