// How `live` lays a table out: its columns as wide as their widest cells,
// drawn from the room between them — and, when that is wider than the pane,
// fitted to the pane with each cell's text wrapped inside its own column
// (#337).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/render/live_tables.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The note the tests lay out: a two-column table whose first cell is longer
/// than any phone pane.
const String _note =
    'x\n\n| head | second |\n|---|---|\n'
    '| a first cell far too long for the pane, and going on | second |\n';

const int _firstLine = 2;

void main() {
  testWidgets('a table that fits its budget is laid out as it always was', (
    tester,
  ) async {
    final theme = await _theme(tester);
    final buffer = SourceBuffer.fromText(_note);
    final row = LiveTables().rowOf(
      _firstLine + 2,
      const Block(kind: BlockKind.table, startLine: _firstLine, endLine: 5),
      buffer,
      tokensOf: (line) => const <Token>[],
      hidden: (line, token) => false,
      styleOf: (token) => null,
      theme: theme,
      scaler: TextScaler.noScaling,
      budget: 2000,
    )!;
    expect(row.wrapped, isEmpty);
    expect(row.gaps, isNotEmpty);
    // The cells are drawn from the room between them: the first cell's text
    // starts at the padding, and the table is as wide as its widest cell
    // wants.
    expect(row.edges.first, 0);
    expect(row.edges.last, greaterThan(300));
  });

  testWidgets('a table wider than its budget is fitted to it', (tester) async {
    final theme = await _theme(tester);
    final buffer = SourceBuffer.fromText(_note);
    const budget = 320.0;
    final row = LiveTables().rowOf(
      _firstLine + 2,
      const Block(kind: BlockKind.table, startLine: _firstLine, endLine: 5),
      buffer,
      tokensOf: (line) => const <Token>[],
      hidden: (line, token) => false,
      styleOf: (token) => null,
      theme: theme,
      scaler: TextScaler.noScaling,
      budget: budget,
    )!;
    expect(row.wrapped, isNotEmpty);
    // Nothing is clipped: the table ends on the pane.
    expect(row.edges.last, lessThanOrEqualTo(budget));
    // The cell wraps: its text is drawn as more than one piece.
    final text = buffer.lineAt(_firstLine + 2);
    final cells = LiveTables.cellsOf(text);
    final mine = <String>[];
    for (final visual in row.wrapped) {
      for (final piece in visual.pieces) {
        expect(piece.end, greaterThan(piece.start));
        expect(piece.start, greaterThanOrEqualTo(cells.first.$1));
        expect(piece.end, lessThanOrEqualTo(cells.last.$2));
        expect(piece.x, greaterThanOrEqualTo(0));
        expect(piece.x, lessThan(row.edges.last));
        if (piece.start >= cells.first.$1 && piece.end <= cells.first.$2) {
          mine.add(text.substring(piece.start, piece.end));
        }
      }
    }
    expect(mine.length, greaterThan(1), reason: 'the first cell wraps');
    expect(mine.join(), text.substring(cells.first.$1, cells.first.$2));
    // The second cell's text stands on the first visual line, at its own
    // column: the pieces keep the columns they were fitted into.
    final second = text.substring(cells.last.$1, cells.last.$2);
    expect(mine.join(), isNot(contains(second)));
    final secondAt = row.wrapped.first.pieces
        .where((piece) => piece.start >= cells.last.$1)
        .first;
    expect(text.substring(secondAt.start, secondAt.end), second);
  });

  testWidgets('the wider column keeps the wider room', (tester) async {
    final theme = await _theme(tester);
    final buffer = SourceBuffer.fromText(_note);
    final narrow = LiveTables().rowOf(
      _firstLine + 2,
      const Block(kind: BlockKind.table, startLine: _firstLine, endLine: 5),
      buffer,
      tokensOf: (line) => const <Token>[],
      hidden: (line, token) => false,
      styleOf: (token) => null,
      theme: theme,
      scaler: TextScaler.noScaling,
      budget: 320,
    )!;
    final first = narrow.edges[1] - narrow.edges[0];
    final rest = narrow.edges.last - narrow.edges[1];
    expect(first, greaterThan(rest), reason: 'the long column got more room');
  });
}

/// The markdown theme of a `MaterialApp`, the one the surface is laid out
/// with.
Future<MarkdownTheme> _theme(WidgetTester tester) async {
  late MarkdownTheme theme;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          theme = markdownThemeOf(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return theme;
}
