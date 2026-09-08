import 'dart:async';

import 'package:copist/src/todo/reminder_health.dart';
import 'package:copist/src/todo/reminders.dart';
import 'package:flutter/foundation.dart';

/// In-memory [ReminderService] for controller and widget tests.
///
/// Records every [reconcile] call; with [permissionGranted] false it
/// behaves like the real service under a denied runtime permission
/// (records an empty set — stale alarms cleared, nothing scheduled).
/// With [failReconcile] true every call throws (the controller must
/// keep working and surface nothing).
final class FakeReminderService implements ReminderService {
  /// Creates a fake; [launchPayload] is returned once per
  /// [consumeLaunchPayload] caller (a tap-started app in tests).
  new({this.launchPayload});

  /// The payload a tap-started app would deliver.
  final String? launchPayload;

  /// Whether the runtime permission counts as granted.
  bool permissionGranted = true;

  /// Whether [reconcile] throws.
  bool failReconcile = false;

  /// Every wanted set handed to [reconcile], in order.
  final List<Map<int, TodoReminder>> reconciled = <Map<int, TodoReminder>>[];

  final StreamController<String?> _taps = StreamController<String?>.broadcast();

  /// Simulates a notification tap with [payload].
  void tap(String? payload) => _taps.add(payload);

  @override
  Future<void> reconcile(Map<int, TodoReminder> wanted) async {
    if (failReconcile) {
      throw StateError('fake reminders unavailable');
    }
    reconciled.add(
      permissionGranted ? Map<int, TodoReminder>.of(wanted) : const {},
    );
  }

  /// The reported health; tests set it to exercise the banner.
  final ValueNotifier<ReminderHealth> healthState =
      ValueNotifier<ReminderHealth>(ReminderHealth.ok);

  /// How many times the banner asked to open a system screen.
  int settingsOpened = 0;

  @override
  ValueListenable<ReminderHealth> get health => healthState;

  @override
  Future<bool> openHealthSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Stream<String?> get taps => _taps.stream;

  @override
  Future<String?> consumeLaunchPayload() async => launchPayload;

  @override
  Future<void> dispose() async {
    healthState.dispose();
    await _taps.close();
  }
}
