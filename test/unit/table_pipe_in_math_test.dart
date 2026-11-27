// A pipe in a formula in a table row (#1376): the row is split at its pipes
// before anything inside it is read, as GitHub reads it, so the pipe is
// written `\|` — and every reader of a row agrees on where its cells are.
//
// Not changed as the review's list asked: reading `$…$` before the pipes
// would make two stray dollar signs in two cells (`| a $ | b $ |`) one cell
// of a formula, which is worse than a pipe that needs its escape. The
// behaviour is documented in `docs/user/editing.md`.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/html/table_html.dart';
import 'package:niman/src/markdown/html/tree_html.dart';
import 'package:niman/src/markdown/render/live_tables.dart';
import 'package:niman/src/markdown/table/markdown_table.dart';
import 'package:niman/src/markdown/table_line_syntax.dart';

void main() {
  const escaped = r'| $a\|b$ | c |';
  const bare = r'| $a|b$ | c |';

  test('an escaped pipe in a formula is one cell, for every reader', () {
    expect(TableLineSyntax.cellsOf(escaped), 2);
    expect(TableHtml.cellsOf(escaped), [r'$a|b$', 'c']);
    expect(MarkdownTable.splitRow(escaped).map((c) => c.trim()), [
      r'$a\|b$',
      'c',
    ]);
    expect(LiveTables.cellsOf(escaped), hasLength(2));
  });

  test('a bare pipe in a formula splits the row, for every reader', () {
    expect(TableLineSyntax.cellsOf(bare), 3);
    expect(TableHtml.cellsOf(bare), [r'$a', r'b$', 'c']);
    expect(MarkdownTable.splitRow(bare), hasLength(3));
    expect(LiveTables.cellsOf(bare), hasLength(3));
  });

  test('the table the escaped row is in keeps its two columns', () {
    final html = TreeHtml('| a | b |\n|---|---|\n$escaped').render();
    expect(html, contains(r'<td>$a|b$</td>'));
    expect(html, contains('<td>c</td>'));
  });

  test('two stray dollar signs in two cells stay two cells', () {
    final html = TreeHtml('| a | b |\n|---|---|\n| 5 \$ | 6 \$ |').render();
    expect(html, contains(r'<td>5 $</td>'));
    expect(html, contains(r'<td>6 $</td>'));
  });
}
