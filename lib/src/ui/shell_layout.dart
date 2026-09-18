/// The shell's two layouts (issue #100, split out of `shell.dart`): the
/// phone, where a note opens full-screen over the tabs, and the wide
/// window, where the rail, the tree and the note share the screen.
///
/// The shell's `State` still owns the state and the flows; what it hands
/// over is [ShellLayoutProps] — one explicit, immutable argument saying
/// what to draw and what to call. That is deliberately a long list rather
/// than a short one hiding a reference back to the shell: a layout that
/// could reach into the shell would go on reaching, and the split would
/// buy nothing. The list is the honest size of the coupling, now visible
/// in one place instead of spread over three hundred lines of builder.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/shell_preview_actions.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/switch_library_screen.dart';
import 'package:niman/src/ui/title_bar.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:path/path.dart' as p;

/// Everything a shell layout draws with, and everything it can ask for.
@immutable
final class ShellLayoutProps {
  /// Creates the arguments for one build of one layout.
  const new({
    required this.controller,
    required this.selectedPath,
    required this.selectedIsDir,
    required this.treeVisible,
    required this.previewFullScreen,
    required this.previewSplitsHere,
    required this.previewVisible,
    required this.previewToggleVisible,
    required this.noteHidingTabs,
    required this.noteFade,
    required this.shortcutBindings,
    required this.onCloseFullScreenNote,
    required this.onLeaveFullScreenPreview,
    required this.isQuickNote,
    required this.noteBarActions,
    required this.buildTabShell,
    required this.buildFullNote,
    required this.window,
    required this.windowTitle,
    required this.sidebarVisible,
    required this.onToggleSidebar,
    required this.shellFocus,
    required this.tabIndex,
    required this.onDestinationSelected,
    required this.buildWideSlots,
  });

  /// The open library.
  final LibrarySession controller;

  /// The selected tree row, or null.
  final String? selectedPath;

  /// Whether that row is a folder.
  final bool selectedIsDir;

  /// Phone only: whether the tree, not the note, is the pane on screen.
  final bool treeVisible;

  /// Whether the preview asked for the whole screen.
  final bool previewFullScreen;

  /// Whether the preview shares this layout's screen with the editor
  /// instead of replacing it.
  final bool previewSplitsHere;

  /// Whether the preview is the pane showing.
  final bool previewVisible;

  /// Whether this note can toggle a preview at all.
  final bool previewToggleVisible;

  /// Whether the tab shell behind a full-screen note may stop drawing
  /// (it waits out the note's opening fade).
  final bool noteHidingTabs;

  /// How long the full-screen note fades in and out.
  final Duration noteFade;

  /// The app accelerators (T-PP-10).
  final Map<ShortcutActivator, VoidCallback> shortcutBindings;

  /// Leaves the full-screen note, back to the tab it opened from.
  final VoidCallback onCloseFullScreenNote;

  /// Leaves the full-screen *preview*, keeping the note.
  final VoidCallback onLeaveFullScreenPreview;

  /// Whether the open note is the library's quick note: the app bar's
  /// label says so (the tabs no longer do, issue #73, item 1).
  final bool isQuickNote;

  /// The open note's own actions for the phone's note bar.
  final List<Widget> noteBarActions;

  /// The phone's tab shell, bodies and all.
  final Widget Function() buildTabShell;

  /// The phone's full-screen note body for [selectedPath].
  final Widget Function(String path) buildFullNote;

  /// The platform window: the wide layout asks whether it draws its own
  /// title bar, and hands it the buttons.
  final WindowController window;

  /// The title that bar carries.
  final String windowTitle;

  /// Whether the wide layout's tree pane shows (the rail always stays).
  final bool sidebarVisible;

  /// Shows/hides that tree pane.
  final VoidCallback onToggleSidebar;

  /// Carries focus for the accelerators when nothing else wants it.
  final FocusNode shellFocus;

  /// The current tab, as the bar and the rail count them.
  final int tabIndex;

  /// A tap on the bar or the rail; the shell decides what it means.
  final ValueChanged<int> onDestinationSelected;

  /// The wide layout's stacked tab slots, in tab order.
  final List<Widget> Function() buildWideSlots;

  /// Whether a note (not a folder) is open at all.
  bool get noteOpen => selectedPath != null && !selectedIsDir;

  /// Phone only: whether that note is the thing on screen.
  bool get fullNote => noteOpen && !treeVisible;

  /// Whether the preview shows without its chrome.
  ///
  /// Only a note that is actually previewing — not split, not a kind GUI
  /// — can get there, so the full-screen flag alone never decides it.
  bool get immersive =>
      fullNote &&
      previewFullScreen &&
      previewVisible &&
      previewToggleVisible &&
      !previewSplitsHere;
}

/// The phone: the selected note opens full-screen, from any tab, as a
/// page over the tab shell, which stays mounted underneath (T-TS-08).
///
/// The note is a page, not a tab: it opens full-screen and the tab bar
/// does not sit under it (issue #73, item 1) — going anywhere else is
/// back, and back lands where the note was opened from. Swapping the
/// tab shell out used to dispose all five kept-alive bodies at once, and
/// going back remounted them mid-animation.
final class NarrowShellLayout extends StatelessWidget {
  /// Creates the phone layout.
  const new({required this.props, super.key});

  /// What to draw, and what to call.
  final ShellLayoutProps props;

  /// The app bar's title: the note's name, its folder under it (the
  /// note is a page now, not a tab — the tab bar no longer says where
  /// it lives), and, for the quick note, the label that says so.
  Widget _noteTitle(BuildContext context, String path) {
    final folder = p.dirname(path);
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (props.isQuickNote)
          Text(
            AppStrings.quickNoteTitle.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1,
            ),
          ),
        Text(p.basename(path)),
        if (folder != '.')
          Text(
            folder,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPath = props.selectedPath;
    final fullNote = props.fullNote;
    final immersive = props.immersive;
    // The same accelerators as the wide layout, but without the focus
    // claim: a field keeps the software keyboard (T-PP-10).
    return CallbackShortcuts(
      bindings: props.shortcutBindings,
      child: PopScope(
        canPop: !fullNote,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          // Back leaves fullscreen before it leaves the note: one
          // gesture, one layer of chrome, the way every other fullscreen
          // behaves.
          if (immersive) {
            props.onLeaveFullScreenPreview();
            return;
          }
          props.onCloseFullScreenNote();
        },
        child: ColoredBox(
          // Opaque surface behind every phone transition (issue #4): the
          // full-note fade starts from transparent, and without this the
          // first frames expose the black Android window instead.
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The tab shell never unmounts: hidden it skips layout,
              // paint and tickers, and the fullscreen note above is
              // opaque. The hiding waits out the open fade (issue #4):
              // the note fades in over the tabs instead of over the
              // window background.
              Offstage(
                key: const ValueKey('tab-shell-offstage'),
                offstage: fullNote && props.noteHidingTabs,
                child: TickerMode(
                  enabled: !fullNote,
                  child: KeyedSubtree(
                    key: const ValueKey('tab-shell'),
                    child: props.buildTabShell(),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: props.noteFade,
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: fullNote && selectedPath != null
                    ? KeyedSubtree(
                        key: const ValueKey('full-note'),
                        child: Scaffold(
                          appBar: immersive
                              ? null
                              : AppBar(
                                  leading: BackButton(
                                    onPressed: props.onCloseFullScreenNote,
                                  ),
                                  title: _noteTitle(context, selectedPath),
                                  actions: props.noteBarActions,
                                ),
                          body: Stack(
                            children: [
                              // Stable subtree across the immersive
                              // toggle: only the top inset flips, so
                              // entering or leaving fullscreen never
                              // reparents (and disposes) the open note's
                              // state, focus and scroll. The all-false
                              // SafeArea is a layout no-op.
                              Positioned.fill(
                                child: SafeArea(
                                  top: immersive,
                                  bottom: false,
                                  left: false,
                                  right: false,
                                  child: props.buildFullNote(selectedPath),
                                ),
                              ),
                              if (immersive)
                                ExitFullScreenButton(
                                  onExit: props.onLeaveFullScreenPreview,
                                ),
                            ],
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The wide window: rail, then whichever tab's slot is showing.
///
/// There is no window app bar (T-PP-22): the rail names the app, the
/// tree carries its own controls at the base, and an open note carries
/// its controls in the detail pane's header. On Linux the window is
/// frameless and the app draws its own title bar instead.
final class WideShellLayout extends StatelessWidget {
  /// Creates the wide layout.
  const new({required this.props, super.key});

  /// What to draw, and what to call.
  final ShellLayoutProps props;

  /// The known-library list, from the rail's foot (#170).
  ///
  /// The same screen the settings row opens, pushed the same way and
  /// with the same exit: the switch tears the shell down itself, so
  /// leaving this route is all the caller has to do.
  Future<void> _switchLibrary(BuildContext context) async {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => SwitchLibraryScreen(
          controller: props.controller,
          onSwitched: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CallbackShortcuts(
        bindings: props.shortcutBindings,
        // The shell has to be an ancestor of the primary focus for key
        // events to bubble to the bindings; a fresh window focuses
        // nothing (T-PP-10), so the body claims it until the tree or the
        // editor takes over.
        child: Focus(
          focusNode: props.shellFocus,
          autofocus: true,
          child: Column(
            children: [
              if (props.window.customTitleBar)
                AppTitleBar(
                  title: props.windowTitle,
                  sidebarVisible: props.sidebarVisible,
                  onToggleSidebar: props.onToggleSidebar,
                  window: props.window,
                ),
              Expanded(
                child: Row(
                  children: [
                    ShellRail(
                      selectedIndex: props.tabIndex,
                      onDestinationSelected: props.onDestinationSelected,
                      onSwitchLibrary: () => _switchLibrary(context),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: props.buildWideSlots(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
