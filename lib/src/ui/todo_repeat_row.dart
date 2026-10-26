/// The task dialog's Repeat row (#1189): what the task repeats by, in words,
/// and the menu that changes it.
///
/// Never, the presets and Custom. The row is a view of the `rec:` tag in the
/// line: picking writes it, and a `rec:` typed in the text shows here as it
/// is read.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/recurrence_words.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_date_panel.dart';
import 'package:niman/src/ui/todo_repeat_presets.dart';
import 'package:niman/src/ui/todo_repeat_sheet.dart';

/// What the Repeat menu picked.
sealed class _Pick {
  const new();
}

/// A rule, or Never when null.
final class _Rule extends _Pick {
  const new(this.rule);

  final RecurrenceRule? rule;
}

/// Custom.
final class _Custom extends _Pick {
  const new();
}

/// The row: the repeat icon, the rule in words (or Never), and a clear
/// button while there is one.
final class TodoRepeatRow extends StatelessWidget {
  /// A row showing [rule]; [unreadable] is a `rec:` value the grammar does
  /// not read, shown as written. [anchor] is the due date, or today.
  ///
  /// A rule chosen is answered through [onChanged] (null for Never). Custom
  /// calls [onCustomInPlace] on a window with the room for the editor under
  /// the row, and otherwise opens its sheet and answers through [onChanged].
  const new({
    required this.rule,
    required this.unreadable,
    required this.anchor,
    required this.onChanged,
    required this.onCustomInPlace,
    super.key,
  });

  /// The rule the line carries, or null.
  final RecurrenceRule? rule;

  /// The value of a `rec:` the grammar cannot read, or null.
  final String? unreadable;

  /// The day the presets and the weekday options are taken from.
  final DateTime anchor;

  /// Called with the rule picked, or null for Never.
  final ValueChanged<RecurrenceRule?> onChanged;

  /// Called when Custom is picked and the editor opens under the row.
  final VoidCallback onCustomInPlace;

  @override
  Widget build(BuildContext context) {
    final current = rule;
    final bad = unreadable;
    final scheme = Theme.of(context).colorScheme;
    final label = current != null
        ? sentenceCase(recurrenceWords(current.description, fromDue: true))
        : bad != null
        ? 'rec:$bad'
        : AppStrings.todoRepeatNever;
    return Row(
      children: [
        const Icon(Icons.repeat, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Builder(
            builder: (context) => TextButton(
              key: const Key('todo-dialog-repeat'),
              onPressed: () => _open(context),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                foregroundColor: current == null && bad != null
                    ? scheme.error
                    : null,
              ),
              child: Text(label),
            ),
          ),
        ),
        if (current != null || bad != null)
          IconButton(
            key: const Key('todo-dialog-repeat-clear'),
            tooltip: AppStrings.todoRepeatNever,
            icon: const Icon(Icons.clear),
            onPressed: () => onChanged(null),
          ),
      ],
    );
  }

  Future<void> _open(BuildContext context) async {
    final pick = await showActionSheet<_Pick>(
      context,
      sheetKey: const Key('todo-repeat-menu'),
      anchor: menuAnchorOf(context),
      title: AppStrings.todoRepeat,
      items: _items,
    );
    if (pick == null || !context.mounted) return;
    switch (pick) {
      case _Rule(:final rule):
        onChanged(rule);
      case _Custom():
        if (todoPicksInPlace(context)) return onCustomInPlace();
        final picked = await showTodoRepeatSheet(
          context,
          initial: rule,
          anchor: anchor,
        );
        if (picked != null) onChanged(picked);
    }
  }

  List<Widget> _items(BuildContext context) {
    final presets = todoRepeatPresets(anchor);
    final custom = rule != null && !presets.contains(rule);
    return [
      ListTile(
        key: const Key('todo-repeat-never'),
        dense: true,
        selected: rule == null && unreadable == null,
        title: Text(AppStrings.todoRepeatNever),
        onTap: () => Navigator.of(context).pop(const _Rule(null)),
      ),
      for (final (index, preset) in presets.indexed)
        ListTile(
          key: Key('todo-repeat-preset-$index'),
          dense: true,
          selected: rule == preset,
          title: Text(
            sentenceCase(recurrenceWords(preset.description, fromDue: true)),
          ),
          onTap: () => Navigator.of(context).pop(_Rule(preset)),
        ),
      ListTile(
        key: const Key('todo-repeat-custom'),
        dense: true,
        selected: custom,
        title: Text(AppStrings.todoRepeatCustom),
        onTap: () => Navigator.of(context).pop(const _Custom()),
      ),
    ];
  }
}
