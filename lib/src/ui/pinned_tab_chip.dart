import 'package:flutter/material.dart';
import 'package:niman/src/ui/note_tab_bar.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/strings.dart';

/// The chip of something pinned in a pane, at the end of its row (#712) —
/// Home or Todo, a version compared with its note: the rectangle the note
/// tabs wear, a click shows it again, the ✕ closes it.
final class PinnedTabChip extends StatelessWidget {
  /// The chip that reads [label] beside [icon].
  const new({
    required this.icon,
    required this.label,
    required this.tabKey,
    required this.closeKey,
    required this.selected,
    required this.focused,
    required this.onTap,
    required this.onClose,
    this.maxLabelWidth,
    super.key,
  });

  /// What is pinned, as an outline icon.
  final IconData icon;

  /// What is pinned, in words.
  final String label;

  /// The tab's key, on the rectangle the tests and the tour find.
  final Key tabKey;

  /// The ✕'s key.
  final Key closeKey;

  /// Whether it is what its pane shows.
  final bool selected;

  /// Whether its pane is the focused one.
  final bool focused;

  /// Shows it again.
  final VoidCallback onTap;

  /// Closes it.
  final VoidCallback onClose;

  /// The widest the label is drawn, when a long one has to give way.
  final double? maxLabelWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colour = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    final text = Text(
      label,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(color: colour),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6, end: 4),
      child: TabSurface(
        key: tabKey,
        selected: selected,
        focused: focused,
        onTap: onTap,
        builder: (context, {required hover}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 12),
            Icon(icon, size: 15, color: colour),
            const SizedBox(width: 6),
            Flexible(
              child: switch (maxLabelWidth) {
                final width? => ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width),
                  child: text,
                ),
                null => text,
              },
            ),
            const SizedBox(width: 6),
            SizedBox.square(
              dimension: TabSurface.closeFor(touch: thumbDense(theme)),
              child: IconButton(
                key: closeKey,
                tooltip: AppStrings.closeTabTooltip,
                padding: EdgeInsets.zero,
                iconSize: 14,
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
