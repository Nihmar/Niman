/// The line over the tree that says which library it is (#1134), and the
/// folder the selection is in: on a window with no title bar of the app's
/// own — an Android tablet — nothing else on screen says it. It stands as
/// tall as the panes' tab row beside it, so the two rules under them meet.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The library's name, the selection's folder under it, and the switch.
final class TreeHeader extends StatelessWidget {
  /// The header of [library], [folder] selected (`''`: its root), [height]
  /// tall.
  const new({
    required this.library,
    required this.folder,
    required this.height,
    required this.onSwitchLibrary,
    super.key,
  });

  /// The library's name.
  final String library;

  /// The library-relative folder the selection is in; empty at the root,
  /// which says nothing more.
  final String folder;

  /// The row's height: the tab row's beside it.
  final double height;

  /// Opens the library switch.
  final VoidCallback onSwitchLibrary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SizedBox(
      key: const Key('tree-header'),
      height: height,
      child: Row(
        children: [
          const SizedBox(width: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox.square(
              dimension: 40,
              child: Icon(Icons.book_outlined, size: 22, color: scheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  library,
                  key: const Key('tree-header-library'),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (folder.isNotEmpty)
                  Text(
                    folder,
                    key: const Key('tree-header-folder'),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            key: const Key('tree-header-switch'),
            tooltip: AppStrings.switchLibraryTitle,
            icon: const Icon(Icons.unfold_more),
            onPressed: onSwitchLibrary,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
