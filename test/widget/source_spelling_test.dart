// The source surface's spelling (#245, phase 3; the legacy editor's T-PP-09):
// a misspelled word of prose is drawn with a wavy underline, code and links
// are not prose, and the underline follows the checker when it changes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/render/squiggle_painter.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';

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

/// A checker whose only misspelling is 'wrold'.
final class _FakeChecker implements SpellChecker {
  const new();

  @override
  bool get available => true;

  @override
  bool isCorrect(String word) => word != 'wrold';

  @override
  List<String> suggest(String word) => const <String>['world'];

  @override
  void dispose() {}
}

/// The words of every line on screen the spelling's squiggle is under.
///
/// The squiggle is painted over the line (`SquigglePainter`), not written
/// into its style, so it is read from the painters and the text they paint
/// over.
List<String> _underlined(WidgetTester tester) => <String>[
  for (final paint in tester.widgetList<CustomPaint>(find.byType(CustomPaint)))
    if (paint.foregroundPainter case final SquigglePainter squiggle)
      for (final range in squiggle.ranges)
        range.textInside(
          tester
              .widget<RichText>(
                find.descendant(
                  of: find.byWidget(paint),
                  matching: find.byType(RichText),
                ),
              )
              .text
              .toPlainText(),
        ),
];

/// Whether some run of a line on screen is [text] struck through.
bool _struck(WidgetTester tester, String text) {
  var found = false;
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    rich.text.visitChildren((span) {
      if (span is TextSpan &&
          span.text == text &&
          (span.style?.decoration?.contains(TextDecoration.lineThrough) ??
              false)) {
        found = true;
      }
      return true;
    });
  }
  return found;
}

/// Which unified mode a body is being run in: the same tests, twice.
enum _Mode { source, live }

Future<void> _pump(
  WidgetTester tester,
  String text,
  EditorSpellCheck check, {
  bool live = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSourceView(
          buffer: SourceBuffer.fromText(text),
          theme: _theme,
          showLineNumbers: false,
          spellCheck: check,
          // The same tests in both unified modes (#246): hiding a marker is a
          // style, and the spelling's skip ranges are read off the tokens, so
          // the underline must not know which mode drew the line.
          hideMarkers: live,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  void both(
    String name,
    Future<void> Function(WidgetTester tester, _Mode mode) body,
  ) {
    for (final mode in _Mode.values) {
      testWidgets('$name (${mode.name})', (tester) => body(tester, mode));
    }
  }

  both('a misspelled word is underlined, and only that word', (
    tester,
    mode,
  ) async {
    final check = EditorSpellCheck(createChecker: (_) => const _FakeChecker());
    addTearDown(check.dispose);
    await _pump(tester, 'hello wrold\n', check, live: mode == _Mode.live);
    expect(_underlined(tester), <String>['wrold']);
  });

  both('a struck-through misspelled word keeps its strike', (
    tester,
    mode,
  ) async {
    // The squiggle used to be the word's style, and a style has one
    // decoration: the strike went, and in `live` — where the strike is all
    // that is left of `~~` — the word read as plain text.
    final check = EditorSpellCheck(createChecker: (_) => const _FakeChecker());
    addTearDown(check.dispose);
    await _pump(tester, 'hello ~~wrold~~\n', check, live: mode == _Mode.live);
    expect(_underlined(tester), <String>['wrold']);
    expect(_struck(tester, 'wrold'), isTrue);
  });

  both('code and links are not prose', (tester, mode) async {
    final check = EditorSpellCheck(createChecker: (_) => const _FakeChecker());
    addTearDown(check.dispose);
    await _pump(
      tester,
      'a `wrold` in code, [wrold](x) linked, and wrold alone\n',
      check,
      live: mode == _Mode.live,
    );
    // Once, for the word alone: the code span and the link are skipped.
    expect(_underlined(tester), <String>['wrold']);
  });

  both('switching the checker off takes the underline away', (
    tester,
    mode,
  ) async {
    final check = EditorSpellCheck(createChecker: (_) => const _FakeChecker());
    addTearDown(check.dispose);
    await _pump(tester, 'hello wrold\n', check, live: mode == _Mode.live);
    expect(_underlined(tester), isNotEmpty);
    check.setEnabled(enabled: false);
    await tester.pump();
    expect(_underlined(tester), isEmpty);
  });
}
