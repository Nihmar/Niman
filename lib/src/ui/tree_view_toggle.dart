/// The Files pane's List | Grid switch (#727), split out of
/// `shell_tree_footer.dart`: one class per file.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/ui/strings.dart';

/// The List | Grid pair (#727), beside the sort chevron in the wide
/// pane's footer.
///
/// Two outline icons in one bordered segment; the one for the view that
/// is on is filled, on the raised ground, per the icon rule — a filled
/// icon says a state is on.
final class TreeViewToggle extends StatelessWidget {
  /// Creates the pair; [view] is the view in force.
  const new({required this.view, required this.onView, super.key});

  /// The view in force.
  final TreeView view;

  /// Applies the view chosen; the shell persists it.
  final ValueChanged<TreeView> onView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _segment(
              context,
              key: const Key('view-list-toggle'),
              tooltip: AppStrings.viewList,
              icon: view == TreeView.list
                  ? Icons.view_list
                  : Icons.view_list_outlined,
              on: view == TreeView.list,
              onTap: () => onView(TreeView.list),
            ),
            Container(width: 1, height: 26, color: theme.colorScheme.outline),
            _segment(
              context,
              key: const Key('view-grid-toggle'),
              tooltip: AppStrings.viewGrid,
              icon: view == TreeView.grid
                  ? Icons.grid_view
                  : Icons.grid_view_outlined,
              on: view == TreeView.grid,
              onTap: () => onView(TreeView.grid),
            ),
          ],
        ),
      ),
    );
  }

  /// One half of the pair: the icon of the view, filled when it is on.
  Widget _segment(
    BuildContext context, {
    required Key key,
    required String tooltip,
    required IconData icon,
    required bool on,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        key: key,
        onTap: onTap,
        child: Container(
          width: 28,
          height: 26,
          alignment: Alignment.center,
          color: on ? theme.colorScheme.surfaceContainerHigh : null,
          child: Icon(
            icon,
            size: 17,
            color: on
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
