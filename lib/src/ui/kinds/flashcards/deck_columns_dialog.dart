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
  late DeckColumns _columns = (
    question: widget.table.question,
    answer: widget.table.answer,
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(AppStrings.flashcardsColumnsTitle),
    content: DeckColumnFields(
      table: widget.table,
      columns: _columns,
      onChanged: (columns) => setState(() => _columns = columns),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(AppStrings.actionCancel),
      ),
      FilledButton(
        key: const Key('deck-columns-save'),
        onPressed: deckColumnsValid(widget.table, _columns)
            ? () => Navigator.pop(context, _columns)
            : null,
        child: Text(AppStrings.actionSave),
      ),
    ],
  );
}

/// Whether [columns] can be written for [table]: two columns, each with a
/// head, since `front:` and `back:` name a column by its head.
bool deckColumnsValid(DeckTable table, DeckColumns columns) =>
    columns.question != columns.answer &&
    table.headers[columns.question].isNotEmpty &&
    table.headers[columns.answer].isNotEmpty;

/// The two pickers of the question and the answer column of [table]: the
/// columns dialog's, and Make flashcards'.
final class DeckColumnFields extends StatelessWidget {
  /// The pickers, set to [columns].
  const new({
    required this.table,
    required this.columns,
    required this.onChanged,
    super.key,
  });

  /// The table whose columns are picked.
  final DeckTable table;

  /// The columns picked.
  final DeckColumns columns;

  /// Another pick.
  final ValueChanged<DeckColumns> onChanged;

  /// Every column, by its head; one with no head is only a number.
  List<DropdownMenuItem<int>> get _items => [
    for (final (at, head) in table.headers.indexed)
      DropdownMenuItem(
        value: at,
        child: Text(head.isEmpty ? '#${at + 1}' : head),
      ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      DropdownButtonFormField<int>(
        key: const Key('deck-column-question'),
        initialValue: columns.question,
        items: _items,
        decoration: InputDecoration(
          labelText: AppStrings.flashcardsQuestionColumn,
        ),
        onChanged: (value) => onChanged((
          question: value ?? columns.question,
          answer: columns.answer,
        )),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        key: const Key('deck-column-answer'),
        initialValue: columns.answer,
        items: _items,
        decoration: InputDecoration(
          labelText: AppStrings.flashcardsAnswerColumn,
        ),
        onChanged: (value) => onChanged((
          question: columns.question,
          answer: value ?? columns.answer,
        )),
      ),
    ],
  );
}
