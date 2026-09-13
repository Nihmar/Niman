// Widget taps (issue 6): a tap lands on the tab or note its widget
// shows, switching libraries first when it points elsewhere — on a warm
// start (the tap stream) and on a cold one (the launch target the shell
// consumes when it mounts).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/widget/widget_target.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_shortcut_service.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_widget_target_service.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeShortcutService shortcuts;
  late FakeWidgetTargetService targets;
  late FakeFilePicker filePicker;

  // Joined, not spelled: the create flow builds the root with
  // `package:path`, which uses '\' on Windows.
  final home = p.join('/fake', 'library');
  final other = p.join('/fake', 'Other');

  setUp(() {
    controller = FakeLibrarySession();
    shortcuts = FakeShortcutService();
    targets = FakeWidgetTargetService();
    filePicker = useFakeFilePicker();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        librarySessionProvider.overrideWithValue(controller),
        shortcutServiceProvider.overrideWithValue(shortcuts),
        widgetTargetServiceProvider.overrideWithValue(targets),
        todoSourceFactoryProvider.overrideWithValue(
          (root) => FakeTodoSource(todo: const <String>[]),
        ),
      ],
      child: const NimanApp(),
    );
  }

  Future<void> pumpApp(WidgetTester tester) async {
    // Phone layout: the wide filter bar overflows the default 800x600
    // test surface.
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);
  }

  Future<void> close() async {
    await controller.close();
    await controller.dispose();
    await shortcuts.dispose();
    await targets.dispose();
  }

  testWidgets('a todo tap opens the Todo tab', (tester) async {
    await pumpApp(tester);

    targets.emit(WidgetTarget(kind: WidgetTargetKind.todo, libraryPath: home));
    await settle(tester);
    expect(find.text(AppStrings.todoEmptyOpen), findsOneWidget);
    await close();
  });

  testWidgets('a note tap opens the note in the editor', (tester) async {
    await pumpApp(tester);
    await controller.createNote(parentPath: '', name: 'Target');
    await settle(tester);
    expect(find.byType(NoteView), findsNothing);

    targets.emit(
      WidgetTarget(
        kind: WidgetTargetKind.note,
        libraryPath: home,
        notePath: 'Target.md',
      ),
    );
    await settle(tester);
    expect(find.byType(NoteView), findsOneWidget);
    await close();
  });

  testWidgets('a + tap hands the focus request to the note view', (
    tester,
  ) async {
    await pumpApp(tester);
    await controller.createNote(parentPath: '', name: 'List');
    await settle(tester);

    targets.emit(
      WidgetTarget(
        kind: WidgetTargetKind.note,
        libraryPath: home,
        notePath: 'List.md',
        focusAdd: true,
      ),
    );
    await settle(tester);
    // The shell hands the one-shot request to the NoteView; the view and
    // the list GUI focus the add field once the note has loaded.
    final noteView = tester.widget<NoteView>(find.byType(NoteView));
    expect(noteView.initialFocusAdd, isTrue);
    await close();
  });

  testWidgets('a tap for another library switches first', (tester) async {
    await pumpApp(tester);
    expect(controller.root, home);

    targets.emit(WidgetTarget(kind: WidgetTargetKind.todo, libraryPath: other));
    await settle(tester);

    expect(controller.root, other);
    expect(find.text(AppStrings.todoEmptyOpen), findsOneWidget);
    await close();
  });

  testWidgets('a cold start applies the launch target once mounted', (
    tester,
  ) async {
    targets.launchTarget = WidgetTarget(
      kind: WidgetTargetKind.note,
      libraryPath: home,
      notePath: 'Target.md',
    );
    await pumpApp(tester);
    await controller.createNote(parentPath: '', name: 'Target');
    await settle(tester);

    expect(find.byType(NoteView), findsOneWidget);
    await close();
  });
}
