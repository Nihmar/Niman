import 'package:flutter/material.dart';

/// One button of the editor toolbar (T-UI-08).
final class EditorToolbarButton {
  /// Creates a toolbar button definition.
  const new({
    required this.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
    this.group,
  });

  /// The button's widget key (tests identify buttons by it).
  final Key key;

  /// The button's icon.
  final IconData icon;

  /// The button's long-press tooltip.
  final String tooltip;

  /// The button's action.
  final VoidCallback onPressed;

  /// Whether the format is on at the caret: the button stays pressed until
  /// it is toggled off, the way a word processor's toolbar behaves
  /// (T-WYS-06). The source editor leaves it false.
  final bool active;

  /// The button's kind; a dense toolbar draws a divider wherever two
  /// neighbours' kinds differ (#173). Null never divides.
  final Object? group;
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
  const new({required this.buttons, this.dense = false, super.key});

  /// The toolbar buttons, in display order.
  final List<EditorToolbarButton> buttons;

  /// The desktop's toolbar (#173): smaller targets than a thumb needs,
  /// and a divider between kinds of button. The phone's stays full size
  /// — it rides the keyboard, under a finger.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pad = dense ? 6.0 : 8.0;
    final iconSize = dense ? 18.0 : 20.0;
    return SizedBox(
      height: editorToolbarHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, button) in buttons.indexed) ...[
              if (dense &&
                  i > 0 &&
                  button.group != null &&
                  buttons[i - 1].group != null &&
                  button.group != buttons[i - 1].group)
                Container(
                  width: 1,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  color: theme.dividerColor,
                ),
              Tooltip(
                message: button.tooltip,
                child: InkWell(
                  key: button.key,
                  onTap: button.onPressed,
                  canRequestFocus: false,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: pad,
                      vertical: (editorToolbarHeight - iconSize) / 2,
                    ),
                    decoration: button.active
                        ? BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          )
                        : null,
                    child: Icon(
                      button.icon,
                      size: iconSize,
                      color: button.active
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
