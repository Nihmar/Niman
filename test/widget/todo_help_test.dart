// T-TD-08: the task dialog writes the todo.txt syntax, so the format is
// easy to never see -- until the file is opened in another editor. The
// reference is one tap from the list, on both layouts.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/todo_help.dart';

void main() {
  Future<void> pumpHelp(WidgetTester tester) async {
    // Tall surface so the whole reference is laid out: the list builds
    // lazily, and most of the syntax sits below a phone-sized fold.
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: TodoHelpScreen()));
    await tester.pump();
  }

  testWidgets('explains the two files and the line anatomy', (tester) async {
    await pumpHelp(tester);
    expect(find.textContaining('todo.txt'), findsWidgets);
    expect(find.textContaining('done.txt'), findsOne);
    expect(find.text('(A) to (Z)'), findsOne);
  });

  testWidgets('documents every token and tag Niman reads', (tester) async {
    await pumpHelp(tester);
    for (final syntax in <String>[
      '+project',
      '@context',
      '#tag',
      'due:2026-09-09',
      'rem:2026-09-08T14:30',
    ]) {
      expect(find.text(syntax), findsOne, reason: syntax);
    }
  });

  testWidgets('says which tags are kept but not acted on', (tester) async {
    // Promising recurrence the parser does not implement would be worse
    // than staying quiet about it.
    await pumpHelp(tester);
    expect(find.text('anything:else'), findsOne);
    expect(find.textContaining('rec:'), findsOne);
  });
}
