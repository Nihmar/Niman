/// Why a task reminder might not reach the user (T-TD-07).
///
/// Scheduling one is silent about everything that can go wrong after it:
/// the alarm is handed to the system and the app usually is not running
/// when it comes due. Niman can see the three preconditions, so it says
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

  /// The system will not run the app in the background.
  ///
  /// Android's *Restricted* mode, which several ROMs show on the app's
  /// battery page as a "Allow background usage" switch, off. It is the
  /// switch the page Niman opens actually offers, so flipping it clears
  /// this state; a restricted app is not started in the background, so a
  /// reminder never fires. Doze optimization is deliberately not part of
  /// this state: an exact alarm is `setExactAndAllowWhileIdle` and fires
  /// in Doze, and warning about a switch that page does not control left
  /// the banner up after the one switch the user could reach was on.
  batteryRestricted,

  /// Only inexact alarms are available: Doze can defer them by minutes.
  inexactOnly,
}
