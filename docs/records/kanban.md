# Kanban board (#1154)

A note with `type: kanban` is a **board**: columns of cards, shown and
edited as a board on a phone, a tablet and the desktop. Written before the
code (2026-10-22), as the design the implementation issues follow. Nothing
is built under #1154.

The constraint that shapes all of it is the app's first rule: **the disk is
the source of truth.** A board is one `.md` file that reads as an ordinary
note — sections and tasks — in any other editor. The view only rewrites
lines of it.

## The note

```markdown
---
type: kanban
---
## To do
- [ ] Write the brief #work
- [ ] Book the venue due:2026-11-10

## Doing
- [ ] Draft the slides
  Outline first, then visuals.

## Done
- [x] Pick the date
```

This is the format of the Obsidian Kanban plugin, so a board made there
opens here and the other way round.

- **`type: kanban`** makes it a board. Like `type: slides` and
  `type: flashcard`, it opens in its own view wherever it is opened from,
  and **Edit as Markdown** shows the text.
- **A `##` heading is a column**; its text is the column's name.
- **A top-level list item is a card.** `- [ ]`, `- [x]` and a plain `- `
  are all cards; the box, when there is one, stays as written.
- **A card's first line is its title.** The lines nested under it (by
  indentation) are its body.
- **On the card**, read from its lines with the parsers the app already
  has: `#tags`, `due:YYYY-MM-DD`, links and wikilinks, pictures.
- **Order is the file's order**, for the columns and for the cards. There
  is no other source of order.
- Text before the first `##` (and any line that is neither a heading, a
  card nor a card's body) is **kept where it is** and is not a card.
- The Mermaid `kanban` fence is unchanged: a read-only diagram.

## Round-trip rules

- An edit rewrites **only the lines it touches**. Every other line keeps its
  bytes, line endings included; a moved card keeps its bytes apart from the
  leading spaces. The model is `moveSubtree` in `list_parser.dart`, and the
  write goes through `NoteKindHost.applyEdit`.
- Obsidian's `%% kanban:settings %%` footer (and the fenced block after it)
  is **read and kept untouched**, never written by Niman.
- A heading level other than `##` inside a board is prose, not a column.
- A card moved to an empty column lands right under its heading; a card
  moved to the end of a column lands before the blank line that separates
  it from the next heading, so the file's spacing is kept.
- Undo is the note's own: one board edit is one `applyEdit`, hence one step.

## The view

One model, three shapes (every platform ships every feature; the shape
adapts to the surface).

### Desktop and tablet in landscape

- Columns side by side, each a fixed width, the board scrolling
  horizontally.
- A card dragged between columns and within one, which rewrites the lines.
- A card edited in place; **Add a card** at the end of each column and
  **Add a column** at the end of the board.
- Keyboard: `Alt+←/→` moves the focused card to the neighbouring column,
  `Alt+↑/↓` within its column, `Enter` edits, `Delete` removes (with undo).

### Tablet in portrait

As the desktop, two or three columns in view and horizontal scroll.

### Phone

- **One column at a time**, swiped; tabs along the top carry each column's
  name and count.
- The cards of the column in a list.
- **Moving a card**: long-press, then a **Move to…** sheet listing the
  columns (and *Move up / Move down*). No cross-column drag on a narrow
  screen.

### Everywhere

- The source editor is a toggle away (the pencil beside the ⋮).
- Controls keep their place: a button that does not apply is disabled, not
  removed.
- Icons are outline.
- Every move is available without drag (the menu, the keys); a screen
  reader says *Card 2 of 5, column Doing*, and *moved to Done*.

## Decided (2026-10-22)

1. **Syntax**: headings as columns, list items as cards (option 1 of the
   issue). The Mermaid fence stays a diagram; a table is not a board.
2. **No per-column setting in v1** (WIP limit, collapsed column). If one
   comes, it goes in the frontmatter and does not change the syntax.
3. **Done**: ticking a card and moving it are independent. A column named
   *Done* does not tick what enters it, and a ticked card does not move.
4. **`todo.txt`**: a board is self-contained. A link between cards and
   tasks belongs to the todo↔note links issue.
5. **Out of scope, later issues**: several boards in one view, cards that
   are notes, a board over a query of tags, drawing the board in HTML, PDF
   and EPUB export (they show it as sections until then).

## Phases

One branch, `feat/kanban`, one PR into `main`; a commit per step.

1. **The model**: reader and byte-stable edits (move, add, edit, delete,
   column add/rename/delete), the settings footer kept; unit tests,
   including files written by Obsidian.
2. **The kind**: `type: kanban` in `NoteKinds`, `LibraryFeature.kindKanban`,
   New → Kanban board.
3. **The wide view**: columns, drag, inline edit, keys.
4. **The phone view**: column tabs, the list, **Move to…**.
5. **Docs**: `docs/user/kanban.md`, `platforms.md`, the editing page's
   Mermaid entry pointing to the kind; this record's *As built*.

Main risk: a heading-and-list note not written for a board (prose between
cards, nested headings). Kept to the rules above and tested on such files.

## As built (2026-10-22)

Phases 1–4 in `feat`-prefixed commits on `docs/kanban-record` (#1165,
#1166, #1167, #1168); the user documentation is `docs/user/kanban.md`.

- **Model** (`lib/src/kanban/`): `parseKanban` and the edits. Only `-`, `*`
  and `+` items open a card (at most three spaces in); numbered items are
  prose. Tags and `due:` are read from the title line through
  `parseTodoLine`. An edit takes the text and column/card indexes and
  parses internally, so a caller cannot hand it a stale board. A move's
  `toIndex` is the card's final place in the destination.
- **Limits**: a 40,000-card board takes about a second to read, since the
  tokenizer reads every line. A note whose first line is `---` with no
  closing one is all frontmatter, so it has no column.
- **Kind**: `KanbanKindGui`, `LibraryFeature.kindKanban`, offered by the
  FAB, the tree footer's New menu, **New kanban board here**, and the
  `newKanban` command (no default chord). The Study empty state has no
  entry: its button is the deck's.
- **Wide view**: also used by a tablet in portrait. Pointers pick a card
  up at once, touch needs a long press; a touch screen on a desktop
  platform does not drag, and uses the card menu or the keys. `Alt+←/→`
  on a focused card moves the card, ahead of the global back/forward.
  Deleting a column asks nothing; the note's undo restores it.
- **Phone view**: tabs with counts, the ⋮ beside the strip for the
  column, **+** for a new column (selected after it is made), and the
  card's sheet for **Move to…**. The selected column survives edits.
- **Not tried**: either view running in the real app (the tests use a
  harness, not the shell), a screen reader speaking the announcements,
  and the vertical edge scroll of a column during a drag.
