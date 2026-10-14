// #712: where a pointer aims, a missing note's question is a menu at the
// click, not a dialog; a phone keeps the dialog.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/missing_note_dialog.dart';

void main() {
  Future<bool?> ask(WidgetTester tester, {required bool dense}) async {
    bool? answer;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
        ),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              answer = await showMissingNoteDialog(
                context,
                path: 'Notes/Foo.md',
                anchor: const Rect.fromLTWH(100, 100, 0, 0),
              );
            },
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return answer;
  }

  testWidgets('a pointer gets a menu with Create', (tester) async {
    await ask(tester, dense: true);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('Notes/Foo.md'), findsOne);
    await tester.tap(find.byKey(const Key('missing-note-create')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('missing-note-create')), findsNothing);
  });

  testWidgets('a phone keeps the dialog', (tester) async {
    await ask(tester, dense: false);
    expect(find.byType(AlertDialog), findsOne);
  });
}
