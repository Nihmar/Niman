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
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/marquee_text.dart';
import 'package:niman/src/ui/shell_navigation.dart';
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
      // The name starts at the panel's edge under it (#708).
      padding: const EdgeInsets.only(left: _titleInset, right: 8),
      child: MarqueeText(
        text: title,
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
            const SizedBox(width: _toggleGap),
            ValueListenableBuilder<KeyMap>(
              // The keys are remappable (#159), so the tooltip is built
              // from the map in force instead of a hard-coded pair (#498):
              // the label and the key that runs the command cannot drift.
              valueListenable: AppKeyMap.current,
              builder: (context, keyMap, _) {
                final keys = keyMap.bindingOf(AppCommand.toggleSidebar);
                final label = sidebarVisible
                    ? AppStrings.hideSidebarTooltip
                    : AppStrings.showSidebarTooltip;
                // Its width fixed, not left to the platform's density: the
                // tabs are placed past [_leading], and a desktop drew the
                // button 6 px narrower than a phone (34 against 40), which
                // put them that far left of the panes under them.
                return SizedBox.square(
                  dimension: _toggleSize,
                  child: IconButton(
                    key: const Key('toggle-sidebar'),
                    tooltip: keys == null
                        ? label
                        : '$label (${describeActivator(keys)})',
                    icon: Icon(
                      sidebarVisible
                          ? Icons.vertical_split
                          : Icons.chrome_reader_mode_outlined,
                    ),
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    onPressed: onToggleSidebar,
                  ),
                );
              },
            ),
            if (tabs case final tabs?) ...[
              // The title keeps the tree's width; the tabs start at its
              // edge. Everything that is not a tab still drags.
              SizedBox(
                width: (tabsStart - _leading).clamp(_tabsGap, double.infinity),
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

/// A thin bar for a window that is showing one thing (#69, #77): a
/// button at the left, the thing's name in the middle, and the window's
/// own buttons — the window stays a window, to move and to find in the
/// taskbar.
final class SlimTitleBar extends StatelessWidget {
  /// Creates the bar for [title], with [leading] before it.
  const new({
    required this.title,
    required this.leading,
    required this.window,
    this.actions = const [],
    super.key,
  });

  /// Buttons before the window's own, at the right.
  final List<Widget> actions;

  /// What the window is showing.
  final String title;

  /// The way out, at the left.
  final Widget leading;

  /// The window seam the buttons act through.
  final WindowController window;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SizedBox(
        height: 38,
        child: Row(
          children: [
            const SizedBox(width: 4),
            leading,
            Expanded(
              child: DragToMoveArea(
                child: Center(
                  child: MarqueeText(
                    text: title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            ...actions,
            _WindowButtons(window: window),
          ],
        ),
      ),
    );
  }
}

/// The bar in Zen mode (#69): the way out, the note's name, and the
/// window's own buttons.
final class ZenTitleBar extends StatelessWidget {
  /// Creates the bar for the note called [title].
  const new({
    required this.title,
    required this.onLeave,
    required this.window,
    this.previewVisible = false,
    this.onTogglePreview,
    super.key,
  });

  /// Whether the note shows its preview.
  final bool previewVisible;

  /// Flips between the note's editor and its preview: the status row
  /// that holds the eye elsewhere is hidden in Zen. Null leaves it out.
  final VoidCallback? onTogglePreview;

  /// The note's name, so a glance back says where the writing is.
  final String title;

  /// Leaves Zen mode.
  final VoidCallback onLeave;

  /// The window seam the buttons act through.
  final WindowController window;

  @override
  Widget build(BuildContext context) => SlimTitleBar(
    key: const Key('zen-title-bar'),
    title: title,
    window: window,
    actions: [
      if (onTogglePreview case final toggle?)
        IconButton(
          key: const Key('zen-preview-toggle'),
          tooltip: previewVisible
              ? AppStrings.showEditorTooltip
              : AppStrings.showPreviewTooltip,
          icon: Icon(
            previewVisible ? Icons.edit_outlined : Icons.visibility_outlined,
          ),
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          onPressed: toggle,
        ),
    ],
    leading: IconButton(
      key: const Key('zen-leave'),
      tooltip: '${AppStrings.zenModeLeave} (${AppStrings.keyEscape})',
      icon: const Icon(Icons.fullscreen_exit),
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      onPressed: onLeave,
    ),
  );
}

/// The sidebar toggle's side: what a desktop draws it at.
const double _toggleSize = 34;

/// The gap before the sidebar toggle: what centres its glyph on the
/// rail's glyphs under it (#708).
const double _toggleGap = ShellRail.glyphCentre - _toggleSize / 2;

/// Left of the title: the leading gap and the sidebar toggle.
const double _leading = _toggleGap + _toggleSize;

/// The title's room before the name: what puts it at the panel's left
/// edge, past the toggle (#708).
const double _titleInset = ShellRail.panelStart - _leading;

/// The least room between the sidebar toggle and the first tab, a guard
/// only: the tabs start at the panes' island, which with the tree hidden
/// is 11 px past the toggle — room enough, and kept so the first tab
/// stands over the panel (0.0.8 test round asked for room; a 16 px floor
/// once pushed the tab 8 px off the panel's edge).
const double _tabsGap = 8;

/// Minimize, maximize/restore and close, at the bar's right edge.
///
/// The bar also tells the window seam where these three ended up (#169):
/// Windows offers the Snap Layouts flyout only to a window that answers
/// `WM_NCHITTEST` with the caption-button hit codes over them, and the
/// rectangles are the drawn ones, so the hit test follows the bar instead
/// of a constant.
final class _WindowButtons extends StatefulWidget {
  const new({required this.window});

  final WindowController window;

  @override
  State<_WindowButtons> createState() => _WindowButtonsState();
}

final class _WindowButtonsState extends State<_WindowButtons> {
  /// The buttons as the render tree holds them: where they are is what the
  /// platform has to be told (#169).
  final GlobalKey _minimize = GlobalKey();
  final GlobalKey _maximize = GlobalKey();
  final GlobalKey _close = GlobalKey();

  /// What the window was last told, so a layout that moves nothing does not
  /// repeat itself.
  ({Rect minimize, Rect maximize, Rect close})? _reported;

  @override
  Widget build(BuildContext context) {
    // The window's size and scale both move the buttons, and both reach the
    // bar as a MediaQuery change: depending on it is what makes the bar
    // report again after a resize or a move to another display (#169).
    final media = MediaQuery.of(context);
    WidgetsBinding.instance.addPostFrameCallback(
      // After the frame: only then are the buttons where the user sees them.
      (_) => _reportButtons(media.devicePixelRatio),
    );
    return ValueListenableBuilder<bool>(
      valueListenable: widget.window.maximized,
      builder: (context, maximized, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KeyedSubtree(
            key: _minimize,
            child: _WindowButton(
              key: const Key('window-minimize'),
              icon: Icons.minimize,
              tooltip: AppStrings.windowMinimizeTooltip,
              onPressed: () => unawaited(widget.window.minimize()),
            ),
          ),
          KeyedSubtree(
            key: _maximize,
            child: _WindowButton(
              key: const Key('window-maximize'),
              icon: maximized ? Icons.filter_none : Icons.crop_square,
              tooltip: maximized
                  ? AppStrings.windowRestoreTooltip
                  : AppStrings.windowMaximizeTooltip,
              onPressed: () => unawaited(widget.window.toggleMaximize()),
            ),
          ),
          KeyedSubtree(
            key: _close,
            child: _WindowButton(
              key: const Key('window-close'),
              icon: Icons.close,
              tooltip: AppStrings.windowCloseTooltip,
              onPressed: () => unawaited(widget.window.close()),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // The bar is going away — the narrow layout draws none (#490). A
    // rectangle left over would keep the runner's hit test answering where
    // the buttons were, so the window is told the three are nowhere.
    widget.window.reportCaptionButtons(
      minimize: Rect.zero,
      maximize: Rect.zero,
      close: Rect.zero,
    );
    super.dispose();
  }

  /// Hands the window seam the buttons' rectangles, in physical pixels: the
  /// Flutter view's top-left corner is the window's client origin, so the
  /// drawn point scaled by the device pixel ratio is the client point.
  void _reportButtons(double ratio) {
    if (!mounted) return;
    final buttons = (
      minimize: _bounds(_minimize, ratio),
      maximize: _bounds(_maximize, ratio),
      close: _bounds(_close, ratio),
    );
    if (buttons == _reported) return;
    _reported = buttons;
    widget.window.reportCaptionButtons(
      minimize: buttons.minimize,
      maximize: buttons.maximize,
      close: buttons.close,
    );
  }

  /// The button [key] holds, as laid out. Zero when it is gone: a rectangle
  /// nobody is in is a hit test that answers nothing, which is the safe
  /// direction to fail in.
  Rect _bounds(GlobalKey key, double ratio) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return Rect.zero;
    final origin = box.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      origin.dx * ratio,
      origin.dy * ratio,
      box.size.width * ratio,
      box.size.height * ratio,
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
