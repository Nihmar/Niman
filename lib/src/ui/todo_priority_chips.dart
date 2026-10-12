/// The todo dialog's priority row: one chip per common choice, the task's
/// own rare one among them, and the rest of the alphabet behind *More*
/// (split out of `todo_edit_dialog.dart` for #710).
///
/// A priority the task already carries is always among the chips, even
/// outside the common six: a `(M)` typed elsewhere must be visible here,
/// and must survive a save that did not touch it.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/ui/strings.dart';

/// The priority chips, over [current] (null = none).
final class TodoPriorityChips extends StatelessWidget {
  /// Creates the row; [onChanged] reports a choice (null clears it).
  const new({required this.current, required this.onChanged, super.key});

  /// The task's priority letter, or null for none.
  final String? current;

  /// Reports a chosen letter, or null.
  final ValueChanged<String?> onChanged;

  /// The letters the row shows without *More*.
  static const List<String> _common = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  Widget build(BuildContext context) {
    final letters = <String>[
      ..._common,
      if (current != null && !_common.contains(current)) current!,
    ];
    return Wrap(
      spacing: 6,
      children: [
        ChoiceChip(
          key: const Key('todo-priority-none'),
          label: Text(AppStrings.todoNoPriorityShort),
          selected: current == null,
          visualDensity: VisualDensity.compact,
          onSelected: (_) => onChanged(null),
        ),
        for (final letter in letters)
          ChoiceChip(
            key: Key('todo-priority-$letter'),
            label: Text(letter),
            selected: current == letter,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => onChanged(letter),
          ),
        ActionChip(
          key: const Key('todo-priority-more'),
          label: Text(AppStrings.todoMorePriorities),
          visualDensity: VisualDensity.compact,
          onPressed: () => _pickOther(context),
        ),
      ],
    );
  }

  /// The rest of the alphabet, as a grid small enough to read at once.
  ///
  /// Desktop gets a compact, fixed-width dialog: a `SimpleDialog` there
  /// stretches to the window and laid all twenty-six chips on one line
  /// (user, 2026-09-10). The phone keeps the sheet-like dialog.
  Future<void> _pickOther(BuildContext context) async {
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    final picked = wide
        ? await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              key: const Key('todo-priority-grid'),
              title: Text(AppStrings.todoPriorityTitle),
              content: SizedBox(
                width: 320,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var code = 65; code <= 90; code++)
                      _letterChip(context, code),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppStrings.actionCancel),
                ),
              ],
            ),
          )
        : await showDialog<String>(
            context: context,
            builder: (context) => SimpleDialog(
              key: const Key('todo-priority-grid'),
              title: Text(AppStrings.todoPriorityTitle),
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var code = 65; code <= 90; code++)
                      _letterChip(context, code),
                  ],
                ),
              ],
            ),
          );
    if (picked != null) onChanged(picked);
  }

  /// One A-Z chip of [_pickOther]'s grid.
  Widget _letterChip(BuildContext context, int code) {
    final letter = String.fromCharCode(code);
    return ActionChip(
      key: Key('todo-priority-pick-$letter'),
      label: Text(letter),
      visualDensity: VisualDensity.compact,
      onPressed: () => Navigator.pop(context, letter),
    );
  }
}
