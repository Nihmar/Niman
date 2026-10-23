/// The links of every task in a snapshot, parsed and not yet resolved
/// (#1152).
library;

import 'package:niman/src/links/link_query.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/todo/task_link.dart';
import 'package:niman/src/todo/todo_store.dart';

/// A link of a task and the question it asks the resolver.
typedef ReadLink = ({ParsedLink link, LinkQuery query});

/// The links of the tasks of a snapshot, as the resolver is to be asked.
///
/// A task's links are a function of its description alone — both files sit
/// at the library root, so a `..` walks the same way from either — so they
/// are read once for each distinct description, and a description that
/// stays between two snapshots is not read again. Only a link that can name
/// a note is kept ([linkQueryOf]).
final class TaskLinkReads {
  /// Reads the descriptions of [snapshot]; [previous], the reads of the
  /// snapshot before it, lends the ones it has.
  factory(TodoSnapshot snapshot, {TaskLinkReads? previous}) {
    final byDescription = <String, List<ReadLink>>{};
    final queries = <LinkQuery>{};
    for (final file in TaskFile.values) {
      final entries = file == TaskFile.todo ? snapshot.todo : snapshot.done;
      for (final entry in entries) {
        final description = entry.task.description;
        if (byDescription.containsKey(description)) continue;
        final links =
            previous?.byDescription[description] ??
            _read(description, file.path);
        if (links.isEmpty) continue;
        byDescription[description] = links;
        for (final read in links) {
          queries.add(read.query);
        }
      }
    }
    return TaskLinkReads._(snapshot, byDescription, queries);
  }

  const new _(this.snapshot, this.byDescription, this.queries);

  /// The snapshot these were read from.
  final TodoSnapshot snapshot;

  /// The links of each description that has any, in the order they are
  /// written (embeds included).
  final Map<String, List<ReadLink>> byDescription;

  /// Every distinct question to put to the resolver, in one batch.
  final Set<LinkQuery> queries;

  /// Whether no task has a link.
  bool get isEmpty => queries.isEmpty;

  static List<ReadLink> _read(String description, String from) {
    // A link needs a bracket: most tasks have none, and are not parsed.
    if (!description.contains('[')) return const <ReadLink>[];
    return <ReadLink>[
      for (final link in parseLinks(description, includeEmbeds: true))
        if (linkQueryOf(link, from) case final query?)
          (link: link, query: query),
    ];
  }
}
