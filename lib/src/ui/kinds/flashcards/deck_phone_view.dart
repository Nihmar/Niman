import 'package:flutter/material.dart';
import 'package:niman/src/flashcards/deck_reading.dart';
import 'package:niman/src/flashcards/flash_card.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/kinds/flashcards/card_sheet.dart';
import 'package:niman/src/ui/kinds/flashcards/card_text.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_edits.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_header.dart';
import 'package:niman/src/ui/kinds/flashcards/next_label.dart';
import 'package:niman/src/ui/strings.dart';

/// The deck on a phone (mockup P2): its counts on top, the questions as a
/// list with the answer under each, and at the bottom, where the thumb is,
/// **Add card** and **Study**. A long press on a question opens the sheet
/// that edits or deletes it (mockup P3).
final class DeckPhoneView extends StatelessWidget {
  /// The view of [reading], editing through [edits].
  const new({
    required this.reading,
    required this.edits,
    required this.mathCache,
    required this.onStudy,
    super.key,
  });

  /// The deck, counted for today.
  final DeckReading reading;

  /// What the sheet does to the note.
  final DeckCardEdits edits;

  /// The formulas typeset so far.
  final MathCache mathCache;

  /// What **Study** does, or null while it cannot.
  final VoidCallback? onStudy;

  Future<void> _edit(BuildContext context, FlashCard card) async {
    final cloze = card.kind == CardKind.cloze;
    // The card as the note holds it now, not as this view read it.
    final draft = await edits.open(card);
    if (draft == null || !context.mounted) return;
    final result = await showCardSheet(
      context,
      question: draft.question,
      answer: draft.answer,
      cloze: cloze,
    );
    switch (result) {
      case CardSaved(:final question, :final answer):
        if (cloze) {
          await edits.rewriteSentence(card, question);
        } else {
          await edits.rewrite(card, question: question, answer: answer);
        }
      case CardDeleted():
        await edits.delete(card);
      case null:
        break;
    }
  }

  Future<void> _add(BuildContext context) async {
    final result = await showCardSheet(context, isNew: true);
    if (result case CardSaved(:final question, :final answer)) {
      await edits.add(question: question, answer: answer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = reading.summary;
    final cards = reading.deck.cards;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            deckPlace(summary.category),
            key: const Key('deck-place'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _Stat(
                key: const Key('deck-stat-due'),
                value: summary.due,
                label: AppStrings.flashcardsDue,
              ),
              const SizedBox(width: 8),
              _Stat(
                key: const Key('deck-stat-new'),
                value: summary.newAvailable,
                label: AppStrings.flashcardsNew,
              ),
              const SizedBox(width: 8),
              _Stat(
                key: const Key('deck-stat-cards'),
                value: summary.total,
                label: AppStrings.flashcardsCardsLabel,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: cards.isEmpty
              ? Center(
                  child: Text(
                    AppStrings.flashcardsEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  key: const Key('deck-list'),
                  itemCount: cards.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _row(context, cards[index]),
                ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                OutlinedButton(
                  key: const Key('deck-add-card'),
                  onPressed: () => _add(context),
                  child: Tooltip(
                    message: AppStrings.flashcardsAddCard,
                    child: const Icon(Icons.add),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('deck-study'),
                    onPressed: summary.toStudy > 0 ? onStudy : null,
                    icon: const Icon(Icons.style_outlined),
                    label: Text(
                      AppStrings.flashcardsStudyCards(summary.toStudy),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, FlashCard card) {
    final theme = Theme.of(context);
    final cloze = card.kind == CardKind.cloze;
    final next = nextLabel(reading.stateOf(card), reading.today);
    return InkWell(
      key: Key('deck-row-${card.key}'),
      onLongPress: () => _edit(context, card),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardText(
                    card.question,
                    mathCache: mathCache,
                    cloze: cloze,
                    maxLines: 2,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  CardText(
                    card.answer,
                    mathCache: mathCache,
                    maxLines: 1,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (reading.isRepeated(card))
                    Text(
                      AppStrings.flashcardsRepeated,
                      key: const Key('deck-row-repeated'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              next,
              style: theme.textTheme.bodySmall?.copyWith(
                color: next == AppStrings.flashcardsDue
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the three boxes on top of the phone's deck.
final class _Stat extends StatelessWidget {
  const new({required this.value, required this.label, super.key});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text('$value', style: theme.textTheme.titleLarge),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
