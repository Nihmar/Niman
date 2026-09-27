# List notes and shopping lists

A **list note** is a note whose frontmatter says `type: list`. The app
shows it as a checklist instead of a document: every task line of the
note becomes a row you can tick, nest, drag, edit and delete, and a
field at the bottom adds the next one. The note is still an ordinary
`.md` file — the raw editor (the pencil beside the ⋮) always has it, and
everything the GUI writes is plain Markdown.

```markdown
---
type: list
---
- [ ] Pane
- [ ] Latte
  - [ ] quello intero
```

Create one with **New list note** in the Files FAB (or
`Ctrl/⌘+Shift+N`), which puts it in the library's list folder
(`listNoteFolder`, default `Lists` — see [settings](settings.md)).

## The rows

- **Tick** the box to flip `[ ]` and `[x]`. A ticked item stays in the
  note and reads struck through; it is not removed.
- **Tap the text** to edit it in place. A long text scrolls itself when
  it does not fit the row, as a note's name does in the tree.
- **Drag the handle** on the left to reorder an item. Dropping it onto
  the upper or lower edge of another row puts it before or after that
  row; dropping it onto the middle makes it a child of that row. A
  parent moves with its whole subtree, prose lines included.
- **Indentation is the nesting**: an item indented under another is its
  child, exactly as it reads in the raw note.
- **The trash** at the end of a row deletes that item and its subtree at
  once, with **Undo** in the snackbar for a few seconds. The note's own
  edit history reaches it too.
- **Add an item** from the field at the bottom; after each add the list
  scrolls to the item just written. Pressing Enter adds and keeps the
  field ready.

Prose between items is not shown in the GUI (the raw editor is where it
lives), and it follows the item above it when that item is dragged or
deleted.

## Shopping lists

A **shopping list** is a list note with a quantity per item
(`type: shopping-list`). It is not a separate thing you create: open a
list note, open its **⋮** menu and pick **Shopping list**. The same
menu entry reads **Checklist** on a shopping list, to turn it back.

The list keeps its name, its folder and its lines through the switch —
only the frontmatter's `type` changes, so the two are the same file read
two ways.

What changes is the quantity:

- Every row shows a `×N` pill. Tapping it edits the quantity; leaving it
  at one writes no marker at all.
- An in-place edit shows the name and the number side by side, and a
  tap on the pill opens the same edit with the number focused.
- The add row has its own chip: pick a quantity, add the item, and the
  chip goes back to one. Quick counts are one tap away; the stepper goes
  up to 99.
- Typing the quantity yourself works too: `latte x2` in the add field is
  added as `Latte ×2`.

The quantity is part of the item's own text, so the note stays portable
Markdown:

```markdown
---
type: shopping-list
---
- [ ] Latte ×2
- [ ] Pane
- [ ] Uova ×6
```

`×` is what the app writes; a hand-typed `x` or `X`, spaced or glued, is
read the same (`Latte x2`, `Latte X 2`). A quantity of one is the
absence of a marker. Quantities are whole numbers, and the item's name
carries whatever unit it needs (`Farina 0`, `1 kg di mele` is a quantity
of one item whose name says the rest).

A note that goes back to `list` keeps its `×2` as ordinary text: nothing
is rewritten on the way, so a round trip loses nothing. The **Count a
list** tool in the editor's Tools works on any list and is a different
thing (see [editing](editing.md)).

## On the home screen

A pinned list note's home-screen widget shows the checklist (up to 100
rows, scrollable), and a shopping list shows each row with its quantity
folded into the text. Tap a row to tick it with the app closed; see
[home-screen widgets](widgets.md).
