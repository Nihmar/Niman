# Wikilink suggester — drawings, and the decision

`#475` asks for the panel Obsidian has and Niman does not: while a wikilink is
typed, list what can go there and filter as the text grows — the library's notes
after `[[`, their headings after a `#`. Writing a link today means remembering
the exact name; a typo writes a dead link that only the report finds later.

These are the **drawings**, so the shape is settled by looking at it. They
answer nothing on the maintainer's behalf: the three questions the issue opened
with are drawn as *states*, to be taken or left.

Five states, in [html/Panel.html](html/Panel.html), each at window size and
again larger (the panel is too small to judge at arm's length):

1. **After `[[`** — the library's notes, each row a name and the folder
   dimmed. Two pairs share a stem, so the folder is what tells them apart, and
   one row is found through an **alias** rather than its name, and says so.
2. **While typing** — the same panel filtered as the text grows: prefix
   matches first, then contains; the top row is selected, and the footer
   carries the keys (`↑↓ move · ⏎ or Tab insert · Esc close`).
3. **After `#`** — the headings of the note just named, filtered the same way;
   and the empty target (`[[#…`) offering the **current** note's headings.
4. **Nothing matches** — the panel's own words; and, as a *separate state*, the
   optional **`New note`** row (question 1).
5. **The book probe** — what `[[Dune.pdf#` could offer (question 3).

What every state keeps: the panel writes nothing but the link that was chosen —
it never invents a note, and `Escape` leaves the text alone. The rows come from
the index the app already keeps (`note_stems`, aliases, the outline's heading
scan); nothing here needs a new scan to fill.

The panel is drawn in the **live editor**, at the caret's own rectangle — the
same seam the touch toolbar uses. Whether `source` gets it too is question 2,
and is left open.

They are mockups, not screenshots of the app: everything here is HTML drawn to
look like Niman, using the real palette from `lib/src/ui/theme/niman.dart`.
Where a mockup and the app disagree, the app is what ships — these record what
was drawn, and what it asks.

## What the drawings ask

* **A `New note` entry when nothing matches** (question 1). Drawn as two states
  side by side: **4a** is the panel's own words with nothing found, **4b** adds
  the `New note “zzz”` row. They are shown together so the row can be accepted
  or dropped on its own; the drawing does not decide.
* **Live surface only, or `source` too** (question 2). Every state is drawn in
  the live editor, where the caret and the line layout live. The drawing does
  not answer whether `source` shares it.
* **The book forms** (question 3). Drawn as a small probe (state 5) rather than
  argued in prose, so the question can be answered by looking — and because the
  probe *is* the answer: after `Dune.pdf#` there is no list to offer, only the
  form `page=` to type. A page is picked, not named, so a suggester has nothing
  to suggest. The row is drawn; whether it earns its place is the maintainer's
  call.

## Re-rendering these

The source is in [`html/`](html) — a plain, self-contained HTML file with no
build step and no external assets. Edit it and render it with headless Chrome:

```bash
chrome --headless --disable-gpu --hide-scrollbars \
  --window-size=1280,900 --screenshot=Panel.png html/Panel.html
```

Each window is 1180px wide and best read in a browser at any width.
