/// The controls a pane's tab row starts with where the panes head their own
/// tabs (#1134) — an Android tablet, a phone in landscape: the sidebar's
/// toggle, and back and forward through the notes shown. A touch screen
/// has no title bar, no `Alt+←` and no mouse side buttons to reach them.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The sidebar's toggle, back and forward, and a rule before the tabs.
final class TabRowLead extends StatelessWidget {
  /// The lead for a sidebar [sidebarVisible] or not; a null [onBack] or
  /// [onForward] disables that arrow, which keeps its place. Without
  /// [arrows] — a row too short for them and the tabs — only the toggle.
  const new({
    required this.sidebarVisible,
    required this.onToggleSidebar,
    required this.onBack,
    required this.onForward,
    this.arrows = true,
    super.key,
  });

  /// The least width of a row the arrows are shown in: below it the tabs
  /// would be squeezed under their own buttons (a 1024 px tablet with the
  /// tree and the dock open leaves its panes 350).
  static const double arrowsRoom = 480;

  /// Whether the arrows show.
  final bool arrows;

  /// Whether the sidebar shows: its icon is filled then.
  final bool sidebarVisible;

  /// Shows or hides the sidebar.
  final VoidCallback onToggleSidebar;

  /// Shows the note before; null with none.
  final VoidCallback? onBack;

  /// Shows the note after; null with none.
  final VoidCallback? onForward;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        key: const Key('tabs-toggle-sidebar'),
        tooltip: sidebarVisible
            ? AppStrings.hideSidebarTooltip
            : AppStrings.showSidebarTooltip,
        isSelected: sidebarVisible,
        // The dock's icon, mirrored: each toggle shows the side its panel
        // is on.
        icon: Transform.flip(
          flipX: true,
          child: const Icon(Icons.view_sidebar_outlined),
        ),
        selectedIcon: Transform.flip(
          flipX: true,
          child: const Icon(Icons.view_sidebar),
        ),
        onPressed: onToggleSidebar,
      ),
      if (arrows) ...[
        IconButton(
          key: const Key('tabs-back'),
          tooltip: AppStrings.shortcutNoteBack,
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        IconButton(
          key: const Key('tabs-forward'),
          tooltip: AppStrings.shortcutNoteForward,
          icon: const Icon(Icons.arrow_forward),
          onPressed: onForward,
        ),
        const SizedBox(height: 28, child: VerticalDivider(width: 17)),
      ],
    ],
  );
}
