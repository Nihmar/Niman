import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/flashcards/flash_card.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/kinds/flashcards/card_text.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_edits.dart';
import 'package:niman/src/ui/pointer_menu.dart';
import 'package:niman/src/ui/strings.dart';

/// How wide the **Next** column is.
const double deckNextWidth = 112;

/// One card of the deck on a wide window (mockup D1): its question, its
/// answer and when it comes back; a double click edits it in place
/// (mockup D5), `Enter` saves and `Esc` cancels.
///
/// A cloze shows its question with the gap as a blank and its answer
/// highlighted; edited, it is one field over both columns: the sentence.
final class DeckCardRow extends StatefulWidget {
  /// The row of [card], which [next] says comes back.
  const new({
    required this.card,
    required this.next,
    required this.repeated,
    required this.mathCache,
    required this.open,
    required this.onSave,
    required this.onSaveSentence,
    required this.onDelete,
    this.studying = false,
    this.hideAnswer = false,
    super.key,
  });

  /// The card.
  final FlashCard card;

  /// When it comes back, in words.
  final String next;

  /// Whether the deck asks the same question earlier.
  final bool repeated;

  /// Whether the study beside the deck is asking this card (#533): the row
  /// is marked.
  final bool studying;

  /// Whether the answer is left out: a study of the deck is open beside
  /// it, and the list must not give its answers away.
  final bool hideAnswer;

  /// The formulas typeset so far, shared by the deck's rows.
  final MathCache mathCache;

  /// What the editor opens with, read when the row is edited: the card as
  /// the note holds it now, or null when the note no longer has it.
  final Future<CardDraft?> Function() open;

  /// Saves a table row's or a `::` line's new question and answer.
  final void Function(String question, String answer) onSave;

  /// Saves a cloze's new sentence.
  final ValueChanged<String> onSaveSentence;

  /// Deletes the card.
  final VoidCallback onDelete;

  @override
  State<DeckCardRow> createState() => _DeckCardRowState();
}

final class _DeckCardRowState extends State<DeckCardRow> {
  bool _editing = false;
  final TextEditingController _question = TextEditingController();
  final TextEditingController _answer = TextEditingController();

  bool get _cloze => widget.card.kind == CardKind.cloze;

  @override
  void dispose() {
    _question.dispose();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    final draft = await widget.open();
    if (draft == null || !mounted) return;
    _question.text = draft.question;
    _answer.text = draft.answer;
    setState(() => _editing = true);
  }

  void _cancel() => setState(() => _editing = false);

  void _save() {
    if (_question.text.trim().isEmpty) return;
    setState(() => _editing = false);
    if (_cloze) {
      widget.onSaveSentence(_question.text);
    } else {
      widget.onSave(_question.text, _answer.text);
    }
  }

  Future<void> _menu(TapUpDetails details) async {
    final position = details.globalPosition;
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        menuItem(
          context,
          value: 'edit',
          child: Text(AppStrings.flashcardsEditCard),
        ),
        menuItem(
          context,
          value: 'delete',
          child: Text(AppStrings.actionDelete),
        ),
      ],
    );
    if (choice == 'edit') unawaited(_edit());
    if (choice == 'delete') widget.onDelete();
  }

  @override
  Widget build(BuildContext context) =>
      _editing ? _editor(context) : _shown(context);

  Widget _shown(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = widget.card;
    final style = Theme.of(context).textTheme.bodyMedium;
    final next = widget.next;
    final nextColor = next == AppStrings.flashcardsDue
        ? scheme.primary
        : next == AppStrings.flashcardsNew
        ? scheme.tertiary
        : scheme.onSurfaceVariant;
    return GestureDetector(
      key: Key('deck-row-${card.key}'),
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () => unawaited(_edit()),
      onSecondaryTapUp: _menu,
      child: Container(
        key: widget.studying ? const Key('deck-row-studying') : null,
        color: widget.studying ? scheme.secondaryContainer : null,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: CardText(
                      card.question,
                      mathCache: widget.mathCache,
                      style: style,
                      cloze: _cloze,
                    ),
                  ),
                  if (widget.repeated) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: AppStrings.flashcardsRepeatedTip,
                      child: Text(
                        AppStrings.flashcardsRepeated,
                        key: const Key('deck-row-repeated'),
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!widget.hideAnswer) ...[
              const SizedBox(width: 16),
              Expanded(child: _answerText(context, style)),
            ],
            const SizedBox(width: 16),
            SizedBox(
              width: deckNextWidth,
              child: Text(
                next,
                style: style?.copyWith(color: nextColor),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _answerText(BuildContext context, TextStyle? style) {
    final text = CardText(
      widget.card.answer,
      mathCache: widget.mathCache,
      style: style,
    );
    if (!_cloze) return text;
    final scheme = Theme.of(context).colorScheme;
    // A cloze's answer is the highlight itself, as the note marks it.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        key: const Key('deck-row-highlight'),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: text,
        ),
      ),
    );
  }

  Widget _editor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _cancel},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: _cloze ? 2 : 1,
              child: TextField(
                key: const Key('row-question-field'),
                controller: _question,
                autofocus: true,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  labelText: _cloze ? AppStrings.flashcardsSentence : null,
                ),
                onSubmitted: (_) => _save(),
              ),
            ),
            if (!_cloze) ...[
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  key: const Key('row-answer-field'),
                  controller: _answer,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _save(),
                ),
              ),
            ],
            const SizedBox(width: 16),
            SizedBox(
              width: deckNextWidth,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  key: const Key('row-delete'),
                  tooltip: AppStrings.actionDelete,
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                  onPressed: () {
                    setState(() => _editing = false);
                    widget.onDelete();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
