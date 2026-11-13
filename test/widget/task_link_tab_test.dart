// #1268: a note a task's link names opens on a wide window in a tab of its
// own, not in place of the note on show; with Ctrl, Cmd or a middle click
// in a tab behind it, landing on the link's heading when it first shows. A
// phone has one note on screen, and shows it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/shell_editor_settings.dart';
import 'package:niman/src/ui/shell_tasks.dart';
import 'package:niman/src/ui/shell_workspace.dart';

import '../fakes/fake_calendar_source.dart';
import '../fakes/fake_library_session.dart';
import '../fakes/fake_reminder_service.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';

void main() {
  late ShellWorkspace workspace;
  late List<(String, String?)> shown;
  late ShellTasks tasks;

  Future<void> pump(WidgetTester tester, Size size) async {
    setSurfaceSize(tester, size);
    final session = FakeLibrarySession();
    await session.open('/lib', create: false);
    final reminders = FakeReminderService();
    workspace = ShellWorkspace(session);
    shown = [];
    late BuildContext context;
    tasks = ShellTasks(
      session: session,
      reminders: reminders,
      todoSourceFactory: (_) => FakeTodoSource(),
      calendarSourceFactory: (_) => FakeCalendarSource(),
      linkSource: () => null,
      suggester: () => null,
      editor: () => ShellEditorSettings.defaults,
      openNote: (path, anchor) => shown.add((path, anchor)),
      workspace: workspace,
      guard: (action) => action(),
      context: () => context,
    );
    addTearDown(() async {
      tasks.dispose();
      workspace.dispose();
      await reminders.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (built) {
            context = built;
            return const SizedBox();
          },
        ),
      ),
    );
    workspace.show('a.md');
    await tester.pump();
  }

  /// Lets the workspace's debounced write run before the test ends.
  Future<void> settleSave(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 1));

  void follow(String path, String? anchor, {bool behind = false}) =>
      tasks.linkTargets(null, behind: behind).onOpenNote!(path, anchor);

  testWidgets('a wide window opens the note in a tab of its own', (
    tester,
  ) async {
    await pump(tester, const Size(1200, 900));
    follow('b.md', 'Boiler');
    await tester.pump();
    expect(
      [for (final tab in workspace.value.tabs) tab.path],
      ['a.md', 'b.md'],
    );
    expect(workspace.value.activePath, 'b.md');
    expect(shown, [('b.md', 'Boiler')], reason: 'shown, at its heading');
    await settleSave(tester);
  }, variant: desktopDensity);

  testWidgets('behind, the tab showing stays and the note waits there', (
    tester,
  ) async {
    await pump(tester, const Size(1200, 900));
    follow('b.md', 'Boiler', behind: true);
    await tester.pump();
    expect(workspace.value.activePath, 'a.md');
    expect(
      [for (final tab in workspace.value.tabs) tab.path],
      ['a.md', 'b.md'],
    );
    expect(shown, isEmpty, reason: 'the list stays on screen');
    expect(workspace.anchorBehind('b.md'), 'Boiler');
    await settleSave(tester);
  }, variant: desktopDensity);

  testWidgets('a phone shows the note, as before', (tester) async {
    await pump(tester, const Size(390, 844));
    follow('b.md', 'Boiler', behind: true);
    await tester.pump();
    expect(shown, [('b.md', 'Boiler')]);
    expect(workspace.anchorBehind('b.md'), isNull);
    await settleSave(tester);
  });
}
