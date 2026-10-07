// #541: a code block has a button that copies its code, in the read view and
// in `live`, at the top right of the part of the block on screen — a block
// taller than the pane has it wherever it is scrolled to.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

const MarkdownTheme _theme = MarkdownTheme(
  body: TextStyle(fontSize: 14, height: 1.5),
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

/// A paragraph, then a fence of [lines] lines of code, then a paragraph.
String _note(int lines) => [
  'Before.',
  '',
  '```dart',
  for (var at = 0; at < lines; at++) 'line $at;',
  '```',
  '',
  'After.',
].join('\n');

/// What the app put on the clipboard, as it is put there.
List<String> _clipboard(WidgetTester tester) {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return copied;
}

Future<void> _read(WidgetTester tester, String text) async {
  tester.view.physicalSize = const Size(500, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownReadView(
          buffer: SourceBuffer.fromText(text),
          parser: ReadParser(),
          mathCache: MathCache(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _live(WidgetTester tester, String text) async {
  tester.view.physicalSize = const Size(500, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSourceView(
          buffer: SourceBuffer.fromText(text),
          theme: _theme,
          showLineNumbers: false,
          hideMarkers: true,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final Finder _button = find.byKey(const Key('code-copy'));

void main() {
  testWidgets('the read view copies a code block', (tester) async {
    final copied = _clipboard(tester);
    await _read(tester, _note(3));
    expect(_button, findsOneWidget);
    await tester.tap(_button);
    await tester.pump();
    expect(copied, ['line 0;\nline 1;\nline 2;']);
    // A tick says it is done, then the button is back.
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
  });

  testWidgets('down a tall block, the read view keeps the button on screen', (
    tester,
  ) async {
    await _read(tester, _note(80));
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(600);
    await tester.pumpAndSettle();
    final pane = tester.getRect(find.byType(Scrollable).first);
    final button = tester.getRect(_button);
    expect(button.top, greaterThanOrEqualTo(pane.top));
    expect(button.top, lessThan(pane.top + 20));
  });

  testWidgets('a block drawn in pieces copies whole from any of them', (
    tester,
  ) async {
    final copied = _clipboard(tester);
    await _read(tester, _note(450));
    await tester.tap(_button.first);
    await tester.pump();
    expect(copied.single.split('\n'), [
      for (var at = 0; at < 450; at++) 'line $at;',
    ]);
  });

  testWidgets('live copies a code block', (tester) async {
    final copied = _clipboard(tester);
    await _live(tester, _note(3));
    expect(_button, findsOneWidget);
    await tester.tap(_button);
    await tester.pump();
    expect(copied, ['line 0;\nline 1;\nline 2;']);
  });

  testWidgets('down a tall block, live keeps the button on screen', (
    tester,
  ) async {
    await _live(tester, _note(80));
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(600);
    await tester.pumpAndSettle();
    final pane = tester.getRect(find.byType(Scrollable).first);
    final button = tester.getRect(_button);
    expect(button.top, greaterThanOrEqualTo(pane.top));
    expect(button.top, lessThan(pane.top + 20));
  });

  testWidgets('a block scrolled away takes its button with it', (tester) async {
    await _live(tester, '${_note(3)}\n\n${'Prose.\n\n' * 60}');
    expect(_button, findsOneWidget);
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(800);
    await tester.pumpAndSettle();
    expect(_button, findsNothing);
  });
}
