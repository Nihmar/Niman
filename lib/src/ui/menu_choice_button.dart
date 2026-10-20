/// A control that picks one of a few values from a menu, the way a
/// drop-down reads (#1119).
///
/// Material's `DropdownButton` takes its rows' height as a constructor
/// argument no theme reaches, and refuses one under 48 px: on a desktop its
/// menu stood taller and wider than every other menu in the app. This one
/// opens the app's own popup menu, its rows built by `menuItem` and
/// `MenuRow`, so it is the tree's compact menu on a pointer and the thumb's
/// on a phone, as every other menu is.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/menu_row.dart';
import 'package:niman/src/ui/pointer_menu.dart';

/// One value a [MenuChoiceButton] offers, and what it reads as.
typedef MenuChoice<T> = (T value, String label);

/// Shows [value]'s label with a drop-down arrow; a tap opens a menu of
/// [options] over it, the current one checked, and a pick is [onChanged].
final class MenuChoiceButton<T> extends StatelessWidget {
  /// Creates the control showing [value] among [options].
  const new({
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  /// The value picked now.
  final T value;

  /// Every value offered, in the menu's order.
  final List<MenuChoice<T>> options;

  /// Called with the value picked.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = options.indexWhere((option) => option.$1 == value);
    // The menu holds the options' places, not the values: a popup menu
    // reads a null pick as no pick, and null is often a choice here
    // ("the same as the app's").
    return PopupMenuButton<int>(
      tooltip: '',
      initialValue: current < 0 ? null : current,
      onSelected: (index) => onChanged(options[index].$1),
      itemBuilder: (context) => [
        for (final (index, (_, label)) in options.indexed)
          menuItem<int>(
            context,
            value: index,
            child: Semantics(
              checked: index == current,
              child: MenuRow(
                label: label,
                trailing: _Check(checked: index == current),
              ),
            ),
          ),
      ],
      // As tall as one of the menu's rows: a thumb's target on a phone, a
      // pointer's on a desktop.
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: theme.menuItemHeight),
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: theme.menuIconGap),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (current >= 0)
                Flexible(
                  child: Text(
                    options[current].$2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }
}

/// The check the chosen entry wears at its end, its room taken either way
/// so the labels line up.
final class _Check extends StatelessWidget {
  const new({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.only(start: theme.menuIconGap),
      child: SizedBox(
        width: theme.menuIconSize,
        child: checked ? Icon(Icons.check, size: theme.menuIconSize) : null,
      ),
    );
  }
}
