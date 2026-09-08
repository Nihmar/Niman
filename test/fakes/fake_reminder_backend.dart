import 'dart:async';

import 'package:copist/src/todo/reminder_backend.dart';
import 'package:copist/src/todo/todo_reminder.dart';

/// In-memory [ReminderBackend] standing in for the OS.
///
/// Records the calls a reconcile makes so tests can assert the order the
/// full replace happens in, and can hold one call open ([holdSchedule]) to
/// force two reconciles to overlap.
final class FakeReminderBackend implements ReminderBackend {
  /// Creates a backend that already holds [pending] alarms.
  FakeReminderBackend({List<int>? pending}) : _pending = <int>{...?pending};

  final Set<int> _pending;

  /// Every call in order, as `ready`, `pending`, `cancel:<id>`,
  /// `schedule:<id>` — the trace an interleaving test reads.
  final List<String> calls = <String>[];

  /// The reminders handed to [schedule], in order.
  final List<TodoReminder> scheduled = <TodoReminder>[];

  /// The ids handed to [cancel], in order.
  final List<int> cancelled = <int>[];

  /// Whether notifications count as allowed.
  bool allowed = true;

  /// Whether exact alarms count as available.
  bool exact = true;

  /// Makes [ensureReady] throw (a dead platform).
  bool failReady = false;

  /// Makes [pendingIds] throw (an unanswered query).
  bool failPending = false;

  /// Ids whose [schedule] throws (one bad alarm in a good set).
  final Set<int> failSchedule = <int>{};

  /// Held open while non-null, so a reconcile can be caught mid-flight.
  Completer<void>? holdSchedule;

  /// The ids the fake OS currently holds.
  List<int> get pending => _pending.toList()..sort();

  @override
  Future<void> ensureReady() async {
    calls.add('ready');
    if (failReady) {
      throw StateError('fake backend unavailable');
    }
  }

  @override
  Future<bool> notificationsAllowed() async => allowed;

  @override
  Future<bool> exactAllowed() async => exact;

  @override
  Future<List<int>> pendingIds() async {
    calls.add('pending');
    if (failPending) {
      throw StateError('fake pending query failed');
    }
    return pending;
  }

  @override
  Future<void> cancel(int id) async {
    calls.add('cancel:$id');
    cancelled.add(id);
    _pending.remove(id);
  }

  @override
  Future<void> schedule(TodoReminder reminder, {required bool exact}) async {
    final hold = holdSchedule;
    if (hold != null) {
      await hold.future;
    }
    calls.add('schedule:${reminder.id}');
    if (failSchedule.contains(reminder.id)) {
      throw StateError('fake schedule failed');
    }
    scheduled.add(reminder);
    _pending.add(reminder.id);
  }

  @override
  Stream<String?> get taps => const Stream<String?>.empty();

  @override
  Future<String?> launchPayload() async => null;

  @override
  Future<void> dispose() async {}
}
