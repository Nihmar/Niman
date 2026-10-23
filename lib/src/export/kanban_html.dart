/// A kanban board as an exported page's body (#1170).
///
/// Semantic HTML rather than a drawing: a column is a `<section>` with its
/// `<h2>` and its count, a card a box in a list. The text stays selectable
/// and searchable, and a reader that ignores the style still shows sections
/// and lists. What is not a card — the text before the first column, the
/// prose between cards — keeps its place; Obsidian's settings footer is not
/// exported.
///
/// ```html
/// <div class="kanban" data-columns="2">
/// <section class="kanban-column">
/// <header class="kanban-column-head"><h2 id="to-do">To do</h2>
/// <span class="kanban-count">1</span></header>
/// <ul class="kanban-cards">
/// <li class="kanban-card">…</li>
/// </ul>
/// </section>
/// </div>
/// ```
///
/// A column's heading is a real `<h2>`, written by the same writer as any
/// other heading: it carries its id, so a link into `Board#Doing` lands on
/// it, and the ids follow the note's document order.
library;

import 'package:niman/src/export/kanban_card_html.dart';
import 'package:niman/src/kanban/kanban_board.dart';
import 'package:niman/src/kanban/kanban_column.dart';
import 'package:niman/src/markdown/html/html_definitions.dart';
import 'package:niman/src/markdown/html/html_hooks.dart';
import 'package:niman/src/markdown/html/tree_html.dart';

/// Writes one [KanbanBoard].
///
/// The board is written in pieces — prose, headings, cards' titles and
/// bodies — each by the writer, and the pieces share the note's
/// definitions: a reference link or a footnote in a card resolves against a
/// definition anywhere in the note, the footnotes are numbered over the
/// whole note, and their list is written once, after the board.
final class KanbanHtml {
  /// A writer of [board], drawing with the page's [hooks].
  new(this.board, this.hooks);

  /// The board, read from the note's text.
  final KanbanBoard board;

  /// What the page draws its own way.
  final HtmlHooks hooks;

  late HtmlDefinitions _defs;
  bool _collecting = false;

  /// The note's body: the prose before the first column, then the board,
  /// then the footnotes cited. A note with no column is only prose.
  String render() {
    _defs = HtmlDefinitions(xhtml: hooks.xhtml);
    // A definition is a line with `]:` in it: a board with none is written
    // in one pass.
    if (_mayDefine) {
      _collecting = true;
      _write();
      _collecting = false;
    }
    return '${_write()}${_defs.footnotes.section(_defs.bodies)}';
  }

  bool get _mayDefine {
    for (var i = 0; i < board.contentEnd; i++) {
      if (board.lines[i].contains(']:')) return true;
    }
    return false;
  }

  String _write() {
    final columns = board.columns;
    final out = StringBuffer(
      _prose(0, columns.isEmpty ? board.contentEnd : columns.first.headingLine),
    );
    if (columns.isEmpty) return out.toString();
    out.write('<div class="kanban" data-columns="${columns.length}">\n');
    for (final column in columns) {
      _column(out, column);
    }
    out.write('</div>\n');
    return out.toString();
  }

  void _column(StringBuffer out, KanbanColumn column) {
    final card = KanbanCardHtml(_piece);
    out.write('<section class="kanban-column">\n');
    // The heading is written as any heading is: its id, its inlines, a
    // closing run of `#` off.
    final heading = _prose(column.headingLine, column.headingLine + 1).trim();
    out.write(
      '<header class="kanban-column-head">$heading\n'
      '<span class="kanban-count">${column.cards.length}</span></header>\n',
    );
    var inList = false;
    var at = column.headingLine + 1;
    for (final item in column.cards) {
      final prose = _prose(at, item.line);
      if (prose.isNotEmpty) {
        if (inList) out.write('</ul>\n');
        inList = false;
        out.write('<div class="kanban-prose">\n$prose</div>\n');
      }
      if (!inList) out.write('<ul class="kanban-cards">\n');
      inList = true;
      out.write(card.render(item));
      at = item.end;
    }
    if (inList) out.write('</ul>\n');
    final tail = _prose(at, column.endLine);
    if (tail.isNotEmpty) out.write('<div class="kanban-prose">\n$tail</div>\n');
    out.write('</section>\n');
  }

  /// The lines [from] to [to] (exclusive) as ordinary Markdown; empty when
  /// they are blank.
  String _prose(int from, int to) {
    final lines = <String>[
      for (var i = from; i < to; i++)
        if (board.lines[i].endsWith('\r'))
          board.lines[i].substring(0, board.lines[i].length - 1)
        else
          board.lines[i],
    ];
    if (lines.every((line) => line.trim().isEmpty)) return '';
    return _piece(lines.join('\n'));
  }

  /// [markdown], a piece of the note, as the writer writes it with the
  /// note's definitions; on the first pass it only reads them.
  String _piece(String markdown) {
    final writer = TreeHtml(markdown, hooks: hooks, shared: _defs);
    if (!_collecting) return writer.render();
    writer.collect();
    return '';
  }
}
