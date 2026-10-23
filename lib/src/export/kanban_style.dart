/// The style of an exported kanban board (#1170), added to a page's own
/// only when a board is on it.
///
/// One look for the cards and the chips, and a layout per medium: columns
/// side by side on a screen (stacked on a narrow one), a row or a grid on
/// paper by the sheet the board is printed on ([KanbanSheet]), and stacked
/// sections in an EPUB, whose readers paginate narrow.
library;

import 'package:niman/src/export/kanban_sheet.dart';

/// The cards, the chips and the column heads: shared by every medium, on
/// the page's own colour variables.
const String _look = '''
.kanban-column-head { display: flex; align-items: baseline;
  justify-content: space-between; gap: 0.5em; break-after: avoid; }
.kanban-column-head h2 { font-size: 1.05em; margin: 0 0 0.6em; }
.kanban-count { color: var(--muted); font-size: 0.85em; }
ul.kanban-cards { list-style: none; margin: 0; padding: 0; }
.kanban-card { background: var(--bg); border: 1px solid var(--line);
  border-radius: 8px; padding: 0.5em 0.7em; margin: 0 0 0.5em;
  break-inside: avoid; }
.kanban-card-title > :last-child { margin-bottom: 0; }
.kanban-done .kanban-card-title { color: var(--muted);
  text-decoration: line-through; }
.kanban-card-title input { margin: 0 0.4em 0 0; }
.kanban-chips { margin-top: 0.3em; }
.kanban-chip { display: inline-block; font-size: 0.8em; line-height: 1.4;
  padding: 0 0.6em; margin: 0 0.3em 0.2em 0; border-radius: 10px;
  background: var(--code-bg); border: 1px solid var(--line);
  color: var(--accent); }
.kanban-due { color: var(--muted); }
.kanban-card-body { margin-top: 0.4em; font-size: 0.92em; }
.kanban-card-body > :last-child { margin-bottom: 0; }
.kanban-prose { margin: 0 0 0.6em; color: var(--muted); }
.kanban-prose > :last-child { margin-bottom: 0; }
''';

/// A board's style on a page: [sheet] is the one the board prints on.
String kanbanPageStyle(KanbanSheet sheet) {
  final gap = '${kanbanGapMm.toStringAsFixed(0)}mm';
  final margin = '${kanbanMarginMm.toStringAsFixed(0)}mm';
  final print = switch (sheet) {
    // Every column in one row, sharing the width.
    KanbanSheet.landscape =>
      '''
  @page { size: A4 landscape; margin: $margin; }
  .kanban { display: flex; gap: $gap; overflow: visible; }
  .kanban-column { flex: 1 1 0; }
''',
    // A grid that wraps, a few columns to a row.
    KanbanSheet.portrait =>
      '''
  .kanban { display: grid;
    grid-template-columns: repeat($kanbanPortraitColumns, minmax(0, 1fr));
    gap: $gap; overflow: visible; }
''',
  };
  return '''
.note { max-width: none; }
.kanban { display: flex; gap: 1em; align-items: flex-start; overflow-x: auto;
  margin: 0 0 1em; padding-bottom: 0.5em; }
.kanban-column { flex: 0 0 16em; min-width: 0; box-sizing: border-box;
  background: var(--code-bg); border: 1px solid var(--line);
  border-radius: 8px; padding: 0.6em 0.7em; }
$_look@media (max-width: 600px) {
  .kanban { flex-direction: column; align-items: stretch; overflow-x: visible; }
  .kanban-column { flex: none; }
}
@media print {
$print  .kanban { align-items: start; }
  .kanban-column { background: none; }
}
''';
}

/// A board's style in an EPUB chapter: the columns one section after
/// another, as a reader that paginates narrow shows them.
const String kanbanEpubStyle = '''
.kanban-column { margin: 0 0 1.2em; }
$_look''';
