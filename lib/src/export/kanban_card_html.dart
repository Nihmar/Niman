/// One card of an exported kanban board (#1170).
library;

import 'package:niman/src/export/html_text.dart';
import 'package:niman/src/kanban/card_text.dart';
import 'package:niman/src/kanban/kanban_card.dart';

/// The `<ul><li>` the writer wraps a one-item list in, around the item's
/// own HTML.
final RegExp _item = RegExp(r'^<ul>\n<li>(.*)</li>\n</ul>\n?$', dotAll: true);

/// Writes a card as a list item of the board's `kanban-cards` list.
///
/// The title and the body go through the writer ([piece]) with the page's
/// hooks and the note's definitions, so a link, a reference link, a
/// footnote, a wikilink, a picture, a formula and the task box come out as
/// they do anywhere else on the page. The tags and the due date, which the
/// board view shows as chips, are taken out of the title and shown as chips
/// here too ([cardShownTitle], the view's own rule).
final class KanbanCardHtml {
  /// A card writer that writes Markdown through [piece].
  const new(this.piece);

  /// A piece of the note's Markdown as the page writes it: the board's
  /// writer, which shares the note's definitions among its pieces.
  final String Function(String markdown) piece;

  /// [card] as `<li class="kanban-card">`.
  String render(KanbanCard card) {
    final done = card.checked ?? false;
    final out = StringBuffer(
      done
          ? '<li class="kanban-card kanban-done">\n'
          : '<li class="kanban-card">\n',
    )..write('<div class="kanban-card-title">${_title(card)}</div>\n');
    final chips = _chips(card);
    if (chips.isNotEmpty) {
      out.write('<div class="kanban-chips">$chips</div>\n');
    }
    final body = _body(card);
    if (body.isNotEmpty) {
      out.write('<div class="kanban-card-body">\n$body</div>\n');
    }
    out.write('</li>\n');
    return out.toString();
  }

  /// The title's inline HTML, the task box first when the card has one: the
  /// card's first line written as the one-item list it is, and unwrapped.
  String _title(KanbanCard card) {
    final checked = card.checked;
    final box = checked == null ? '' : (checked ? '[x] ' : '[ ] ');
    final shown = cardShownTitle(card.title);
    final html = piece('- $box$shown');
    final match = _item.firstMatch(html);
    return match == null ? escapeHtml(shown) : match.group(1)!;
  }

  /// The card's tags and due date as chips.
  String _chips(KanbanCard card) {
    final out = StringBuffer();
    for (final tag in card.tags) {
      out.write(
        '<span class="kanban-chip kanban-tag">#${escapeHtml(tag)}</span>',
      );
    }
    final due = card.due;
    if (due != null) {
      out.write(
        '<span class="kanban-chip kanban-due">'
        '${escapeHtml(cardDueText(due))}</span>',
      );
    }
    return out.toString();
  }

  /// The lines under the title as blocks; empty when there are none worth
  /// writing.
  String _body(KanbanCard card) {
    final lines = card.body;
    var from = 0;
    var to = lines.length;
    while (from < to && lines[from].trim().isEmpty) {
      from++;
    }
    while (to > from && lines[to - 1].trim().isEmpty) {
      to--;
    }
    if (from == to) return '';
    return piece(lines.sublist(from, to).join('\n'));
  }
}
