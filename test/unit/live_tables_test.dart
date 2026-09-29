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
import 'package:niman/src/markdown/table/markdown_table.dart';

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

  test('live splits a row into the cells the table model does', () {
    // One rule for where a row's cells are: live draws and measures the
    // cells the table model edits and pads, an escaped pipe at the row's
    // end included — it is the last cell's text, not the row's edge.
    const rows = <String>[
      r'| a | b \|',
      r'| a | b \| |',
      r'| a \| b | c |',
      r'a | b \\|',
      '| a |  | c |',
      'a | b',
      '|a|b|',
      '| a | b | ',
      '| a | b |',
      '',
      '   ',
    ];
    for (final row in rows) {
      expect(
        <String>[
          for (final (start, end) in LiveTables.cellsOf(row))
            row.substring(start, end),
        ],
        <String>[for (final cell in MarkdownTable.splitRow(row)) cell.trim()],
        reason: row,
      );
    }
  });

  testWidgets('a cell with hidden marks wraps between its words', (
    tester,
  ) async {
    final theme = await _theme(tester);
    // Every bold word hides four characters of marks: a break taken in the
    // visible text and read as a source offset would land that much short
    // of the word boundary it was taken at, and more with every word.
    const note =
        '| h |\n|---|\n'
        '| **alpha** beta **gamma** delta **epsilon** zeta **eta** theta '
        '**iota** kappa **lambda** mu |\n';
    final buffer = SourceBuffer.fromText(note);
    final text = buffer.lineAt(2);
    final tokens = <Token>[
      for (final match in RegExp(r'\*\*(\w+)\*\*').allMatches(text)) ...[
        Token(TokenKind.bold, match.start, match.start + 2, marker: true),
        Token(TokenKind.bold, match.start + 2, match.end - 2),
        Token(TokenKind.bold, match.end - 2, match.end, marker: true),
      ],
    ];
    final (start, end) = LiveTables.cellsOf(text).single;
    for (final budget in <double>[300, 220, 160]) {
      final row = LiveTables().rowOf(
        2,
        const Block(kind: BlockKind.table, startLine: 0, endLine: 3),
        buffer,
        tokensOf: (line) => line == 2 ? tokens : const <Token>[],
        hidden: (line, token) => token.marker,
        styleOf: (token) => null,
        theme: theme,
        scaler: TextScaler.noScaling,
        budget: budget,
      )!;
      final pieces = <LiveTablePiece>[
        for (final visual in row.wrapped) ...visual.pieces,
      ];
      expect(pieces.length, greaterThan(2), reason: 'wraps at $budget');
      expect(pieces.first.start, start);
      expect(pieces.last.end, end);
      final column =
          row.edges[1] - row.edges[0] - 2 * theme.tableCellPadding.left;
      for (var at = 0; at < pieces.length; at++) {
        final piece = pieces[at];
        final shown = text
            .substring(piece.start, piece.end)
            .replaceAll('**', '');
        if (at > 0) {
          expect(piece.start, pieces[at - 1].end, reason: 'contiguous');
        }
        // A line ends past a space: no word is cut in two, and a word's
        // marks open the line its word is on.
        if (at < pieces.length - 1) {
          expect(
            text[piece.end - 1],
            ' ',
            reason: '"$shown" at $budget ends mid-word',
          );
        }
        // What a piece shows fits its column: nothing spills into the next.
        final painter = TextPainter(
          text: TextSpan(text: shown.trimRight(), style: theme.tableCell),
          textDirection: TextDirection.ltr,
        )..layout();
        expect(
          painter.width,
          lessThanOrEqualTo(column + 0.5),
          reason: '"$shown" at $budget is wider than its column',
        );
        painter.dispose();
      }
    }
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
