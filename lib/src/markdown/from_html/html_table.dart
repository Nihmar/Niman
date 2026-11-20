/// A page's table as a Markdown one.
library;

import 'package:html/dom.dart';
import 'package:niman/src/markdown/from_html/html_inline.dart';

/// Writes the tables of a page.
final class HtmlTable {
  /// A table writer that sets each cell's words with [inline].
  const new(this.inline);

  /// The writer of a cell's inline content.
  final HtmlInline inline;

  /// [table] as a Markdown table, its first row the header; null when it
  /// has no cell.
  String? of(Element table) {
    final rows = table.querySelectorAll('tr');
    if (rows.isEmpty) return null;
    final cells = [
      for (final row in rows)
        [
          for (final cell in row.children)
            if (cell.localName == 'td' || cell.localName == 'th')
              // One line a row: a break in a cell is a space. (Its `|`s
              // are escaped with the rest of the text.)
              inline.lineOf(cell.nodes),
        ],
    ];
    final width = cells.fold<int>(0, (w, r) => r.length > w ? r.length : w);
    if (width == 0) return null;
    String row(List<String> r) =>
        '| ${[...r, for (var i = r.length; i < width; i++) ''].join(' | ')} |';
    return [
      row(cells.first),
      '|${List.filled(width, ' --- ').join('|')}|',
      for (final r in cells.skip(1)) row(r),
    ].join('\n');
  }
}
