/// A GFM table written as HTML, as `cmark-gfm`'s table extension writes
/// it.
library;

/// Writes a table from its rows.
abstract final class TableHtml {
  /// The table of [lines] — a head row, the delimiter row, body rows — into
  /// [out], each cell's inline text written by [inline].
  static void write(
    StringBuffer out,
    List<String> lines,
    void Function(String text) inline,
  ) {
    final head = cellsOf(lines.first);
    final aligns = [for (final cell in cellsOf(lines[1])) _alignOf(cell)];
    out.write('<table>\n<thead>\n<tr>\n');
    for (var at = 0; at < head.length; at++) {
      _cell(
        out,
        'th',
        head[at],
        at < aligns.length ? aligns[at] : null,
        inline,
      );
    }
    out.write('</tr>\n</thead>\n');
    if (lines.length > 2) {
      out.write('<tbody>\n');
      for (final line in lines.skip(2)) {
        final cells = cellsOf(line);
        out.write('<tr>\n');
        for (var at = 0; at < head.length; at++) {
          _cell(
            out,
            'td',
            at < cells.length ? cells[at] : '',
            at < aligns.length ? aligns[at] : null,
            inline,
          );
        }
        out.write('</tr>\n');
      }
      out.write('</tbody>\n');
    }
    out.write('</table>\n');
  }

  static void _cell(
    StringBuffer out,
    String tag,
    String text,
    String? align,
    void Function(String text) inline,
  ) {
    out.write(align == null ? '<$tag>' : '<$tag align="$align">');
    inline(text);
    out.write('</$tag>\n');
  }

  /// The cells of a row: split at the pipes no backslash escapes, its
  /// outer pipes off, each trimmed, `\|` made `|`.
  static List<String> cellsOf(String line) {
    var text = line.trim();
    if (text.startsWith('|')) text = text.substring(1);
    if (text.endsWith('|') && !text.endsWith(r'\|')) {
      text = text.substring(0, text.length - 1);
    }
    final cells = <String>[];
    final cell = StringBuffer();
    for (var at = 0; at < text.length; at++) {
      final char = text.codeUnitAt(at);
      if (char == 0x5C &&
          at + 1 < text.length &&
          text.codeUnitAt(at + 1) == 0x7C) {
        cell.write('|');
        at++;
      } else if (char == 0x7C) {
        cells.add(cell.toString().trim());
        cell.clear();
      } else {
        cell.writeCharCode(char);
      }
    }
    cells.add(cell.toString().trim());
    return cells;
  }

  static String? _alignOf(String cell) {
    final left = cell.startsWith(':');
    final right = cell.endsWith(':');
    if (left && right) return 'center';
    if (left) return 'left';
    if (right) return 'right';
    return null;
  }
}
