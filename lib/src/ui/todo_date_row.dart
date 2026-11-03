/// One of the task dialog's date rows, the due date's or the reminder's
/// (split out of `todo_edit_dialog.dart` for #100).
library;

import 'package:flutter/material.dart';

/// A row that shows [value] (or [empty] when there is none) as the button
/// that picks it, and, while one is set, the button that clears it.
final class TodoDateRow extends StatelessWidget {
  /// The row; [onPick] picks a value, [onClear] clears it.
  const new({
    required this.icon,
    required this.pickKey,
    required this.clearKey,
    required this.value,
    required this.empty,
    required this.onPick,
    required this.onClear,
    super.key,
  });

  /// The row's leading icon.
  final IconData icon;

  /// The pick button's key.
  final Key pickKey;

  /// The clear button's key.
  final Key clearKey;

  /// The value shown, formatted, or null when none is set.
  final String? value;

  /// The words shown with no value, and the clear button's tooltip.
  final String empty;

  /// Picks a value.
  final VoidCallback onPick;

  /// Clears the value.
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: TextButton(
            key: pickKey,
            onPressed: onPick,
            style: TextButton.styleFrom(alignment: Alignment.centerLeft),
            child: Text(value ?? empty),
          ),
        ),
        if (value != null)
          IconButton(
            key: clearKey,
            tooltip: empty,
            icon: const Icon(Icons.clear),
            onPressed: onClear,
          ),
      ],
    );
  }
}
