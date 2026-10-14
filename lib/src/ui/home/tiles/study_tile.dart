/// The Home's Study tile (#533, mockup P7): today's cards, the decks with
/// cards to study, and Study on the first of them.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/flashcards/deck_summary.dart';
import 'package:niman/src/ui/home/home_host.dart';
import 'package:niman/src/ui/home/home_tile_frame.dart';
import 'package:niman/src/ui/strings.dart';

/// The decks to study today.
final class StudyTile extends StatelessWidget {
  /// The tile over [host]'s decks.
  const new({required this.host, super.key});

  /// The shell's side of the Home.
  final HomeHost host;

  /// The decks with cards today, the most cards first.
  static List<DeckSummary> toStudy(List<DeckSummary> summaries) =>
      [
        for (final deck in summaries)
          if (deck.toStudy > 0) deck,
      ]..sort((a, b) {
        final byCards = b.toStudy.compareTo(a.toStudy);
        return byCards != 0 ? byCards : a.name.compareTo(b.name);
      });

  @override
  Widget build(BuildContext context) {
    final catalog = host.decks();
    if (catalog == null) return HomeTileEmpty(AppStrings.studyNothingToday);
    return ListenableBuilder(
      listenable: catalog,
      builder: (context, _) {
        if (!catalog.loaded) return const SizedBox.shrink();
        final decks = toStudy(catalog.summaries);
        if (decks.isEmpty) return HomeTileEmpty(AppStrings.studyNothingToday);
        final theme = Theme.of(context);
        final muted = theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
        final due = decks.fold(0, (sum, deck) => sum + deck.due);
        final fresh = decks.fold(0, (sum, deck) => sum + deck.newAvailable);
        final first = decks.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              [
                AppStrings.flashcardsDueCount(due),
                AppStrings.flashcardsNewCount(fresh),
              ].join(' · '),
              key: const Key('home-study-counts'),
              style: muted,
            ),
            const SizedBox(height: 4),
            Expanded(
              // Not scrollable: a tile shows what its height holds.
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final deck in decks)
                    InkWell(
                      key: Key('home-study-${deck.path}'),
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => host.openNote(deck.path),
                      child: SizedBox(
                        height: 32,
                        child: Row(
                          children: [
                            Icon(
                              Icons.style_outlined,
                              size: 16,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                deck.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${deck.toStudy}', style: muted),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonalIcon(
                key: const Key('home-study-first'),
                onPressed: () => host.study([first.path], first.name),
                icon: const Icon(Icons.play_arrow_outlined),
                label: Text(
                  '${AppStrings.flashcardsStudyCount(first.toStudy)} · '
                  '${first.name}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
