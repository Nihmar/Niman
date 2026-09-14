# Home-screen widgets

Android only — on Linux and Windows the **Pin to home widget** row
just says the widgets are unavailable.

Add one from the launcher: long-press the home screen, then
**Widgets** → **Niman Todos** or **Niman Note**. Placement walks a
short setup dialog: pick the library from the ones you have open
(or open the app first if there are none yet).

## Niman Todos

- **Rows:** the same open tasks the Todo tab shows with its default
  filter — due date first (overdue on top), ties broken by priority
  (`(A)` first) — up to 100 rows in a scrollable list. The header names the true total even when capped.
- **Meta line:** each row names its priority, due date and
  `+project` / `@context` / `#tag` markers; rows without any of them
  hide the line so the text stays aligned.
- **Tap a row:** toggles the task; works with the app closed.
- **Tap the header:** opens the app on that library.
- **"+":** opens the app with the task add field focused.

## Niman Note

- **Placement:** choose the library, then the note (a `.md` file) in
  the setup dialog — or choose **Pin to home widget** on a note's
  row menu and place the widget; the next placed instance adopts the
  pin.
- **Rows:** a prose note shows its text excerpt; a `type: list` note
  shows its checklist (up to 100 rows, scrollable). Tap a row to
  toggle the item — with the app closed. **"+"** adds an item from a
  home-screen dialog.
- **Tap the note:** opens it in the app.

Both wear the app theme (brightness and palette) and refresh when
the app resumes or the files they show change. To point an instance
at another library or note, remove the widget and place it again —
there is no in-place reconfiguration yet.
