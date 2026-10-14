// #712: where a pointer aims, a template is picked by typing — the
// palette's panel, filtered as you type, the arrows and Enter — and a
// phone keeps the dialog.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/templates/repo.dart';
import 'package:niman/src/ui/template_picker.dart';

void main() {
  const templates = [
    TemplateEntry(path: 'Templates/Meeting.md', name: 'Meeting'),
    TemplateEntry(path: 'Templates/Work/Review.md', name: 'Work/Review'),
    TemplateEntry(path: 'Templates/Work/Retro.md', name: 'Work/Retro'),
  ];

  Future<List<TemplateEntry?>> open(
    WidgetTester tester, {
    required bool dense,
  }) async {
    final picked = <TemplateEntry?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
        ),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => picked.add(
              await showTemplatePicker(
                context,
                templates: templates,
                folder: 'Templates',
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return picked;
  }

  testWidgets('typing filters, the arrows move, Enter picks', (tester) async {
    final picked = await open(tester, dense: true);
    expect(find.byType(SimpleDialog), findsNothing);
    await tester.enterText(find.byKey(const Key('quick-pick-field')), 'work');
    await tester.pump();
    expect(find.text('Meeting'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(picked.single?.name, 'Work/Retro');
  });

  testWidgets('a phone keeps the dialog', (tester) async {
    await open(tester, dense: false);
    expect(find.byType(SimpleDialog), findsOne);
  });
}
