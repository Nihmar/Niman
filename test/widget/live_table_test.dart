// A table in `live`: the read view's grid over the table's own source, the
// caret's row on the grid too — only its run's marks show — and the caret
// kept out of the room between the cells.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/block_view.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/preview/math_cache.dart';

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

/// A two-column table whose first cell cannot fit a phone's pane.
const String _longTable =
    '| head | second |\n|---|---|\n'
    '| a first cell far too long for the pane, and still going further |'
    ' second |';

/// Pumps [note] in `live` at the pane the test set, and hands back the view.
Future<MarkdownSourceViewState> _pumpNote(
  WidgetTester tester,
  String note,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => MarkdownSurface(
            buffer: SourceBuffer.fromText(note),
            mode: MarkdownSurfaceMode.live,
            theme: markdownThemeOf(context),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));
}

/// A table whose first cell holds an escaped pipe: one cell, so the cell
/// after it is `c` — the read view's own count.
const String _escaped = '| a \\| b | c |\n|---|---|\n| one | two |\n';

/// The same, with a second cell too long for a phone's pane: laid out in
/// columns fitted to it, its cells wrapped inside them.
const String _escapedLong =
    '| a \\| b | a second cell far too long for the pane, and still going |\n'
    '|---|---|\n'
    '| one | two |\n';

/// Pumps [note] in the read view, for the cell count `live` has to agree with.
Future<void> _pumpReadView(WidgetTester tester, String note) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownReadView(
          buffer: SourceBuffer.fromText(note),
          parser: BlockParser(),
          mathCache: MathCache(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Where [text] starts on line [line] of [_note], plus [plus].
int _at(int line, String text, [int plus = 0]) =>
    _buffer.offsetOfLine(line) + _buffer.lineAt(line).indexOf(text) + plus;

/// The paragraph of the line whose drawn text holds [text].
RenderParagraph _row(WidgetTester tester, String text) => tester
    .renderObjectList<RenderParagraph>(find.byType(RichText))
    .firstWhere((p) => p.text.toPlainText().contains(text));

void main() {
  testWidgets('a table that fits the pane is one line, however long its '
      'cells', (tester) async {
    tester.view.physicalSize = const Size(1200, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpNote(tester, _longTable);

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

  testWidgets('a table too wide for the pane wraps its cells inside them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpNote(tester, _longTable);

    const pane = 320.0;
    final pieces = tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        // The table's own text: a handle's glyph is an icon font's, and the
        // surface overlays more than the note.
        .where((p) => RegExp('[A-Za-z]').hasMatch(p.text.toPlainText()))
        .toList();
    // Every word of the table is drawn, and nothing reaches past the pane:
    // the columns were fitted to it instead of the row being clipped.
    for (final word in <String>[
      'head',
      'second',
      'first',
      'cell',
      'long',
      'pane',
      'still',
      'further',
    ]) {
      expect(
        pieces.any((p) => p.text.toPlainText().contains(word)),
        isTrue,
        reason: word,
      );
    }
    for (final piece in pieces) {
      final box = piece.localToGlobal(Offset.zero) & piece.size;
      expect(
        box.right,
        lessThanOrEqualTo(pane + 0.5),
        reason:
            '"${piece.text.toPlainText()}" at '
            '${box.left}..${box.right}, ${box.top}..${box.bottom}',
      );
    }
    // The long cell wraps: its last word is drawn below the header row.
    final head = tester.getRect(
      find.textContaining('head', findRichText: true),
    );
    final tail = tester.getRect(
      find.textContaining('further', findRichText: true),
    );
    expect(
      tail.top,
      greaterThan(head.bottom),
      reason: 'the long cell continues on a later visual line',
    );
    // The columns are kept: the second cell stands where the header set it.
    final seconds = <double>[
      for (final piece in pieces)
        if (piece.text.toPlainText().contains('second'))
          piece.localToGlobal(Offset.zero).dx,
    ];
    expect(seconds.length, 2, reason: 'header and body, one column each');
    expect(seconds.first, closeTo(seconds.last, 0.5));
  });

  testWidgets('a tap in a wrapped row lands in the cell it was on', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = await _pumpNote(tester, _longTable);
    final buffer = state.widget.buffer;
    // The tail of the long cell is on a later visual line of the row.
    final tail = find.textContaining('further', findRichText: true);
    final box = tester.getRect(tail);
    expect(box.right, lessThanOrEqualTo(320.5));
    await tester.tapAt(box.center);
    await tester.pump();

    final line = buffer.lineOf(state.selection.extent);
    expect(line, 2, reason: 'the tap was on the table, not a line about it');
    final text = buffer.lineAt(line);
    final local = state.selection.extent - buffer.offsetOfLine(line);
    final piece = tester.widget<RichText>(tail).text.toPlainText();
    final start = text.indexOf(piece);
    expect(start, greaterThanOrEqualTo(0));
    expect(local, inInclusiveRange(start, start + piece.length));
    // And the caret is drawn where the tap was: on the piece's own line.
    final caret = state.caretRect;
    expect(caret, isNotNull);
    expect(caret!.top, lessThan(box.bottom + 1));
    expect(caret.bottom, greaterThan(box.top - 1));
  });

  testWidgets("a caret in a wrapped row's room is drawn at its cell's edge", (
    tester,
  ) async {
    // Typing a space after a cell's text leaves the caret in the room round
    // the cells, which no piece of a wrapped row holds. It is drawn on its
    // side of the pipe, at the nearer edge of that side's cell — where an
    // unwrapped row, the room spread evenly between the two cells' text,
    // draws it too — not in the row's first piece.
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = await _pumpNote(tester, _longTable);
    final buffer = state.widget.buffer;
    final text = buffer.lineAt(2);
    Future<Rect> caretAt(int column) async {
      state.placeCaret(buffer.offsetOfLine(2) + column);
      await tester.pump();
      return state.caretRect!;
    }

    final firstEnd = text.indexOf('further') + 'further'.length;
    final secondStart = text.indexOf('second');
    final secondEnd = secondStart + 'second'.length;
    // Before the pipe: the first cell's end, on its last visual line.
    expect(await caretAt(firstEnd + 1), await caretAt(firstEnd));
    // After the pipe: the second cell's start.
    expect(await caretAt(secondStart - 1), await caretAt(secondStart));
    // Past the last cell, the closing pipe included: the last cell's end.
    expect(await caretAt(secondEnd + 1), await caretAt(secondEnd));
    expect(await caretAt(text.length), await caretAt(secondEnd));
    // Before the row's first cell: its start.
    expect(await caretAt(0), await caretAt(text.indexOf('a first')));
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

  testWidgets('an escaped pipe is one cell, in live and in the read view', (
    tester,
  ) async {
    // The caret stepped cell by cell through every pipe, the read view's row
    // by the pipes that are not escaped: `| a \| b | c |` was three cells to
    // `live` and two to the reader (#361).
    final state = await _pumpNote(tester, _escaped);
    final buffer = state.widget.buffer;
    await tester.tap(find.byType(MarkdownSourceView));
    await tester.pump();
    state.placeCaret(buffer.offsetOfLine(0) + buffer.lineAt(0).indexOf('a'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      state.selectedText,
      'c',
      reason: r'the cell after `a \| b`, not the `b` a split would make',
    );

    // And the read view reads the row as two cells, the escaped pipe standing
    // in the first one's text: the count `live` now steps by.
    await _pumpReadView(tester, _escaped);
    final grid = tester.widget<Table>(
      find.descendant(of: find.byType(BlockView), matching: find.byType(Table)),
    );
    expect(grid.children.first.children, hasLength(2));
    expect(
      tester
          .widgetList<RichText>(
            find.descendant(
              of: find.byType(Table),
              matching: find.byType(RichText),
            ),
          )
          .first
          .text
          .toPlainText(),
      'a | b',
      reason: 'the escaped pipe is the cell text, not an edge',
    );
  });

  testWidgets('an escaped pipe is one cell in a row fitted to the pane', (
    tester,
  ) async {
    // The same row in a pane it does not fit: its cells are wrapped inside
    // their fitted columns, and cut from the same ranges — so the pipe is
    // still one cell's text there, and the step still skips it.
    tester.view.physicalSize = const Size(320, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = await _pumpNote(tester, _escapedLong);
    final buffer = state.widget.buffer;
    await tester.tap(find.byType(MarkdownSourceView));
    await tester.pump();
    state.placeCaret(buffer.offsetOfLine(0) + buffer.lineAt(0).indexOf('a'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      state.selectedText,
      'a second cell far too long for the pane, and still going',
    );
    // The row is laid out in fitted columns, its cells wrapped inside them:
    // the last cell's last word is drawn, and inside the pane. (A phrase
    // straddles the wrap, so its words are asked for one by one.)
    expect(
      find.textContaining('going', findRichText: true),
      findsOneWidget,
      reason: 'the fitted row is drawn, its last cell inside the pane',
    );
    expect(
      tester.getRect(find.textContaining('going', findRichText: true)).right,
      lessThanOrEqualTo(320.5),
    );
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
