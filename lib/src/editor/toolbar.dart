import 'package:flutter/material.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/pointer_menu.dart';

/// One button of the editor toolbar (T-UI-08).
final class EditorToolbarButton {
  /// Creates a toolbar button definition.
  const new({
    required this.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.onPressedAt,
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

  /// A button that opens a menu runs this instead of [onPressed], handed
  /// the place on screen it was pressed in — the button, or the overflow
  /// button holding it — for a pointer's menu to grow from (#780).
  final ValueChanged<Rect?>? onPressedAt;

  /// Runs the button's action as pressed in [context]'s widget.
  void pressIn(BuildContext context) => switch (onPressedAt) {
    final at? => at(menuAnchorOf(context)),
    null => onPressed(),
  };

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

  /// The width one button takes: its padding and its icon.
  double get _itemWidth => (dense ? 6.0 : 8.0) * 2 + (dense ? 18.0 : 20.0);

  /// The width a divider takes: a line and the margin on either side.
  static const double _dividerWidth = 1 + 5 * 2;

  /// Whether a divider stands before [index].
  bool _divides(int index) =>
      dense &&
      index > 0 &&
      buttons[index].group != null &&
      buttons[index - 1].group != null &&
      buttons[index].group != buttons[index - 1].group;

  /// How many buttons fit in [width], room kept for the overflow button
  /// when the rest do not.
  int _fitCount(double width) {
    if (!dense) return buttons.length;
    var used = 0.0;
    for (var count = 0; count < buttons.length; count++) {
      final divider = count > 0 && _divides(count) ? _dividerWidth : 0.0;
      final remaining = buttons.length - count - 1;
      // Showing this button means, while others are left, also showing the
      // overflow button that holds them.
      final reserve = remaining > 0 ? _itemWidth : 0.0;
      if (used + divider + _itemWidth + reserve > width) return count;
      used += divider + _itemWidth;
    }
    return buttons.length;
  }

  @override
  Widget build(BuildContext context) {
    final pad = dense ? 6.0 : 8.0;
    final iconSize = dense ? 18.0 : 20.0;
    return SizedBox(
      height: editorToolbarHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fit = _fitCount(constraints.maxWidth);
          if (fit == buttons.length) return _row(context, pad, iconSize);
          // A pointer's toolbar puts what does not fit behind an overflow
          // menu (#712), where a swipe would hide it; a phone keeps the
          // horizontal scroll.
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (fit > 0)
                Flexible(child: _row(context, pad, iconSize, take: fit)),
              _overflow(context, pad, iconSize, from: fit),
            ],
          );
        },
      ),
    );
  }

  /// The buttons' row, all of them or the first [take].
  Widget _row(BuildContext context, double pad, double iconSize, {int? take}) {
    final theme = Theme.of(context);
    final shown = take == null ? buttons : buttons.take(take).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, button) in shown.indexed) ...[
            if (dense &&
                i > 0 &&
                button.group != null &&
                shown[i - 1].group != null &&
                button.group != shown[i - 1].group)
              Container(
                width: 1,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                color: theme.dividerColor,
              ),
            Tooltip(
              message: button.tooltip,
              child: Builder(
                builder: (context) => InkWell(
                  key: button.key,
                  onTap: () => button.pressIn(context),
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
            ),
          ],
        ],
      ),
    );
  }

  /// The trailing button holding [from] on: a menu of the buttons that
  /// did not fit, with their tooltips as labels.
  Widget _overflow(
    BuildContext context,
    double pad,
    double iconSize, {
    required int from,
  }) {
    final theme = Theme.of(context);
    // The overflow button's own context: a menu one of its entries opens
    // grows from it, the button that was pressed.
    return Builder(
      builder: (anchor) => _overflowMenu(anchor, theme, pad, iconSize, from),
    );
  }

  Widget _overflowMenu(
    BuildContext anchor,
    ThemeData theme,
    double pad,
    double iconSize,
    int from,
  ) {
    return MenuAnchor(
      key: const Key('editor-toolbar-overflow'),
      menuChildren: [
        for (final button in buttons.skip(from))
          MenuItemButton(
            key: button.key,
            onPressed: () => button.pressIn(anchor),
            // A format on at the caret reads as on here too (#788), as the
            // pressed button does in the row: the same tint, and a check
            // a menu row says "on" with.
            style: button.active
                ? MenuItemButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    iconColor: theme.colorScheme.onPrimaryContainer,
                  )
                : null,
            leadingIcon: Icon(button.icon, size: theme.menuIconSize),
            trailingIcon: button.active
                ? Icon(Icons.check, size: theme.menuIconSize)
                : null,
            child: Text(button.tooltip),
          ),
      ],
      builder: (context, controller, _) => Tooltip(
        message: MaterialLocalizations.of(context).showMenuTooltip,
        child: InkWell(
          onTap: () => controller.open(),
          canRequestFocus: false,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: pad,
              vertical: (editorToolbarHeight - iconSize) / 2,
            ),
            child: Icon(
              Icons.more_horiz,
              size: iconSize,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
