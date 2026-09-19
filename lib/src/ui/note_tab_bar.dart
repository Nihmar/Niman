/// The open notes as tabs, in the title bar (issue #23).
///
/// Each tab is the note's name (without `.md`, as the tree reads it), a
/// close button, and — while the note holds edits the disk has not got
/// yet — a dot where the close button sits, which gives way to it under
/// the pointer. A middle click closes, as in every tabbed app. Past the
/// tabs: `+` for a new note in a new tab, and ▾ listing every tab, for
/// the row that no longer fits.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/tab_drag.dart';
import 'package:niman/src/workspace/workspace.dart';
import 'package:niman/src/workspace/workspace_tab.dart';
import 'package:path/path.dart' as p;

/// A tab's label: the note's name, `.md` dropped like the tree drops it.
String noteTabLabel(String path) {
  final name = p.posix.basename(path);
  return isMarkdownNote(name) ? name.substring(0, name.length - 3) : name;
}

/// The row of tabs.
final class NoteTabBar extends StatefulWidget {
  /// Creates the row for [tabs], [active] showing.
  const new({
    required this.tabs,
    required this.active,
    required this.unsaved,
    required this.onActivate,
    required this.onClose,
    required this.onNew,
    this.filler = const SizedBox.shrink(),
    this.focused = true,
    this.onSplit,
    this.onMoveToOtherPane,
    this.pane = 0,
    this.onDrop,
    super.key,
  });

  /// Which pane's row this is (#204): what a dragged tab carries.
  final int pane;

  /// A tab dropped in this row, at a place in it — this row's own tab
  /// dragged along it, or the other pane's moved here. Null leaves the
  /// row undraggable.
  final void Function(TabDrag drag, int at)? onDrop;

  /// Whether this row's pane has the focus: its showing tab is marked
  /// in the accent, the other pane's only outlined (#23).
  final bool focused;

  /// Splits the window with the tab at the index; null once it is split.
  final void Function(int index, SplitAxis axis)? onSplit;

  /// Moves the tab at the index to the other pane; null while unsplit.
  final ValueChanged<int>? onMoveToOtherPane;

  /// What fills the row past the tabs and their buttons: in the title
  /// bar, the area the window is dragged by.
  final Widget filler;

  /// The least of [filler] the tabs leave free, however many there are.
  static const double minFiller = 48;

  /// The tabs, left to right.
  final List<WorkspaceTab> tabs;

  /// The index of the tab showing; -1 for none.
  final int active;

  /// The library-relative paths holding unsaved edits.
  final Set<String> unsaved;

  /// Shows the tab at the index.
  final ValueChanged<int> onActivate;

  /// Closes the tab at the index.
  final ValueChanged<int> onClose;

  /// Makes a new note, in a new tab.
  final VoidCallback onNew;

  @override
  State<NoteTabBar> createState() => _NoteTabBarState();
}

final class _NoteTabBarState extends State<NoteTabBar> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _activeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _revealActive();
  }

  @override
  void didUpdateWidget(NoteTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active ||
        oldWidget.tabs.length != widget.tabs.length) {
      _revealActive();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Keeps the showing tab in view when the row scrolls.
  void _revealActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _activeKey.currentContext;
      if (context == null || !mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 150),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  /// A tab that can be dragged (#204), and taken as a drop's place: the
  /// left half of a tab is before it, the right half after it.
  Widget _draggable({
    required int index,
    required WorkspaceTab tab,
    required Widget child,
  }) {
    final onDrop = widget.onDrop;
    if (onDrop == null) return child;
    final label = noteTabLabel(tab.path);
    return Draggable<TabDrag>(
      // The pointer, not the tab's own corner: the chip follows the hand.
      dragAnchorStrategy: pointerDragAnchorStrategy,
      data: TabDrag(pane: widget.pane, index: index, label: label),
      feedback: TabDragFeedback(label),
      childWhenDragging: Opacity(opacity: 0.4, child: child),
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: Row(
              children: [
                Expanded(child: _dropSlot(index, marker: _Marker.before)),
                Expanded(child: _dropSlot(index + 1, marker: _Marker.after)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A place in the row a tab can be dropped at, drawn as a line while
  /// the drop is over it.
  Widget _dropSlot(int at, {double? width, _Marker? marker}) {
    final onDrop = widget.onDrop;
    if (onDrop == null) return SizedBox(width: width ?? 0);
    return DragTarget<TabDrag>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => onDrop(details.data, at),
      builder: (context, candidate, _) {
        final over = candidate.isNotEmpty;
        final line = ColoredBox(
          color: Theme.of(context).colorScheme.primary,
          child: const SizedBox(width: 2, height: double.infinity),
        );
        return SizedBox(
          width: width,
          height: double.infinity,
          child: !over
              ? const SizedBox.shrink()
              : Align(
                  alignment: switch (marker) {
                    _Marker.before => Alignment.centerLeft,
                    _Marker.after => Alignment.centerRight,
                    null => Alignment.centerLeft,
                  },
                  child: line,
                ),
        );
      },
    );
  }

  Future<void> _showList(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final at = box.localToGlobal(Offset(0, box.size.height));
    final chosen = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx + 1, at.dy + 1),
      items: [
        for (final (i, tab) in widget.tabs.indexed)
          PopupMenuItem<int>(
            key: Key('tab-list-$i'),
            value: i,
            child: _TabListRow(
              tab: tab,
              active: i == widget.active,
              unsaved: widget.unsaved.contains(tab.path),
            ),
          ),
      ],
    );
    if (chosen != null) widget.onActivate(chosen);
  }

  /// The tab's right-click menu: the ways to split with it, to move it,
  /// and to close it.
  Future<void> _showTabMenu(
    BuildContext context,
    int index,
    Offset position,
  ) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final split = widget.onSplit;
    final move = widget.onMoveToOtherPane;
    final chosen = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        if (split != null) ...[
          PopupMenuItem(
            key: const Key('tab-menu-split-right'),
            value: 'right',
            child: Text(AppStrings.splitRight),
          ),
          PopupMenuItem(
            key: const Key('tab-menu-split-down'),
            value: 'down',
            child: Text(AppStrings.splitDown),
          ),
        ],
        if (move != null)
          PopupMenuItem(
            key: const Key('tab-menu-move'),
            value: 'move',
            child: Text(AppStrings.moveToOtherPane),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          key: const Key('tab-menu-close'),
          value: 'close',
          child: Text(AppStrings.closeTabTooltip),
        ),
      ],
    );
    switch (chosen) {
      case 'right':
        split?.call(index, SplitAxis.right);
      case 'down':
        split?.call(index, SplitAxis.down);
      case 'move':
        move?.call(index);
      case 'close':
        widget.onClose(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.tabs;
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = (constraints.maxWidth - 2 * 40 - NoteTabBar.minFiller)
            .clamp(0.0, double.infinity);
        // Short of room, the tabs shrink first — their names cut with an
        // ellipsis — and only below the narrowest does the row scroll.
        // Scrolling a wide tab into a narrow pane showed its end and cut
        // its name at the start (0.0.8 test round).
        final tabWidth = tabs.isEmpty
            ? _NoteTab.widest
            : (room / tabs.length).clamp(_NoteTab.narrowest, _NoteTab.widest);
        return Row(
          key: const Key('note-tab-bar'),
          children: [
            // As wide as the tabs need, up to what leaves the buttons and
            // some of the filler: past that the row scrolls.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: room),
              child: SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, tab) in tabs.indexed)
                      _draggable(
                        index: i,
                        tab: tab,
                        child: _NoteTab(
                          key: i == widget.active
                              ? _activeKey
                              : ValueKey(tab.path),
                          tab: tab,
                          index: i,
                          active: i == widget.active,
                          focused: widget.focused,
                          unsaved: widget.unsaved.contains(tab.path),
                          onActivate: () => widget.onActivate(i),
                          onClose: () => widget.onClose(i),
                          onMenu: (position) =>
                              unawaited(_showTabMenu(context, i, position)),
                          maxWidth: tabWidth,
                        ),
                      ),
                    // Past the last tab: a drop here puts the tab at the
                    // end of the row, and an empty pane's row is all this.
                    _dropSlot(tabs.length, width: 40),
                  ],
                ),
              ),
            ),
            IconButton(
              key: const Key('tab-new'),
              tooltip: AppStrings.newNoteTabTooltip,
              icon: const Icon(Icons.add, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: widget.onNew,
            ),
            if (tabs.isNotEmpty)
              Builder(
                builder: (context) => IconButton(
                  key: const Key('tab-list'),
                  tooltip: AppStrings.openNotesTooltip,
                  icon: const Icon(Icons.expand_more, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => unawaited(_showList(context)),
                ),
              ),
            Expanded(child: widget.filler),
          ],
        );
      },
    );
  }
}

/// One tab.
final class _NoteTab extends StatefulWidget {
  const new({
    required this.tab,
    required this.index,
    required this.active,
    required this.focused,
    required this.unsaved,
    required this.onActivate,
    required this.onClose,
    required this.onMenu,
    this.maxWidth = _NoteTab.widest,
    super.key,
  });

  /// A tab's width when there is room for it.
  static const double widest = 190;

  /// The narrowest a tab gets before the row scrolls instead: its close
  /// button and a few letters of its name.
  static const double narrowest = 72;

  /// How wide this tab may be: less than [widest] when the row is short
  /// of room, so the tabs shrink before they scroll.
  final double maxWidth;

  final WorkspaceTab tab;
  final int index;
  final bool active;
  final bool focused;
  final bool unsaved;
  final VoidCallback onActivate;
  final VoidCallback onClose;
  final ValueChanged<Offset> onMenu;

  @override
  State<_NoteTab> createState() => _NoteTabState();
}

final class _NoteTabState extends State<_NoteTab> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = widget.active;
    final missing = widget.tab.missing;
    // The dot says "not saved yet"; under the pointer the close takes its
    // place, the way the hand expects to find it.
    final showDot = widget.unsaved && !_hover;
    final showClose = !showDot && (active || _hover);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: widget.tab.path,
        waitDuration: const Duration(milliseconds: 600),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: Listener(
            // A middle click closes, as everywhere else tabs exist.
            onPointerDown: (event) {
              if (event.buttons == kMiddleMouseButton) widget.onClose();
              if (event.buttons == kSecondaryMouseButton) {
                widget.onMenu(event.position);
              }
            },
            child: Material(
              key: Key('note-tab-${widget.index}'),
              color: active
                  ? scheme.surface
                  : _hover
                  ? scheme.surfaceContainerHighest
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
                side: active
                    ? BorderSide(
                        color: widget.focused
                            ? scheme.primary
                            : scheme.outlineVariant,
                      )
                    : BorderSide.none,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(7),
                onTap: widget.onActivate,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: math.min(90, widget.maxWidth),
                    maxWidth: widget.maxWidth,
                  ),
                  child: SizedBox(
                    height: 30,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        12,
                        0,
                        6,
                        0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              noteTabLabel(widget.tab.path),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: active
                                    ? scheme.onSurface
                                    : scheme.onSurfaceVariant,
                                decoration: missing
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox.square(
                            dimension: 20,
                            child: showDot
                                ? Center(
                                    child: Container(
                                      key: Key('note-tab-dot-${widget.index}'),
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: scheme.tertiary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : showClose
                                ? IconButton(
                                    key: Key('note-tab-close-${widget.index}'),
                                    tooltip: AppStrings.closeTabTooltip,
                                    padding: EdgeInsets.zero,
                                    iconSize: 14,
                                    icon: const Icon(Icons.close),
                                    onPressed: widget.onClose,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of the ▾ list: the note's name and its folder, marked when it
/// is the one showing, dotted while unsaved.
final class _TabListRow extends StatelessWidget {
  const new({required this.tab, required this.active, required this.unsaved});

  final WorkspaceTab tab;
  final bool active;
  final bool unsaved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folder = p.posix.dirname(tab.path);
    return Row(
      children: [
        Icon(
          active ? Icons.description : Icons.description_outlined,
          size: 18,
          color: active ? theme.colorScheme.primary : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(noteTabLabel(tab.path), overflow: TextOverflow.ellipsis),
              if (folder != '.')
                Text(
                  folder,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (unsaved) ...[
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}

/// Which side of a tab a drop's line is drawn on.
enum _Marker {
  /// Before the tab: its left edge.
  before,

  /// After it: its right edge.
  after,
}
