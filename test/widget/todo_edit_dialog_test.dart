// #267: the task description wraps and grows downward, stays a single
// line of the task file, and the dialog is wider on a wide window.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/todo_edit_dialog.dart';

void main() {
  final field = find.byKey(const Key('todo-dialog-field'));

  /// Opens the add dialog in a window [width] wide; the returned getter
  /// reads what it resolved to.
  Future<String? Function()> open(
    WidgetTester tester, {
    double width = 400,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showTodoTaskDialog(
                  context,
                  today: DateTime(2026, 9, 7),
                );
              },
              child: const Text('open dialog'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open dialog'));
    await tester.pumpAndSettle();
    return () => result;
  }

  testWidgets('a long description grows downward', (tester) async {
    await open(tester);
    final oneLine = tester.getSize(field).height;
    await tester.enterText(
      field,
      'call the plumber about the kitchen sink ' * 4,
    );
    await tester.pump();
    expect(tester.getSize(field).height, greaterThan(oneLine * 1.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('it grows only so far, then scrolls inside itself', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(field, 'word ' * 400);
    await tester.pump();
    final editable = tester.widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );
    expect(editable.maxLines, 6);
  });

  testWidgets('Enter saves rather than breaking the line', (tester) async {
    final result = await open(tester);
    await tester.enterText(field, 'water the plants');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(result(), '2026-09-07 water the plants');
  });

  testWidgets('a line break that comes in becomes a space', (tester) async {
    final result = await open(tester);
    await tester.enterText(field, 'first\nsecond');
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, 'first second');
    await tester.tap(find.byKey(const Key('todo-dialog-save')));
    await tester.pumpAndSettle();
    expect(result(), '2026-09-07 first second');
  });

  testWidgets('a wide window gives the dialog more width', (tester) async {
    await open(tester, width: 1200);
    final wide = tester.getSize(find.byType(AlertDialog)).width;
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await open(tester);
    final narrow = tester.getSize(find.byType(AlertDialog)).width;
    expect(wide, greaterThan(narrow + 100));
    expect(narrow, lessThanOrEqualTo(400));
  });
}
