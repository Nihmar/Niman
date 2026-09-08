/// The reminder model: what a `rem:` tag becomes before anything
/// platform-specific touches it (plan/todo-tab.md T-TD-07).
///
/// Pure and dependency-free on purpose. The scheduling half lives in
/// `reminders.dart` and the plugin half in `reminder_backend_plugin.dart`;
/// keeping the model apart is what lets both be tested without a device.
library;

import 'package:copist/src/todo/parser.dart';
import 'package:copist/src/todo/todo_store.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:meta/meta.dart';

/// The notification payload routing taps to the Todo tab.
const String todoReminderPayload = 'todo';

/// The Android channel every reminder posts on.
///
/// Stable for the life of the install: Android keys a channel by id and
/// freezes its importance at creation, so a new id would strand the
/// user's per-channel settings on the old one.
const String todoReminderChannelId = 'copist_reminders';

/// The status-bar icon for reminders: a BARE drawable resource name.
///
/// Android masks a small icon to its alpha channel and tints the result,
/// so it has to be a flat silhouette; the launcher icon is fully opaque
/// and came out as a plain white square.
///
/// The plugin resolves this with `getIdentifier(name, "drawable", pkg)`,
/// so it must be the bare entry name. An `@drawable/…` or `@mipmap/…`
/// string does not resolve — it throws `invalid_icon` out of
/// `initialize`, which took the whole reminder system down with it.
///
/// Shipped as density PNGs (`tool/make_reminder_icon.py`), not as a
/// vector: a `VectorDrawable` under `res/drawable/` never reached the
/// resource table on the build machine, even from a clean build, while
/// the density-qualified buckets resolve.
const String todoReminderIcon = 'ic_stat_reminder';

/// One schedulable reminder: a stable [id] with content + fire time.
@immutable
final class TodoReminder {
  /// Creates a reminder firing at [when] (local wall-clock time).
  const TodoReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
  });

  /// The notification id, derived from the task text ([todoReminderId]).
  final int id;

  /// The task description.
  final String title;

  /// The due line, or the generic reminder text.
  final String body;

  /// When to fire (local wall-clock time, from `rem:`).
  final DateTime when;
}

/// A stable notification id for a task description.
///
/// FNV-1a over the UTF-16 units, masked to a positive 31-bit int:
/// identical descriptions share one notification (documented: exact
/// duplicate tasks collapse to a single alarm), a description edit
/// yields a new id while reconciliation cancels the orphan, and line
/// moves between the files keep the id (only the description feeds
/// it — never the `x`/date prefix or the line index).
int todoReminderId(String description) {
  var hash = 0x811C9DC5;
  for (final unit in description.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}

/// The schedulable reminders of [snapshot]: open (`todo.txt`) tasks
/// with a `rem:` after [now]. Completed tasks (archived, or still `x`
/// in `todo.txt` awaiting migration) and past times never fire. [now]
/// is the wall clock (the controller's injected clock in tests, real
/// time on device).
Map<int, TodoReminder> wantedReminders(
  TodoSnapshot snapshot,
  DateTime now, {
  bool showTokens = false,
}) {
  final wanted = <int, TodoReminder>{};
  for (final entry in snapshot.todo) {
    final task = entry.task;
    // `todo.txt` is not guaranteed migrated: only a reload archives stray
    // `x` lines, so an edit that completes a task in place publishes it
    // here first. A completed task never fires.
    if (task.completed) {
      continue;
    }
    final when = task.reminder;
    if (when == null || !when.isAfter(now)) {
      continue;
    }
    // The id stays over the full text (stable identity), but the shown
    // title never carries the managed due:/rem: tags. The
    // +project/@context/#tag markers are the user's call ([showTokens]):
    // off by default, because on a lock screen they are syntax with
    // nothing to explain them, but someone who files by project reads
    // them as part of the task. A line written elsewhere can be nothing
    // but tokens, which would leave a titleless notification.
    final title = showTokens
        ? withoutKeyValueTags(task.description)
        : taskDisplayText(task.description);
    wanted[todoReminderId(task.description)] = TodoReminder(
      id: todoReminderId(task.description),
      title: title.isEmpty ? AppStrings.todoReminderFallbackTitle : title,
      body: task.due == null
          ? AppStrings.todoReminderBody
          : '${AppStrings.todoReminderDue} ${formatTodoDate(task.due!)}',
      when: when,
    );
  }
  return wanted;
}
