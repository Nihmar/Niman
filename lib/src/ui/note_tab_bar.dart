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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/ui/strings.dart';
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
    super.key,
  });

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

  @override
  Widget build(BuildContext context) {
    final tabs = widget.tabs;
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        key: const Key('note-tab-bar'),
        children: [
          // As wide as the tabs need, up to what leaves the buttons and
          // some of the filler: past that the row scrolls.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: (constraints.maxWidth - 2 * 40 - NoteTabBar.minFiller)
                  .clamp(0, double.infinity),
            ),
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, tab) in tabs.indexed)
                    _NoteTab(
                      key: i == widget.active ? _activeKey : ValueKey(tab.path),
                      tab: tab,
                      index: i,
                      active: i == widget.active,
                      unsaved: widget.unsaved.contains(tab.path),
                      onActivate: () => widget.onActivate(i),
                      onClose: () => widget.onClose(i),
                    ),
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
      ),
    );
  }
}

/// One tab.
final class _NoteTab extends StatefulWidget {
  const new({
    required this.tab,
    required this.index,
    required this.active,
    required this.unsaved,
    required this.onActivate,
    required this.onClose,
    super.key,
  });

  final WorkspaceTab tab;
  final int index;
  final bool active;
  final bool unsaved;
  final VoidCallback onActivate;
  final VoidCallback onClose;

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
                    ? BorderSide(color: scheme.outlineVariant)
                    : BorderSide.none,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(7),
                onTap: widget.onActivate,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 90,
                    maxWidth: 190,
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
