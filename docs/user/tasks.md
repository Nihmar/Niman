# Tasks and reminders

The Todo tab reads `todo.txt` files (todo.txt grammar: `x (A)
2016-05-20 2016-04-30 description +project @context #tag key:value`).

## Line anatomy

- `x ` marks completion; `(A)`…`(Z)` is priority; dates are
  completion-then-creation on done lines, creation-only otherwise.
- `+project`, `@context`, `#tag` tokens carry filing meaning and power
  the filter chips.
- `key:value` tags are annotations. Known: `due:YYYY-MM-DD` (badge,
  filter) and `rem:YYYY-MM-DDTHH:MM` (schedules a reminder).
- Untouched lines round-trip byte-stable; edits normalize spacing.

## Editing and deleting

Tap a task to edit it; the trash icon in the dialog's title deletes it.
Long-press a row (right-click on desktop) for the same Edit / Delete as
a menu, or swipe it to the left (drag it, with a mouse) and confirm. Deleting removes the line from `todo.txt` (or `done.txt`, in the
Done view) outright: there is no trash for tasks. To keep a finished
task, check it instead.

## Reminders

Add `rem:2026-09-20T09:00` to a task and Niman schedules an exact alarm
in local wall-clock time. It fires with the screen off, the app in the
background, or the process killed (Android). The app warns when
notification or battery-optimization permissions could block delivery.
On Android, the battery warning's **Open settings** goes straight to
Niman's battery page: pick **Unrestricted**.

Notification text is the task's prose without `key:value` tags (and
without `+`/`@`/`#` markers unless the library's `reminderShowTokens`
is true).

## Home-screen widget

Android: the **Niman Todos** widget mirrors the tab's open view —
due-soonest first — and toggles a task on a row tap, with the app
closed or not. See [widgets](widgets.md).

## Settings

Per library (`.niman/settings.json`): `reminderShowTokens` (default
false). Global debug log (last 5 000 lines, exportable, survives
reboots) helps diagnose missed reminders.

A reminder whose time has passed gets a `todo reminders: overdue` line
in the log, saying what happened to it:

- **Android**, where the system holds the alarm: `STILL PENDING, never
  fired` (the system is still holding it past its time) or `no longer
  pending, fired`, plus the two settings that can defer an alarm, exact
  alarms and battery optimization.
- **Linux and Windows**, where the alarm is a timer inside Niman:
  `timer fired … late`, `timer STILL ARMED past its time` (the machine
  slept through it) or `NOT FIRED` (Niman was not running at its time;
  it fires as soon as Niman starts). A desktop reminder needs Niman
  running, in the tray if the window is closed.
