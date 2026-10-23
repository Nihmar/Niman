/// The right dock (#175): the note's outline, its tags, its links, its tasks
/// and its history, one at a time, beside the note on a window wide enough
/// for both — and the journal's calendar (#7), which is the library's, not the
/// note's.
///
/// It follows the focused pane's note: with the window split, the dock
/// speaks for the note the next key would go to. Closing it gives the
/// width back; whether it is open, and which pane it shows, are kept with
/// the workspace.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/workspace/workspace.dart';

/// The feature [pane] belongs to (#1109), or null for a core one: the
/// note's own, and the library's journal calendar for the journal.
LibraryFeature? featureOfDockPane(DockPane pane) => switch (pane) {
  DockPane.journal => LibraryFeature.journal,
  DockPane.tasks => LibraryFeature.todo,
  DockPane.outline ||
  DockPane.spelling ||
  DockPane.tags ||
  DockPane.links ||
  DockPane.history => null,
};

/// The dock: a row of pane tabs and a close, over the pane shown. A pane
/// whose feature is off in [features] has no tab, and the dock shows the
/// outline in its place until it is back; the pane it was left on is kept.
final class RightDock extends StatelessWidget {
  /// Shows [pane], built by [paneBuilder].
  const new({
    required this.pane,
    required this.onPane,
    required this.onClose,
    required this.paneBuilder,
    this.features = const Features(),
    super.key,
  });

  /// The library's features.
  final Features features;

  /// Whether [pane] has a place in the dock.
  bool _offers(DockPane pane) => switch (featureOfDockPane(pane)) {
    final feature? => features.isOn(feature),
    null => true,
  };

  /// The pane showing.
  final DockPane pane;

  /// Shows another pane.
  final ValueChanged<DockPane> onPane;

  /// Closes the dock.
  final VoidCallback onClose;

  /// Builds a pane's body.
  final Widget Function(DockPane pane) paneBuilder;

  /// The panes a dragged dock always leaves beside it (#297): past this,
  /// the dock stops growing rather than squeezing the note away. Its own
  /// width is the library's `dockWidth`.
  static const double minPanesWidth = 360;

  /// A window at least this wide has room for the dock beside a note
  /// column; below it the dock does not dock — it opens over the note
  /// instead (see `DockOverlay`), and the docked state stays as it was
  /// chosen.
  static const double minWindowWidth = 1000;

  static String _label(DockPane pane) => switch (pane) {
    DockPane.outline => AppStrings.outlineTooltip,
    DockPane.tags => AppStrings.tagsTitle,
    DockPane.links => AppStrings.linksToNoteTitle,
    DockPane.tasks => AppStrings.tasksForNoteTitle,
    DockPane.spelling => AppStrings.spellCheckTitle,
    DockPane.history => AppStrings.noteHistoryTitle,
    DockPane.journal => AppStrings.paletteGroupJournal,
  };

  static IconData _icon(DockPane pane, {required bool selected}) =>
      switch (pane) {
        DockPane.outline => Icons.toc,
        DockPane.tags => selected ? Icons.sell : Icons.sell_outlined,
        DockPane.links => selected ? Icons.link : Icons.link_outlined,
        DockPane.tasks => selected ? Icons.check_box : Icons.check_box_outlined,
        DockPane.spelling => Icons.spellcheck,
        DockPane.history => Icons.history,
        DockPane.journal =>
          selected ? Icons.calendar_today : Icons.calendar_today_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shown = _offers(pane) ? pane : DockPane.outline;
    return Material(
      key: const Key('right-dock'),
      color: scheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 38,
            child: Row(
              children: [
                const SizedBox(width: 6),
                // The strip has the row's larger share, so the pane's name
                // beside it — the smaller one — keeps a little width.
                Flexible(
                  flex: 2,
                  child: _PaneTabs(
                    pane: shown,
                    panes: [
                      for (final each in DockPane.values)
                        if (_offers(each)) each,
                    ],
                    onPane: onPane,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _label(shown),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('dock-close'),
                  tooltip: AppStrings.sidePanelTooltip,
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: paneBuilder(shown)),
        ],
      ),
    );
  }
}

/// The dock's pane tabs (#1000).
///
/// The strip shows its last tabs first — it is laid out from its end, as
/// the tree footer's is (#849) — so at the dock's narrowest the first ones
/// are the ones cut off at the left: the outline above all, which is the
/// pane a fresh dock opens on. A mouse reaches them: the wheel over the
/// strip scrolls it sideways, and the row drags under a held left button as
/// a finger drags it on a tablet. The panes do not all fit the narrowest
/// dock (200 px) at a thumb's sizes, and a tab a thumb cannot hit is worse
/// than a strip that scrolls.
final class _PaneTabs extends StatefulWidget {
  const new({required this.pane, required this.panes, required this.onPane});

  /// The pane showing, drawn as the selected tab.
  final DockPane pane;

  /// The panes there are tabs for, in order.
  final List<DockPane> panes;

  /// Shows another pane.
  final ValueChanged<DockPane> onPane;

  @override
  State<_PaneTabs> createState() => _PaneTabsState();
}

final class _PaneTabsState extends State<_PaneTabs> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// A plain vertical wheel over the strip, turned into a horizontal
  /// scroll (#1000).
  ///
  /// Claimed through the pointer-signal resolver, which gives the event to
  /// the first that asks, as `TextZoomPinch` does: the strip's own
  /// Scrollable lies deeper and asks first whenever the delta it would take
  /// is not zero — a tilt wheel, a trackpad's own pan, or `Shift`'s flip —
  /// so only the plain wheel is left to this one. The delta follows the
  /// strip's axis direction, which is the direction `Shift`+wheel already
  /// gives it.
  void _signal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || event.scrollDelta.dx != 0) return;
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final delta = axisDirectionIsReversed(position.axisDirection)
        ? -event.scrollDelta.dy
        : event.scrollDelta.dy;
    if (delta == 0) return;
    // A strip that fits keeps Flutter to itself: nothing is asked for when
    // there is nowhere to scroll.
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target == position.pixels) return;
    GestureBinding.instance.pointerSignalResolver.register(
      event,
      // The resolver runs after the event is dispatched: the strip may have
      // lost its position by then (#1025), so it is read again.
      (_) {
        if (_scroll.hasClients) _scroll.position.pointerScroll(delta);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final behavior = ScrollConfiguration.of(context);
    return ScrollConfiguration(
      // A mouse drags the strip as a finger does (#1000): Flutter's own
      // devices — touch, stylus, trackpad — are kept.
      behavior: behavior.copyWith(
        dragDevices: {...behavior.dragDevices, PointerDeviceKind.mouse},
      ),
      child: Listener(
        // The gaps between the tabs are the strip's too.
        behavior: HitTestBehavior.translucent,
        onPointerSignal: _signal,
        child: SingleChildScrollView(
          key: const Key('dock-pane-strip'),
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final each in widget.panes)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: IconButton(
                    key: Key('dock-pane-${each.name}'),
                    tooltip: RightDock._label(each),
                    isSelected: each == widget.pane,
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    style: IconButton.styleFrom(
                      backgroundColor: each == widget.pane
                          ? scheme.surfaceContainerHighest
                          : null,
                    ),
                    icon: Icon(
                      RightDock._icon(each, selected: each == widget.pane),
                    ),
                    onPressed: () => widget.onPane(each),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
