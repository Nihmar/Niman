// Ctrl+click on a link in the source surface (#245, phase 3; the legacy
// editor's T-M3-07): the link opens, a plain click stays a click.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';
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

/// Which unified mode a body is being run in: the same tests, twice.
enum _Mode { source, live }

/// Column [column] of line [line], as the view lays the text out (14 px a
/// glyph, a 5 px inset, an 8 px top margin, 21 px rows).
Offset _at(int line, int column) =>
    Offset(5 + column * 14.0 + 7, 8 + line * 21.0 + 10);

/// The visual column of a buffer offset, which is the offset itself in
/// `source` and the offset minus the markers hidden before it in `live` — a
/// hidden marker is a style and takes no room, so the text is drawn shifted
/// left by exactly those characters. The fixture hides `[[` and `]]` (4) before
/// `La nota`, and those plus the `[` of the Markdown link (5) before `il sito`.
Offset _atOffset(_Mode mode, int offset) =>
    _at(0, mode == _Mode.live ? offset - _hiddenBefore(offset) : offset);

int _hiddenBefore(int offset) => switch (offset) {
  // The space inside `[[La nota]]`.
  9 => 2,
  // The space inside `[il sito](…)`.
  22 => 5,
  _ => 0,
};

/// The links opened, as the surface reports them.
final List<(TokenKind, String)> _opened = <(TokenKind, String)>[];

Future<MarkdownSourceViewState> _pump(
  WidgetTester tester,
  String text,
  _Mode mode,
) async {
  _opened.clear();
  tester.view.physicalSize = const Size(900, 500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSourceView(
          buffer: SourceBuffer.fromText(text),
          theme: _theme,
          showLineNumbers: false,
          hideMarkers: mode == _Mode.live,
          onOpenLink: (kind, raw) => _opened.add((kind, raw)),
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));
}

Future<void> _click(
  WidgetTester tester,
  Offset at, {
  bool control = false,
}) async {
  if (control) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.tapAt(at, kind: PointerDeviceKind.mouse);
  if (control) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

void main() {
  const note = 'vedi [[La nota]] e [il sito](https://example.com) ora';

  /// The same test in `source` and in `live` (#246): the link is the same run
  /// of the same text, hidden markers or not, so a Ctrl+click on it must land
  /// and open the same thing.
  void both(
    String name,
    Future<void> Function(WidgetTester tester, _Mode mode) body,
  ) {
    for (final mode in _Mode.values) {
      testWidgets('$name (${mode.name})', (tester) => body(tester, mode));
    }
  }

  both('Ctrl+click on a wikilink opens it', (tester, mode) async {
    final state = await _pump(tester, note, mode);
    await _click(tester, _atOffset(mode, 9), control: true);
    expect(_opened, <(TokenKind, String)>[(TokenKind.wikilink, '[[La nota]]')]);
    expect(state.selection.extent, 9, reason: 'the caret went there too');
  });

  both('Ctrl+click on a Markdown link opens it', (tester, mode) async {
    await _pump(tester, note, mode);
    await _click(tester, _atOffset(mode, 22), control: true);
    expect(_opened, <(TokenKind, String)>[
      (TokenKind.link, '[il sito](https://example.com)'),
    ]);
  });

  both('a plain click on a link only places the caret', (tester, mode) async {
    final state = await _pump(tester, note, mode);
    await _click(tester, _atOffset(mode, 9));
    expect(_opened, isEmpty);
    expect(state.selection.extent, 9);
  });

  both('Ctrl+click on plain text opens nothing', (tester, mode) async {
    await _pump(tester, note, mode);
    await _click(tester, _atOffset(mode, 1), control: true);
    expect(_opened, isEmpty);
  });
}
