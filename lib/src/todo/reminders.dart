/// OS reminders for `rem:` tags (T-TD-07).
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
/// `timezone`. The desktops get an in-process timer over the same plugin
/// (T-PP-03): a notification is shown while Niman runs, and a closed app
/// fires late on the next run or not at all — no desktop equivalent of
/// AlarmManager exists. Anything else (web) gets [NoopReminderService].
/// Widget tests inject a fake; the plugin itself is only touched
/// on-device.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/reminder_backend.dart';
import 'package:niman/src/todo/reminder_backend_desktop.dart';
import 'package:niman/src/todo/reminder_backend_plugin.dart';
import 'package:niman/src/todo/reminder_health.dart';
import 'package:niman/src/todo/reminder_settings.dart';
import 'package:niman/src/todo/todo_reminder.dart';

/// The reminder model travels with the service: callers that schedule
/// also build the wanted set.
export 'package:niman/src/todo/todo_reminder.dart';

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

/// Creates the platform service: scheduled OS notifications on Android,
/// an in-process timer on the desktops (T-PP-03), a no-op elsewhere.
///
/// [isAndroid] and [isDesktop] override the host platform so a plain test
/// can cover the branches that do not run here (T-PP-01).
ReminderService createReminderService({bool? isAndroid, bool? isDesktop}) {
  if (isAndroid ?? Platform.isAndroid) {
    return LocalReminderService();
  }
  if (isDesktop ?? (Platform.isLinux || Platform.isWindows)) {
    return LocalReminderService(backend: DesktopReminderBackend());
  }
  return const NoopReminderService();
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

/// The reminder scheduling policy over a [ReminderBackend].
///
/// Shared by Android (OS alarms) and the desktops (in-process timers);
/// everything above the backend is platform-agnostic.
///
/// Holds no platform code of its own -- the full replace, the single
/// flight, the grant gating and the health reporting are ordinary Dart,
/// which is what lets them be tested. `USE_EXACT_ALARM` is auto-granted
/// at install, so exact scheduling is available from the first run with
/// no settings trip, and that is what makes a reminder fire on time with
/// the screen off and the app closed.
final class LocalReminderService implements ReminderService {
  /// Creates the service over [backend] (the plugin by default).
  ///
  /// [settings] reaches the system screens behind [health]; [clock] is the
  /// wall clock guarding against scheduling into the past. All three are
  /// injected in tests, which is what lets the logic below run without a
  /// device.
  new({
    ReminderBackend? backend,
    this.settings = const PlatformReminderSettings(),
    DateTime Function()? clock,
  }) : _backend = backend ?? PluginReminderBackend(),
       _clock = clock ?? DateTime.now;

  final ReminderBackend _backend;

  /// Reaches the system screens behind [health].
  final ReminderSettings settings;

  /// The wall clock guarding against scheduling into the past.
  ///
  /// Separate from the controller's clock, which stamps the wanted set:
  /// a set computed before a permission round trip can be stale by the
  /// time it lands here.
  final DateTime Function() _clock;

  final ValueNotifier<ReminderHealth> _health = ValueNotifier<ReminderHealth>(
    ReminderHealth.ok,
  );

  static const AppLogger _log = AppLogger(name: 'todo');

  bool _started = false;

  /// The newest wanted set waiting for [_drain], or null when none is.
  Map<int, TodoReminder>? _queued;

  /// The running [_drain], or null while idle.
  Future<void>? _running;

  /// Prepares the backend, logging what survived the previous process.
  Future<void> _ensureReady() async {
    await _backend.ensureReady();
    if (_started) {
      return;
    }
    _started = true;
    // What the OS still holds from the run before this one. After a kill,
    // a swipe away or a reboot this is the only evidence of whether the
    // alarms survived, and the process that would have logged it is gone.
    await _logPending('at startup');
  }

  /// Logs the ids the OS reports as pending, tagged with [stage].
  ///
  /// The authoritative answer to "is this reminder actually armed?" --
  /// everything else here is what Niman *asked* for.
  Future<void> _logPending(String stage) async {
    try {
      final ids = await _backend.pendingIds();
      _log.info('todo reminders: ${ids.length} pending $stage $ids');
    } on Object catch (error) {
      _log.warning('todo reminders: pending query failed ($error)');
    }
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

  /// One full replace pass for [wanted] (serialized by [_drain]).
  Future<void> _reconcileOnce(Map<int, TodoReminder> wanted) async {
    try {
      await _ensureReady();
    } on Object catch (error) {
      // A dead platform leaves the existing alarms alone: better stale
      // than cancelled by something that cannot reschedule them.
      _log.warning('todo reminders unavailable: $error');
      return;
    }
    // Grants resolve BEFORE the sweep: a request dialog backgrounds the
    // app, and cancelling first would leave nothing behind if the user
    // came back through onResume instead of a fresh reconcile. Nothing is
    // asked while nothing is wanted.
    final granted = wanted.isEmpty || await _backend.notificationsAllowed();
    final exact = granted && wanted.isNotEmpty && await _backend.exactAllowed();
    final batteryExempt = await settings.isBatteryExempt();
    _health.value = _healthOf(
      granted: granted,
      exact: exact,
      batteryExempt: batteryExempt,
      wantsAny: wanted.isNotEmpty,
    );
    _log.info(
      'todo reminders: reconcile ${wanted.length} wanted, '
      'notifications ${granted ? 'allowed' : 'blocked'}, '
      'alarms ${exact ? 'exact' : 'inexact'}, '
      'battery ${batteryExempt ? 'unrestricted' : 'optimized'}',
    );
    await _logOverdue(wanted, exact: exact, batteryExempt: batteryExempt);
    await _cancelStale(wanted);
    if (wanted.isEmpty) {
      _log.info('todo reminders reconciled: 0 scheduled');
      return;
    }
    if (!granted) {
      _log.info(
        'todo reminders: notifications blocked, '
        '${wanted.length} wanted not scheduled',
      );
      return;
    }
    await _scheduleAll(wanted, exact: exact);
    // Read back what the OS actually holds: everything above is what
    // Niman asked for, and the two can differ (a rejected alarm, an OEM
    // limit). This line is what makes an exported log conclusive.
    await _logPending('after reconcile');
  }

  /// Logs the reminders whose moment has already passed (T-RL-01).
  ///
  /// Reminders are reported arriving minutes late, and nothing in the app
  /// sees a delivery: the plugin reports no "delivered at". What it does
  /// report is what the OS still holds, and that is enough to tell the
  /// two cases apart. An id still pending after its own time never fired,
  /// which is what a deferred alarm looks like; an id that is gone did
  /// fire, so any lateness was in the delivery, not in the alarm. Each
  /// line carries the two settings that decide which — exact alarms and
  /// the battery exemption — so one exported log answers the question
  /// instead of narrowing it.
  ///
  /// Only runs when something is actually overdue, so a healthy set costs
  /// nothing.
  ///
  /// This depends on [reminderGrace]: before it existed the wanted set
  /// could not contain a past reminder by construction, so this logged
  /// nothing on the very run that caught the bug. The evidence was the
  /// `cancelled 1 stale` line instead.
  Future<void> _logOverdue(
    Map<int, TodoReminder> wanted, {
    required bool exact,
    required bool batteryExempt,
  }) async {
    final now = _clock();
    final overdue = [
      for (final reminder in wanted.values)
        if (!reminder.when.isAfter(now)) reminder,
    ];
    if (overdue.isEmpty) return;
    final List<int> pending;
    try {
      pending = await _backend.pendingIds();
    } on Object catch (error) {
      _log.warning('todo reminders: pending query failed ($error)');
      return;
    }
    for (final reminder in overdue) {
      final held = pending.contains(reminder.id);
      _log.warning(
        'todo reminders: overdue ${reminder.id} '
        'due ${reminder.when.toIso8601String()} '
        '(${_since(now.difference(reminder.when))} ago), '
        '${held ? 'STILL PENDING, never fired' : 'no longer pending, fired'}, '
        'alarms ${exact ? 'exact' : 'inexact'}, '
        'battery ${batteryExempt ? 'unrestricted' : 'optimized'}',
      );
    }
  }

  /// The worst precondition currently failing.
  ///
  /// Ordered by consequence: a blocked notification hides the reminder
  /// outright, a battery-managed app may never get to fire it, and
  /// inexact only makes it late.
  static ReminderHealth _healthOf({
    required bool granted,
    required bool exact,
    required bool batteryExempt,
    required bool wantsAny,
  }) {
    if (!granted) return ReminderHealth.notificationsBlocked;
    if (!batteryExempt) return ReminderHealth.batteryRestricted;
    if (!exact && wantsAny) return ReminderHealth.inexactOnly;
    return ReminderHealth.ok;
  }

  /// Cancels every pending alarm that [wanted] no longer asks for.
  ///
  /// Never a blanket cancel: that also dismisses notifications already
  /// sitting in the tray, so any todo edit or app resume wiped a reminder
  /// the user had not acted on yet. Diffing against the OS's own pending
  /// list keeps the no-stored-state property (nothing of ours to drift
  /// from the files or to lose across a reinstall) while touching only
  /// pending alarms.
  ///
  /// Ids still wanted are left alone: rescheduling the same id replaces
  /// the pending alarm, so an edited time or body converges without a
  /// cancel. Niman posts no notifications other than reminders, so every
  /// pending id outside [wanted] is stale -- that reservation of the id
  /// space is what makes the sweep safe.
  ///
  /// "Stale" is the caller's word: [wantedReminders] holds a reminder for
  /// [reminderGrace] past its own moment, because an alarm the OS has
  /// deferred is still pending and cancelling it here is what silences a
  /// reminder outright rather than merely delaying it.
  Future<void> _cancelStale(Map<int, TodoReminder> wanted) async {
    final List<int> pending;
    try {
      pending = await _backend.pendingIds();
    } on Object catch (error) {
      // Better a stale alarm than a blown-away set.
      _log.warning('todo reminders: pending query failed ($error)');
      return;
    }
    var cancelled = 0;
    for (final id in pending) {
      if (wanted.containsKey(id)) {
        continue;
      }
      try {
        await _backend.cancel(id);
        cancelled++;
      } on Object catch (error) {
        _log.warning('todo reminders: cancel failed for id $id ($error)');
      }
    }
    if (cancelled > 0) {
      _log.info('todo reminders: cancelled $cancelled stale');
    }
  }

  /// Schedules every reminder in [wanted] still in the future.
  Future<void> _scheduleAll(
    Map<int, TodoReminder> wanted, {
    required bool exact,
  }) async {
    if (!exact) {
      _log.info('todo reminders: exact denied, falling back to inexact');
    }
    final now = _clock();
    var scheduled = 0;
    for (final reminder in wanted.values) {
      if (!reminder.when.isAfter(now)) {
        // Two ways to get here: the set is stale, because it is computed
        // before the grant round trip and that can open a system screen
        // and take minutes; or the reminder is inside `reminderGrace`,
        // kept in the set so the sweep does not cancel an alarm the OS
        // still owes. Either way there is nothing to arm — an instant
        // already past cannot be scheduled — and the pending alarm, if
        // there is one, is left to fire.
        _log.info(
          'todo reminders: skipped ${reminder.id}, '
          '${reminder.when.toIso8601String()} already passed',
        );
        continue;
      }
      try {
        await _backend.schedule(reminder, exact: exact);
        _log.info(
          'todo reminders: armed ${reminder.id} '
          'for ${reminder.when.toIso8601String()} '
          '(in ${_since(reminder.when.difference(now))}) ${reminder.title}',
        );
      } on Object catch (error) {
        // One bad alarm must not abort the rest of the set.
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
    return await switch (_health.value) {
      ReminderHealth.notificationsBlocked =>
        settings.openNotificationSettings(),
      ReminderHealth.batteryRestricted => settings.openBatterySettings(),
      // No in-app remedy: the exact-alarm privilege is auto-granted, so a
      // build that still refuses it is not offering a toggle either.
      ReminderHealth.inexactOnly || ReminderHealth.ok => false,
    };
  }

  @override
  Stream<String?> get taps => _backend.taps;

  @override
  Future<String?> consumeLaunchPayload() async {
    try {
      await _ensureReady();
      return await _backend.launchPayload();
    } on Object catch (error) {
      _log.debug('todo reminders: no launch payload ($error)');
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    _health.dispose();
    await _backend.dispose();
  }
}

/// Desktop (and test) no-op: v1 shows no OS notifications off Android;
/// the due badges carry the state (documented limitation, T-TD-07).
final class NoopReminderService implements ReminderService {
  /// Creates the no-op service.
  const new();

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
