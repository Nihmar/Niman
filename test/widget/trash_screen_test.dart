// Issue #131: the trash rejoins the family — flat rows like every
// other list, Empty in the app bar instead of a FAB in the create
// corner, and the auto-empty setting reachable from the screen it
// governs.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/trash.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession controller;

  setUp(() async {
    controller = FakeLibrarySession();
    await controller.open('/fake/library', create: true);
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: TrashScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('flat rows, empty in the app bar, no FAB', (tester) async {
    await controller.createNote(parentPath: '', name: 'Gone');
    await controller.ops!.delete('Gone.md');
    await pump(tester);

    // No cards, no floating action button: rows and an app bar action.
    expect(find.byType(Card), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byKey(const Key('empty-trash-action')), findsOneWidget);
    // The app bar names the count and the library it counts for.
    expect(find.text('1 item · Library library'), findsOne);
    // A top-level note was in the library root, not "at" nothing.
    expect(find.textContaining(AppStrings.trashOriginalRoot), findsOneWidget);
  });

  testWidgets('empty keeps its place when there is nothing to empty', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(AppStrings.trashEmpty), findsOne);
    // Disabled, not gone: nothing moves under the thumb between states.
    final button = tester.widget<TextButton>(
      find.byKey(const Key('empty-trash-action')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('the auto-empty footer opens its setting', (tester) async {
    await pump(tester);
    final row = find.byKey(const Key('trash-auto-empty-row'));
    expect(
      find.descendant(
        of: row,
        matching: find.text(AppStrings.trashAutoEmptyValue(0)),
      ),
      findsOne,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trash-auto-empty-setting')), findsOneWidget);
  });
}
