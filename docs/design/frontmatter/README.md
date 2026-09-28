# Frontmatter — mockups

`#157` has asked since September how a note's frontmatter should be edited:
raw YAML (what ships today), or a properties UI. A working prototype exists
(PR #465); these are the **drawings**, so the shape can be settled by looking
at it rather than by building the next version of it.

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

## What the drawings ask

* Does the panel belong in the **read view** (A), in the **editor** (B), or in
  neither (keep raw YAML)?
* If it belongs somewhere: do the type chips earn their space, is a row per
  field the right density, and is a toggled raw view enough of an escape
  hatch?
