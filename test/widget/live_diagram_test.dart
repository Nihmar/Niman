// A Mermaid fence in `live` (#530): drawn while the caret is out of it, its
// source again while the caret is in it.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_painter.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/preview/math_cache.dart';

const MarkdownTheme _theme = MarkdownTheme(
  body: TextStyle(fontSize: 14, height: 1.5, fontFamily: 'monospace'),
  heading1: TextStyle(fontSize: 25),
  heading2: TextStyle(fontSize: 21),
  heading3: TextStyle(fontSize: 18),
  heading4: TextStyle(fontSize: 16),
  heading5: TextStyle(fontSize: 14),
  heading6: TextStyle(fontSize: 13),
  code: TextStyle(fontSize: 14, fontFamily: 'monospace'),
  quote: TextStyle(fontSize: 14),
  tableCell: TextStyle(fontSize: 14),
  tableHeader: TextStyle(fontSize: 14),
  link: TextStyle(fontSize: 14),
  wikilink: TextStyle(fontSize: 14),
  tag: TextStyle(fontSize: 14),
  marker: TextStyle(fontSize: 14),
  codeHighlight: <String, TextStyle>{},
  rule: Color(0xFF888888),
  codeBackground: Color(0xFFEEEEEE),
  quoteBar: Color(0xFFCCCCCC),
  tableBorder: Color(0xFFCCCCCC),
  markerDim: Color(0xFF999999),
  blockSpacing: 10,
  listIndentPerLevel: 22,
  quoteIndentPerLevel: 12,
  codePadding: 8,
  quoteBarWidth: 3,
  ruleThickness: 1,
  tableCellPadding: EdgeInsets.all(4),
  lineHeight: 21,
);

const String _note = '```mermaid\nflowchart TD\nA[Start] --> B\n```\n\ntail\n';

Iterable<DiagramPainter> _painters(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((paint) => paint.painter)
    .whereType<DiagramPainter>();

Future<MarkdownSurfaceController> _pumpLive(
  WidgetTester tester,
  String note,
) async {
  final buffer = SourceBuffer.fromText(note);
  final surface = MarkdownSurfaceController(buffer, caret: note.length);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSurface(
          buffer: buffer,
          mode: MarkdownSurfaceMode.live,
          theme: _theme,
          showLineNumbers: false,
          mathCache: MathCache(),
          surface: surface,
        ),
      ),
    ),
  );
  await tester.pump();
  return surface;
}

void main() {
  testWidgets('a click on the full screen button opens the diagram alone', (
    tester,
  ) async {
    // A mouse places the caret as it goes down: on the button that would
    // reveal the source and take the button away before it is let go.
    final surface = await _pumpLive(tester, _note);
    await tester.tap(
      find.byKey(const Key('diagram-full-screen')),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('diagram-full-screen-close')), findsOneWidget);
    expect(surface.selection.caret, _note.length);
  });

  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets('a tap on a parse error puts the caret on its line ($kind)', (
      tester,
    ) async {
      const note = '```mermaid\nflowchart TD\nA -- B\n```\n\ntail\n';
      final surface = await _pumpLive(tester, note);
      await tester.tap(find.textContaining('Line 2:'), kind: kind);
      await tester.pump();
      // The fence content's second line, the one the error names.
      expect(surface.selection.caret, note.indexOf('A -- B'));
    });
  }

  testWidgets('the diagram is drawn while the caret is out of the fence', (
    tester,
  ) async {
    final buffer = SourceBuffer.fromText(_note);
    final surface = MarkdownSurfaceController(buffer, caret: _note.length);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSurface(
            buffer: buffer,
            mode: MarkdownSurfaceMode.live,
            theme: _theme,
            showLineNumbers: false,
            mathCache: MathCache(),
            surface: surface,
          ),
        ),
      ),
    );
    await tester.pump();

    // The caret at the end of the note, well out of the fence.
    expect(_painters(tester), isNotEmpty);

    // The caret back in the fence: its source, no diagram.
    surface.placeCaret(13);
    await tester.pump();
    expect(_painters(tester), isEmpty);
    expect(find.textContaining('flowchart TD'), findsWidgets);
  });
}
