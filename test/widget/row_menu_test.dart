// The tree row's long-press sheet: what it says it acts on, and the
// order its entries come in.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
  });

  Future<void> pumpLibrary(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(controller)],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
  }

  /// The vertical position of a menu row, laid out whether or not the
  /// sheet has scrolled it into view.
  double top(WidgetTester tester, String key) =>
      tester.getTopLeft(find.byKey(Key(key))).dy;

  testWidgets('the sheet names the row it was opened from', (tester) async {
    await pumpLibrary(tester);
    await controller.createFolder(parentPath: '', name: 'Books');
    await controller.createNote(parentPath: 'Books', name: 'Nested');
    await settle(tester);
    await tester.tap(noteRow('Books', offstage: true));
    await settle(tester);

    await tester.longPress(noteRow('Nested.md', offstage: true));
    await settle(tester);

    final header = find.byKey(const Key('row-menu-header'));
    expect(header, findsOneWidget);
    expect(
      find.descendant(of: header, matching: find.text('Nested.md')),
      findsOneWidget,
    );
    // The folder it sits in, so a long press one row off is visible as
    // such instead of looking exactly like one that landed right.
    expect(
      find.descendant(of: header, matching: find.text('Books')),
      findsOneWidget,
    );
  });

  testWidgets('a note at the library root says so', (tester) async {
    await pumpLibrary(tester);
    await controller.createNote(parentPath: '', name: 'Loose');
    await settle(tester);

    await tester.longPress(noteRow('Loose.md'));
    await settle(tester);

    expect(
      find.descendant(
        of: find.byKey(const Key('row-menu-header')),
        matching: find.text('Library root'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('on a note, creating is demoted and deleting is last', (
    tester,
  ) async {
    await pumpLibrary(tester);
    await controller.createNote(parentPath: '', name: 'Note');
    await settle(tester);

    await tester.longPress(noteRow('Note.md'));
    await settle(tester);

    // What the note is, then what the file is, then what to make beside
    // it — "here" on a note only ever meant "in the folder it happens to
    // be in" — and the destructive one alone at the bottom.
    expect(
      top(tester, 'menu-quick-note'),
      lessThan(top(tester, 'menu-rename')),
    );
    expect(top(tester, 'menu-rename'), lessThan(top(tester, 'menu-new-note')));
    expect(top(tester, 'menu-new-note'), lessThan(top(tester, 'menu-delete')));

    // And it says which folder it means.
    expect(find.text('New note in the same folder'), findsOneWidget);
    expect(find.text('New note here'), findsNothing);
  });

  testWidgets('on a folder, creating comes first', (tester) async {
    await pumpLibrary(tester);
    await controller.createFolder(parentPath: '', name: 'Books');
    await settle(tester);

    await tester.longPress(noteRow('Books'));
    await settle(tester);

    // Here "here" means inside this folder, which is most of why the
    // menu is opened at all.
    expect(top(tester, 'menu-new-note'), lessThan(top(tester, 'menu-rename')));
    expect(top(tester, 'menu-rename'), lessThan(top(tester, 'menu-delete')));
    // Here "here" is the folder itself, and says so.
    expect(find.text('New note here'), findsOneWidget);
    // A folder has no quick note, no widget pin and no history.
    expect(find.byKey(const Key('menu-quick-note')), findsNothing);
    expect(find.byKey(const Key('menu-history')), findsNothing);
  });

  testWidgets('deleting is marked as the destructive one', (tester) async {
    await pumpLibrary(tester);
    await controller.createNote(parentPath: '', name: 'Note');
    await settle(tester);

    await tester.longPress(noteRow('Note.md'));
    await settle(tester);

    final tile = tester.widget<ListTile>(find.byKey(const Key('menu-delete')));
    final scheme = Theme.of(
      tester.element(find.byKey(const Key('menu-delete'))),
    ).colorScheme;
    expect(tile.textColor, scheme.error);
    expect(tile.iconColor, scheme.error);
    // And nothing else is.
    final rename = tester.widget<ListTile>(
      find.byKey(const Key('menu-rename')),
    );
    expect(rename.textColor, isNull);
  });
}
