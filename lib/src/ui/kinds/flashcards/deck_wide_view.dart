import 'package:flutter/material.dart';
import 'package:niman/src/flashcards/card_edits.dart';
import 'package:niman/src/flashcards/deck_reading.dart';
import 'package:niman/src/flashcards/flash_card.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_add_card.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_card_row.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_edits.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_header.dart';
import 'package:niman/src/ui/kinds/flashcards/next_label.dart';
import 'package:niman/src/ui/strings.dart';

/// The deck on a wide window (mockup D1): the header, the cards as rows —
/// question, answer, when it comes back — **+ Add card**, and the status
/// row.
final class DeckWideView extends StatelessWidget {
  /// The view of [reading], editing through [edits].
  const new({
    required this.reading,
    required this.edits,
    required this.mathCache,
    required this.onStudy,
    this.studying,
    super.key,
  });

  /// The deck, counted for today.
  final DeckReading reading;

  /// What the rows do to the note.
  final DeckCardEdits edits;

  /// The formulas typeset so far.
  final MathCache mathCache;

  /// What **Study** does, or null while it cannot.
  final VoidCallback? onStudy;

  /// The key of the card the study beside the deck asks, if any.
  final String? studying;

  @override
  Widget build(BuildContext context) {
    final cards = reading.deck.cards;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final head = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeckHeader(summary: reading.summary, onStudy: onStudy),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(AppStrings.flashcardsQuestion, style: head)),
              const SizedBox(width: 16),
              Expanded(child: Text(AppStrings.flashcardsAnswer, style: head)),
              const SizedBox(width: 16),
              SizedBox(
                width: deckNextWidth,
                child: Text(
                  AppStrings.flashcardsNextColumn,
                  style: head,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (cards.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
            child: Text(
              AppStrings.flashcardsEmpty,
              key: const Key('deck-empty'),
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: muted),
            ),
          ),
        Expanded(
          child: ListView.separated(
            key: const Key('deck-list'),
            itemCount: cards.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == cards.length) {
                return DeckAddCard(
                  onAdd: (question, answer) => edits.add(
                    reading.deck,
                    question: question,
                    answer: answer,
                  ),
                );
              }
              final card = cards[index];
              return DeckCardRow(
                key: ValueKey(card.key),
                card: card,
                next: nextLabel(reading.stateOf(card), reading.today),
                repeated: reading.isRepeated(card),
                studying: card.key == studying,
                mathCache: mathCache,
                sentence: () => clozeSentence(edits.host.text, card),
                onSave: (question, answer) =>
                    edits.rewrite(card, question: question, answer: answer),
                onSaveSentence: (sentence) =>
                    edits.rewriteSentence(card, sentence),
                onDelete: () => edits.delete(card),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            _status(reading),
            key: const Key('deck-status'),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }

  /// `Flashcards · 42 cards · 2 table rows, 3 clozes`: the kinds the deck
  /// has, those it has none of left out.
  static String _status(DeckReading reading) {
    final rows = reading.countOf(CardKind.tableRow);
    final lines = reading.countOf(CardKind.line);
    final clozes = reading.countOf(CardKind.cloze);
    final kinds = [
      if (rows > 0) AppStrings.flashcardsKindRows(rows),
      if (lines > 0) AppStrings.flashcardsKindLines(lines),
      if (clozes > 0) AppStrings.flashcardsKindClozes(clozes),
    ];
    return [
      AppStrings.flashcardsName,
      AppStrings.flashcardsCardCount(reading.deck.cards.length),
      if (kinds.isNotEmpty) kinds.join(', '),
    ].join(' · ');
  }
}
