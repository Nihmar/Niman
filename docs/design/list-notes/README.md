# List notes — mockups

Three changes to the `list` note kind, drawn before any of them is
written:

1. **Delete an item** — a trash on every row; a tap deletes the
   item's subtree at once, and the snackbar offers Undo.
2. **The add row scrolls the list to the new item** — no visual change,
   only behavior.
3. **A `shopping-list` subtype, with a quantity per item** — reached
   only from the open list note's ⋮ menu; there is no "New shopping
   list" anywhere.

A long item text marquees when it overflows its width, exactly as a
note's name already does in the tree and the title bar (`MarqueeText`).

They are mockups, not screenshots of the app: everything here is HTML
drawn to look like Niman, using the real palette from
`lib/src/ui/theme/niman.dart`. Where a mockup and the app disagree, the
app is what ships — these record what was decided, and when.

## The screens

### [Desktop](html/Desktop.html) — the list, and the shopping list

Two 1280×800 windows, one above the other:

- The list as it is today plus the trash on each row.
- **The shopping list**: the name, the quantity pill (`×2`), the trash,
  one row open in place — the name field and the quantity field side by
  side — and the add row with its own quantity chip.

The trash is on every row and keeps its place while a row is edited: a
control that comes and goes would move what is under the thumb already
on it. A tap deletes the item and its sub-items at once; the snackbar's
**Undo** puts them back.

### [Phone](html/Phone.html) — three 390×844 states

- The shopping list itself.
- The quantity sheet, opened by the pill.
- **Deleted**, with the snackbar's **Undo**.

### [Menu](html/Menu.html) — the way into the subtype

The open list note's ⋮ menu, with **Shopping list**; and, on a shopping
list, the same entry reading **Checklist** to come back. Nothing is
created from the create menu: a shopping list is a list note turned,
which is what keeps one kind of file in `Lists/`.

## The line format

The quantity lives in the item's own text, so the note stays plain
Markdown:

```markdown
- [ ] Latte ×2
- [ ] Pane
- [ ] Uova ×6
```

`×` is the canonical glyph the GUI writes; a raw `x` or `X`, spaced or
glued, reads the same (`Latte x2`). A quantity of one is not written at
all: `- [ ] Pane` is one, and setting it back to one leaves the line
without a marker rather than writing `- [ ] Pane ×1` into the file.

## Re-rendering these

The sources are in [`html/`](html) — plain, self-contained HTML files
with no build step and no external assets. Edit one and render it with
headless Chrome:

```bash
chrome --headless --disable-gpu --hide-scrollbars \
  --window-size=1280,800 --screenshot=Desktop.png html/Desktop.html
```

`Phone.html` is best read in a browser at any width; each of its frames
is 390×844.
