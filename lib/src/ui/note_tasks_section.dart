import 'package:flutter/material.dart';
import 'package:niman/src/ui/note_tasks_host.dart';
import 'package:niman/src/ui/note_tasks_list.dart';
import 'package:niman/src/ui/strings.dart';

/// The note view's own "Tasks for this note" (#1152): a header under the
/// note, below "Links to this note", that opens onto the tasks that link it,
/// collapsed to a count until it is asked for.
///
/// The header is always there while a library is open and the Todo feature is
/// on, so it never appears under a thumb that was already on the row below;
/// with no task linking in it opens onto the words that say so, and Add task.
/// The count is the open tasks; Done is in the list. The dock's pane and the
/// phone's sheet list the same tasks.
final class NoteTasksSection extends StatefulWidget {
  /// The tasks of [host] that link the note at library-relative [path].
  const new({required this.host, required this.path, super.key});

  /// The tasks, or null while the Todo feature is off: no header then.
  final NoteTasksHost? host;

  /// The note's library-relative path, or null for a note outside a library.
  final String? path;

  /// How tall the opened list is at most: a few rows, scrolled for the rest.
  static const double maxListHeight = 220;

  @override
  State<NoteTasksSection> createState() => _NoteTasksSectionState();
}

final class _NoteTasksSectionState extends State<NoteTasksSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final host = widget.host;
    final path = widget.path;
    if (host == null || path == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      key: const Key('tasks-for-note-section'),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const Key('tasks-for-note-header'),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _open ? Icons.expand_more : Icons.chevron_right,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.tasksForNoteTitle,
                    style: theme.textTheme.labelLarge,
                  ),
                  const Spacer(),
                  ListenableBuilder(
                    listenable: host.map,
                    builder: (context, _) => Text(
                      '${host.map.tasksFor(path).open.length}',
                      key: const Key('tasks-for-note-count'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: NoteTasksSection.maxListHeight,
              ),
              child: NoteTasksList(host: host, path: path, shrinkWrap: true),
            ),
        ],
      ),
    );
  }
}
