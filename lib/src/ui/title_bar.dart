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
    this.tabs,
    this.tabsStart = 0,
    super.key,
  });

  /// The open notes' tabs (#23), in the bar's middle, built around the
  /// drag area they leave free; null leaves the whole middle to the
  /// title.
  final Widget Function(Widget dragArea)? tabs;

  /// Where the tabs start, from the bar's left edge: the tree's right
  /// edge, so the two line up and nothing moves as notes open.
  final double tabsStart;

  /// What the bar shows, e.g. `Niman — note.md`.
  final String title;

  /// Whether the tree pane is showing (drives the button and its tooltip).
  final bool sidebarVisible;

  /// Shows/hides the tree pane (the rail stays).
  final VoidCallback onToggleSidebar;

  /// The window seam the buttons act through.
  final WindowController window;

  Widget _title(ThemeData theme) => Align(
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
  );

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
            if (tabs case final tabs?) ...[
              // The title keeps the tree's width; the tabs start at its
              // edge. Everything that is not a tab still drags.
              SizedBox(
                width: (tabsStart - _leading).clamp(0, double.infinity),
                child: DragToMoveArea(child: _title(theme)),
              ),
              Expanded(
                child: tabs(const DragToMoveArea(child: SizedBox.expand())),
              ),
            ] else
              Expanded(
                // The whole middle is the drag area (double-click
                // maximizes, handled by the widget); the title rides at
                // its left.
                child: DragToMoveArea(child: _title(theme)),
              ),
            _WindowButtons(window: window),
          ],
        ),
      ),
    );
  }
}

/// The bar in Zen mode (#69): the way out, the note's name, and the
/// window's own buttons — the window stays a window, to move and to find
/// in the taskbar.
final class ZenTitleBar extends StatelessWidget {
  /// Creates the bar for the note called [title].
  const new({
    required this.title,
    required this.onLeave,
    required this.window,
    super.key,
  });

  /// The note's name, so a glance back says where the writing is.
  final String title;

  /// Leaves Zen mode.
  final VoidCallback onLeave;

  /// The window seam the buttons act through.
  final WindowController window;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const Key('zen-title-bar'),
      color: theme.colorScheme.surface,
      child: SizedBox(
        height: 38,
        child: Row(
          children: [
            const SizedBox(width: 4),
            IconButton(
              key: const Key('zen-leave'),
              tooltip: '${AppStrings.zenModeLeave} (${AppStrings.keyEscape})',
              icon: const Icon(Icons.fullscreen_exit),
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              onPressed: onLeave,
            ),
            Expanded(
              child: DragToMoveArea(
                child: Center(
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
            _WindowButtons(window: window),
          ],
        ),
      ),
    );
  }
}

/// Left of the title: the leading gap and the sidebar toggle.
const double _leading = 4 + 40;

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
