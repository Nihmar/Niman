# Tasks and reminders

The Todo tab reads `todo.txt` files (todo.txt grammar: `x (A)
2016-05-20 2016-04-30 description +project @context #tag key:value`).

Todo and Calendar are [Features](features.md). Switched off, `todo.txt` and `calendar.txt` stay plain files, the reminders already scheduled are cancelled, and none is scheduled until it is switched on again.

## The list

The open tasks come in sections that follow the sort:

- **By due date** (the default): Overdue, Today, Next 7 days, Later and
  No date.
- **By priority**: one section per letter, A first, then No priority.
- **By creation date**: one plain list, without headers.

Each header shows how many tasks it holds; tap it (or click it) to fold
the section or open it again. A section with nothing in it is not shown.
Which sections are folded is remembered on each device, for each
library.

There is no standing total of open or done tasks, on purpose: the
numbers are in the section headers, and while a filter is on the strip
says how many open tasks are shown out of how many. The plain list
sorted by creation date has no header, so it shows no count until a
filter is on.

**Done** is the last section: the tasks of `done.txt`, newest first,
folded until you open it. A done task is checked and shows the day it was
finished; unchecking it puts it back among the open ones.

**Filter** narrows both the open tasks and Done: a due range (All dates,
Overdue, Today, Next 7 days, No date) and any number of `+project`,
`@context` and `#tag` chips, which all have to match. **Sort** picks the
order: due date, priority or creation date. A task's priority shows as a
small badge, except when the list is sorted by priority, where its
section already says it. While a filter is on, a strip under the bar
lists it as chips you can remove one by one, with how many open tasks
are shown out of how many, and **Clear** to drop them all.

On a phone, help, **Filter** and **Sort** are in the app bar; the Filter
icon takes the accent color and a dot while a filter is on. On a
desktop they are a toolbar over the list — **Filter** (`Filter · 2` with
two filters on) and **Sort** as pills, then **Add task** and help — or
four icons in a pane too narrow for the pills.

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
- `↑` / `↓` move the selection across the tasks and the section headers
  and scroll it into view; on a task, `Space` checks it, `Enter` or `F2`
  edits it in place and `Delete` deletes it — the selection moves on to
  the row that takes the task's place; on a header, `Enter` or `Space`
  folds the section or opens it;
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
- **Filter** and **Sort** open under their pills.

Deleting removes the line from `todo.txt` (or `done.txt`, for a task in
the Done section) outright: there is no trash for tasks. To keep a
finished task, check it instead.

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

Android: the **Niman Todos** widget shows the tab's open tasks in the
same due-date sections (Overdue, Today, Next 7 days, Later, No date)
and toggles a task on a row tap, with the app closed or not. See
[widgets](widgets.md).

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
