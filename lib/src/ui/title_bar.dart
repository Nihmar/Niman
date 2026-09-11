// The app's own window title bar (T-PP-22).
//
// Linux runs the app frameless and draws this in place of the system bar:
// the sidebar toggle on the left, a drag area carrying the app/note name,
// and the window buttons on the right. The drag area is deliberately the
// widest part — that is where the tabs will live.
//
// The window buttons go through [WindowController], not the plugin
// directly: the close button must meet the same unsaved-edits guard as
// the system one (with prevent-close on, `window_manager` reports
// `close()` as a close request instead of closing).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:window_manager/window_manager.dart' show DragToMoveArea;

/// The window title bar drawn by the app.
final class AppTitleBar extends StatelessWidget {
  /// Creates the bar; [title] names the window (app and open note).
  const new({
    required this.title,
    required this.sidebarVisible,
    required this.onToggleSidebar,
    required this.window,
    super.key,
  });

  /// What the bar shows, e.g. `Niman — note.md`.
  final String title;

  /// Whether the tree pane is showing (drives the button and its tooltip).
  final bool sidebarVisible;

  /// Shows/hides the tree pane (the rail stays).
  final VoidCallback onToggleSidebar;

  /// The window seam the buttons act through.
  final WindowController window;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const Key('title-bar'),
      color: theme.colorScheme.surfaceContainer,
      child: SizedBox(
        height: 38,
        child: Row(
          children: [
            const SizedBox(width: 4),
            IconButton(
              key: const Key('toggle-sidebar'),
              tooltip: sidebarVisible
                  ? AppStrings.hideSidebarTooltip
                  : AppStrings.showSidebarTooltip,
              icon: Icon(
                sidebarVisible
                    ? Icons.vertical_split
                    : Icons.chrome_reader_mode_outlined,
              ),
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: onToggleSidebar,
            ),
            Expanded(
              // The whole middle is the drag area (double-click maximizes,
              // handled by the widget); the title rides at its left.
              child: DragToMoveArea(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _WindowButtons(window: window),
          ],
        ),
      ),
    );
  }
}

/// Minimize, maximize/restore and close, at the bar's right edge.
final class _WindowButtons extends StatelessWidget {
  const new({required this.window});

  final WindowController window;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: window.maximized,
      builder: (context, maximized, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WindowButton(
            key: const Key('window-minimize'),
            icon: Icons.minimize,
            tooltip: AppStrings.windowMinimizeTooltip,
            onPressed: () => unawaited(window.minimize()),
          ),
          _WindowButton(
            key: const Key('window-maximize'),
            icon: maximized ? Icons.filter_none : Icons.crop_square,
            tooltip: maximized
                ? AppStrings.windowRestoreTooltip
                : AppStrings.windowMaximizeTooltip,
            onPressed: () => unawaited(window.toggleMaximize()),
          ),
          _WindowButton(
            key: const Key('window-close'),
            icon: Icons.close,
            tooltip: AppStrings.windowCloseTooltip,
            onPressed: () => unawaited(window.close()),
          ),
        ],
      ),
    );
  }
}

/// One window button: a flat, hover-highlighted square, the shape of a
/// system title-bar button.
final class _WindowButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 38,
      child: IconButton(
        icon: Icon(icon, size: 18),
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          shape: const RoundedRectangleBorder(),
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
