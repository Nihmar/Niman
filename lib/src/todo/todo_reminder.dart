/// The reminder model: what a `rem:` becomes before anything
/// platform-specific touches it (T-TD-07, the calendar since #730).
///
/// Pure and device-free on purpose. The scheduling half lives in
/// `reminders.dart` and the plugin half in `reminder_backend_plugin.dart`;
/// keeping the model apart is what lets them be tested without a device.
///
/// One set covers both files: `todo.txt`'s `rem:` is a stamp
/// (`2026-10-12T16:30`), `calendar.txt`'s is a clock time on the day its
/// line heads (`17-18 jogging @park rem:16:30.`), and both become the same
/// [TodoReminder] — ids salted apart so the two files' ids never mean each
/// other, and a payload that says which of the two a tap opens.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/templates/engine.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/task_link_label.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/strings.dart';

/// The notification payload routing taps to the Todo tab.
const String todoReminderPayload = 'todo';

/// The payload prefix routing a tap to the journal, on the day an event
/// sits on (#730).
const String journalReminderPrefix = 'journal:';

/// The payload of an event's reminder on [day]: the journal, that day.
String journalReminderPayload(DateTime day) =>
    '$journalReminderPrefix${formatTodoDate(day)}';

/// The day a journal payload points at, or null when it is not one.
DateTime? journalReminderDayOf(String? payload) {
  if (payload == null || !payload.startsWith(journalReminderPrefix)) {
    return null;
  }
  return DateTime.tryParse(payload.substring(journalReminderPrefix.length));
}

/// The Android channel every reminder posts on.
///
/// Stable for the life of the install: Android keys a channel by id and
/// freezes its importance at creation, so a new id would strand the
/// user's per-channel settings on the old one.
const String todoReminderChannelId = 'niman_reminders';

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
/// Shipped as density PNGs (`tool/make_stat_icon.py`), not as a vector:
/// a `VectorDrawable` under `res/drawable/` never reached the resource
/// table on the build machine, even from a clean build, while the
/// density-qualified buckets resolve.
///
/// The app's own mark, so a reminder in the status bar reads as Niman
/// rather than as any app's alarm. Android masks a small icon to its
/// alpha and tints it, so what shows is the white silhouette of the
/// launcher foreground's ink — the blue of the "i" cannot survive.
const String todoReminderIcon = 'ic_stat_niman';

/// The alarm glyph the reminders used before the app mark
/// (`tool/make_reminder_icon.py`), kept as the first fallback.
const String todoReminderIconLegacy = 'ic_stat_reminder';

/// One schedulable reminder: a stable [id] with content + fire time.
@immutable
final class TodoReminder {
  /// Creates a reminder firing at [when] (local wall-clock time).
  const new({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
    this.payload = todoReminderPayload,
  });

  /// The notification id, derived from the task text ([todoReminderId]).
  final int id;

  /// The task description.
  final String title;

  /// The due line, or the generic reminder text.
  final String body;

  /// When to fire (local wall-clock time, from `rem:`).
  final DateTime when;

  /// What a tap on the notification opens ([todoReminderPayload] for a
  /// task, [journalReminderPayload] for an event).
  final String payload;
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

/// A stable notification id for an event on [day] (#730).
///
/// The same hash the tasks' ids come from, salted with the word and the
/// day: an event's id can never be a task's, and an event that keeps its
/// text keeps its id when the file's lines move — only the day and the
/// text feed it.
int calendarReminderId(DateTime day, String text) {
  return todoReminderId('calendar ${formatTodoDate(day)} $text');
}

/// How long a reminder stays wanted after its own moment (T-RL-03).
///
/// The wanted set is a full replace: anything outside it has its pending
/// alarm cancelled. Dropping a reminder the instant its time passes
/// therefore cancels an alarm the OS has not fired yet, and Android does
/// hold alarms past their time — a device log caught one still pending
/// three minutes after it was due, cancelled by the next reconcile
/// before it could ring. Whether the user heard the reminder came down
/// to which happened first.
///
/// An hour is longer than any deferral `setExactAndAllowWhileIdle`
/// admits to, and costs nothing while nothing is deferred: a reminder
/// that already fired is no longer pending, so the sweep skips it, and
/// one the user completes or edits leaves the set on its own merits.
const reminderGrace = Duration(hours: 1);

/// The schedulable reminders of the calendar (#730): every event of
/// [snapshot] whose line carries a `rem:HH:MM`, as a clock time on the day
/// that line heads. A `Z` in the event's own time never moves it — the
/// reminder is the clock time that was written next to it.
///
/// A missing snapshot is no calendar file, and nothing wanted from it.
Map<int, TodoReminder> calendarWantedReminders(
  CalendarSnapshot? snapshot,
  DateTime now, {
  bool showTokens = false,
}) {
  final wanted = <int, TodoReminder>{};
  if (snapshot == null) return wanted;
  for (final entry in snapshot.entries) {
    final line = entry.line;
    final day = line.date;
    if (day == null || line.kind != CalendarLineKind.day) continue;
    for (final event in line.events) {
      final when = _eventReminderStamp(day, event.reminder);
      if (when == null || when.isBefore(now.subtract(reminderGrace))) {
        continue;
      }
      final id = calendarReminderId(day, event.text);
      // The same two readings a task's title gets: the managed `rem:` (and
      // any other `key:value`) is never shown, the `+`/`@`/`#` markers are
      // the user's call.
      final title = showTokens
          ? withoutKeyValueTags(event.text)
          : taskDisplayText(event.text);
      wanted[id] = TodoReminder(
        id: id,
        title: title.isEmpty ? AppStrings.todoReminderFallbackTitle : title,
        body: _eventReminderBody(day, event),
        when: when,
        payload: journalReminderPayload(day),
      );
    }
  }
  return wanted;
}

/// The day the event sits on, and the time it says, as one line — what a
/// notification reads under the event's own text.
String _eventReminderBody(DateTime day, CalendarEvent event) {
  final label = formatDateTime(day, 'ddd D MMM');
  final time = event.time?.raw;
  return time == null || time.isEmpty ? label : '$label · $time';
}

/// A `rem:` value on [day] as a local stamp, or null when it is not a
/// time at all. The format's own readings are accepted (`0530`, `5:30`,
/// `5`), and a `Z` is the instant it names, not a clock time.
DateTime? _eventReminderStamp(DateTime day, String? reminder) {
  final moment = reminder == null ? null : parseCalendarMoment(reminder);
  if (moment == null) return null;
  if (!moment.utc) {
    return DateTime(day.year, day.month, day.day, moment.hour, moment.minute);
  }
  return DateTime.utc(
    day.year,
    day.month,
    day.day,
    moment.hour,
    moment.minute,
  ).toLocal();
}

/// The schedulable reminders of [snapshot]: open (`todo.txt`) tasks with
/// a `rem:` no more than [reminderGrace] before [now]. Completed tasks
/// (archived, or still `x` in `todo.txt` awaiting migration) and times
/// older than that never fire. [now] is the wall clock (the controller's
/// injected clock in tests, real time on device).
///
/// Reminders inside the grace window are kept so the sweep leaves their
/// alarms alone. An Android alarm is a future instant, so scheduling
/// skips them there; a desktop timer fires an already-past reminder, so
/// one that came due while Niman was closed is shown late (#356).
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
    if (when == null || when.isBefore(now.subtract(reminderGrace))) {
      continue;
    }
    // The id stays over the full text (stable identity), but the shown
    // title never carries the managed due:/rem: tags. The
    // +project/@context/#tag markers are the user's call ([showTokens]):
    // off by default, because on a lock screen they are syntax with
    // nothing to explain them, but someone who files by project reads
    // them as part of the task. A line written elsewhere can be nothing
    // but tokens, which would leave a titleless notification.
    final title = taskPlainText(task.description, markers: showTokens);
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
