/// The Repeat row (#1189, #1191): what a task or an event repeats by, in
/// words, and the menu that changes it.
///
/// Never, the presets and Custom. The task dialog's row is a view of the
/// `rec:` tag in the line: picking writes it, and a `rec:` typed in the text
/// shows here as it is read. The event form's has no text to read it from
/// and holds the rule itself.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/recurrence_words.dart';
import 'package:niman/src/ui/repeat_sheet.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_date_panel.dart';

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
final class RepeatRow extends StatelessWidget {
  /// A row showing [rule]; [unreadable] is a `rec:` value the grammar does
  /// not read, shown as written. [anchor] is the due date, or today, or the
  /// day of the event; [presets] are the rules the menu lists before Custom.
  ///
  /// [keyPrefix] names the row's keys: `todo` for a task's, `calendar-event`
  /// for an event's. A task's rule can count from its due date or from its
  /// completion, and says so ([countsFrom]); an event's counts from its first
  /// day and has nothing to say. A row that is not [enabled] stays where it
  /// is and shows what it holds, and answers no tap.
  ///
  /// A rule chosen is answered through [onChanged] (null for Never). Custom
  /// calls [onCustomInPlace] on a window with the room for the editor under
  /// the row, and otherwise opens its sheet and answers through [onChanged].
  const new({
    required this.rule,
    required this.unreadable,
    required this.anchor,
    required this.presets,
    required this.onChanged,
    required this.onCustomInPlace,
    this.keyPrefix = 'todo',
    this.countsFrom = true,
    this.enabled = true,
    super.key,
  });

  /// The rule the line carries, or null.
  final RecurrenceRule? rule;

  /// The value of a `rec:` the grammar cannot read, or null.
  final String? unreadable;

  /// The day the presets and the weekday options are taken from.
  final DateTime anchor;

  /// The rules the menu lists between Never and Custom.
  final List<RecurrenceRule> presets;

  /// The prefix of the row's keys.
  final String keyPrefix;

  /// Whether the rule counts from a due date or a completion, and says so
  /// in words and in the custom editor.
  final bool countsFrom;

  /// Whether the row answers a tap. A disabled row keeps its place.
  final bool enabled;

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
        ? sentenceCase(
            recurrenceWords(current.description, fromDue: countsFrom),
          )
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
              key: Key('$keyPrefix-dialog-repeat'),
              onPressed: enabled ? () => _open(context) : null,
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
            key: Key('$keyPrefix-dialog-repeat-clear'),
            tooltip: AppStrings.todoRepeatNever,
            icon: const Icon(Icons.clear),
            onPressed: enabled ? () => onChanged(null) : null,
          ),
      ],
    );
  }

  Future<void> _open(BuildContext context) async {
    final pick = await showActionSheet<_Pick>(
      context,
      sheetKey: Key('$keyPrefix-repeat-menu'),
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
        final picked = await showRepeatSheet(
          context,
          initial: rule,
          anchor: anchor,
          keyPrefix: keyPrefix,
          countsFrom: countsFrom,
        );
        if (picked != null) onChanged(picked);
    }
  }

  List<Widget> _items(BuildContext context) {
    final custom = rule != null && !presets.contains(rule);
    return [
      ListTile(
        key: Key('$keyPrefix-repeat-never'),
        dense: true,
        selected: rule == null && unreadable == null,
        title: Text(AppStrings.todoRepeatNever),
        onTap: () => Navigator.of(context).pop(const _Rule(null)),
      ),
      for (final (index, preset) in presets.indexed)
        ListTile(
          key: Key('$keyPrefix-repeat-preset-$index'),
          dense: true,
          selected: rule == preset,
          title: Text(
            sentenceCase(
              recurrenceWords(preset.description, fromDue: countsFrom),
            ),
          ),
          onTap: () => Navigator.of(context).pop(_Rule(preset)),
        ),
      ListTile(
        key: Key('$keyPrefix-repeat-custom'),
        dense: true,
        selected: custom,
        title: Text(AppStrings.todoRepeatCustom),
        onTap: () => Navigator.of(context).pop(const _Custom()),
      ),
    ];
  }
}
