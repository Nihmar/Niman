// What the reader says about a place of a PDF or a book (#284), asked
// over the file: a sheet on a phone, a dialog on a wide window.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/annotation_sheet.dart';

void main() {
  /// What the sheet answers, once it closes.
  late Future<String?> answer;

  Future<void> open(
    WidgetTester tester, {
    required Size size,
    String quote = 'The spice must flow.',
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => answer = showAnnotationSheet(
                context,
                label: 'Dune, p. 34',
                quote: quote,
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  testWidgets('on a phone, a sheet: the place, the passage, the comment', (
    tester,
  ) async {
    await open(tester, size: const Size(400, 800));
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.textContaining('Dune, p. 34'), findsOneWidget);
    expect(find.text('The spice must flow.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('annotation-comment')),
      '  Remember this.  ',
    );
    await tester.tap(find.byKey(const Key('annotation-save')));
    await tester.pumpAndSettle();
    expect(await answer, 'Remember this.');
  });

  testWidgets('on a wide window, a dialog; cancelled, no comment', (
    tester,
  ) async {
    await open(tester, size: const Size(1200, 800), quote: '');
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byKey(const Key('annotation-quote')), findsNothing);
    await tester.tap(find.byKey(const Key('annotation-cancel')));
    await tester.pumpAndSettle();
    expect(await answer, isNull);
  });

  testWidgets('an empty comment still annotates', (tester) async {
    await open(tester, size: const Size(400, 800));
    await tester.tap(find.byKey(const Key('annotation-save')));
    await tester.pumpAndSettle();
    expect(await answer, '');
  });
}
