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

## Reminders

Add `rem:2026-09-20T09:00` to a task and Niman schedules an exact alarm
in local wall-clock time. It fires with the screen off, the app in the
background, or the process killed (Android). The app warns when
notification or battery-optimization permissions could block delivery.

Notification text is the task's prose without `key:value` tags (and
without `+`/`@`/`#` markers unless the library's `reminderShowTokens`
is true).

## Home-screen widget

Android: the **Niman Todos** widget mirrors the tab's open view —
due-soonest first — and toggles a task on a row tap, with the app
closed or not. See [widgets](widgets.md).

## The task dialog

Adding or editing a task opens one dialog: the description, with
completion for the `+project`, `@context` and `#tag` already in use, the
priority, the due date and the reminder. A long description wraps and
the field grows downward, a few lines at most, then scrolls; it is still
one line of `todo.txt`, so Enter saves and a pasted line break becomes a
space. On a wide window the dialog is wider.

On a window with the room (a desktop, a tablet), the due date and the
reminder are picked inside the dialog: the calendar opens under its row,
and for a reminder the time is typed beside it (`14:30`) and set with
**OK**. One opens at a time; tapping the row again folds it. A phone
keeps the system date and time pickers, made for a small screen.

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
