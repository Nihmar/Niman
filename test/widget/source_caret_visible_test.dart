// The caret is always whole on screen (the bottom of the note, desktop): a
// line the writer reaches by typing, Enter, the arrows, PageDown or Ctrl+End
// is scrolled into the viewport with its whole line box, in `source` and in
// `live`, whatever the reveal measured before the edit's layout.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';

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

Future<MarkdownSourceViewState> _pump(
  WidgetTester tester,
  String text, {
  required bool live,
}) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSourceView(
          buffer: SourceBuffer.fromText(text),
          theme: _theme,
          showLineNumbers: false,
          hideMarkers: live,
        ),
      ),
    ),
  );
  await tester.pump();
  final state = tester.state<MarkdownSourceViewState>(
    find.byType(MarkdownSourceView),
  );
  await tester.tap(find.byType(MarkdownSourceView));
  await tester.pump();
  expect(state.isKeyboardAttached, isTrue);
  return state;
}

/// The frames that follow an action, the way a running app draws them.
Future<void> _settle(WidgetTester tester) async {
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// The caret is whole inside the viewport: its rectangle, top to bottom.
void _wholeCaret(WidgetTester tester, MarkdownSourceViewState state) {
  final caret = state.caretRect;
  expect(caret, isNotNull);
  final viewport = tester.getRect(find.byType(Scrollable).first);
  expect(
    caret!.top,
    greaterThanOrEqualTo(viewport.top - 0.5),
    reason: 'caret $caret, viewport $viewport',
  );
  expect(
    caret.bottom,
    lessThanOrEqualTo(viewport.bottom + 0.5),
    reason: 'caret $caret, viewport $viewport',
  );
}

/// Types [text] at the caret through the platform's own path.
Future<void> _type(
  WidgetTester tester,
  MarkdownSourceViewState state,
  String text,
) async {
  final buffer = state.widget.buffer;
  final at = state.selection.extent;
  expect(state.platformWindowStart, 0);
  tester.testTextInput.updateEditingValue(
    TextEditingValue(
      text: buffer.text.replaceRange(at, at, text),
      selection: TextSelection.collapsed(offset: at + text.length),
    ),
  );
  await _settle(tester);
}

void main() {
  final note = [for (var i = 0; i < 80; i++) 'line $i'].join('\n');
  for (final live in [false, true]) {
    final mode = live ? 'live' : 'source';
    group(mode, () {
      /// The caret at the end of the last line the viewport shows whole.
      Future<MarkdownSourceViewState> lastVisible(WidgetTester tester) async {
        final state = await _pump(tester, note, live: live);
        final viewport = tester.getRect(find.byType(Scrollable).first);
        var line = 0;
        for (var i = 0; i < 80; i++) {
          final box = tester.getRect(find.text('line $i').first);
          if (box.bottom > viewport.bottom - 8) break;
          line = i;
        }
        state.placeCaret(
          state.widget.buffer.offsetOfLine(line) +
              state.widget.buffer.lineLengthAt(line),
        );
        await _settle(tester);
        return state;
      }

      testWidgets('Enter on the last visible line', (tester) async {
        final state = await lastVisible(tester);
        for (var i = 0; i < 5; i++) {
          await _type(tester, state, '\n');
          _wholeCaret(tester, state);
        }
      });

      testWidgets('typing that wraps onto a new row', (tester) async {
        final state = await lastVisible(tester);
        await _type(tester, state, List.filled(60, 'wrapping').join(' '));
        _wholeCaret(tester, state);
      });

      testWidgets('ArrowDown past the viewport', (tester) async {
        final state = await lastVisible(tester);
        for (var i = 0; i < 5; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await _settle(tester);
          _wholeCaret(tester, state);
        }
      });

      testWidgets('PageDown', (tester) async {
        final state = await lastVisible(tester);
        for (var i = 0; i < 3; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
          await _settle(tester);
          _wholeCaret(tester, state);
        }
      });

      testWidgets('Ctrl+End', (tester) async {
        final state = await _pump(tester, note, live: live);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await _settle(tester);
        _wholeCaret(tester, state);
      });

      testWidgets('Enter at the end of the note', (tester) async {
        final state = await _pump(tester, note, live: live);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await _settle(tester);
        for (var i = 0; i < 4; i++) {
          await _type(tester, state, '\n');
          _wholeCaret(tester, state);
        }
      });

      testWidgets('a click on the row the pane cuts', (tester) async {
        final state = await _pump(tester, note, live: live);
        state.jumpToOffset(10.5);
        await _settle(tester);
        await tester.tapAt(const Offset(200, 799));
        await _settle(tester);
        _wholeCaret(tester, state);
      });

      testWidgets('blocks of different heights at the end', (tester) async {
        const tail =
            '\n\n## Heading\n\n- one\n- two\n\n> quote\n\n'
            '```dart\ncode\n```\n\n'
            r'$$x^2$$'
            '\n\nlast';
        final state = await _pump(tester, '$note$tail', live: live);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await _settle(tester);
        _wholeCaret(tester, state);
        for (final typed in ['\n# Title', '\n- item', '\n\n> quoted']) {
          await _type(tester, state, typed);
          _wholeCaret(tester, state);
        }
      });

      testWidgets('a tall last line', (tester) async {
        final state = await _pump(tester, '$note\n\n# Heading', live: live);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await _settle(tester);
        _wholeCaret(tester, state);
        await _type(tester, state, '\n# Another');
        _wholeCaret(tester, state);
      });
    });
  }
}
