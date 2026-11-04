import 'package:flutter/material.dart';
import 'package:niman/src/search/task_events.dart';
import 'package:niman/src/ui/search_field_pager.dart';
import 'package:niman/src/ui/search_task_events.dart';
import 'package:niman/src/ui/strings.dart';

/// How many rows the Tasks and events group takes in the results before
/// the notes (#730): its heading, its own [groupRows], and the Notes
/// heading when both sections show ([hasNotes]).
int searchGroupLead(int groupRows, {required bool hasNotes}) =>
    groupRows == 0 ? 0 : 1 + groupRows + (hasNotes ? 1 : 0);

/// The results of a search that ran: the Tasks and events group above
/// the notes, the notes shown so far, and the Show more row — or the
/// empty state when nothing matched.
final class SearchResultsList extends StatelessWidget {
  /// Creates the list of [shown] of [hitCount] note hits under [group].
  const new({
    required this.group,
    required this.hitCount,
    required this.shown,
    required this.hasMore,
    required this.pager,
    required this.scanning,
    required this.scroll,
    required this.eventTimesClock,
    required this.onOpenTaskEvent,
    required this.onLoadMore,
    required this.hitRow,
    super.key,
  });

  /// The Tasks and events rows the query answers with.
  final List<TaskEventHit> group;

  /// How many note hits are held.
  final int hitCount;

  /// How many of them are listed.
  final int shown;

  /// Whether the list ends in its Show more row.
  final bool hasMore;

  /// The pages of the `key = value` filter the hits came from, or null
  /// for a text search.
  final FieldPager? pager;

  /// Whether a contains scan is still running (#1038).
  final bool scanning;

  /// The list's scroll.
  final ScrollController scroll;

  /// Whether an event's time is read as a clock rather than as written.
  final bool eventTimesClock;

  /// Opens a row of the group; null leaves the rows inert.
  final void Function(TaskEventHit hit)? onOpenTaskEvent;

  /// Lists the next page.
  final VoidCallback onLoadMore;

  /// Builds the row of the note hit at an index.
  final Widget Function(int at) hitRow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // No match is only known once the scan is done (#1038).
    if (hitCount == 0 && group.isEmpty && scanning) {
      return const SizedBox.shrink();
    }
    if (hitCount == 0 && group.isEmpty) {
      return Center(
        child: Text(
          AppStrings.searchNoMatches,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final lead = searchGroupLead(group.length, hasNotes: hitCount > 0);
    final onOpenTaskEvent = this.onOpenTaskEvent;
    return ListView.builder(
      key: const Key('search-results'),
      controller: scroll,
      itemCount: lead + shown + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < lead) {
          if (index == 0) {
            return searchSectionHeader(
              context,
              AppStrings.searchTasksAndEvents(group.length),
              key: const Key('search-group-tasks-events'),
            );
          }
          if (index <= group.length) {
            final hit = group[index - 1];
            return searchTaskEventRow(
              context,
              hit,
              today: DateTime.now(),
              asClock: eventTimesClock,
              onTap: onOpenTaskEvent == null
                  ? null
                  : () => onOpenTaskEvent(hit),
            );
          }
          return searchSectionHeader(
            context,
            AppStrings.searchNotes(hitCount),
            key: const Key('search-group-notes'),
          );
        }
        final at = index - lead;
        if (at >= shown) {
          return ListTile(
            key: const Key('search-load-more'),
            leading: const Icon(Icons.expand_more),
            title: Text(AppStrings.searchLoadMore),
            // A filter that holds more notes than it lists says how many.
            subtitle: switch (pager) {
              final pager? when pager.hasMore || shown >= hitCount => Text(
                AppStrings.searchShowingFirst(hitCount, pager.total),
              ),
              _ => null,
            },
            onTap: onLoadMore,
          );
        }
        return hitRow(at);
      },
    );
  }
}
