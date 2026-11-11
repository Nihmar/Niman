/// The rail of the wide shell on a touch device (#1266): a tablet's, where
/// a thumb has no hover to read a tooltip by. Each destination is its icon
/// on the active pill with its label under it; the library sits at the top
/// with **New** under it, where a thumb on the left edge finds them, and
/// Settings at the foot. A desktop keeps [ShellRail]'s icons.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/new_shell_items.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/strings.dart';

/// The labelled rail: library, New, the destinations, Settings.
final class TouchRail extends StatelessWidget {
  /// The rail over [destinations] with [current] selected.
  const new({
    required this.destinations,
    required this.current,
    required this.onDestinationSelected,
    required this.onSwitchLibrary,
    required this.library,
    required this.newItems,
    required this.onNewItem,
    required this.tooltipOf,
    super.key,
  });

  /// The rail's width: a navigation rail's, the labels' room. It stays
  /// when the labels go, so the panes beside it never move under the
  /// keyboard.
  static const double width = 88;

  /// The height each labelled destination takes.
  static const double _labelledHeight = 60;

  /// The height each destination takes without its label.
  static const double _iconHeight = 48;

  /// What the column above the destinations takes with the labels: the
  /// library, New and the gaps around them.
  static const double _headLabelled = 20 + 48 + 12 + 56 + 16;

  /// The destinations shown, in order; Settings among them.
  final List<ShellDestination> destinations;

  /// The current tab; a hidden one leaves the rail with none selected.
  final ShellTab current;

  /// Reports a tap; the shell decides what it means.
  final ValueChanged<ShellTab> onDestinationSelected;

  /// Opens the known-library list.
  final VoidCallback onSwitchLibrary;

  /// The open library's name: its initial on the button, the whole in its
  /// tooltip.
  final String library;

  /// The create menu's entries, read as it opens.
  final List<PopupMenuEntry<NewShellItem>> Function(BuildContext) newItems;

  /// Runs the chosen create action.
  final ValueChanged<NewShellItem> onNewItem;

  /// A destination's tooltip: its label, with its key where there is one.
  final String Function(ShellDestination) tooltipOf;

  /// Whether a rail [height] tall has the room for the labels.
  bool _labelsFit(double height) =>
      height >= _headLabelled + destinations.length * _labelledHeight + 16;

  @override
  Widget build(BuildContext context) {
    final settings = destinations.firstWhere((d) => d.tab == ShellTab.settings);
    final places = [
      for (final d in destinations)
        if (d != settings) d,
    ];
    return Container(
      key: const Key('shell-rail'),
      width: width,
      color: Theme.of(context).colorScheme.surfaceContainer,
      // The labels go where the rail is too short for them — the keyboard
      // up, a short window — and what is left scrolls rather than lose
      // Settings under the overflow (#849).
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelled = _labelsFit(constraints.maxHeight);
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: _column(context, places, settings, labelled: labelled),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _column(
    BuildContext context,
    List<ShellDestination> places,
    ShellDestination settings, {
    required bool labelled,
  }) {
    return Column(
      children: [
        SizedBox(height: labelled ? 20 : 8),
        _LibraryButton(
          library: library,
          size: labelled ? 48 : 44,
          onPressed: onSwitchLibrary,
        ),
        SizedBox(height: labelled ? 12 : 6),
        _NewButton(
          size: labelled ? 56 : 48,
          items: newItems,
          onSelected: onNewItem,
        ),
        SizedBox(height: labelled ? 16 : 8),
        for (final destination in places)
          _item(destination, labelled: labelled),
        const Spacer(),
        _item(settings, labelled: labelled),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _item(ShellDestination destination, {required bool labelled}) =>
      _TouchRailItem(
        buttonKey: Key('rail-${destination.name}'),
        destination: destination,
        tooltip: tooltipOf(destination),
        selected: current == destination.tab,
        labelled: labelled,
        height: labelled ? _labelledHeight : _iconHeight,
        onPressed: () => onDestinationSelected(destination.tab),
      );
}

/// The tint of the active pill and of New: the accent over the rail.
Color _tint(ColorScheme scheme) => Color.alphaBlend(
  scheme.primary.withValues(alpha: 0.16),
  scheme.surfaceContainer,
);

/// One destination: the icon on its pill, the label under it.
final class _TouchRailItem extends StatelessWidget {
  const new({
    required this.buttonKey,
    required this.destination,
    required this.tooltip,
    required this.selected,
    required this.labelled,
    required this.height,
    required this.onPressed,
  });

  final Key buttonKey;
  final ShellDestination destination;
  final String tooltip;
  final bool selected;
  final bool labelled;
  final double height;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Tooltip(
      message: tooltip,
      // The label is on screen; the tooltip only adds the key.
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        selected: selected,
        label: destination.label,
        excludeSemantics: true,
        child: InkWell(
          key: buttonKey,
          onTap: onPressed,
          // At least [height] tall, taller under a large text scale: the
          // rail scrolls rather than clip a label.
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: TouchRail.width,
              maxWidth: TouchRail.width,
              minHeight: height,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected ? _tint(scheme) : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 22,
                    color: color,
                  ),
                ),
                if (labelled) ...[
                  const SizedBox(height: 4),
                  Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The library's button: its initial on the accent, the window of
/// libraries on a tap.
final class _LibraryButton extends StatelessWidget {
  const new({
    required this.library,
    required this.size,
    required this.onPressed,
  });

  final String library;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = library.trim().isEmpty
        ? '·'
        : library.trim().characters.first.toUpperCase();
    return Tooltip(
      message: '${AppStrings.switchLibraryTitle}: $library',
      child: Material(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: const Key('rail-library'),
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: Text(
                initial,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// **New**: the create menu the tree footer has, at the rail's top.
final class _NewButton extends StatelessWidget {
  const new({
    required this.size,
    required this.items,
    required this.onSelected,
  });

  final double size;
  final List<PopupMenuEntry<NewShellItem>> Function(BuildContext) items;
  final ValueChanged<NewShellItem> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<NewShellItem>(
      key: const Key('rail-new'),
      tooltip: AppStrings.actionNew,
      onSelected: onSelected,
      position: PopupMenuPosition.over,
      itemBuilder: items,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _tint(scheme),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.add, size: 26, color: scheme.primary),
      ),
    );
  }
}
