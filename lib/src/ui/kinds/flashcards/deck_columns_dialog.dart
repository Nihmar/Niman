import 'package:flutter/material.dart';
import 'package:niman/src/flashcards/deck_table.dart';
import 'package:niman/src/ui/strings.dart';

/// The question and answer columns, by index into a table's head.
typedef DeckColumns = ({int question, int answer});

/// **Question and answer columns**: which two columns of [table] are read
/// as the question and the answer, among the ones its head names. Null when
/// the dialog is closed with Cancel.
Future<DeckColumns?> showDeckColumnsDialog(
  BuildContext context,
  DeckTable table,
) => showDialog<DeckColumns>(
  context: context,
  builder: (context) => _ColumnsDialog(table),
);

final class _ColumnsDialog extends StatefulWidget {
  const new(this.table);

  final DeckTable table;

  @override
  State<_ColumnsDialog> createState() => _ColumnsDialogState();
}

final class _ColumnsDialogState extends State<_ColumnsDialog> {
  late int _question = widget.table.question;
  late int _answer = widget.table.answer;

  /// Every column, by its head; one with no head is only a number, and
  /// cannot be picked, since `front:` and `back:` name a column by its head.
  List<DropdownMenuItem<int>> get _items => [
    for (final (at, head) in widget.table.headers.indexed)
      DropdownMenuItem(
        value: at,
        child: Text(head.isEmpty ? '#${at + 1}' : head),
      ),
  ];

  bool get _valid =>
      _question != _answer &&
      widget.table.headers[_question].isNotEmpty &&
      widget.table.headers[_answer].isNotEmpty;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(AppStrings.flashcardsColumnsTitle),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<int>(
          key: const Key('deck-column-question'),
          initialValue: _question,
          items: _items,
          decoration: InputDecoration(
            labelText: AppStrings.flashcardsQuestionColumn,
          ),
          onChanged: (value) => setState(() => _question = value ?? _question),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: const Key('deck-column-answer'),
          initialValue: _answer,
          items: _items,
          decoration: InputDecoration(
            labelText: AppStrings.flashcardsAnswerColumn,
          ),
          onChanged: (value) => setState(() => _answer = value ?? _answer),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(AppStrings.actionCancel),
      ),
      FilledButton(
        key: const Key('deck-columns-save'),
        onPressed: !_valid
            ? null
            : () => Navigator.pop(context, (
                question: _question,
                answer: _answer,
              )),
        child: Text(AppStrings.actionSave),
      ),
    ],
  );
}
