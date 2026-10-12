// The tree's keyboard walk in the shell (#727): F2 renames the row the
// cursor is on — not the one selected — in place, Delete takes that row to
// the trash, and the walk lets go while the grid holds the pane.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';

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

  Future<void> openShell(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(1400, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(session)],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    for (final name in ['alpha', 'bravo']) {
      await session.createNote(parentPath: '', name: name);
    }
    await settle(tester);
  }

  /// Whether the keyboard's ring is drawn on the tree row showing [name].
  bool ringOn(WidgetTester tester, String name) {
    final row = find
        .ancestor(of: noteRow(name), matching: find.byType(Container))
        .first;
    final decoration = tester.widget<Container>(row).foregroundDecoration;
    return decoration is BoxDecoration && decoration.border != null;
  }

  testWidgets("F2 renames the cursor's row, not the selected one", (
    tester,
  ) async {
    await openShell(tester);
    // The cursor moves off the selection: a click selects alpha, the arrow
    // walks to bravo.
    await tester.tap(noteRow('alpha.md'));
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
    await tester.tap(noteRow('alpha.md'));
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
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);

    await tester.tap(find.byKey(const Key('view-grid-toggle')));
    await settle(tester);
    // Offstage, the tree must not walk the rows nobody is looking at.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await settle(tester);
    await tester.tap(find.byKey(const Key('view-list-toggle')));
    await settle(tester);

    expect(ringOn(tester, 'bravo.md'), isFalse);
    expect(ringOn(tester, 'alpha.md'), isFalse);
  });
}
