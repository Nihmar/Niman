// Phase 4's first exit criterion (docs/records/unified-surface.md): typing at the
// end of a bold, italic, code, link or maths run produces what a writer
// expects — the character lands *inside* the run, next to what it marks, and
// the run's markers still hold it.
//
// Under approach B the markers are hidden by style and never removed, so the
// run's text and every offset are the note's own; the test exists to prove
// that the zero-size runs really do not shift what a keystroke addresses.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
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

/// One run, where the writer's caret ends up, and what typing there says.
typedef _Case = ({String what, String note, int caret, String expected});

/// The caret a writer reaches by putting it at the end of the run's *text* —
/// just before the first character of the closing marker.
///
/// `at` is the offset of that closing marker.
_Case _case(String what, String note, int at) => (
  what: what,
  note: note,
  caret: at,
  expected: '${note.substring(0, at)}X${note.substring(at)}',
);

final List<_Case> _cases = <_Case>[
  _case('bold', 'a **bold** b\n', 'a **bold'.length),
  _case('italic', 'a *ital* b\n', 'a *ital'.length),
  _case('strikethrough', 'a ~~gone~~ b\n', 'a ~~gone'.length),
  _case('inline code', 'a `code` b\n', 'a `code'.length),
  _case('a link', 'a [text](u) b\n', 'a [text'.length),
  _case('an image', 'a ![alt](u) b\n', 'a ![alt'.length),
  _case('a wikilink', 'a [[target]] b\n', 'a [[target'.length),
  _case(
    'inline maths',
    r'a $x^2$ b'
        '\n',
    r'a $x^2'.length,
  ),
  _case('a heading', '# Titolo\n', '# Titolo'.length),
  _case('a list item', '- voce\n', '- voce'.length),
  _case('a quote', '> voce\n', '> voce'.length),
];

void main() {
  for (final testCase in _cases) {
    testWidgets('typing at the end of ${testCase.what}', (tester) async {
      final buffer = SourceBuffer.fromText(testCase.note);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownSourceView(
              buffer: buffer,
              theme: _theme,
              hideMarkers: true,
              selection: SelectionModel.at(testCase.caret),
            ),
          ),
        ),
      );
      await tester.pump();
      final state = tester.state<MarkdownSourceViewState>(
        find.byType(MarkdownSourceView),
      );
      // The keyboard exists only while the surface has the focus.
      await tester.tap(find.byType(MarkdownSourceView));
      await tester.pump();
      expect(state.isKeyboardAttached, isTrue);

      // The platform's own path: what a real keyboard does, and what the
      // hidden runs must not disturb.
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: testCase.expected,
          selection: TextSelection.collapsed(offset: testCase.caret + 1),
        ),
      );
      await tester.pump();

      expect(
        buffer.text,
        testCase.expected,
        reason: 'the character lands inside the run',
      );
      // And the run's markers are still the note's own characters, at their own
      // offsets: the reveal is a style, so nothing was rewritten.
      expect(
        buffer.text.length,
        testCase.note.length + 1,
        reason: 'one character was typed and nothing else moved',
      );
    });
  }
}
