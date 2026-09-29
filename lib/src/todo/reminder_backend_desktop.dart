/// The desktop [ReminderBackend] (T-PP-03).
///
/// Linux has no OS scheduler: `flutter_local_notifications` there can only
/// `show` while the process runs, and `zonedSchedule`/`cancel` throw (see
/// the T-PP-02 spike). So the schedule lives
/// in-process: `schedule` arms a [Timer] for the due instant and posts the
/// notification when it fires. The app has to be running, which is what the
/// in-app help tells the user; a closed or slept-through app fires late on
/// the next run or not at all.
///
/// Windows could hand a future toast to the OS (`zonedSchedule` ->
/// `AddToSchedule`) but cancelling it needs MSIX package identity, which
/// only lands with M7 packaging; until then both desktops share the timer
/// floor, and the pending map is exactly what the service reads back.
library;

import 'dart:async';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/desktop_notifier.dart';
import 'package:niman/src/todo/desktop_shown_log.dart';
import 'package:niman/src/todo/reminder_backend.dart';
import 'package:niman/src/todo/todo_reminder.dart';

/// The desktop reminders: an in-process timer over a [DesktopNotifier].
final class DesktopReminderBackend implements ReminderBackend {
  /// Creates the backend over [notifier] (the plugin by default).
  new({DesktopNotifier? notifier})
    : _notifier = notifier ?? PluginDesktopNotifier();

  final DesktopNotifier _notifier;

  /// Armed timers by reminder id; the pending map the service reads back.
  final Map<int, Timer> _armed = {};

  /// What this run has shown, by task and moment (#42, #497).
  final DesktopShownLog _shown = DesktopShownLog();

  final StreamController<String?> _taps = StreamController<String?>.broadcast();

  static const AppLogger _log = AppLogger(name: 'todo');

  bool _ready = false;

  @override
  Future<void> ensureReady() async {
    if (_ready) {
      return;
    }
    await _notifier.init(onTap: _taps.add);
    _ready = true;
  }

  /// Always true: a desktop notification needs no runtime grant. The
  /// system can still be set to hide them, and neither desktop exposes a
  /// query for that, so this is the honest best answer.
  @override
  Future<bool> notificationsEnabled() async => true;

  @override
  Future<bool> notificationsAllowed() async => true;

  /// Always true: a [Timer] is not subject to Doze batching.
  @override
  Future<bool> exactAllowed() async => true;

  @override
  Future<List<int>> pendingIds() async => _armed.keys.toList()..sort();

  @override
  void noteWanted(Iterable<TodoReminder> wanted) => _shown.reconcile(wanted);

  @override
  Future<void> cancel(int id) async {
    _armed.remove(id)?.cancel();
  }

  @override
  Future<void> schedule(TodoReminder reminder, {required bool exact}) async {
    await ensureReady();
    // Replacing the same id converges an edited time or body, exactly like
    // the OS replacement the Android backend relies on.
    _armed.remove(reminder.id)?.cancel();
    // Delivered already: the reminder stays wanted for `reminderGrace` past
    // its moment, so every reconcile in that window — a todo edit, a focus
    // regain — schedules it again, and one that was shown is not shown
    // twice. What "it" is — this task at this moment, surviving an edit of
    // its text — is [DesktopShownLog]'s rule. A new moment, or another task
    // at the same one, is a new reminder, and it fires.
    if (_shown.isShown(reminder)) {
      _log.info(
        'todo reminders: ${reminder.id} already shown for '
        '${reminder.when.toIso8601String()}, not shown again',
      );
      return;
    }
    final delay = reminder.when.difference(DateTime.now());
    final timer = Timer(delay.isNegative ? Duration.zero : delay, () {
      _armed.remove(reminder.id);
      unawaited(_show(reminder));
    });
    _armed[reminder.id] = timer;
  }

  /// True: an already-past reminder arms a zero-delay timer above, so one
  /// that came due while Niman was closed is shown on the next run rather
  /// than dropped — once: one this run already showed for that moment is
  /// not armed again.
  @override
  bool get firesOverdue => true;

  /// Posts [reminder], logging rather than throwing: the timer callback has
  /// no caller to return an error to.
  ///
  /// A show that fails is not recorded as shown, so the next reconcile in
  /// the grace window hands the reminder over again: the system's daemon
  /// not answering at login is a delivery that has not happened, not one
  /// that cannot be improved on.
  Future<void> _show(TodoReminder reminder) async {
    try {
      await _notifier.show(reminder);
      _shown.record(reminder, DateTime.now());
      _log.info('todo reminders: fired ${reminder.id} ${reminder.title}');
    } on Object catch (error) {
      _log.warning(
        'todo reminders: show failed for id ${reminder.id} ($error)',
      );
    }
  }

  /// The desktop reading of an overdue reminder (#42). No OS keeps its
  /// alarm, so "not pending" does not mean "fired": after a restart the
  /// timers start empty, and a reminder due while Niman was closed was
  /// never armed at all. Exact alarms and battery say nothing here.
  @override
  String overdueState(
    TodoReminder reminder, {
    required bool pending,
    required bool exact,
    required bool batteryExempt,
    required bool backgroundRestricted,
  }) {
    if (pending) {
      return 'timer STILL ARMED past its time: the machine slept through '
          'it, or the process stalled';
    }
    final firedAt = _shown.shownAt(reminder);
    if (firedAt != null) {
      return 'timer fired ${_late(firedAt.difference(reminder.when))} late';
    }
    return 'NOT FIRED: no timer in this run, Niman was not running at its '
        'time';
  }

  /// A lateness, short: "0 s", "42 s", "3 min".
  static String _late(Duration d) {
    final seconds = d.isNegative ? 0 : d.inSeconds;
    return seconds < 60 ? '$seconds s' : '${d.inMinutes} min';
  }

  /// Null: a desktop launch is a plain start, never a notification tap.
  @override
  Future<String?> launchPayload() async => null;

  @override
  Stream<String?> get taps => _taps.stream;

  @override
  Future<void> dispose() async {
    for (final timer in _armed.values) {
      timer.cancel();
    }
    _armed.clear();
    await _taps.close();
  }
}
