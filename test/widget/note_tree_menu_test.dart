// A right click on a tree row opens the row's menu and not the tree's own,
// however long the button is held: a press held past the tap's deadline is
// told to every detector still in the running, and the tree's background
// opened its menu under the row's (0.0.9 test round).
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/tree.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession session;

  setUp(() => session = FakeLibrarySession());
  tearDown(() async {
    await session.close();
    await session.dispose();
  });

  Future<List<String>> rightClick(
    WidgetTester tester,
    Offset Function() at, {
    required Duration hold,
  }) async {
    final calls = <String>[];
    await session.open('/lib', create: false);
    await session.createNote(parentPath: '', name: 'nota', content: 'x');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteTree(
            controller: session,
            selectedPath: null,
            expanded: const <String>{},
            onToggle: (_) {},
            onSelect: (_) {},
            onSecondaryTapDown: (note, _) => calls.add('row ${note.path}'),
            onBackgroundSecondaryTapUp: (_) => calls.add('background'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final press = await tester.startGesture(
      at(),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await tester.pump(hold);
    await press.up();
    await tester.pump();
    return calls;
  }

  for (final hold in [Duration.zero, const Duration(milliseconds: 300)]) {
    testWidgets('on a row, held ${hold.inMilliseconds} ms: the row alone', (
      tester,
    ) async {
      final calls = await rightClick(
        tester,
        () => tester.getCenter(find.text('nota.md')),
        hold: hold,
      );
      expect(calls, <String>['row nota.md']);
    });
  }

  testWidgets("below the rows: the tree's own", (tester) async {
    final calls = await rightClick(
      tester,
      () => tester.getBottomLeft(find.byType(NoteTree)) + const Offset(40, -40),
      hold: const Duration(milliseconds: 300),
    );
    expect(calls, <String>['background']);
  });
}
