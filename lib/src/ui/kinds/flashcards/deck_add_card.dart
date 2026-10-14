import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_card_row.dart';
import 'package:niman/src/ui/strings.dart';

/// **+ Add card** at the end of the deck's list on a wide window: pressed,
/// it becomes a row of two empty fields, `Enter` adds the card and `Esc`
/// takes the row back.
final class DeckAddCard extends StatefulWidget {
  /// A row that adds cards through [onAdd].
  const new({required this.onAdd, super.key});

  /// Adds a card asking the question and answering the answer.
  final void Function(String question, String answer) onAdd;

  @override
  State<DeckAddCard> createState() => _DeckAddCardState();
}

final class _DeckAddCardState extends State<DeckAddCard> {
  bool _adding = false;
  final TextEditingController _question = TextEditingController();
  final TextEditingController _answer = TextEditingController();

  @override
  void dispose() {
    _question.dispose();
    _answer.dispose();
    super.dispose();
  }

  void _cancel() => setState(() => _adding = false);

  void _add() {
    if (_question.text.trim().isEmpty) return;
    widget.onAdd(_question.text, _answer.text);
    _question.clear();
    _answer.clear();
    setState(() => _adding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_adding) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const Key('deck-add-card'),
            onPressed: () => setState(() => _adding = true),
            icon: const Icon(Icons.add),
            label: Text(AppStrings.flashcardsAddCard),
          ),
        ),
      );
    }
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _cancel},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const Key('add-question-field'),
                controller: _question,
                autofocus: true,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  hintText: AppStrings.flashcardsQuestion,
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                key: const Key('add-answer-field'),
                controller: _answer,
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  hintText: AppStrings.flashcardsAnswer,
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 16 + deckNextWidth),
          ],
        ),
      ),
    );
  }
}
