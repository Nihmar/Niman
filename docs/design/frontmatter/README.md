# Frontmatter — drawings, and the decision

`#157` asked since September how a note's frontmatter should be edited: raw
YAML (what shipped), or a properties UI. A working prototype exists (PR #465);
these are the **drawings**, so the shape could be settled by looking at it
rather than by arguing about it. They were looked at, and the shape is now
settled.

**Decided: the same field rows at the top of the note in *both* surfaces** —
the read view and the live editor — as Obsidian does. The prototype is being
extended to the live editor on `feat/157-frontmatter-properties` (PR #465);
the drawings here are the reference.

Three states, in [html/Panel.html](html/Panel.html):

1. **A — the fields above the note, in the read view.** Key, value and the
   type the parser can already tell apart (text, number, date, boolean,
   list); add and remove a field; **Raw YAML** one toggle away.
2. **B — the same fields inline, at the top of the live editor**, where the
   writing happens: the same rows, in the surface the caret lives in.
3. **C — a frontmatter the parser refuses.** No field rows, no silent repair:
   the panel says why and leaves the raw YAML, which is still editable.

What every state keeps: one edit per change, one undo step, one write to the
one `.md` file — the file stays the only source of truth.

They are mockups, not screenshots of the app: everything here is HTML drawn to
look like Niman, using the real palette from `lib/src/ui/theme/niman.dart`.
Where a mockup and the app disagree, the app is what ships — these record what
was decided, and when.

## What the drawings asked, and the answers

* Does the panel belong in the **read view** (A), in the **editor** (B), or in
  neither (keep raw YAML)? — **Both**: the same rows above the note in the
  read view and in the live editor, from one widget and two call sites, so the
  two cannot drift.
* If it belongs somewhere: do the type chips earn their space, is a row per
  field the right density, and is a toggled raw view enough of an escape
  hatch? — **Yes to all three**: the key, the value and a small chip naming
  the type are one row, **Add a property** is the last row, and the **Raw
  YAML** toggle is the escape hatch. State C keeps the raw YAML as the only
  thing shown for a block that does not parse.
