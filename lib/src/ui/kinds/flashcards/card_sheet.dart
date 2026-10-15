import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// What the card sheet was closed with.
sealed class CardSheetResult {
  const new();
}

/// **Save**: the card as the fields now have it. For a cloze [question] is
/// the whole sentence and [answer] is empty.
final class CardSaved extends CardSheetResult {
  /// A card asking [question] and answering [answer].
  const new(this.question, this.answer);

  /// The question, or a cloze's sentence.
  final String question;

  /// The answer.
  final String answer;
}

/// **Delete**.
final class CardDeleted extends CardSheetResult {
  /// The card is to go.
  const new();
}

/// The bottom sheet a long press on a card opens (mockup P3), and **Add
/// card** opens empty: the question and the answer, what saving does, and
/// **Delete** and **Save**.
///
/// A cloze has one field, its sentence: the paragraph around the
/// highlight, as the note writes it.
Future<CardSheetResult?> showCardSheet(
  BuildContext context, {
  String question = '',
  String answer = '',
  bool isNew = false,
  bool cloze = false,
}) => showModalBottomSheet<CardSheetResult>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _CardSheet(
    question: question,
    answer: answer,
    isNew: isNew,
    cloze: cloze,
  ),
);

final class _CardSheet extends StatefulWidget {
  const new({
    required this.question,
    required this.answer,
    required this.isNew,
    required this.cloze,
  });

  final String question;
  final String answer;
  final bool isNew;
  final bool cloze;

  @override
  State<_CardSheet> createState() => _CardSheetState();
}

final class _CardSheetState extends State<_CardSheet> {
  late final TextEditingController _question = TextEditingController(
    text: widget.question,
  )..addListener(_changed);
  late final TextEditingController _answer = TextEditingController(
    text: widget.answer,
  );

  void _changed() => setState(() {});

  @override
  void dispose() {
    _question.dispose();
    _answer.dispose();
    super.dispose();
  }

  bool get _canSave => _question.text.trim().isNotEmpty;

  void _save() {
    if (!_canSave) return;
    Navigator.pop(context, CardSaved(_question.text, _answer.text));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isNew
                    ? AppStrings.flashcardsAddCard
                    : AppStrings.flashcardsEditCard,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('card-sheet-question'),
                controller: _question,
                autofocus: true,
                minLines: 1,
                maxLines: widget.cloze ? 6 : 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: widget.cloze
                      ? AppStrings.flashcardsSentence
                      : AppStrings.flashcardsQuestion,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (!widget.cloze) ...[
                const SizedBox(height: 12),
                TextField(
                  key: const Key('card-sheet-answer'),
                  controller: _answer,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: AppStrings.flashcardsAnswer,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                AppStrings.flashcardsEditNote,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Always there, so Save does not move when a card is
                  // added: with nothing to delete it is disabled.
                  OutlinedButton(
                    key: const Key('card-sheet-delete'),
                    onPressed: widget.isNew
                        ? null
                        : () => Navigator.pop(context, const CardDeleted()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: widget.isNew
                          ? null
                          : BorderSide(color: scheme.error),
                    ),
                    child: Text(AppStrings.actionDelete),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const Key('card-sheet-save'),
                    onPressed: _canSave ? _save : null,
                    child: Text(AppStrings.actionSave),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
