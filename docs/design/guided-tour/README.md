# The guided tour — drawings, and what they ask

`#266` asks for a guided tour that shows a new user around the app's features,
one step at a time, pointing at the real controls. The welcome deck
(`docs/design/welcome/`) introduces the app; the tour is act two — the same
ground again, but over a real library, with each step spotlit.

These are the **drawings**, so the shape is settled by looking at it. They
answer nothing on the maintainer's behalf: where the issue left a choice open,
the drawing shows the one it judged and says why; where the choice is still
open, it is left open below.

Two files, self-contained HTML, no external CSS or JS:

* [html/Tour.html](html/Tour.html) — the **desktop** steps, the **offer**, where
  the tour comes back, and the **playground**.
* [html/Phone.html](html/Phone.html) — the **phone** steps, at 390×844.

They are mockups, not screenshots of the app: everything here is HTML drawn to
look like Niman, using the real palette from `lib/src/ui/theme/niman.dart`
(night). Where a mockup and the app disagree, the app is what ships — these
record what was drawn, and what it asks.

## What is drawn

**Desktop** (`Tour.html`) — three steps of the wide walk, each with the whole
window at the scrim and a rounded hole over the control it talks about, the
card beside it carrying the counter, the heading, the prose and
`Back` / `Next` / `Skip`:

1. **The tree** (step 1 of 8) — the hole is the tree pane's own rectangle; the
   note, the rail and the title bar sit under the dim. No `Back`: there is
   nowhere behind it.
2. **The mode switch** (step 4 of 8) — the small switch at the foot of the
   note, the card above it because there is no room below. The step is left out
   when the library offers only one editor.
3. **The dock** (step 7 of 8) — the right dock, outline / tags / history.

The last step (step 8) is drawn with the **playground** below.

**The offer** (`Tour.html`) — the welcome deck's last page with *Show me around
the app* checked, then the one dialog the shell raises after the first library
opens: *Show you around?* · *Not now* / *Show me*. The offer is spent the moment
it is shown, and declining leaves the tour to Help and the palette.

**Where it comes back** (`Tour.html`) — the two entries, drawn side by side: the
**Diagnostics and info** row *Take the tour*, and the **palette** command of the
same name. *What Niman can do* beside them reopens the deck, read-only.

**The playground** (`Tour.html`) — the last step's card (button **Open it**, not
`Next`) hands the tour over to the **cheatsheet** (#265): written beside shown,
with Copy and Insert on every row.

**Phone** (`Phone.html`) — the bottom bar (step 6 of 7) and the toolbar (step 5
of 7), the two controls the issue names for the phone. Same drawing, the
platform's own control.

## What every step keeps

The **dim never hides the control it is talking about**: one scrim at the app's
`55%`, minus the target's own rectangle inflated `6 px`, edged in `2 px` of the
accent at a `12 px` radius. A control that is not on screen — a hidden rail, a
closed dock, a source switch turned off — registers nothing, so its step is
**skipped**, never pointed at nothing. The card sits below the control when
there is room under it and above it otherwise, kept inside the window.

## What the drawings ask

* **Offered once, skippable** (the issue's own requirement). Drawn as the deck's
  checkbox plus the single shell dialog. Left open: whether the offer should be
  a dialog at all, or an affordance inside the shell that is easier to ignore.
* **Re-runnable from Help and the palette.** Drawn as the Diagnostics row and
  the palette command, which are the same call: a walk left half-way resumes, a
  finished one starts over. Left open: whether *Take the tour* vs *Continue the
  tour* should be two rows or one.
* **Each step spotlights a real control, with `Next` / `Back` / `Skip`.** Drawn
  with the counter in the card's top-left and `Skip` at its top-right, `Back` /
  `Next` at the foot, `Done` on the last. Left open: whether `Skip` belongs in
  the card's header (drawn) or only at its foot.
* **Per-platform steps.** Desktop draws **8** (tree, create, note, modes,
  toolbar, tabs/rail, dock, cheatsheet); a phone draws **7** — the same walk
  without the dock, whose three panes the phone reaches through the note's menu.
  Left open: the issue lists the **command palette** and **search** among the
  candidate steps; the drawing points at the shell controls instead, because the
  palette is where the tour is *reached from*, not something a spotlight over a
  shell gets at. Whether they earn steps of their own is the maintainer's call.
* **The playground.** The drawing is firm here and says why below.

## The playground: the cheatsheet, not a sample note

`#265`'s cheatsheet is the tour's playground. A sample note would either be
**left behind** in a library the user just met, or have to be **cleaned up
afterwards** — a tour that leaves litter or a deletion behind it. The cheatsheet
is already there, it teaches the syntax rather than one note's words, and the
user walks away with exactly what they chose to **Insert** — nothing else. So
the last step writes nothing of its own: it opens the cheatsheet and ends.

(If the maintainer would rather the tour run inside a note, the drawing above is
still the shape; only the target of the steps and the bookkeeping of any note
created for it change.)

## Where the app already stands

The tour is **in the app**: `lib/src/ui/tour/` holds the overlay, the steps, the
targets and the host (`tour_host.dart` — the offer, the palette and the Help
entry), the first-run state is `lib/src/core/welcome.dart`, and the steps point
through `TourTargets` at the tree, the create affordance, the note, the mode
switch, the toolbar, the nav, the dock and the cheatsheet. This folder draws
that shape state by state, so it can be judged and changed by looking — the same
role `docs/design/frontmatter/` plays beside its prototype.

## Re-rendering these

The source is in [`html/`](html) — a plain, self-contained HTML file with no
build step and no external assets. Edit it and render it with headless Chrome:

```bash
chrome --headless --disable-gpu --hide-scrollbars \
  --window-size=1360,880 --screenshot=Tour.png html/Tour.html
chrome --headless --disable-gpu --hide-scrollbars \
  --window-size=680,940 --screenshot=Phone.png html/Phone.html
```
