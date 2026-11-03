import 'package:flutter/material.dart';
import 'package:niman/src/editor/toolbar.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/tree_drag.dart';

/// The pinned section's heading: a chevron, the word, and how many are
/// in there. Tapping it rolls the section up or down.
///
/// The count is what makes rolling it up bearable — closed, the heading
/// still says how much is behind it, so the section is a thing you put
/// away rather than a thing you lose.
///
/// The row is exactly [editorToolbarHeight] tall, matching the editor
/// toolbar across the pane boundary so the rows below start together
/// (user, 2026-09-09).
final class TreePinnedHeading extends StatelessWidget {
  /// The heading of [count] pinned notes, rolled up when [collapsed].
  const new({
    required this.count,
    required this.collapsed,
    required this.onToggle,
    super.key,
  });

  /// How many notes are pinned.
  final int count;

  /// Whether the section is rolled up.
  final bool collapsed;

  /// Rolls the section up or down.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return TreeDropShield(
      child: SizedBox(
        height: editorToolbarHeight,
        child: InkWell(
          key: const Key('pinned-heading'),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 16),
            child: Row(
              children: [
                Icon(
                  collapsed ? Icons.chevron_right : Icons.expand_more,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(AppStrings.pinnedSectionCount(count), style: style),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
