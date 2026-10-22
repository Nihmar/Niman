# Kanban boards

A **board** is a note whose frontmatter says `type: kanban`. The app shows
it as columns of cards instead of a document: you move a card by dragging
it (or from a menu), tick it, edit it and add the next one. It is still an
ordinary `.md` file — the pencil beside the ⋮ opens the raw editor — and
everything the board writes is plain Markdown, so the same file reads as
sections and tasks in any other editor.

Kanban boards are one of the [Features](features.md). Switched off, a
board opens as plain Markdown with its `type:` kept.

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

This is the format of the Obsidian Kanban plugin: a board made there opens
here, and the other way round. Obsidian's `%% kanban:settings %%` footer is
kept untouched at the end of the file.

Create one with **New kanban board** in the Files FAB, the New menu of the
tree, **New kanban board here** on a folder, or the command palette. A new
board has three empty columns: *To do*, *Doing* and *Done*.

## How the file is read

- A **`##` heading is a column**; its text is the column's name.
- A **list item at the top level of a column is a card** — with a box
  (`- [ ]`, `- [x]`) or without (`- text`). Its first line is the title;
  the lines indented under it are its body.
- A card shows its `#tags` and its `due:YYYY-MM-DD` as chips, and a link
  in its title follows as it does in the read view.
- The order of the columns and of the cards is the order in the file.
  Nothing else holds it.
- Anything else — text before the first column, a paragraph between
  cards, a heading of another level — stays where it is and is not a
  card.
- Ticking a card does not move it, and moving a card into *Done* does not
  tick it.

Every change rewrites only the lines it touches; the rest of the file
keeps its bytes, line endings included. One change is one step of the
note's undo.

## On a computer and a tablet

A window wide enough shows the columns side by side, scrolling sideways.

- **Drag** a card to another column or within its column; a bar shows
  where it will land. With a finger, press and hold the card first.
- **Tap** a card to select it, tap its title again to edit it; `Enter`
  saves, `Esc` cancels.
- **Add a card** with the dashed field at the foot of a column and a
  **column** with the one after the last column. The column's ⋮ renames
  or deletes it.
- A card's ⋮ (or a right-click) moves it left, right, up or down, and
  deletes it.

Keys, on the selected card: `Alt+←` / `Alt+→` move it to the neighbouring
column, `Alt+↑` / `Alt+↓` within its column, `Enter` edits, `Space` ticks,
`Delete` removes, the arrows move the selection.

## On a phone

A narrow screen shows **one column at a time**: tabs along the top carry
each column's name and its number of cards, and swiping changes column.

- **Press and hold** a card for its sheet: **Move to…** lists the other
  columns and puts the card at the end of the one you pick; **Move up**
  and **Move down**, **Edit** and **Delete** follow. There is no
  dragging across columns on a narrow screen.
- The ⋮ beside the tabs renames or deletes the column on screen, and **+**
  adds a column.

## Without dragging

Every move has a way that needs no drag — the keys, the card's menu, the
phone's sheet. A screen reader reads a card as *Card 2 of 5, column
Doing*, offers the moves as actions on it, and announces where a card
went.

## Not yet

HTML, PDF and EPUB export show a board as its sections and tasks; drawing
the board is tracked in #1170. Several boards in one view, cards that are
notes, and a board over a query of tags are tracked in #1171.
