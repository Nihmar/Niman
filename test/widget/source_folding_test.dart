// Folding on the source surface (#245, phase 3; the legacy editor's
// T-M2-07): a heading's arrow folds its section away, the rows close up, and
// the caret is never left on a line nobody can see.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
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

/// Two sections, the second with a subsection.
const String _note =
    '# Uno\nprima riga\nseconda riga\nterza riga\n'
    '# Due\nsotto due\n## Due.a\nsotto due.a\naltro due.a\n'
    '# Tre\nfine';

/// Which unified mode a body is being run in: the same tests, twice.
enum _Mode { source, live }

Future<MarkdownSourceViewState> _pump(
  WidgetTester tester, {
  bool live = false,
}) async {
  tester.view.physicalSize = const Size(700, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSourceView(
          buffer: SourceBuffer.fromText(_note),
          theme: _theme,
          // Folding draws rows, and the mode only decides whether a marker is
          // hidden: the section arrows and what they fold are the same in both.
          hideMarkers: live,
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));
}

/// Whether a line with [text] is drawn.
bool _drawn(String text) =>
    find.text(text, findRichText: true).evaluate().isNotEmpty;

void main() {
  /// The same test in `source` and in `live` (#246).
  void both(
    String name,
    Future<void> Function(WidgetTester tester, _Mode mode) body,
  ) {
    for (final mode in _Mode.values) {
      testWidgets('$name (${mode.name})', (tester) => body(tester, mode));
    }
  }

  both('a heading with a section has an arrow, a line has none', (
    tester,
    mode,
  ) async {
    await _pump(tester, live: mode == _Mode.live);
    expect(find.byKey(const ValueKey<String>('fold-0')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('fold-4')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('fold-1')), findsNothing);
    // One line under it is not a section worth folding.
    expect(find.byKey(const ValueKey<String>('fold-9')), findsNothing);
  });

  both('the arrow folds the section, and folds it back', (tester, mode) async {
    final state = await _pump(tester, live: mode == _Mode.live);
    await tester.tap(find.byKey(const ValueKey<String>('fold-0')));
    await tester.pump();
    expect(state.isFolded(0), isTrue);
    expect(_drawn('prima riga'), isFalse);
    expect(_drawn('terza riga'), isFalse);
    expect(_drawn('# Due'), isTrue);
    // The next heading's row is right under the folded one.
    // The two headings are adjacent rows, whatever height a row is: in `live`
    // a heading is drawn at the heading's own size, so a constant here would
    // be an assertion about the typography rather than about the fold.
    final uno = tester.getRect(find.text('# Uno', findRichText: true));
    final due = tester.getRect(find.text('# Due', findRichText: true));
    expect(due.top - uno.top, closeTo(uno.height, 1));
    expect(state.selection.extent, 0, reason: 'the arrow moved no caret');

    await tester.tap(find.byKey(const ValueKey<String>('fold-0')));
    await tester.pump();
    expect(state.isFolded(0), isFalse);
    expect(_drawn('prima riga'), isTrue);
  });

  both('a section runs to the next heading of its level or above', (
    tester,
    mode,
  ) async {
    final state = await _pump(tester, live: mode == _Mode.live);
    state.toggleFold(4);
    await tester.pump();
    expect(_drawn('sotto due'), isFalse);
    expect(_drawn('## Due.a'), isFalse, reason: 'a subsection is inside');
    expect(_drawn('# Tre'), isTrue);
  });

  both('folding the caret away puts it on the heading', (tester, mode) async {
    final state = await _pump(tester, live: mode == _Mode.live);
    state
      ..placeCaret(_note.indexOf('seconda'))
      ..toggleFold(0);
    await tester.pump();
    expect(state.selection.extent, '# Uno'.length);
  });

  both('a caret that goes into a folded section opens it', (
    tester,
    mode,
  ) async {
    final state = await _pump(tester, live: mode == _Mode.live);
    state.toggleFold(0);
    await tester.pump();
    state
      ..placeCaret('# Uno'.length)
      ..moveCaretBy(CaretMotion.characterRight);
    await tester.pump();
    expect(state.isFolded(0), isFalse);
    expect(_drawn('prima riga'), isTrue);
  });

  both('an edit above a fold keeps it folded', (tester, mode) async {
    final state = await _pump(tester, live: mode == _Mode.live);
    state.toggleFold(4);
    await tester.pump();
    state
      ..placeCaret(0)
      ..replaceText(0, 0, 'nuova\n');
    await tester.pump();
    expect(state.isFolded(5), isTrue);
    expect(_drawn('sotto due'), isFalse);
    expect(_drawn('nuova'), isTrue);
  });

  both('a tap below a fold lands on the line that is drawn there', (
    tester,
    mode,
  ) async {
    final state = await _pump(tester, live: mode == _Mode.live);
    state.toggleFold(0);
    await tester.pump();
    final due = tester.getCenter(find.text('# Due', findRichText: true));
    await tester.tapAt(due);
    await tester.pump();
    expect(state.widget.buffer.lineOf(state.selection.extent), 4);
  });

  both('Ctrl+End with a fold keeps working', (tester, mode) async {
    final state = await _pump(tester, live: mode == _Mode.live);
    state.focusNode.requestFocus();
    await tester.pump();
    state.toggleFold(0);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(state.selection.extent, _note.length);
    expect(state.isFolded(0), isTrue, reason: 'the end is not in the fold');
  });
}
