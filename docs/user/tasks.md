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

On a phone, tap a task to edit it; the trash icon in the dialog's title
deletes it. Long-press a row for the same Edit / Delete as a menu, or
swipe it to the left and confirm.

On a desktop the list is driven by the mouse and the keyboard (#712):

- a click selects a row, a double click edits its text in place —
  `Enter` saves, `Esc` cancels;
- `↑` / `↓` move the selection, `Space` checks the task, `Enter` or `F2`
  edits it in place and `Delete` deletes it;
- a right click opens the row's menu at the pointer: **Edit…** (the
  dialog, for the dates, the reminder and the priority), **Set due** ▸
  (Today, Tomorrow, Next week, Pick a date…, No due date), **Priority** ▸
  (A, B, C, None) and **Delete**;
- hovering a row shows a calendar (the due days alone), a trash and a ⋯
  that opens the same menu;
- a field at the top adds a task per `Enter`, as typed — `+project`,
  `@context` and `due:` included, with the tokens already in the list
  completed as you type them (`Tab` takes the first) — and keeps the
  cursor for the next one;
- **Filter** opens its tokens and sort under the pill.

Deleting removes the line from `todo.txt` (or `done.txt`, in the
Done view) outright: there is no trash for tasks. To keep a finished
task, check it instead.

## The files themselves

`todo.txt` and `done.txt` also open in the editor, as text, coloured as a
task list: the priority, the dates at the head of a task, `+projects`,
`@contexts`, `#tags` and `key:value` tags (`due:`, `rem:`) each in their
own color, and a completed task struck through. They open in the source
editor only — the preview and the WYSIWYG editor read Markdown, and would
run the lines together — so their switches stay in place, off. The colors
are the theme's, under **Task lists (todo.txt)** in the theme editor
([themes](themes.md)).

## Reminders

Add `rem:2026-09-20T09:00` to a task and Niman schedules an exact alarm
in local wall-clock time. It fires with the screen off, the app in the
background, or the process killed (Android). The app warns when a
notification or background setting could block delivery — the banner
over the task list, and, as soon as a reminder is set, the dialog that
set it. The banner appears as soon as the app knows a setting is off,
even before any reminder exists; only the system permission dialog waits
for the first reminder. Both **Open settings** actions open Niman's **App info** page
(*Informazioni app*), where the notification switch, the battery usage
row and the permissions sit together: turn on **Allow background usage**
(*Consenti l'utilizzo in background*). An app the system will not start
in the background never fires an alarm, whatever the notifications say.

Notification text is the task's prose without `key:value` tags (and
without `+`/`@`/`#` markers unless the library's `reminderShowTokens`
is true).

An event in `calendar.txt` carries its reminder the same way — `17-18
jogging @park rem:16:30.`, a clock time on the line's own day
([journal](journal.md)) — and it feeds the same alarms: one wanted set
over both files, so completing or deleting either takes its reminder
with it. Tapping an event's notification opens the journal on that day;
tapping a task's opens the task list.

## Home-screen widget

Android: the **Niman Todos** widget mirrors the tab's open view —
due-soonest first — and toggles a task on a row tap, with the app
closed or not. See [widgets](widgets.md).

## The task dialog

Adding or editing a task opens one dialog: the description, with
completion for the `+project`, `@context` and `#tag` already in use, the
priority, the due date and the reminder. **Add task** from a day in the
journal opens the same dialog with that day already set as the due date
(see [journal](journal.md)). A long description wraps and
the field grows downward, a few lines at most, then scrolls; it is still
one line of `todo.txt`, so Enter saves and a pasted line break becomes a
space. On a wide window the dialog is wider.

On a desktop window with the room, the due date and the reminder are
picked inside the dialog: the calendar opens under its row, and for a
reminder the time is typed beside it (`14:30`) and set with **OK**. One
opens at a time; tapping the row again folds it. Android — a phone or a
tablet alike — keeps the system calendar and clock: a date or a time is
picked there, never typed, so the soft keyboard stays down while you
choose.

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
  slept through it) or `NOT FIRED` (Niman was not running at its time).
  A desktop reminder needs Niman running, in the tray if the window is
  closed; one that came due while it was closed is shown on the next
  run, as long as it is still within the hour it stays wanted. A reminder
  is shown once: editing the task's text after it showed does not show it
  again, while a second task due at the same minute is a reminder of its own
  and is shown.
