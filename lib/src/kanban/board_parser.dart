import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/kanban/card_reader.dart';
import 'package:niman/src/kanban/kanban_board.dart';
import 'package:niman/src/kanban/kanban_card.dart';
import 'package:niman/src/kanban/kanban_column.dart';
import 'package:niman/src/kanban/line_ending.dart';
import 'package:niman/src/kanban/line_facts.dart';

/// The line Obsidian's Kanban plugin opens its settings footer with.
const String kanbanSettingsMarker = '%% kanban:settings';

/// The most leading spaces a heading or a list item may have and still be
/// one (four make an indented code block).
const int _maxBlockIndent = 3;

/// The board [text] holds (#1154).
///
/// A column is a `##` heading, a card a top-level `-`, `*` or `+` item
/// under it, and a card's body the lines indented under that item (blank
/// lines between them included). Every other line — the text before the
/// first column, blank lines, headings of other levels, a numbered list,
/// prose between cards — is kept where it is and is not a card. Nothing in
/// the frontmatter, a code fence or a math block is a column or a card: the
/// editor's tokenizer decides, as it does for the list kinds.
///
/// Obsidian's `%% kanban:settings` footer, from its line to the end of the
/// note, is recorded as [KanbanBoard.settingsLine] and never read into
/// columns or cards.
///
/// Line indexes count `text.split('\n')`, so a CRLF note's lines keep their
/// `\r`; the reader sees them without it.
KanbanBoard parseKanban(String text) {
  final lines = text.split('\n');
  final plain = <String>[
    for (final line in lines)
      if (line.endsWith('\r')) line.substring(0, line.length - 1) else line,
  ];
  final doc = HighlightDocument.fromLines(plain);
  final contentLines = lines.last.isEmpty ? lines.length - 1 : lines.length;

  final columns = <KanbanColumn>[];
  var frontmatterEnd = 0;
  int? footer;

  // The open column.
  LineFacts? heading;
  var headingLine = 0;
  var cards = <KanbanCard>[];
  // The open card: where it starts, how it opened, where its body ends.
  LineFacts? cardFacts;
  var cardLine = 0;
  var cardEnd = 0;
  // Whether the line before was a protected line taken into the body, so
  // an unindented line of an indented fence does not end the card.
  var inProtectedBody = false;

  void closeCard() {
    final facts = cardFacts;
    if (facts == null) return;
    cards.add(readCard(plain, cardLine, cardEnd, facts));
    cardFacts = null;
  }

  void closeColumn(int regionEnd) {
    closeCard();
    final open = heading;
    if (open == null) return;
    var last = regionEnd - 1;
    while (last > headingLine && plain[last].trim().isEmpty) {
      last--;
    }
    columns.add(
      KanbanColumn(
        name: open.headingText,
        headingLine: headingLine,
        headingMarkerEnd: open.headingMarkerEnd,
        endLine: regionEnd,
        insertLine: last + 1,
        cards: cards,
      ),
    );
    heading = null;
    cards = <KanbanCard>[];
  }

  for (var i = 0; i < contentLines; i++) {
    final facts = LineFacts.of(doc.lineAt(i));
    if (facts.isProtected) {
      if (i == frontmatterEnd && _isFrontmatter(doc, i)) frontmatterEnd = i + 1;
      if (cardFacts != null &&
          (inProtectedBody || facts.indent > cardFacts!.indent)) {
        cardEnd = i + 1;
        inProtectedBody = true;
      } else {
        closeCard();
        inProtectedBody = false;
      }
      continue;
    }
    inProtectedBody = false;
    if (plain[i].startsWith(kanbanSettingsMarker)) {
      footer = i;
      break;
    }
    if (facts.isBlank) continue;
    final open = cardFacts;
    if (open != null && facts.indent > open.indent) {
      cardEnd = i + 1;
      continue;
    }
    closeCard();
    if (facts.headingLevel == 2 && facts.indent <= _maxBlockIndent) {
      closeColumn(i);
      heading = facts;
      headingLine = i;
    } else if (heading != null &&
        facts.isBullet &&
        facts.indent <= _maxBlockIndent) {
      cardFacts = facts;
      cardLine = i;
      cardEnd = i + 1;
    }
  }
  final contentEnd = footer ?? contentLines;
  closeColumn(contentEnd);

  return KanbanBoard(
    lines: lines,
    columns: columns,
    contentEnd: contentEnd,
    settingsLine: footer,
    frontmatterEnd: frontmatterEnd,
    lineEnding: lineEndingOf(text),
  );
}

bool _isFrontmatter(HighlightDocument doc, int line) {
  for (final token in doc.lineAt(line).tokens) {
    if (token.kind == TokenKind.frontmatter) return true;
  }
  return false;
}
