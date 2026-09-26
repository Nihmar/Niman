// A table in `live`: the read view's grid over the table's own source, the
// caret's row on the grid too — only its run's marks show — and the caret
// kept out of the room between the cells.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';

const String _note =
    'caret\n\n| a | b |\n|---|---|\n| **one** | two |\n\nafter';

/// Pumps [_note] in `live`, the caret held at [caret] — or left to the view,
/// with none — and hands back the view.
Future<MarkdownSourceViewState> _pump(
  WidgetTester tester,
  int? caret, {
  bool numbers = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => MarkdownSurface(
            buffer: SourceBuffer.fromText(_note),
            mode: MarkdownSurfaceMode.live,
            theme: markdownThemeOf(context),
            selection: caret == null ? null : SelectionModel.at(caret),
            showLineNumbers: numbers,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));
}

final SourceBuffer _buffer = SourceBuffer.fromText(_note);

/// Where [text] starts on line [line] of [_note], plus [plus].
int _at(int line, String text, [int plus = 0]) =>
    _buffer.offsetOfLine(line) + _buffer.lineAt(line).indexOf(text) + plus;

/// The paragraph of the line whose drawn text holds [text].
RenderParagraph _row(WidgetTester tester, String text) => tester
    .renderObjectList<RenderParagraph>(find.byType(RichText))
    .firstWhere((p) => p.text.toPlainText().contains(text));

void main() {
  testWidgets('a table row is one line, however long its cells', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MarkdownSurface(
              buffer: SourceBuffer.fromText(
                '| head | second |\n|---|---|\n'
                '| a first cell far too long for the pane, and still going, '
                'and going, and going, and going | second |',
              ),
              mode: MarkdownSurfaceMode.live,
              theme: markdownThemeOf(context),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final paragraphs = tester.renderObjectList<RenderParagraph>(
      find.byType(RichText),
    );
    final header = paragraphs.firstWhere(
      (p) => p.text.toPlainText().contains('head'),
    );
    final row = paragraphs.firstWhere(
      (p) => p.text.toPlainText().contains('far too long'),
    );
    // The cells after the long one stay on its line: a soft-wrapped row
    // dropped them wherever the wrap left the pen, in the wrong columns.
    expect(row.size.height, closeTo(header.size.height, 0.5));
  });

  testWidgets("a row's pipes are drawn as room, on the caret's row too", (
    tester,
  ) async {
    await _pump(tester, 0);
    // At rest the pipes and the spaces round the cells are room, drawn as
    // nothing, and so are a cell's marks.
    expect(_row(tester, 'one').text.toPlainText(), isNot(contains('|')));
    final restTwo = tester.getTopLeft(
      find.textContaining('two', findRichText: true),
    );
    await _pump(tester, _at(2, 'b'));
    expect(
      _row(tester, 'one').text.toPlainText(),
      isNot(contains('|')),
      reason: 'another row of the table is drawn as it was',
    );
    // The caret on a row keeps it on the grid: its pipes are still room.
    final state = await _pump(tester, _at(4, 'two', 1));
    expect(state.selection.extent, _at(4, 'two', 1));
    expect(_row(tester, 'one').text.toPlainText(), isNot(contains('|')));
    expect(
      tester.getTopLeft(find.textContaining('two', findRichText: true)).dx,
      closeTo(restTwo.dx, 0.5),
      reason: 'a cell with no mark showing stays on its column',
    );
  });

  testWidgets('the delimiter row takes no room with the line numbers on', (
    tester,
  ) async {
    double gap() =>
        _row(tester, 'one').localToGlobal(Offset.zero).dy -
        _row(tester, 'b').localToGlobal(Offset.zero).dy;
    await _pump(tester, 0);
    final without = gap();
    await _pump(tester, 0, numbers: true);
    expect(gap(), closeTo(without, 0.5), reason: 'its number kept its row');
    expect(find.text('4'), findsNothing, reason: 'the delimiter row is line 4');
  });

  testWidgets('the delimiter row takes no room, caret or not', (tester) async {
    await _pump(tester, 0);
    expect(_row(tester, '---').size.height, lessThan(1));
    await _pump(tester, _buffer.offsetOfLine(3) + 1);
    expect(_row(tester, '---').size.height, lessThan(1));
  });

  group('the caret stays in the cells', () {
    Future<int> move(WidgetTester tester, int from, CaretMotion motion) async {
      final state = await _pump(tester, null);
      state.placeCaret(from);
      await tester.pump();
      state.moveCaretBy(motion);
      await tester.pump();
      return state.selection.extent;
    }

    testWidgets('right, past a cell, is the next cell', (tester) async {
      expect(
        await move(tester, _at(2, 'a', 1), CaretMotion.characterRight),
        _at(2, 'b'),
      );
    });

    testWidgets('right, past a row, skips the delimiter row', (tester) async {
      expect(
        await move(tester, _at(2, 'b', 1), CaretMotion.characterRight),
        _at(4, '**one'),
      );
    });

    testWidgets('left, before a row, is the row above', (tester) async {
      expect(
        await move(tester, _at(4, '**one'), CaretMotion.characterLeft),
        _at(2, 'b', 1),
      );
    });

    testWidgets('Home and End are the first and the last cell', (tester) async {
      expect(
        await move(tester, _at(4, 'two'), CaretMotion.lineStart),
        _at(4, '**one'),
      );
      expect(
        await move(tester, _at(4, '**one'), CaretMotion.lineEnd),
        _at(4, 'two', 3),
      );
    });

    testWidgets('out of the table, nothing changes', (tester) async {
      expect(await move(tester, 1, CaretMotion.characterRight), 2);
    });

    testWidgets('a deletion stops at its cell', (tester) async {
      final state = await _pump(tester, null);
      state.placeCaret(_at(4, 'two'));
      await tester.pump();
      state.deleteBackward();
      await tester.pump();
      expect(state.widget.buffer.lineAt(4), '| **one** | two |');
      state.placeCaret(_at(4, 'two', 3));
      await tester.pump();
      state
        ..deleteForward()
        ..deleteBackward(word: true);
      await tester.pump();
      expect(state.widget.buffer.lineAt(4), '| **one** |  |');
    });
  });

  group('Tab goes from cell to cell', () {
    Future<MarkdownSourceViewState> at(WidgetTester tester, int offset) async {
      final state = await _pump(tester, null);
      await tester.tap(find.byType(MarkdownSourceView));
      await tester.pump();
      state.placeCaret(offset);
      await tester.pump();
      return state;
    }

    Future<void> tab(WidgetTester tester, {bool shift = false}) async {
      if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();
    }

    testWidgets('forward, the next cell’s text selected', (tester) async {
      final state = await at(tester, _at(2, 'a'));
      await tab(tester);
      expect(state.selectedText, 'b');
      // Past the header's last cell: the first row's first cell, the
      // delimiter row passed over.
      await tab(tester);
      expect(state.selectedText, '**one**');
    });

    testWidgets('back, and past the first row to the header', (tester) async {
      final state = await at(tester, _at(4, 'one'));
      await tab(tester, shift: true);
      expect(state.selectedText, 'b');
    });

    testWidgets('past the last cell, a new row', (tester) async {
      final state = await at(tester, _at(4, 'two'));
      await tab(tester);
      expect(
        state.widget.buffer.text,
        'caret\n\n| a | b |\n|---|---|\n| **one** | two |\n|  |  |\n\nafter',
      );
      expect(state.widget.buffer.lineOf(state.selection.extent), 5);
    });
  });
}
