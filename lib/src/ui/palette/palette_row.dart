import 'package:flutter/material.dart';

/// One row of the palette's list: highlighted while selected.
final class PaletteRow extends StatelessWidget {
  /// A row showing [child], [selected] or not.
  const new({
    required this.selected,
    required this.onTap,
    required this.onHover,
    required this.child,
    this.anchor,
    super.key,
  });

  /// Whether this is the row ↵ runs.
  final bool selected;

  /// The key the selected row carries, for the list to scroll to it.
  final GlobalKey? anchor;

  /// The row was tapped.
  final VoidCallback onTap;

  /// The pointer came onto this row.
  final VoidCallback onHover;

  /// What the row shows.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      key: anchor,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: selected ? scheme.surfaceContainerHighest : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          // The field keeps the keyboard: a row that took the focus left
          // the arrows and Alt+P doing nothing until Tab put it back.
          canRequestFocus: false,
          onHover: (over) {
            if (over) onHover();
          },
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: child,
          ),
        ),
      ),
    );
  }
}
