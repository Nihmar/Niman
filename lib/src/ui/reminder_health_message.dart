/// What a failing reminder precondition reads as in the UI, in one place
/// (T-TD-07): the Todo tab's banner and the task dialog's warning say the
/// same thing about the same state.
library;

import 'package:niman/src/todo/reminder_health.dart';
import 'package:niman/src/ui/strings.dart';

/// The sentence [health] reads as; empty for [ReminderHealth.ok].
String reminderHealthMessage(ReminderHealth health) => switch (health) {
  ReminderHealth.notificationsBlocked => AppStrings.todoReminderBlocked,
  ReminderHealth.batteryRestricted => AppStrings.todoReminderBattery,
  ReminderHealth.inexactOnly => AppStrings.todoReminderInexact,
  ReminderHealth.ok => '',
};

/// Whether a system screen can fix [health].
///
/// Exact alarms cannot: the privilege is auto-granted, so a build that
/// still refuses it offers no toggle either.
bool reminderHealthFixable(ReminderHealth health) =>
    health != ReminderHealth.inexactOnly;
