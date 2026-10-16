# Home-screen widgets

Android only — on Linux and Windows the **Pin to home widget** row
just says the widgets are unavailable.

Add one from the launcher: long-press the home screen, then
**Widgets** → **Niman Todos**, **Niman Note** or **Niman Study**. Placement walks a
short setup dialog: pick the library from the ones you have open
(or open the app first if there are none yet).

## Niman Todos

- **Sections:** the open tasks are grouped as the Todo tab does when
  sorted by due date — **Overdue**, **Today**, **Next 7 days**,
  **Later**, **No date** — each heading with its count. A section with no
  task is not shown. Within a section the order is the tab's: due date,
  ties broken by priority (`(A)` first). The widget has no Done section
  (open tasks only), no sort and no filter of its own, and it always
  shows every section open: a heading is not a button, so folding a
  section in the app does not fold it here. The list scrolls and holds up
  to 100 tasks; a section's count is the number of tasks listed under it,
  so a heading never promises more than the widget shows, while the
  header's `N open` stays true even when the list is capped.
- **At midnight:** the sections depend on the day, so the widget
  re-reads your `todo.txt` when the day turns over — with the app closed —
  and moves a task due yesterday from *Today* to *Overdue* (and the rest
  of the buckets with it). The same refresh runs when the clock or the
  time zone changes and after a restart. It is an inexact system alarm,
  so it can land a few minutes after midnight, and it only runs while a
  Todos widget is placed.
- **Meta line:** each row names its priority, due date and
  `+project` / `@context` / `#tag` markers; rows without any of them
  hide the line so the text stays aligned. The section already says what
  it says, so a row under *Today* does not repeat its date; an *Overdue*
  row keeps it.
- **Tap a row:** toggles the task; works with the app closed.
- **Tap the header:** opens the app on that library.
- **"+":** opens the app with the task add field focused.

## Niman Note

- **Placement:** choose the library, then the note (a `.md` file) in
  the setup dialog — or choose **Pin to home widget** on a note's
  row menu and place the widget; the next placed instance adopts the
  pin.
- **Rows:** a prose note shows its text excerpt; a `type: list` note
  shows its checklist (up to 100 rows, scrollable) and a
  `type: shopping-list` note the same, each row's quantity folded into
  its text. Tap a row to toggle the item — with the app closed. **"+"**
  adds an item from a home-screen dialog.
- **Tap the note:** opens it in the app.

## Niman Study

- **Rows:** the [flashcard](flashcards.md) decks with cards to study
  today, grouped by their `deck:` — the categories alphabetically, *No
  category* last — each with its due and new cards; the header names the
  library and today's cards.
- **Tap a deck:** opens it in the app.
- **Tap the header:** opens Study.
- **When it changes:** on a grade, on a deck edited, synced or reset, and
  when the app comes back after the day turned (the journal's *A new day
  starts at* applies). The app counts the decks; with the app closed
  across midnight, the widget shows yesterday's cards until it is opened.

A widget that points at another library than the open one switches to it,
saving the open notes first; a note that cannot be saved keeps the current
library open and says so, and the tap opens nothing.

All three wear the app theme (brightness, palette and, for the Overdue
heading, the palette's error color) and refresh when
the app resumes or the files they show change. To point an instance
at another library or note, remove the widget and place it again —
there is no in-place reconfiguration yet.
