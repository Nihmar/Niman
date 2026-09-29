import 'package:niman/src/todo/desktop_notifier.dart';
import 'package:niman/src/todo/todo_reminder.dart';

/// Records what a desktop backend asked the platform to show.
///
/// The plugin is the one part of the desktop path that needs a session;
/// this stands in for it so the timer, the pending map and the overdue
/// policy are driven without one (T-PP-03).
final class FakeDesktopNotifier implements DesktopNotifier {
  /// Reminders the backend posted.
  final List<TodoReminder> shown = [];

  /// How many upcoming `show` calls fail — the daemon not answering at
  /// login, which the backend only logs.
  int failShows = 0;

  /// How many times the backend initialized the plugin.
  int initCalls = 0;

  void Function(String? payload)? _onTap;

  @override
  Future<void> init({required void Function(String? payload) onTap}) async {
    initCalls++;
    _onTap = onTap;
  }

  @override
  Future<void> show(TodoReminder reminder) async {
    if (failShows > 0) {
      failShows--;
      throw StateError('the notification daemon did not answer');
    }
    shown.add(reminder);
  }

  /// Simulates a notification tap with [payload].
  void emit(String? payload) => _onTap?.call(payload);
}
