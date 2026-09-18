/// The right dock (#175): the note's outline, its tags and its history,
/// one at a time, beside the note on a window wide enough for both.
///
/// It follows the focused pane's note: with the window split, the dock
/// speaks for the note the next key would go to. Closing it gives the
/// width back; whether it is open, and which pane it shows, are kept with
/// the workspace.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/workspace/workspace.dart';

/// The dock: a row of three pane tabs and a close, over the pane shown.
final class RightDock extends StatelessWidget {
  /// Shows [pane], built by [paneBuilder].
  const new({
    required this.pane,
    required this.onPane,
    required this.onClose,
    required this.paneBuilder,
    super.key,
  });

  /// The pane showing.
  final DockPane pane;

  /// Shows another pane.
  final ValueChanged<DockPane> onPane;

  /// Closes the dock.
  final VoidCallback onClose;

  /// Builds a pane's body.
  final Widget Function(DockPane pane) paneBuilder;

  /// The dock's width.
  static const double width = 280;

  /// A window at least this wide has room for the dock beside a note
  /// column; below it the dock stays shut whatever was chosen.
  static const double minWindowWidth = 1000;

  static String _label(DockPane pane) => switch (pane) {
    DockPane.outline => AppStrings.outlineTooltip,
    DockPane.tags => AppStrings.tagsTitle,
    DockPane.history => AppStrings.noteHistoryTitle,
  };

  static IconData _icon(DockPane pane, {required bool selected}) =>
      switch (pane) {
        DockPane.outline => Icons.toc,
        DockPane.tags => selected ? Icons.sell : Icons.sell_outlined,
        DockPane.history => Icons.history,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      key: const Key('right-dock'),
      color: scheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 38,
            child: Row(
              children: [
                const SizedBox(width: 6),
                for (final each in DockPane.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: IconButton(
                      key: Key('dock-pane-${each.name}'),
                      tooltip: _label(each),
                      isSelected: each == pane,
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      style: IconButton.styleFrom(
                        backgroundColor: each == pane
                            ? scheme.surfaceContainerHighest
                            : null,
                      ),
                      icon: Icon(_icon(each, selected: each == pane)),
                      onPressed: () => onPane(each),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _label(pane),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('dock-close'),
                  tooltip: AppStrings.sidePanelTooltip,
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: paneBuilder(pane)),
        ],
      ),
    );
  }
}
