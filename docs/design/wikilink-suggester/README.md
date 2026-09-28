# Wikilink suggester — drawings, and the decision

`#475` asks for the panel Obsidian has and Niman does not: while a wikilink is
typed, list what can go there and filter as the text grows — the library's notes
after `[[`, their headings after a `#`. Writing a link today means remembering
the exact name; a typo writes a dead link that only the report finds later.

The maintainer answered the three questions these drawings were made to ask (the
**Decisions (2026-09-28)** section of `#475`), so they are no longer open. Each
state below is the **decided** shape; where a question is still open it is named
as such.

Six states, in [html/Panel.html](html/Panel.html), each drawn in the app's
window, most again larger (the panel is too small to judge at arm's length):

1. **After `[[`** — the library's notes, each row a name and the folder
   dimmed. Two pairs share a stem, so the folder is what tells them apart, and
   one row is found through an **alias** rather than its name, and says so.
2. **While typing** — the same panel filtered as the text grows: prefix
   matches first, then contains; the top row is selected, and the footer
   carries the keys (`↑↓ move · ⏎ or Tab insert · Esc close`).
3. **After `#`** — the headings of the note just named, filtered the same way;
   and the empty target (`[[#…`) offering the **current** note's headings.
4. **Nothing matches** — **4a**, the decided shape: the panel says so and offers
   nothing. **4b**, the `New note` row, is drawn **decided against** — the panel
   lists only what exists. **4c** draws where a new note actually comes from:
   ctrl+click on the dead link (`#477`).
5. **A book target** — the decided `#` shape when the link names a PDF or an
   EPUB: the completion offers its pages and chapters,
   `[[Dune.pdf#page=34]]` and `[[Dune.epub#chapter=…&line=12]]`, the forms
   `docs/user/links.md` documents.
6. **In `source` too** — the same panel over the raw text: both surfaces carry
   it.

What every state keeps: the panel writes nothing but the link that was chosen —
it never invents a note; a note nobody has written is made from the dead link
itself, on ctrl+click (`#477`), not from a row in the panel. `Escape` closes the
panel and leaves the text alone. The rows come from the index the app already
keeps (`note_stems`, aliases, the outline's heading scan); nothing here needs a
new scan to fill.

The panel appears in **both** surfaces: drawn here in the **live editor**, at
the caret's own rectangle — the same seam the touch toolbar uses — and drawn
again over **`source`** (state 6), the same rows over the raw text.

They are mockups, not screenshots of the app: everything here is HTML drawn to
look like Niman, using the real palette from `lib/src/ui/theme/niman.dart`.
Where a mockup and the app disagree, the app is what ships — these record what
was drawn, and what was decided.

## What the drawings record

The maintainer's three answers (2026-09-28, on `#475`):

* **A `New note` row when nothing matches — no.** A wikilink that names nothing
  is a *dead link*, and a dead link is where a new note comes from: ctrl+click
  on it creates the note it names (`#477`). So the panel lists only what exists
  and says so plainly when nothing matches — **4a** is the decided shape; the
  `New note` row (**4b**) is kept only to record that it was asked and turned
  down.
* **Live surface only, or `source` too — both.** The panel is drawn in the live
  editor and again over `source` (**6**): the same rows and the same keys, in
  the raw text.
* **The book forms — in scope.** When the link's target resolves to a PDF or an
  EPUB, the `#` completion offers its pages and chapters (**5**):
  `[[Dune.pdf#page=34]]`, `[[Dune.epub#chapter=…&line=12]]`. The earlier lean —
  that a book had "no list to offer", only a `page=` form to type — was the
  drawing agent's, not the decision; it went the other way, and an EPUB's named
  chapters are as much a list to filter as the library's notes.

Still open: **what a tap does on touch.** There is no ctrl on a phone, so what a
tap on a dead link should do — offer the creation, or keep the present message —
is left to [`#477`](https://github.com/Nihmar/Niman/issues/477), the issue that
carries the question.

## Re-rendering these

The source is in [`html/`](html) — a plain, self-contained HTML file with no
build step and no external assets. Edit it and render it with headless Chrome:

```bash
chrome --headless --disable-gpu --hide-scrollbars \
  --window-size=1280,900 --screenshot=Panel.png html/Panel.html
```

The full windows are 1180px wide and best read in a browser at any width.
