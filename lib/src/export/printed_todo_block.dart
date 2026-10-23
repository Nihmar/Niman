/// A `todo` block as an export prints it (#1152): the list it is at the moment
/// of the export, as plain words.
library;

import 'package:meta/meta.dart';

/// One task of a printed block: whether it is done, and its words, the links
/// in them shown by their labels.
typedef PrintedTodoTask = ({bool done, String text});

/// The printed blocks of a note, by [todoBlockKey] of the block's source.
typedef PrintedTodoBlocks = Map<String, PrintedTodoBlock>;

/// What an exported page prints for a `todo` fence instead of its source: a
/// head, and the tasks (☐ open, ☑ done), or the lines that could not be read,
/// or the line that says the list is empty.
///
/// Plain strings and lists of them: it is built where the tasks are, on the
/// UI isolate, and read where the page is built, on another.
@immutable
final class PrintedTodoBlock {
  /// A block printed as [head] over its [tasks]; with [problems] it lists
  /// none, and [empty] says a block that lists none has nothing to list.
  const new({
    required this.head,
    this.tasks = const <PrintedTodoTask>[],
    this.problems = const <String>[],
    this.empty,
  });

  /// `Tasks · project house · due within 7 days · 2`.
  final String head;

  /// The tasks, open ones first.
  final List<PrintedTodoTask> tasks;

  /// What could not be read, a line each, with where in the block it is.
  final List<String> problems;

  /// What a block with nothing to list says; null when it lists or failed.
  final String? empty;
}

/// How the block whose source is [code] is found among a note's printed
/// ones: its lines trimmed and the blank ones dropped, so the fence's indent
/// (a block in a list item) and the blank lines round a line change nothing.
String todoBlockKey(String code) => <String>[
  for (final line in code.split('\n'))
    if (line.trim().isNotEmpty) line.trim(),
].join('\n');
