/// The note's **Edit | Read** pair on a tablet (#1266): the eye of the
/// status row, as two named halves at the top of the note where a thumb
/// reads which one is on without trying it.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/note_top_bar_room.dart';
import 'package:niman/src/ui/strings.dart';

/// Edit and Read in one rounded outline, the one on screen filled.
///
/// Drawn by hand rather than as a [SegmentedButton]: a note's view moves
/// to the other pane with its state (a reparented subtree), and the
/// labelled segmented button trips the framework's semantics geometry
/// there.
final class NoteModeToggle extends StatelessWidget {
  /// The pair for a note whose preview is [previewVisible] or not; a null
  /// [onToggle] leaves it in its place, off — a file with no preview.
  const new({required this.previewVisible, required this.onToggle, super.key});

  /// Whether the read view is the one on screen.
  final bool previewVisible;

  /// Flips the note between its editor and its read view.
  final VoidCallback? onToggle;

  /// The pair's height: a thumb's target, less the row's breathing room.
  static const double height = 44;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A narrow row keeps the icons, each named in its tooltip.
    final labelled = NoteTopBarRoom.roomyAt(context);
    final radius = BorderRadius.circular(height / 2);
    return Container(
      key: const Key('note-mode-toggle'),
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _half(
              context,
              key: const Key('note-mode-edit'),
              icon: Icons.edit_outlined,
              label: AppStrings.noteModeEdit,
              selected: !previewVisible,
              labelled: labelled,
            ),
            VerticalDivider(width: 1, color: scheme.outline),
            _half(
              context,
              key: const Key('note-mode-read'),
              icon: Icons.visibility_outlined,
              label: AppStrings.noteModeRead,
              selected: previewVisible,
              labelled: labelled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _half(
    BuildContext context, {
    required Key key,
    required IconData icon,
    required String label,
    required bool selected,
    required bool labelled,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onToggle = this.onToggle;
    final enabled = onToggle != null;
    final colour = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : selected
        ? scheme.onSurface
        : scheme.onSurfaceVariant;
    final half = Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        key: key,
        // The half already on is no switch to press.
        onTap: !enabled || selected ? null : onToggle,
        child: Container(
          color: selected ? scheme.surfaceContainerHigh : null,
          constraints: const BoxConstraints(minWidth: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: colour),
              if (labelled) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colour,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return labelled ? half : Tooltip(message: label, child: half);
  }
}
