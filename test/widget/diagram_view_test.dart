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

  testWidgets('a diagram wider than the pane is scaled to fit it whole', (
    tester,
  ) async {
    const width = 240.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: MarkdownReadView(
                buffer: SourceBuffer.fromText(
                  '```mermaid\nflowchart LR\n'
                  'A[First step] --> B[Second step] --> C[Third step]'
                  ' --> D[Fourth step]\n```\n',
                ),
                parser: BlockParser(),
                mathCache: MathCache(),
                diagramCache: DiagramCache(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final paint = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is DiagramPainter,
    );
    final painter = tester.widget<CustomPaint>(paint).painter!;
    final drawing = (painter as DiagramPainter).layout.size;
    expect(drawing.width, greaterThan(width));
    // Painted at its own size — not cut to the pane's — and shrunk inside it.
    expect(tester.getSize(paint), drawing);
    expect(tester.getRect(paint).right, lessThanOrEqualTo(width + 0.01));
  });

  testWidgets('the full screen view is drawn on the theme surface', (
    tester,
  ) async {
    await _pump(tester, '```mermaid\nflowchart TD\nA --> B\n```\n');
    await tester.tap(find.byKey(const Key('diagram-full-screen')));
    await tester.pumpAndSettle();
    final context = tester.element(
      find.byKey(const Key('diagram-full-screen-close')),
    );
    final scaffold = tester.widget<Scaffold>(
      find
          .ancestor(
            of: find.byKey(const Key('diagram-full-screen-close')),
            matching: find.byType(Scaffold),
          )
          .first,
    );
    // The diagram's dark lines are drawn for the theme's own surface, not
    // over the near-black barrier, where they would vanish.
    expect(scaffold.backgroundColor, Theme.of(context).colorScheme.surface);
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
