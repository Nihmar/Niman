// Issue #23, PR 4: the phone's open-notes switcher. Notes opened stay
// open after back; a badge on the note bar (and on Files, once any are
// open) counts them and opens the sheet that switches, closes, and
// closes all. One editor is mounted at a time.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/note_view.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Future<void> pumpPhone(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(400, 800));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    for (final name in ['alpha', 'beta', 'gamma']) {
      await controller.createNote(parentPath: '', name: name);
    }
    await settle(tester);
  }

  Future<void> open(WidgetTester tester, String name) async {
    await tester.tap(noteRow(name));
    await settle(tester);
  }

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await settle(tester);
  }

  Future<void> sheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('open-notes')));
    await settle(tester);
  }

  String badge(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(const Key('open-notes')),
          matching: find.byType(Text),
        ),
      )
      .data!;

  testWidgets('notes opened stay open, and the badge counts them', (
    tester,
  ) async {
    await pumpPhone(tester);
    // Nothing open yet: no badge on Files.
    expect(find.byKey(const Key('open-notes')), findsNothing);
    await open(tester, 'alpha.md');
    expect(badge(tester), '1');
    await back(tester);
    // Back on the tree, the note is still open, and Files says so.
    expect(badge(tester), '1');
    await open(tester, 'beta.md');
    expect(badge(tester), '2');
    // One editor at a time on a phone.
    expect(find.byType(NoteView, skipOffstage: false), findsOne);
  });

  testWidgets('the switcher shows every open note and switches', (
    tester,
  ) async {
    await pumpPhone(tester);
    await open(tester, 'alpha.md');
    await back(tester);
    await open(tester, 'beta.md');
    await sheet(tester);
    expect(find.byKey(const Key('open-notes-sheet')), findsOne);
    expect(find.byKey(const Key('open-note-0')), findsOne);
    expect(find.byKey(const Key('open-note-1')), findsOne);
    await tester.tap(find.byKey(const Key('open-note-0')));
    await settle(tester);
    expect(
      tester.widget<NoteView>(find.byType(NoteView)).path,
      endsWith('alpha.md'),
    );
  });

  testWidgets('closing the note on screen shows the next, then the tree', (
    tester,
  ) async {
    await pumpPhone(tester);
    await open(tester, 'alpha.md');
    await back(tester);
    await open(tester, 'beta.md');
    await sheet(tester);
    await tester.tap(find.byKey(const Key('open-note-close-1')));
    await settle(tester);
    // The sheet stays, with one note left.
    expect(find.byKey(const Key('open-note-1')), findsNothing);
    Navigator.of(tester.element(find.byKey(const Key('open-notes-sheet'))))
        .pop();
    await settle(tester);
    expect(
      tester.widget<NoteView>(find.byType(NoteView)).path,
      endsWith('alpha.md'),
    );
    await sheet(tester);
    await tester.tap(find.byKey(const Key('open-note-close-0')));
    await settle(tester);
    expect(find.byType(NoteView), findsNothing);
    expect(controller.workspace.tabs, isEmpty);
  });

  testWidgets('close all empties the list and goes back to the tree', (
    tester,
  ) async {
    await pumpPhone(tester);
    await open(tester, 'alpha.md');
    await back(tester);
    await open(tester, 'beta.md');
    await sheet(tester);
    await tester.tap(find.byKey(const Key('open-notes-close-all')));
    await settle(tester);
    expect(controller.workspace.tabs, isEmpty);
    expect(find.byType(NoteView), findsNothing);
    expect(find.byKey(const Key('open-notes')), findsNothing);
  });
}
