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
- `[[Note]]` is a link to a note (see *Links to notes* below); inside
  the brackets a `+`, `@`, `#` or `key:` is part of the link, not a
  token.
- Untouched lines round-trip byte-stable; edits normalize spacing.

## Links to notes

A task can point at a note: write a wikilink in its text, the way a note
does. `(A) Call the plumber [[House/Repairs]] due:2026-11-02` links the
note *Repairs*; a task can hold any number of links. A heading
(`[[Repairs#Boiler]]`), a block (`[[Repairs#^b7]]`) and an alias
(`[[Repairs|the plumber's notes]]`) are written as in a note, and a
Markdown link to a note (`[plumber](House/Repairs.md)`) is read too —
Niman writes wikilinks. The link is resolved like any other, from the
library root: a bare name finds the note anywhere, a path finds it by its
tail, and case does not matter. See [links](links.md) for the forms.

The Todo list draws each link as a **chip** with the note's name, and the
link's words are taken out of the task's text, so they are not shown
twice. A link to a heading reads `Repairs › Boiler`, one to a block
`Repairs › ^b7`; an alias, when you wrote one, is the chip's text. A chip
you have just typed shows at once, from the words, and settles when the
library has answered: it never shows as raw `[[…]]`, and nothing in the
row moves when it does. On a phone the chips sit under the task, after the
due date and the tokens; on a desktop they follow the task's text on its
line.

Where a task is shown as plain text — a reminder's notification, the
home-screen widget, the Home's *Tasks due* tile, the day's due list in the
journal — a link reads the same words as its chip, `Repairs` or
`Repairs › Boiler`, never `[[…]]`.

- **Tap** (or click) a chip to open the note. A heading or a block link
  opens the note scrolled to it, as a wikilink in a note does. On a
  desktop, hovering a chip says where it goes (`Open House/Repairs.md`).
  The rest of the row still opens the task.
- **Long-press** a chip on a phone or a tablet to preview the note in a
  sheet with an **Open** action, as a long press on a wikilink does
  (when *Preview a link* is on; see [links](links.md)).
- A link to a name two notes share asks which one, as in a note.
- A link to a note that does not exist is a **dead link**: its chip is
  dashed and dimmed, with a broken-link icon and the name as you wrote it.
  Tap it to be offered the note, created where a new note goes, as for a
  dead link in a note; decline and nothing changes.

Typing `[[` in a task — in the dialog, or in the field at the top of the
list on a desktop — lists the library's notes under the field, the ones the
editor lists for a wikilink; `#` after a note's name lists its headings and
`#^` its blocks. Tap one, or move with `↑` / `↓` and press `Enter` or
`Tab`, to write the link in its shortest form that finds that note alone;
`Esc` closes the list. The task stays one line.

Renaming or moving a note rewrites the task links that name it, as it does
a note's (see *Updating the links to what moved* in [links](links.md)).

Other todo.txt tools see the words `[[House/Repairs]]` in the task's text,
and nothing else: a link is only text on the line, so `todo.txt` stays the
source of truth and syncs line by line like the rest of it.

## Tasks for this note

A note shows the tasks that link it. It is in three places, one list, the
way [Links to this note](links.md#links-to-this-note) is:

- **under the note**, a header — *Tasks for this note*, with the number of
  open tasks — below *Links to this note*, that opens onto the list and shuts
  again. It is always there while a library is open and the Todo feature is
  on, so it never appears under your thumb; with no task linking in it opens
  onto the words that say so. With the Todo feature off (Settings → Features)
  there is no header, no pane and no menu entry. On a wide window the header
  steps aside while the side panel is open, as *Links to this note* does;
- **in the side panel** on a wide window, the *Tasks* pane, after Links and
  before History, following the note in the focused pane;
- **as a sheet on a phone**, from the note's ⋮ menu — *Tasks for this note* —
  as the Outline, Tags and Links are (see [platforms](platforms.md)).

**Add task** heads the list. The open tasks follow, the soonest due first and
the ones with no due date last, in the order of `todo.txt`; then **Done (n)**,
folded, lists the completed ones from `done.txt`, the latest first. A row is a task as the Todo
tab draws it — checkbox, priority, text, due date, `+project` / `@context` /
`#tag` and a chip for each other note it links — without the link to *this*
note, which is what the list is about. A heading or block that link names
stays, as a small `§ Boiler` chip. The checkbox ticks the task (a ticked one
goes to *Done*, and unticking it there reopens it); a tap on the text opens
the task dialog, to change it, give it a date or delete it. The list follows
`todo.txt`: a task edited in the Todo tab, in a text editor or by sync shows
at once, and a renamed note keeps its tasks (their links are rewritten).

**Add task** opens the dialog with `[[Note]]` already in the description — the
shortest form that finds this note alone, as the `[[` completion writes it — and
the caret at the start, ready for the words of the task. **New task** in the
note's ⋮ menu does the same from the note itself and, on a desktop, so does
*Note: New task for this note…* in the command palette. With text selected in
the editor, the selection (on one line, its white space collapsed) is the
description, and the link follows it: select "Order the filter cartridges" and
choose *New task* to get `Order the filter cartridges [[Repairs]]`.

## Move to tasks

A checkbox item in a note can become a task. **Move to tasks** turns the
item into a line of `todo.txt`, links it to the note, and takes it out of the
note. It is for the list you wrote as notes and now want in the Todo tab, with
a date, a priority or a reminder.

Put the caret on a `- [ ]` or `- [x]` line (any list marker, any indent) and
choose **Move to tasks**:

- in the editor's right-click menu on a desktop (near its top, below the link
  and spelling entries), or in the bar a long press opens on a phone, where it
  is the first entry;
- in the toolbar's **Tools** sheet, on every platform;
- in the command palette — *Move to tasks*.

**One item opens the task dialog**, titled *Move to tasks* and saved with
**Move**. The description is the item's text as written — bold, code and links
kept — followed by `[[Note]]`, so you can give it a date, a priority or a
reminder before it is saved. Cancel changes nothing, in the note or in the
files. The task carries today's creation date, as every task the dialog adds
does.

**Several items are moved at once**, with no dialog: select the lines and
choose the same command. Each becomes `text [[Note]]` with today's creation
date. A ticked item (`- [x]`) goes to `done.txt`, completed today:
`x 2026-10-23 2026-10-23 Fix the hallway light [[Repairs]]`.

The tasks are written to `todo.txt` and `done.txt` **first**, and the lines
leave the note only once both files took them, as one undoable edit of the
note, saved like any other. If anything fails in between, the item is in the
note and in the task file — never in neither. A snackbar says *Moved 3 to
tasks* with **Undo**, which puts the lines back where they were (at the nearest
place if you have edited the note since) and takes the tasks out of the files.

An item that has **sub-items** (or a paragraph or a code block of its own under
it) is not moved: *Move to tasks* is greyed on it, with *Has sub-items — move
them first* as its reason, and a selection of several items moves the others
and skips it; the snackbar counts what moved. Items inside a quote, and
anything inside a code block, are not checkbox items and are left alone. The
command is part of the Todo feature: with Todo off in the library, it is gone.

## A list of tasks in a note

A fenced block whose language is `todo` draws a live list of tasks, from
`todo.txt` and `done.txt`, where you write it. The block holds the question,
never the answers: on disk it is a few lines of text, and another Markdown
tool shows a code block. (It is `todo`, not `tasks`, because Obsidian's Tasks
plugin owns that name with a query language of its own.)

    ```todo
    link: any
    project: house
    due: <=+7d
    ```

With the caret outside the block, the list is drawn in the read view and in
live mode alike, on a desktop, a tablet and a phone. Its head says what it
lists and how many (*Tasks · project house · due within 7 days · 2*). A row is
a task as *Tasks for this note* draws it: a checkbox that ticks it, a tap that
opens the task dialog, a chip for each link; a ticked task goes to `done.txt`,
and the list follows. **Add task** at its foot opens the dialog written out
from the block (below). With the caret inside the block, or after a tap on its
head, you see the source again, coloured: the keys the block knows, the values,
and a key it does not know in the red of a deletion. Drawing the list never
changes the note; the block is rewritten only when you type in it. With the
Todo feature off (Settings → Features), or for a note outside a library, the
block is just a code block.

### The lines

One `key: value` to a line; blank lines and the spaces round a line do not
matter, and keys may be written in any case. **Every line must match**: a task
is listed only if it passes all of them. A key left out asks for nothing,
except `link`, `done` and `sort`, which have defaults.

| Key | Value | Meaning |
|---|---|---|
| `link` | `this` (default), `[[Note]]`, `any` | Whose tasks: the ones that link this note; the ones that link another note; every task. |
| `project` | a name, with or without the `+` | A task with that `+project`. May be given again: the task must have all of them. |
| `context` | a name, with or without the `@` | A task with that `@context`. May repeat. |
| `tag` | a name, with or without the `#` | A task with that `#tag`. May repeat. |
| `due` | `today`, `overdue`, `<=+7d`, `2026-11-02`, `2026-11-01..2026-11-07` | Tasks due then. `<=+7d` is today, the next seven days **and everything overdue**. A task with no due date matches none of them. |
| `priority` | `A`, `A-C` | Tasks with that priority, or one in that range. |
| `done` | `no` (default), `yes`, `all` | The open tasks of `todo.txt`; the completed ones of `done.txt`; both, the open ones first. |
| `sort` | `due` (default), `priority`, `file` | The soonest due first, undated last; `(A)` first; or the file's own order. As in the Todo tab, ties are broken by priority and creation date. |

**An empty block is the tasks that link this note**, the list *Tasks for this
note* has. `link` stays `this` whatever else the block filters by, so a block
never widens by itself: to list tasks that do not link the note, say
`link: any`. A block of one line,

    ```todo
    due: overdue
    ```

lists only the overdue tasks among the ones that link the note; and a
dashboard over the whole list, in a note of its own, is

    ```todo
    link: any
    due: <=+7d
    sort: priority
    ```

`link: [[Repairs]]` lists the tasks that link *Repairs*, resolved as a wikilink
in this note is. A link to a heading or a block of the note counts, as in
*Tasks for this note*. A row in a `link: this` or `link: [[Note]]` list leaves
out the link to that note, as that list does; a `link: any` list shows every
link as a chip.

### Add task

**Add task** opens the task dialog with what the block's lines would give a new
task, so that it shows up in the list. For `link: this` that is ` [[Note]]` — a
space, then the shortest link that names this note, the caret before it, as
*Tasks for this note* writes it — and then the `+project`, `@context` and
`#tag` the block filters by (` [[Note]] +house @phone`). For `link: [[Repairs]]`
the link is to *Repairs*; for `link: any` there is no link, only the tokens.
Dates and priorities are not filled in.

### Mistakes

A line the block cannot read — a key it does not know, a value the key does
not take, a key with no value, a line with no colon, a key that takes one value
given twice — is a **row in the block saying so**, with the line it is on, and
a block with any such row **lists no tasks** until it is fixed: a half-read
filter would show a list that looks right. The rows replace the list; Add task
is still there. A mistyped key names the nearest one (*Unknown key prio — did
you mean priority?*), and a wrong value lists what the key takes. A
`link: [[Note]]` that names no note, or a name several notes share, is a row in
the same way. In live mode a tap on a row puts the caret on its line.

A block that is fine and finds nothing says *No tasks match* in one line.

### Exporting, and other tools

HTML, PDF and EPUB print the list **as it is when you export**: the head, then
each task after a box — ☐ open, ☑ done — its links shown by their labels, its
priority before it and its due date after (*Due 2026-11-02*). The block's
source is not printed, and a block with errors prints its error lines.
Exporting a folder or the library prints the block as the code it is on disk,
since a page of a zip is not made where the tasks are.

Another Markdown tool, a sync client or GitHub shows the block as a code block
with the lines you wrote, and nothing else; `todo.txt` is read by the same tools
as ever.

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
  completed as you type them (`Tab` takes the first) and `[[` completing
  a link to a note — and keeps the cursor for the next one;
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
completion for the `+project`, `@context` and `#tag` already in use and
for a `[[` link to a note (see *Links to notes*), the
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
