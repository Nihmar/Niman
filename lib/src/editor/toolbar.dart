import 'package:flutter/material.dart';

/// One button of the editor toolbar (T-UI-08).
final class EditorToolbarButton {
  /// Creates a toolbar button definition.
  const new({
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

/// The toolbar's height: icon 20 px with 6 px padding above and below.
///
/// Shared with the pinned section's heading, whose row matches it so the
/// two top bars line up across panes (user, 2026-09-09). Pinned here
/// (rather than derived) so a padding tweak cannot silently misalign them.
const double editorToolbarHeight = 32;

/// The editor formatting toolbar (T-UI-08): a horizontally scrollable row
/// of buttons at the bottom (no scrollbar). The buttons are non-focusable
/// so tapping one never takes focus from the editor (the keyboard stays
/// up). Dumb: the owner supplies the buttons and applies the markdown
/// commands (editor/md_editing.dart) through the controller.
final class EditorToolbar extends StatelessWidget {
  /// Creates the toolbar; [buttons] scroll horizontally when they overflow.
  const new({required this.buttons, super.key});

  /// The toolbar buttons, in display order.
  final List<EditorToolbarButton> buttons;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: editorToolbarHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final button in buttons)
              Tooltip(
                message: button.tooltip,
                child: InkWell(
                  key: button.key,
                  onTap: button.onPressed,
                  canRequestFocus: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Icon(button.icon, size: 20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
