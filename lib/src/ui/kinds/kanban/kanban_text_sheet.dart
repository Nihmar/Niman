import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The bottom sheet that asks the phone's board for one line of text
/// (#1168): a card's title, a column's new name, the name of a column to add.
///
/// Gives the text as typed once **Save** is pressed on something that is not
/// blank, null when the sheet is dismissed or **Cancel** is.
Future<String?> showKanbanTextSheet(
  BuildContext context, {
  required String title,
  required String hint,
  String initial = '',
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) =>
      _KanbanTextSheet(title: title, hint: hint, initial: initial),
);

final class _KanbanTextSheet extends StatefulWidget {
  const new({required this.title, required this.hint, required this.initial});

  final String title;
  final String hint;
  final String initial;

  @override
  State<_KanbanTextSheet> createState() => _KanbanTextSheetState();
}

final class _KanbanTextSheetState extends State<_KanbanTextSheet> {
  late final TextEditingController _text =
      TextEditingController(text: widget.initial)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.initial.length,
        )
        ..addListener(_changed);

  void _changed() => setState(() {});

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canSave => _text.text.trim().isNotEmpty;

  void _save() {
    if (_canSave) Navigator.pop(context, _text.text.trim());
  }

  @override
  Widget build(BuildContext context) {
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
                widget.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('kanban-sheet-field'),
                controller: _text,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('kanban-sheet-cancel'),
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppStrings.actionCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('kanban-sheet-save'),
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
