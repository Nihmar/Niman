/// The tasks' links, resolved, and the questions asked of them (#1152).
library;

import 'package:niman/src/links/moved_links.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/task_link.dart';
import 'package:niman/src/todo/task_link_hits.dart';
import 'package:niman/src/todo/task_link_reads.dart';
import 'package:niman/src/todo/todo_store.dart';

/// A task that links a note: where it is, and whether the link is one a
/// reader sees (a task that only embeds the note is carried by a move, but
/// is not one of the note's tasks).
typedef _Placed = ({TaskFile file, TodoEntry entry, bool shown});

/// The links of `todo.txt` and `done.txt`, resolved against the index as of
/// one moment: immutable, and answering from memory.
///
/// Built by [TaskLinkIndex.of] from [TaskLinkReads] and the resolver's
/// answers; the `TaskLinkMap` publishes a new one whenever the tasks or the
/// index change. Asking costs a hash lookup, never a pass over the tasks.
final class TaskLinkIndex {
  const new _(this._all, this._shown, this._byNote, this.linkCount);

  /// Pairs each read link of [reads] with its answer in [resolved]. A link
  /// the resolver did not answer is dead.
  factory of(TaskLinkReads reads, Map<LinkQuery, ResolveResult> resolved) {
    final all = <String, List<TaskLink>>{};
    final shown = <String, List<TaskLink>>{};
    var count = 0;
    for (final MapEntry(key: description, value: links)
        in reads.byDescription.entries) {
      final linked = <TaskLink>[
        for (final read in links)
          TaskLink(
            link: read.link,
            result:
                resolved[read.query] ??
                UnresolvedNote(target: read.query.target),
          ),
      ];
      all[description] = linked;
      final visible = <TaskLink>[
        for (final link in linked)
          if (!link.embed) link,
      ];
      if (visible.isNotEmpty) {
        shown[description] = visible.length == linked.length ? linked : visible;
        count += visible.length;
      }
    }
    final byNote = <String, List<_Placed>>{};
    final snapshot = reads.snapshot;
    for (final file in TaskFile.values) {
      final entries = file == TaskFile.todo ? snapshot.todo : snapshot.done;
      for (final entry in entries) {
        final links = all[entry.task.description];
        if (links == null) continue;
        // One place for each note a task links, however many times.
        final seen = <String, bool>{};
        for (final link in links) {
          final path = link.notePath;
          if (path == null) continue;
          seen[path] = (seen[path] ?? false) || !link.embed;
        }
        for (final MapEntry(key: path, value: visible) in seen.entries) {
          (byNote[path] ??= <_Placed>[]).add((
            file: file,
            entry: entry,
            shown: visible,
          ));
        }
      }
    }
    return TaskLinkIndex._(all, shown, byNote, count);
  }

  /// No task has a link: what the map holds while it is inert.
  static const TaskLinkIndex empty = TaskLinkIndex._(
    <String, List<TaskLink>>{},
    <String, List<TaskLink>>{},
    <String, List<_Placed>>{},
    0,
  );

  final Map<String, List<TaskLink>> _all;
  final Map<String, List<TaskLink>> _shown;
  final Map<String, List<_Placed>> _byNote;

  /// How many links the tasks hold that a reader sees (embeds not counted).
  final int linkCount;

  /// Whether no task has a link.
  bool get isEmpty => _all.isEmpty;

  /// The links of [task], in the order they are written in its description:
  /// the ones a reader sees, embeds left out. Empty for a task with none.
  ///
  /// Told by the description alone, so an answer given for an earlier
  /// snapshot is right for any task that still has the same words.
  List<TaskLink> linksOf(TodoTask task) =>
      _shown[task.description] ?? const <TaskLink>[];

  /// The tasks that link the note at [notePath] (library-relative, as the
  /// index has it), open and done. A link to a heading or a block of the
  /// note counts; an ambiguous or dead link names no note and counts for
  /// none.
  NoteTasks tasksFor(String notePath) {
    final placed = _byNote[notePath];
    if (placed == null) return NoteTasks.none;
    final open = <TodoEntry>[];
    final done = <TodoEntry>[];
    for (final (:file, :entry, :shown) in placed) {
      if (!shown) continue;
      (file == TaskFile.todo ? open : done).add(entry);
    }
    return open.isEmpty && done.isEmpty
        ? NoteTasks.none
        : NoteTasks(open: open, done: done);
  }

  /// The tasks with a link that resolved to one of [oldPaths], the files
  /// about to move (library-relative, as the index has them): each with the
  /// links to follow, the way [MovedLinks.of] tells a note's. Embeds count,
  /// as they do in a note.
  ///
  /// Asks nothing of the resolver: the answer is the index as it was when
  /// the map was built, which a move has not touched yet.
  List<MovedTaskLinks> movedBy(Iterable<String> oldPaths) {
    final places = <TodoEntry, TaskFile>{};
    final followed = <TodoEntry, Map<(String, bool), String>>{};
    for (final old in oldPaths) {
      for (final placed in _byNote[old] ?? const <_Placed>[]) {
        places[placed.entry] = placed.file;
        final links = followed[placed.entry] ??= <(String, bool), String>{};
        for (final link in _all[placed.entry.task.description]!) {
          if (link.notePath == old) {
            links[(link.target, link.link is MarkdownLink)] = old;
          }
        }
      }
    }
    return <MovedTaskLinks>[
      for (final MapEntry(key: entry, value: links) in followed.entries)
        MovedTaskLinks(
          file: places[entry]!,
          entry: entry,
          links: MovedLinks.resolved(links),
        ),
    ]..sort((a, b) {
      final byFile = a.file.index.compareTo(b.file.index);
      return byFile != 0
          ? byFile
          : a.entry.lineIndex.compareTo(b.entry.lineIndex);
    });
  }
}
