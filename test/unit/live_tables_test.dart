// How `live` lays a table out: its columns as wide as their widest cells,
// drawn from the room between them — and, when that is wider than the pane,
// fitted to the pane with each cell's text wrapped inside its own column
// (#337) — and how much of that work a revision, a caret move and a frame
// may cost (#494).
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

  // The work a table costs, held to the number of measurements rather than to
  // a wall-clock (a shared runner reads different milliseconds for the same
  // commit): a revision measures the cells of the rows it changed, a table
  // that fits measures no word at all, a caret move measures the row it
  // entered (the one it left stands measured at rest), and a row's pieces are
  // laid out only when a frame draws it (#494).
  testWidgets(
    'a revision measures a fitting table once, a caret move its rows',
    (tester) async {
      final theme = await _theme(tester);
      // A table that fits any pane: three rows of two cells, two words a cell,
      // the last two rows carrying a bold run. A cell's width is work every
      // lay-out needs; a word's is work only a fitted table needs — and the
      // run's marks are what a caret move brings back to be measured.
      const note =
          '| head one | second two |\n|---|---|\n'
          '| alpha **bold** | beta two |\n'
          '| gamma **wide** | delta two |\n';
      final buffer = SourceBuffer.fromText(note);
      const block = Block(kind: BlockKind.table, startLine: 0, endLine: 4);
      final tables = LiveTables();
      int? revealed;
      LiveTableRow? row(int line, {Object? reveal}) => tables.rowOf(
        line,
        block,
        buffer,
        tokensOf: (line) => _boldTokens(buffer.lineAt(line)),
        hidden: (line, token) =>
            token.marker && (reveal == null || line != revealed),
        styleOf: (token) => null,
        theme: theme,
        scaler: TextScaler.noScaling,
        budget: 2000,
        reveal: reveal,
        revealLine: reveal == null ? null : revealed,
      );

      int count(void Function() body) {
        LiveTables.measurements = 0;
        body();
        return LiveTables.measurements;
      }

      void askAll({Object? reveal}) {
        for (var line = 0; line < 4; line++) {
          row(line, reveal: reveal);
        }
      }

      // A revision: one painter a cell, none a word — the table fits.
      expect(
        count(askAll),
        6,
        reason: 'three rows of two cells, measured once',
      );
      // The same revision asks for its lines again: the work stands.
      expect(count(askAll), 0, reason: 'the same revision measures nothing');
      final atRest = row(3)!.edges.last;

      // The caret enters the third row: its two cells are measured again, and
      // the rows at rest are not — they stood measured already.
      revealed = 2;
      expect(count(() => askAll(reveal: 'run')), 2, reason: "the caret's row");
      // The run's marks show on that row, so its cell widens: the row really
      // was measured again, not merely skipped.
      expect(
        row(3, reveal: 'run')!.edges.last,
        greaterThan(atRest),
        reason: "the caret's row widens the table",
      );

      // A second move: the row it left is taken back at rest from what was
      // measured of it, and the row it entered is measured.
      revealed = 3;
      expect(
        count(() => askAll(reveal: 'run')),
        2,
        reason: 'the row it entered; the one it left stood measured',
      );
      // Another run on the same row: the reveal changed, so the row is measured
      // again — its marks stand differently.
      expect(count(() => askAll(reveal: 'other')), 2, reason: 'the same row');
      // The caret leaves the table: the row it left is measured at rest, and
      // nothing else.
      expect(count(askAll), 0, reason: 'the row the caret left stood measured');
      expect(
        row(3)!.edges.last,
        closeTo(atRest, 0.5),
        reason: 'the table is back as it was',
      );
    },
  );

  testWidgets(
    "a fitted table measures its words once, a row's pieces when drawn",
    (tester) async {
      final theme = await _theme(tester);
      // A table wider than any phone pane: two long rows of seven words and a
      // short one, over a two-cell header.
      const note =
          '| head | second |\n|---|---|\n'
          '| aaaaaaa bbbbbbb ccccccc ddddddd eeeeeee fffffff ggggggg'
          ' | second |\n'
          '| hhhhhhh iiiiiii jjjjjjj kkkkkkk lllllll mmmmmmm nnnnnnn'
          ' | third |\n';
      final buffer = SourceBuffer.fromText(note);
      const block = Block(kind: BlockKind.table, startLine: 0, endLine: 4);
      const budget = 320.0;
      final tables = LiveTables();
      int? revealed;
      LiveTableRow? row(int line, {Object? reveal}) => tables.rowOf(
        line,
        block,
        buffer,
        tokensOf: (line) => const <Token>[],
        hidden: (line, token) => false,
        styleOf: (token) => null,
        theme: theme,
        scaler: TextScaler.noScaling,
        budget: budget,
        reveal: reveal,
        revealLine: reveal == null ? null : revealed,
      );

      int count(void Function() body) {
        LiveTables.measurements = 0;
        body();
        return LiveTables.measurements;
      }

      void askAll({Object? reveal}) {
        for (var line = 0; line < 4; line++) {
          row(line, reveal: reveal);
        }
      }

      // The table wants more room than the pane, so every cell's widest word is
      // measured beside the cell itself: six cells and eighteen words.
      expect(count(askAll), 24, reason: 'six cells and eighteen words, once');
      expect(count(askAll), 0, reason: 'the same revision measures nothing');
      // No frame has drawn a row yet: the words stand measured and no piece has
      // been laid out. A row pays for its pieces when a frame first asks.
      expect(count(() => row(0)!.wrapped), 2, reason: "the header's two cells");
      expect(count(() => row(0)!.wrapped), 0, reason: 'kept by the row');

      // The caret enters the fourth row: that row's two cells and eight words
      // are measured again, the table's own lay-out standing.
      revealed = 3;
      expect(
        count(() => askAll(reveal: 'run')),
        2 + 8,
        reason: 'two cells and eight words of one row',
      );
      // The caret leaves the table: the row it left is taken back at rest.
      expect(count(askAll), 0, reason: 'the row the caret left stood measured');
    },
  );

  testWidgets('rows measured before their tokens land are measured again', (
    tester,
  ) async {
    final theme = await _theme(tester);
    // The colours of a long note land after its first frame: a row measured
    // before then was measured as plain text, its marks drawn as characters,
    // and asking for it again once they have landed must draw it with them
    // hidden — without an edit to make the buffer's revision move (#494).
    const note =
        '| head | second |\n|---|---|\n'
        '| **alpha** beta | **gamma** delta |\n'
        '| **eps** zeta | plain **words** here |\n';
    for (final budget in <double>[2000, 90]) {
      final buffer = SourceBuffer.fromText(note);
      const block = Block(kind: BlockKind.table, startLine: 0, endLine: 4);
      var landed = false;
      LiveTableRow? row(LiveTables tables, int line) => tables.rowOf(
        line,
        block,
        buffer,
        tokensOf: (line) =>
            landed ? _boldTokens(buffer.lineAt(line)) : const <Token>[],
        hidden: (line, token) => token.marker,
        styleOf: (token) => null,
        theme: theme,
        scaler: TextScaler.noScaling,
        budget: budget,
        tokensFrom: landed,
      );

      final tables = LiveTables();
      for (var line = 0; line < 4; line++) {
        row(tables, line);
      }
      final plain = row(tables, 3)!.edges.last;

      landed = true;
      final fresh = LiveTables();
      for (var line = 0; line < 4; line++) {
        _expectSame(
          row(tables, line)!,
          row(fresh, line)!,
          reason: 'line $line at $budget',
        );
      }
      if (budget > 1000) {
        expect(
          row(tables, 3)!.edges.last,
          lessThan(plain),
          reason: 'the marks are hidden now: the table is narrower',
        );
      }
    }
  });

  // A keystroke is a revision, and a revision used to drop every measurement
  // of every table: on a phone, a 2,000-row table on screen was every word of
  // it laid out again for a letter typed anywhere in the note (#494). The
  // measurements are kept per row of text, so a revision measures the rows it
  // changed. Held to the number of measurements, not to a wall-clock.
  testWidgets('a revision measures the rows it changed, not the table', (
    tester,
  ) async {
    final theme = await _theme(tester);
    final note = StringBuffer('intro\n\n| h1 | h2 | h3 |\n|---|---|---|\n');
    for (var at = 0; at < 30; at++) {
      note.write('| r$at alpha | r$at beta gamma | r$at delta |\n');
    }
    // 'intro', a blank line, the header, the delimiter row and 30 rows.
    for (final budget in <double>[2000, 120]) {
      final fits = budget > 1000;
      final buffer = SourceBuffer.fromText(note.toString());
      final tables = LiveTables();
      var first = 2;
      LiveTableRow? row(LiveTables tables, int at) => tables.rowOf(
        first + at,
        Block(kind: BlockKind.table, startLine: first, endLine: first + 32),
        buffer,
        tokensOf: (line) => const <Token>[],
        hidden: (line, token) => false,
        styleOf: (token) => null,
        theme: theme,
        scaler: TextScaler.noScaling,
        budget: budget,
      );

      int count(void Function() body) {
        LiveTables.measurements = 0;
        body();
        return LiveTables.measurements;
      }

      void askAll() {
        for (var at = 0; at < 32; at++) {
          row(tables, at);
        }
      }

      expect(count(askAll), greaterThan(90), reason: 'the table, once');
      expect(count(askAll), 0, reason: 'the same revision');

      // A letter typed above the table.
      buffer.replaceRange(0, 5, 'INTRO');
      expect(count(askAll), 0, reason: 'a keystroke outside, at $budget');

      // A line typed above it: every row of the table moves down one line.
      buffer.replaceRange(0, 0, 'new\n');
      first = 3;
      expect(count(askAll), 0, reason: 'a line above the table, at $budget');

      // A letter typed in one cell: that row's three cells, and — in a table
      // that does not fit — the seven words of the row.
      final at = buffer.offsetOfLine(first + 2 + 10) + 3;
      buffer.replaceRange(at, at, 'x');
      expect(
        count(askAll),
        fits ? 3 : 3 + 7,
        reason: 'one row changed, at $budget',
      );

      // And what stands is what a table laid out from nothing draws.
      final fresh = LiveTables();
      for (var at = 0; at < 32; at++) {
        _expectSame(
          row(tables, at)!,
          row(fresh, at)!,
          reason: 'row $at at $budget',
        );
      }
    }
  });

  testWidgets('a row kept across revisions is drawn as a fresh one', (
    tester,
  ) async {
    final theme = await _theme(tester);
    // Every kind of cell the measuring has an opinion about: a wide one, a
    // marked one, CJK and emoji, over a table that fits and one that does not
    // — each step edits the note, moves the caret's run or the pane's width,
    // and the table must be what one laid out from nothing draws.
    const rows = <String>[
      '| head | second | third |',
      '|:---|---:|:---:|',
      '| plain words here | **bold** cell | c |',
      '| 日本語のテキスト | 😀 emoji 👍 | a very long cell that goes on and on |',
      '| x | y | z |',
    ];
    final buffer = SourceBuffer.fromText('${rows.join('\n')}\n');
    const block = Block(kind: BlockKind.table, startLine: 0, endLine: 5);
    final tables = LiveTables();
    int? revealed;
    double budget = 2000;
    LiveTableRow? row(LiveTables tables, int line, {Object? reveal}) =>
        tables.rowOf(
          line,
          block,
          buffer,
          tokensOf: (line) => _boldTokens(buffer.lineAt(line)),
          hidden: (line, token) =>
              token.marker && (reveal == null || line != revealed),
          styleOf: (token) => null,
          theme: theme,
          scaler: TextScaler.noScaling,
          budget: budget,
          reveal: reveal,
          revealLine: reveal == null ? null : revealed,
        );

    void expectFresh(String step, {Object? reveal}) {
      final fresh = LiveTables();
      for (var line = 0; line < 5; line++) {
        _expectSame(
          row(tables, line, reveal: reveal)!,
          row(fresh, line, reveal: reveal)!,
          reason: '$step, line $line at $budget',
        );
      }
    }

    for (final width in <double>[2000, 260, 2000, 90]) {
      budget = width;
      expectFresh('the pane');
      // An edit of the wide cell, of the CJK one, and of the emoji one.
      for (final (line, word, insert) in <(int, String, String)>[
        (3, 'long', 'very '),
        (3, 'テキスト', '日本語'),
        (3, 'emoji', '🎉 '),
        (2, 'plain', 'so '),
      ]) {
        final at =
            buffer.offsetOfLine(line) + buffer.lineAt(line).indexOf(word);
        buffer.replaceRange(at, at, insert);
        expectFresh('an edit of $word');
      }
      // The caret's run shows its marks on its own row, and leaves.
      revealed = 2;
      expectFresh('a reveal', reveal: 'run 2');
      revealed = 3;
      expectFresh('a move', reveal: 'run 3');
      expectFresh('the caret leaves');
    }
  });
}

/// Expects [a] and [b] to be the same row as far as anything draws it: its
/// columns, its gaps and its wrapped pieces.
void _expectSame(LiveTableRow a, LiveTableRow b, {String? reason}) {
  expect(a.edges, b.edges, reason: reason);
  expect(a.gaps, b.gaps, reason: reason);
  // A visual line holds a list, which a record compares by identity: the
  // pieces are read out.
  List<Object> pieces(LiveTableRow row) => <Object>[
    for (final line in row.wrapped) (line.height, line.pieces.toList()),
  ];
  expect(pieces(a).toString(), pieces(b).toString(), reason: reason);
  expect(a.header, b.header, reason: reason);
  expect(a.delimiter, b.delimiter, reason: reason);
  expect(a.last, b.last, reason: reason);
}

/// The tokens of a line's `**bold**` runs: the opening and closing marks —
/// which a lay-out hides at rest — and the word between them.
List<Token> _boldTokens(String line) => <Token>[
  for (final match in RegExp(r'\*\*(\w+)\*\*').allMatches(line)) ...[
    Token(TokenKind.bold, match.start, match.start + 2, marker: true),
    Token(TokenKind.bold, match.start + 2, match.end - 2),
    Token(TokenKind.bold, match.end - 2, match.end, marker: true),
  ],
];

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
