/// OS reminders for `rem:` tags (plan/todo-tab.md T-TD-07).
///
/// The controller derives the wanted set from the snapshot
/// ([wantedReminders]: open tasks with a future `rem:`) and hands it to
/// the [ReminderService]; reconciliation runs after every publish, so
/// external edits, deletes and reinstalls converge on the next open.
/// Scheduling is a full replace -- sweep the pending alarms the OS reports
/// but nobody wants any more, then (re)schedule every wanted one -- so it
/// is idempotent and free of stored state.
///
/// The invariant that makes the full replace safe: [ReminderService.reconcile]
/// is only ever called with a set derived from a *loaded* snapshot. An
/// empty set means "this library wants no reminders", never "nothing is
/// loaded yet" -- the controller drops the latter before it gets here,
/// because reconciling it would cancel every pending alarm.
///
/// Platform split: Android schedules OS notifications (exact alarms
/// via `setExactAndAllowWhileIdle`, so they fire in Doze — screen off —
/// and with the app closed; the exact privilege comes from the
/// auto-granted `USE_EXACT_ALARM` permission, with an inexact fallback
/// if a device reports otherwise) through `flutter_local_notifications` +
/// `timezone`; every other platform gets [NoopReminderService] — no OS
/// notifications in v1, the due badges carry the state (documented
/// limitation). Widget tests inject a fake; the plugin itself is only
/// touched on-device.
library;

import 'dart:async';
import 'dart:io';

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/todo/parser.dart';
import 'package:copist/src/todo/reminder_health.dart';
import 'package:copist/src/todo/reminder_settings.dart';
import 'package:copist/src/todo/todo_store.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The notification payload routing taps to the Todo tab.
const String todoReminderPayload = 'todo';

/// The Android channel every reminder posts on.
///
/// Stable for the life of the install: Android keys a channel by id and
/// freezes its importance at creation, so a new id would strand the
/// user's per-channel settings on the old one.
const String todoReminderChannelId = 'copist_reminders';

/// The status-bar icon for reminders.
///
/// Android masks a small icon to its alpha channel and tints the result,
/// so it has to be a flat silhouette. The launcher icon (used here before)
/// is fully opaque and came out as a plain white square.
const String todoReminderIcon = '@drawable/ic_stat_reminder';

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
  DateTime now,
) {
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
    // Only the user's entered description: the id stays over the full
    // text (stable identity), but the shown text drops the managed
    // due:/rem:/… tags Copist appends — a reminder reads as one phrase,
    // not the whole raw line. A line written elsewhere can be nothing but
    // those tags, which would leave a titleless notification.
    final title = withoutKeyValueTags(task.description);
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

/// What the todo UI needs from the OS notification layer.
///
/// Implemented by [LocalReminderService] (Android) and
/// [NoopReminderService] (elsewhere), plus an in-memory fake in widget
/// and controller tests.
abstract interface class ReminderService {
  /// Schedules exactly [wanted] (cancelling everything stale first).
  Future<void> reconcile(Map<int, TodoReminder> wanted);

  /// Notification tap payloads; the shell opens the Todo tab.
  Stream<String?> get taps;

  /// The launch payload when a tap started the app (once, then null).
  Future<String?> consumeLaunchPayload();

  /// Whether the OS-side preconditions for reminders hold.
  ///
  /// Refreshed on every [reconcile], so the resume-driven resync picks up
  /// a grant made in system settings without any extra plumbing.
  ValueListenable<ReminderHealth> get health;

  /// Opens the system screen that fixes [health], if there is one.
  ///
  /// Returns false when the current state has no in-app remedy (only
  /// inexact alarms available) or no activity handles the intent.
  Future<bool> openHealthSettings();

  /// Releases resources.
  Future<void> dispose();
}

/// Creates the platform service: scheduled OS notifications on
/// Android, a no-op elsewhere.
ReminderService createReminderService() {
  if (Platform.isAndroid) {
    return LocalReminderService();
  }
  return NoopReminderService();
}

/// The single reminder service for the app session.
///
/// Typed as the [ReminderService] interface so the UI (and tests, which
/// substitute a fake) never depends on the platform implementation.
final reminderServiceProvider = Provider<ReminderService>((ref) {
  final service = createReminderService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

/// Android reminders via `flutter_local_notifications` (exact alarms via
/// `setExactAndAllowWhileIdle` — see [_ensureExact]) + `timezone` for
/// the local wall clock. `USE_EXACT_ALARM` is auto-granted at install, so
/// exact scheduling is available from the first run with no settings trip
/// — which is what makes a reminder fire on time with the screen off and
/// the app closed.
final class LocalReminderService implements ReminderService {
  /// Creates the service; [settings] reaches the system screens that
  /// decide whether a reminder can fire (injected in tests).
  LocalReminderService({
    this.settings = const PlatformReminderSettings(),
  });

  /// The plugin (method channels — on-device only, never in tests).
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Reaches the system screens behind [health].
  final ReminderSettings settings;

  final ValueNotifier<ReminderHealth> _health =
      ValueNotifier<ReminderHealth>(ReminderHealth.ok);

  final StreamController<String?> _taps = StreamController<String?>.broadcast();

  static const AppLogger _log = AppLogger(name: 'todo');

  bool _ready = false;
  bool _permissionAsked = false;
  bool _launchConsumed = false;

  /// The newest wanted set waiting for [_drain], or null when none is.
  Map<int, TodoReminder>? _queued;

  /// The running [_drain], or null while idle.
  Future<void>? _running;

  /// Timezone database + plugin init, once (idempotent).
  Future<void> _ensureReady() async {
    if (_ready) {
      return;
    }
    tzdata.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
      _log.info('todo reminders: timezone ${local.identifier}');
    } on Object catch (error) {
      // The schedule below falls back to tz.local (UTC): wrong wall
      // clock, but loud in the logs instead of silent.
      _log.warning('todo reminders: local timezone unknown ($error)');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(todoReminderIcon),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _taps.add(response.payload),
    );
    // Create the channel up front instead of letting the first schedule
    // create it implicitly: that way it exists (with a description the
    // user can read in system settings) before any notification does, and
    // it shows in the app's notification settings even when nothing has
    // been scheduled yet. Re-creating with the same id updates the name
    // and description; importance stays whatever it was first created
    // with, and Importance.max matches what installs already have.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            todoReminderChannelId,
            AppStrings.todoReminderChannel,
            description: AppStrings.todoReminderChannelDescription,
            importance: Importance.max,
          ),
        );
    _ready = true;
    // What the OS still holds from the run before this one. After a kill,
    // a swipe away or a reboot this is the only evidence of whether the
    // alarms survived, and the process that would have logged it is gone.
    await _logPending('at startup');
  }

  /// Logs the ids the OS reports as pending, tagged with [stage].
  ///
  /// The authoritative answer to "is this reminder actually armed?" --
  /// everything else in this file is what Copist *asked* for.
  Future<void> _logPending(String stage) async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      final ids = pending.map((r) => r.id).toList()..sort();
      _log.info('todo reminders: ${ids.length} pending $stage $ids');
    } on Object catch (error) {
      _log.warning('todo reminders: pending query failed ($error)');
    }
  }

  /// The runtime permission state (Android 13+): granted at install
  /// below 13 (the query answers null there — treated as granted); on
  /// 13+ the system dialog shows once per process, afterwards the
  /// stored answer stands.
  Future<bool> _ensurePermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >();
    if (android == null) {
      return true;
    }
    if (await android.areNotificationsEnabled() ?? true) {
      return true;
    }
    if (_permissionAsked) {
      return false;
    }
    _permissionAsked = true;
    return await android.requestNotificationsPermission() ?? false;
  }

  /// Whether minute-precise (exact) alarms can be scheduled.
  ///
  /// A defensive query, not a gate: `USE_EXACT_ALARM` is declared and
  /// auto-granted at install, so this is true on any stock Android the app
  /// runs on (minSdk 35). It can still come back false on an OEM build
  /// that gates exact alarms behind its own toggle, and there is no in-app
  /// remedy for that -- requesting `SCHEDULE_EXACT_ALARM` would need that
  /// permission declared, which would trade an always-granted privilege
  /// for one denied by default. The caller falls back to inexact and says
  /// so in the log; Doze can then defer a reminder by several minutes.
  Future<bool> _ensureExact() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >();
    if (android == null) {
      return true;
    }
    if (await android.canScheduleExactNotifications() ?? true) {
      return true;
    }
    _log.warning(
      'todo reminders: exact alarms unavailable on this build',
    );
    return false;
  }

  @override
  Future<void> reconcile(Map<int, TodoReminder> wanted) {
    // Single flight, newest set wins. Reconciliation is a full replace,
    // so two overlapping calls could interleave one's cancel pass with
    // the other's schedule pass and leave the device with no alarms at
    // all -- a resume racing a debounced reload did exactly that. A
    // superseded set is dropped rather than scheduled: it is stale by
    // definition, and the set that replaced it is about to run.
    _queued = wanted;
    final running = _running;
    if (running != null) {
      return running;
    }
    // _drain() runs synchronously up to its first await (consuming
    // _queued), so the assignment below always lands before the finally
    // that clears it: no lost wakeup.
    final drain = _drain();
    _running = drain;
    return drain;
  }

  /// Applies queued sets until none is left, then goes idle.
  Future<void> _drain() async {
    try {
      while (_queued != null) {
        final wanted = _queued!;
        _queued = null;
        await _reconcileOnce(wanted);
      }
    } finally {
      _running = null;
    }
  }

  /// Cancels every pending alarm that [wanted] no longer asks for.
  ///
  /// Never `cancelAll()`: that also dismisses notifications already sitting
  /// in the tray, so any todo edit or app resume wiped a reminder the user
  /// had not acted on yet. Diffing against the OS's own pending list keeps
  /// the no-stored-state property (nothing of ours to drift from the files
  /// or to lose across a reinstall) while touching only pending alarms.
  ///
  /// Ids still wanted are left alone: rescheduling the same id replaces the
  /// pending alarm, so an edited time or body converges without a cancel.
  /// Copist posts no notifications other than reminders, so every pending
  /// id outside [wanted] is a stale one -- that reservation of the id space
  /// is what makes the sweep safe.
  Future<void> _cancelStale(Map<int, TodoReminder> wanted) async {
    final List<PendingNotificationRequest> pending;
    try {
      pending = await _plugin.pendingNotificationRequests();
    } on Object catch (error) {
      // Better a stale alarm than a blown-away set.
      _log.warning('todo reminders: pending query failed ($error)');
      return;
    }
    var cancelled = 0;
    for (final request in pending) {
      if (wanted.containsKey(request.id)) {
        continue;
      }
      try {
        await _plugin.cancel(id: request.id);
        cancelled++;
      } on Object catch (error) {
        _log.warning(
          'todo reminders: cancel failed for id ${request.id} ($error)',
        );
      }
    }
    if (cancelled > 0) {
      _log.info('todo reminders: cancelled $cancelled stale');
    }
  }

  /// One full replace pass for [wanted] (serialized by [_drain]).
  Future<void> _reconcileOnce(Map<int, TodoReminder> wanted) async {
    try {
      await _ensureReady();
    } on Object catch (error) {
      _log.warning('todo reminders unavailable: $error');
      return;
    }
    // Grants resolve BEFORE the sweep: a request dialog backgrounds the
    // app, and cancelling first would leave nothing behind if the user
    // came back through onResume instead of a fresh reconcile. Nothing is
    // asked while nothing is wanted.
    final granted = wanted.isEmpty || await _ensurePermission();
    final exact = granted && wanted.isNotEmpty && await _ensureExact();
    final batteryExempt = await settings.isBatteryExempt();
    // Worst-first: a blocked notification hides the reminder outright, a
    // battery-managed app may never get to fire it, and inexact only
    // makes it late.
    _health.value = !granted
        ? ReminderHealth.notificationsBlocked
        : !batteryExempt
        ? ReminderHealth.batteryRestricted
        : !exact && wanted.isNotEmpty
        ? ReminderHealth.inexactOnly
        : ReminderHealth.ok;
    _log.info(
      'todo reminders: reconcile ${wanted.length} wanted, '
      'notifications ${granted ? 'allowed' : 'blocked'}, '
      'alarms ${exact ? 'exact' : 'inexact'}, '
      'battery ${batteryExempt ? 'unrestricted' : 'optimized'}',
    );
    await _cancelStale(wanted);
    if (wanted.isEmpty) {
      _log.info('todo reminders reconciled: 0 scheduled');
      return;
    }
    if (!granted) {
      _log.info(
        'todo reminders: permission denied, '
        'clearing ${wanted.length} wanted',
      );
      return;
    }
    if (!exact) {
      _log.info('todo reminders: exact denied, falling back to inexact');
    }
    final now = DateTime.now();
    var scheduled = 0;
    for (final reminder in wanted.values) {
      if (!reminder.when.isAfter(now)) {
        _log.info(
          'todo reminders: skipped ${reminder.id}, '
          '${reminder.when.toIso8601String()} already passed',
        );
        continue;
      }
      try {
        await _plugin.zonedSchedule(
          id: reminder.id,
          title: reminder.title,
          body: reminder.body,
          scheduledDate: tz.TZDateTime.from(reminder.when, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              todoReminderChannelId,
              AppStrings.todoReminderChannel,
              icon: todoReminderIcon,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          payload: todoReminderPayload,
        );
        _log.info(
          'todo reminders: armed ${reminder.id} '
          'for ${reminder.when.toIso8601String()} '
          '(in ${_since(reminder.when.difference(now))}) ${reminder.title}',
        );
      } on Object catch (error) {
        // One bad alarm (e.g. exact without the grant) must not abort
        // the rest of the set.
        _log.warning(
          'todo reminders: schedule failed for id ${reminder.id} ($error)',
        );
        continue;
      }
      scheduled++;
    }
    _log.info(
      'todo reminders reconciled: $scheduled scheduled '
      '(${exact ? 'exact' : 'inexact'})',
    );
    // Read back what the OS actually holds: everything above is what
    // Copist asked for, and the two can differ (a rejected alarm, an OEM
    // limit). This line is what makes an exported log conclusive.
    await _logPending('after reconcile');
  }

  /// A compact "2h 14m" for a wait, for the schedule log.
  static String _since(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) {
      return '${days}d ${hours}h';
    }
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  ValueListenable<ReminderHealth> get health => _health;

  @override
  Future<bool> openHealthSettings() async {
    return switch (_health.value) {
      ReminderHealth.notificationsBlocked =>
        settings.openNotificationSettings(),
      ReminderHealth.batteryRestricted => settings.openBatterySettings(),
      // No in-app remedy: the exact-alarm privilege is auto-granted, so a
      // build that still refuses it is not offering a toggle either.
      ReminderHealth.inexactOnly || ReminderHealth.ok => false,
    };
  }

  @override
  Stream<String?> get taps => _taps.stream;

  @override
  Future<String?> consumeLaunchPayload() async {
    if (_launchConsumed) {
      return null;
    }
    _launchConsumed = true;
    try {
      await _ensureReady();
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        _log.info('todo reminders: launched from a tap');
        return details?.notificationResponse?.payload;
      }
    } on Object catch (error) {
      _log.debug('todo reminders: no launch payload ($error)');
    }
    return null;
  }

  @override
  Future<void> dispose() async {
    _health.dispose();
    await _taps.close();
  }
}

/// Desktop (and test) no-op: v1 shows no OS notifications off Android;
/// the due badges carry the state (documented limitation, T-TD-07).
final class NoopReminderService implements ReminderService {
  @override
  Future<void> reconcile(Map<int, TodoReminder> wanted) async {}

  @override
  Stream<String?> get taps => const Stream<String?>.empty();

  @override
  Future<String?> consumeLaunchPayload() async => null;

  /// Always healthy: nothing is scheduled, so nothing can be blocked.
  @override
  ValueListenable<ReminderHealth> get health => _health;

  static final ValueNotifier<ReminderHealth> _health =
      ValueNotifier<ReminderHealth>(ReminderHealth.ok);

  @override
  Future<bool> openHealthSettings() async => false;

  @override
  Future<void> dispose() async {}
}
