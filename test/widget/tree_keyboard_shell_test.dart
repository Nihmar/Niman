// The tree's keyboard walk in the shell (#727): a click on a folder takes
// the keys and the walk goes on from there; a click on a note opens it and
// asks its editor for the caret, so you can write; F2 renames the row the
// cursor is on — not the one selected — in place, Delete takes that row to
// the trash, and the walk lets go while the grid holds the pane.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/note_view.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession session;
  late FakeFilePicker filePicker;

  final desktop = TargetPlatformVariant.only(TargetPlatform.linux);

  setUp(() {
    session = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });
  tearDown(() async {
    await session.close();
    await session.dispose();
  });

  Future<void> openShell(
    WidgetTester tester, {
    Size size = const Size(1400, 900),
  }) async {
    setSurfaceSize(tester, size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(session)],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    // A folder to take the keys with: folders lead the rows, so it sits
    // above the notes the walk reaches.
    await session.createFolder(parentPath: '', name: 'Zulu');
    for (final name in ['alpha', 'bravo']) {
      await session.createNote(parentPath: '', name: name);
    }
    await settle(tester);
  }

  /// The note view showing the note at [path].
  NoteView noteView(WidgetTester tester, String path) =>
      tester.widget<NoteView>(
        find.byWidgetPredicate(
          (w) => w is NoteView && w.path.endsWith(path),
          skipOffstage: false,
        ),
      );

  /// Whether the keyboard's ring is drawn on the tree row showing [name].
  bool ringOn(WidgetTester tester, String name) {
    final row = find
        .ancestor(of: noteRow(name), matching: find.byType(Container))
        .first;
    final decoration = tester.widget<Container>(row).foregroundDecoration;
    return decoration is BoxDecoration && decoration.border != null;
  }

  testWidgets('a click on a note asks its editor for the caret', (
    tester,
  ) async {
    await openShell(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);

    // The note view takes the caret when the number moves (#727): that is
    // what lets you write in the note you just clicked.
    expect(noteView(tester, 'alpha.md').caretRequest, 1);
  }, variant: desktop);

  testWidgets('a phone leaves the caret to the keyboard-on-open setting', (
    tester,
  ) async {
    // On a phone the tap that opens a note is also what raises the IME,
    // and the setting decides — so nothing is asked for here.
    await openShell(tester, size: const Size(390, 844));
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);

    expect(noteView(tester, 'alpha.md').caretRequest, 0);
  });

  testWidgets("F2 renames the cursor's row, not the selected one", (
    tester,
  ) async {
    await openShell(tester);
    // The folder's click takes the keys; the arrows walk off it.
    await tester.tap(noteRow('Zulu'));
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await settle(tester);

    final field = find.byKey(const Key('tree-rename-field'));
    expect(field, findsOne, reason: 'in place, on the cursor');
    expect(tester.widget<TextField>(field).controller!.text, 'bravo.md');
  }, variant: desktop);

  testWidgets("Delete takes the cursor's row to the trash", (tester) async {
    await openShell(tester);
    await tester.tap(noteRow('Zulu'));
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await settle(tester);

    expect(await session.find('bravo.md'), isNull);
    expect(await session.find('alpha.md'), isNotNull);
  }, variant: desktop);

  testWidgets('the walk lets go while the grid holds the pane', (tester) async {
    await openShell(tester);
    await tester.tap(noteRow('Zulu'));
    await settle(tester);

    await tester.tap(find.byKey(const Key('view-grid-toggle')));
    await settle(tester);
    // Offstage, the tree must not walk the rows nobody is looking at.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await settle(tester);
    await tester.tap(find.byKey(const Key('view-list-toggle')));
    await settle(tester);

    expect(ringOn(tester, 'bravo.md'), isFalse);
    expect(ringOn(tester, 'Zulu'), isFalse);
  });
}
