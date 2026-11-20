import 'package:flutter/material.dart';
import 'package:niman/src/links/mention_reader.dart';
import 'package:niman/src/ui/links_to_note_controller.dart';
import 'package:niman/src/ui/note_tasks_host.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/workspace/workspace.dart';

/// The wide layout's two counters in the note's status row (#1296): how many
/// notes link here (#842) and how many open tasks do (#1152), each with the
/// icon of its pane in the side panel. A tap opens that pane, through the
/// same call the note's ⋮ menu makes.
///
/// They stand in their place whenever the note is in a library (the tasks one
/// only while the Todo feature is on), whatever the counts say and whether
/// or not the panel is open already: a control that comes and goes with a
/// number would move the row under a pointer on it. A zero is muted a little
/// more than the rest; the links number appears once the index has answered,
/// with a `+` when there are more than the first page holds.
final class NoteRelatedCounters extends StatefulWidget {
  /// The counters of the note at library-relative [path]; [onShow] opens
  /// [DockPane.links] or [DockPane.tasks].
  const new({
    required this.linkSource,
    required this.path,
    required this.tasks,
    required this.onShow,
    super.key,
  });

  /// Where the notes that link the note are read from, or null while no
  /// library is open: no links counter then.
  final MentionSource? linkSource;

  /// The note's library-relative path, or null for a note outside a library:
  /// no counters then.
  final String? path;

  /// The tasks, or null while the Todo feature is off: no tasks counter then.
  final NoteTasksHost? tasks;

  /// Asks for the pane of the counter that was tapped.
  final ValueChanged<DockPane> onShow;

  @override
  State<NoteRelatedCounters> createState() => _NoteRelatedCountersState();
}

final class _NoteRelatedCountersState extends State<NoteRelatedCounters> {
  final LinksToNoteController _links = LinksToNoteController();

  @override
  void initState() {
    super.initState();
    _target();
  }

  @override
  void didUpdateWidget(NoteRelatedCounters oldWidget) {
    super.didUpdateWidget(oldWidget);
    _target();
  }

  // Asks again only when the source or the note changed.
  void _target() => _links.target(
    widget.path == null ? null : widget.linkSource,
    widget.path,
  );

  @override
  void dispose() {
    _links.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.path;
    if (path == null) return const SizedBox.shrink();
    final tasks = widget.tasks;
    final links = widget.linkSource;
    if (links == null && tasks == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (links != null)
          ListenableBuilder(
            listenable: _links,
            builder: (context, _) => _Counter(
              tooltip: AppStrings.linksToNoteTitle,
              icon: Icons.link_outlined,
              countKey: const Key('links-to-note-count'),
              count: _links.referrers == null
                  ? null
                  : '${_links.count}${_links.truncated ? '+' : ''}',
              zero: _links.count == 0,
              onTap: () => widget.onShow(DockPane.links),
            ),
          ),
        if (tasks != null)
          ListenableBuilder(
            listenable: tasks.map,
            builder: (context, _) {
              final open = tasks.map.tasksFor(path).open.length;
              return _Counter(
                tooltip: AppStrings.tasksForNoteTitle,
                icon: Icons.check_box_outlined,
                countKey: const Key('tasks-for-note-count'),
                count: '$open',
                zero: open == 0,
                onTap: () => widget.onShow(DockPane.tasks),
              );
            },
          ),
        const SizedBox(width: 6),
      ],
    );
  }
}

/// One counter: an outline [icon] and, once known, its [count].
final class _Counter extends StatelessWidget {
  const new({
    required this.tooltip,
    required this.icon,
    required this.countKey,
    required this.count,
    required this.zero,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final Key countKey;

  /// The number to show, or null while it is not known.
  final String? count;

  /// Whether the count is nothing: muted a little more.
  final bool zero;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = zero
        ? scheme.onSurfaceVariant.withValues(alpha: 0.6)
        : scheme.onSurfaceVariant;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              if (count != null) ...[
                const SizedBox(width: 4),
                Text(
                  count!,
                  key: countKey,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
