// T-PP-03: the desktop backend keeps the reminder schedule in-process.
// The plugin is faked so the timer, the pending map and the full-replace
// semantics are exercised without a desktop session.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/desktop_notifier.dart';
import 'package:niman/src/todo/reminder_backend_desktop.dart';
import 'package:niman/src/todo/todo_reminder.dart';

void main() {
  late FakeDesktopNotifier notifier;
  late DesktopReminderBackend backend;
  var nextId = 0;

  TodoReminder reminder(Duration ahead) {
    final id = ++nextId;
    return TodoReminder(
      id: id,
      title: 'task $id',
      body: 'body',
      when: DateTime.now().add(ahead),
    );
  }

  setUp(() {
    notifier = FakeDesktopNotifier();
    backend = DesktopReminderBackend(notifier: notifier);
  });

  tearDown(() => backend.dispose());

  test(
    'a due reminder is posted at its time, then drops out of pending',
    () async {
      final r = reminder(const Duration(milliseconds: 30));
      await backend.schedule(r, exact: true);
      expect(await backend.pendingIds(), [r.id]);
      expect(notifier.shown, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 90));
      expect(notifier.shown.map((posted) => posted.id), [r.id]);
      expect(await backend.pendingIds(), isEmpty);
    },
  );

  test('a cancelled reminder never fires', () async {
    final r = reminder(const Duration(milliseconds: 30));
    await backend.schedule(r, exact: true);
    await backend.cancel(r.id);
    expect(await backend.pendingIds(), isEmpty);

    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(notifier.shown, isEmpty);
  });

  test(
    'rescheduling one id replaces the timer instead of duplicating it',
    () async {
      final soon = reminder(const Duration(milliseconds: 20));
      final later = TodoReminder(
        id: soon.id,
        title: soon.title,
        body: soon.body,
        when: DateTime.now().add(const Duration(seconds: 5)),
      );
      await backend.schedule(later, exact: true);
      await backend.schedule(soon, exact: true);

      expect(await backend.pendingIds(), [soon.id]);
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(notifier.shown.map((posted) => posted.id), [soon.id]);
    },
  );

  test('the plugin is initialized once however often we schedule', () async {
    await backend.schedule(reminder(const Duration(seconds: 5)), exact: true);
    await backend.schedule(reminder(const Duration(seconds: 5)), exact: true);
    expect(notifier.initCalls, 1);
  });

  test('the desktop needs no grant and offers no launch payload', () async {
    expect(await backend.notificationsAllowed(), isTrue);
    expect(await backend.exactAllowed(), isTrue);
    expect(await backend.launchPayload(), isNull);
  });

  test('a notification tap reaches the service stream', () async {
    final taps = <String?>[];
    final subscription = backend.taps.listen(taps.add);
    await backend.ensureReady();

    notifier.emit('todo');
    await Future<void>.delayed(Duration.zero);

    expect(taps, ['todo']);
    await subscription.cancel();
  });

  test('dispose cancels every armed timer', () async {
    await backend.schedule(
      reminder(const Duration(milliseconds: 30)),
      exact: true,
    );
    await backend.dispose();

    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(notifier.shown, isEmpty);
  });
}

/// Records what the backend asked the platform to show.
final class FakeDesktopNotifier implements DesktopNotifier {
  /// Reminders the backend posted.
  final List<TodoReminder> shown = [];

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
    shown.add(reminder);
  }

  /// Simulates a notification tap with [payload].
  void emit(String? payload) => _onTap?.call(payload);
}
