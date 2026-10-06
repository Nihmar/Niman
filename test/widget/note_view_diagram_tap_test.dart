// A diagram tapped in the read pane is looked at, not written (#530): the
// pane stays the read view. Only `live`, where the source is, shows it on
// a tap.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_painter.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';

Future<void> _tap(WidgetTester tester, String note, Finder target) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NoteView(
          path: '/tmp/niman-diagram-tap-test.md',
          showLineNumbers: true,
          autofocusEditor: false,
          showPreview: true,
          readNote: (_) async => note,
          writeNote: (_, _) async {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(MarkdownReadView), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a tap on a diagram leaves the read pane as it is', (
    tester,
  ) async {
    await _tap(
      tester,
      'Intro\n\n```mermaid\nflowchart TD\nA --> B\n```\n\nEnd\n',
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is DiagramPainter,
      ),
    );
    expect(find.byType(MarkdownReadView), findsOneWidget);
    expect(find.byType(MarkdownSourceView), findsNothing);
  });

  testWidgets('a tap on a parse error leaves it as it is too', (tester) async {
    await _tap(
      tester,
      'Intro\n\n```mermaid\nflowchart TD\nA -- B\n```\n\nEnd\n',
      find.textContaining('Line 2:'),
    );
    expect(find.byType(MarkdownReadView), findsOneWidget);
    expect(find.byType(MarkdownSourceView), findsNothing);
  });
}
