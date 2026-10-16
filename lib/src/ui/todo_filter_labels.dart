/// The words of the todo list's controls, defined once: the Filter sheet,
/// the Sort menu, the toolbar's Sort pill and the filter strip's chips all
/// name a sort key or a due range, and must read alike.
library;

import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/ui/strings.dart';

/// The name of the sort key [sort].
String todoSortLabel(TodoSort sort) {
  return switch (sort) {
    TodoSort.due => AppStrings.todoSortDue,
    TodoSort.priority => AppStrings.todoSortPriority,
    TodoSort.creation => AppStrings.todoSortCreation,
  };
}

/// The name of the due range [range].
String todoDueRangeLabel(TodoDueRange range) {
  return switch (range) {
    TodoDueRange.all => AppStrings.todoAllDates,
    TodoDueRange.overdue => AppStrings.todoDueOverdue,
    TodoDueRange.today => AppStrings.todoDueToday,
    TodoDueRange.next7 => AppStrings.todoDueNext7,
    TodoDueRange.noDate => AppStrings.todoDueNoDate,
  };
}
