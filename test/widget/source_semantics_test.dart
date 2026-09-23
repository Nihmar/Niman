// The source surface to a screen reader (#245, phase 3): one multiline text
// field whose value is the note around the caret, with its selection, and
// the moves a reader asks for.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

/// Which unified mode a body is being run in: the same tests, twice.
enum _Mode { source, live }

Future<MarkdownSourceViewState> _pump(
  WidgetTester tester,
  String text, {
  bool live = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSourceView(
          buffer: SourceBuffer.fromText(text),
          theme: _theme,
          // Hiding a marker is a style: the note the reader is given is the
          // note's own text either way, which is the property under test.
          hideMarkers: live,
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));
}

SemanticsNode _field(WidgetTester tester) => tester.getSemantics(
  find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_NoteSemantics',
  ),
);

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

  both('the note is one multiline text field with its text', (
    tester,
    mode,
  ) async {
    final semantics = tester.ensureSemantics();
    final state = await _pump(
      tester,
      'prima riga\nseconda riga\n',
      live: mode == _Mode.live,
    );
    state.select(const SelectionModel(anchor: 6, extent: 10));
    await tester.pump();
    final data = _field(tester).getSemanticsData();
    expect(data.flagsCollection.isTextField, isTrue);
    expect(data.flagsCollection.isMultiline, isTrue);
    expect(data.value, 'prima riga\nseconda riga\n');
    expect(
      data.textSelection,
      const TextSelection(baseOffset: 6, extentOffset: 10),
    );
    // The lines are not read a second time.
    expect(find.bySemanticsLabel(RegExp('seconda')).evaluate(), isEmpty);
    semantics.dispose();
  });

  both('a reader moves the caret and sets the selection', (tester, mode) async {
    final semantics = tester.ensureSemantics();
    final state = await _pump(tester, 'una parola\n', live: mode == _Mode.live);
    final owner = tester.binding.renderViews.first.owner!.semanticsOwner!;
    final id = _field(tester).id;
    owner.performAction(id, SemanticsAction.moveCursorForwardByCharacter, true);
    await tester.pump();
    expect(state.selection, const SelectionModel(anchor: 0, extent: 1));
    owner.performAction(id, SemanticsAction.setSelection, <String, int>{
      'base': 4,
      'extent': 10,
    });
    await tester.pump();
    expect(state.selectedText, 'parola');
    semantics.dispose();
  });

  both('a long note gives the reader the text around the caret', (
    tester,
    mode,
  ) async {
    final semantics = tester.ensureSemantics();
    final text = List<String>.generate(
      2000,
      (at) => 'riga numero $at',
    ).join('\n');
    final state = await _pump(tester, text, live: mode == _Mode.live);
    state.placeCaret(text.indexOf('riga numero 1500'));
    await tester.pump();
    final data = _field(tester).getSemanticsData();
    expect(data.value.length, lessThan(9000));
    expect(data.value, contains('riga numero 1500'));
    final selection = data.textSelection!;
    expect(
      data.value.substring(selection.baseOffset).startsWith('riga numero 1500'),
      isTrue,
    );
    semantics.dispose();
  });
}
