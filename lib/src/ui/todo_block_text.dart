/// The words of a `todo` block (#1152): what its head says it lists, and what
/// each problem in it says. The screen and the export read the same ones.
library;

import 'package:niman/src/todo/todo_block_due.dart';
import 'package:niman/src/todo/todo_block_error.dart';
import 'package:niman/src/todo/todo_block_query.dart';
import 'package:niman/src/ui/strings.dart';

/// What [query] asks for, in pieces for the head: `linked here`,
/// `project house`, `due within 7 days`, and so on, in the order the lines
/// are written in the block's syntax. `link: any` and the defaults say
/// nothing.
List<String> todoBlockSummary(TodoBlockQuery query) {
  final due = query.due;
  final from = query.priorityFrom;
  return <String>[
    switch (query.link) {
      LinkThis() => AppStrings.todoBlockLinkedHere,
      LinkNote(:final target) => AppStrings.todoBlockLinkedTo(target),
      LinkAny() => '',
    },
    for (final name in query.projects) AppStrings.todoBlockProject(name),
    for (final name in query.contexts) AppStrings.todoBlockContext(name),
    for (final name in query.tags) AppStrings.todoBlockTag(name),
    if (due != null) _dueText(due),
    if (from != null)
      AppStrings.todoBlockPriority(
        from == query.priorityTo ? from : '$from-${query.priorityTo}',
      ),
    switch (query.done) {
      TodoBlockDone.no => '',
      TodoBlockDone.yes => AppStrings.todoBlockDoneOnly,
      TodoBlockDone.all => AppStrings.todoBlockOpenAndDone,
    },
    switch (query.sort) {
      TodoBlockSort.due => '',
      TodoBlockSort.priority => AppStrings.todoBlockSortPriority,
      TodoBlockSort.file => AppStrings.todoBlockSortFile,
    },
  ].where((piece) => piece.isNotEmpty).toList();
}

/// The head of a block: `Tasks · project house · due within 7 days`, and its
/// [count] after a last dot when it has one.
String todoBlockHead(TodoBlockQuery query, {int? count}) => <String>[
  AppStrings.todoBlockTitle,
  ...todoBlockSummary(query),
  if (count != null) '$count',
].join(' · ');

String _dueText(TodoBlockDue due) => switch (due) {
  DueToday() => AppStrings.todoBlockDueToday,
  DueOverdue() => AppStrings.todoBlockDueOverdue,
  DueWithin(:final days) => AppStrings.todoBlockDueWithin(days),
  DueOn(:final day) => AppStrings.todoBlockDueOn(_iso(day)),
  DueBetween(:final from, :final to) => AppStrings.todoBlockDueBetween(
    _iso(from),
    _iso(to),
  ),
};

String _iso(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// What [error] says.
String todoBlockErrorText(TodoBlockError error) => switch (error.kind) {
  TodoBlockErrorKind.noColon => AppStrings.todoBlockNoColon,
  TodoBlockErrorKind.unknownKey =>
    error.suggestion == null
        ? AppStrings.todoBlockUnknownKey(error.key)
        : AppStrings.todoBlockUnknownKeySuggest(error.key, error.suggestion!),
  TodoBlockErrorKind.missingValue => AppStrings.todoBlockMissingValue(
    error.key,
  ),
  TodoBlockErrorKind.badValue => AppStrings.todoBlockBadValue(
    error.key,
    error.value,
    error.expected,
  ),
  TodoBlockErrorKind.repeatedKey => AppStrings.todoBlockRepeatedKey(error.key),
};
