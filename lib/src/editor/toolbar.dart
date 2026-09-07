import 'package:flutter/material.dart';

/// One button of the editor toolbar (T-UI-08).
final class EditorToolbarButton {
  /// Creates a toolbar button definition.
  const EditorToolbarButton({
    required this.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  /// The button's widget key (tests identify buttons by it).
  final Key key;

  /// The button's icon.
  final IconData icon;

  /// The button's long-press tooltip.
  final String tooltip;

  /// The button's action.
  final VoidCallback onPressed;
}

/// The editor formatting toolbar (T-UI-08): one evenly spaced row of
/// buttons at the bottom (mockup's uneven spacing and trailing gear are
/// dropped). Dumb: the owner supplies the buttons and applies the
/// markdown commands (editor/md_editing.dart) through the controller.
final class EditorToolbar extends StatelessWidget {
  /// Creates the toolbar; [buttons] are laid out evenly across the width.
  const EditorToolbar({required this.buttons, super.key});

  /// The toolbar buttons, in display order.
  final List<EditorToolbarButton> buttons;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final button in buttons)
          Expanded(
            child: IconButton(
              key: button.key,
              tooltip: button.tooltip,
              icon: Icon(button.icon),
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              onPressed: button.onPressed,
            ),
          ),
      ],
    );
  }
}
