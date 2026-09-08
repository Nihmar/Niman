/// Why a task reminder might not reach the user (T-TD-07).
///
/// Scheduling one is silent about everything that can go wrong after it:
/// the alarm is handed to the system and the app usually is not running
/// when it comes due. Copist can see the three preconditions, so it says
/// so in the Todo tab rather than leaving the user to discover a missed
/// reminder.
library;

/// The state of the OS-side preconditions for reminders.
///
/// Ordered by severity: the UI reports the worst one it finds.
enum ReminderHealth {
  /// Everything needed is in place.
  ok,

  /// Notifications are off: the alarm fires and nothing is shown.
  notificationsBlocked,

  /// The system may sleep the app or drop its alarms.
  ///
  /// Several OEM ROMs discard pending alarms when an optimized app is
  /// swiped away from recents, which is when a reminder is most likely to
  /// be needed and least likely to arrive.
  batteryRestricted,

  /// Only inexact alarms are available: Doze can defer them by minutes.
  inexactOnly,
}
