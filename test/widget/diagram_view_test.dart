// A Mermaid fence in the read view (#530): drawn when it parses, and left
// as code with the error when it does not.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_cache.dart';
import 'package:niman/src/diagrams/diagram_painter.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

Future<void> _pump(WidgetTester tester, String document) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownReadView(
          buffer: SourceBuffer.fromText(document),
          parser: BlockParser(),
          mathCache: MathCache(),
          diagramCache: DiagramCache(),
        ),
      ),
    ),
  );
  await tester.pump();
}

Iterable<DiagramPainter> _painters(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((paint) => paint.painter)
    .whereType<DiagramPainter>();

void main() {
  testWidgets('a mermaid fence is drawn as a diagram', (tester) async {
    await _pump(
      tester,
      'Before.\n\n```mermaid\n'
      'flowchart TD\nA[Start] --> B{Ok?}\nB --> C\n```\n',
    );
    expect(_painters(tester), isNotEmpty);
    expect(find.byKey(const Key('diagram-full-screen')), findsOneWidget);
  });

  testWidgets('the full screen button opens the diagram alone', (tester) async {
    await _pump(tester, '```mermaid\nflowchart TD\nA --> B\n```\n');
    await tester.tap(find.byKey(const Key('diagram-full-screen')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('diagram-full-screen-close')), findsOneWidget);
  });

  testWidgets('a syntax error stays source, with the line and message', (
    tester,
  ) async {
    await _pump(tester, '```mermaid\nflowchart TD\nA -- B\n```\n');
    expect(_painters(tester), isEmpty);
    expect(find.textContaining('Line 2:'), findsOneWidget);
    expect(find.textContaining('after "--"'), findsOneWidget);
  });

  testWidgets('a non-mermaid fence stays code', (tester) async {
    await _pump(tester, '```dart\nvoid main() {}\n```\n');
    expect(_painters(tester), isEmpty);
    expect(find.byKey(const Key('diagram-full-screen')), findsNothing);
  });
}
