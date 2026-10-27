# Journal

One note per day, made the first time you open that day.

The journal is one of the [Features](features.md). Switched off, entries stay ordinary notes and Settings has no Journal area.

An entry is an ordinary note: it lives in the library like any other,
syncs, is found by search and links to and from other notes. What makes
it an entry is where it is and what it is called, set in **Settings →
Journal** and kept in the library's `settings.json`, so they
travel with it (see [settings](settings.md)). The entry name shows today's
entry as you type it, and a name that cannot make one entry per day is
not saved:

- **Folder** (`journalFolder`, default `Journal`).
- **Entry name** (`journalEntryName`, default `YYYY/MM/YYYY-MM-DD`):
  `YYYY`, `MM` / `M` and `DD` / `D` are the day's year, month and day; a
  `/` makes a folder; text in `'quotes'` is kept as it is. Numbers only,
  so an entry has the same name on every device whatever the app's
  language. The default files 23 September 2026 as
  `Journal/2026/09/2026-09-23.md`.
- **Template** (`journalTemplate`): the template an entry is made from.
  None set, an entry starts with a heading holding its date.
- **A new day starts at** (`journalDayStart`, 0 to 6): for late nights,
  at 4 the journal's "today" stays on the day before until four in the
  morning.

## Opening the journal

- **Today's entry**: `Ctrl/⌘+Shift+J`, or *Journal: Today's entry* in the
  command palette. It opens today's entry, and makes it first when there
  is none — no question asked, since it is the one you want every day.
- **The entries around it**: on an entry, `Ctrl/⌘+Shift+Page Up` and
  `Page Down` (or *Journal: Previous entry* / *Next entry*) go to the
  entry before or after it, skipping the days without one. With none
  left in that direction, previous offers the day before; next stops at
  today.
- **Another day**: a day with no entry is not made behind your back —
  Niman asks first, so leafing through the days never leaves empty notes.

## The calendar

A month with a dot under each day that has an entry, today ringed, a
**Today** button, the open [tasks](tasks.md) due on the day (from
`todo.txt`: tap one for the task list), and the latest entries with
their first words. In the side panel the day is the entry on screen's,
or today; on the phone's screen, the day picked.

The week starts on the system's first day — the one its region uses,
whatever language the app or the system speaks (English set for Germany
starts on Monday; on Windows, the first day the region settings name) —
or on the day the library sets in
**Settings → Appearance → First day of the week**; the task date panel
and the date picker follow the same day.

- **Desktop** (a window wide enough for the side panel): the *Journal*
  pane of the side panel, beside the note. Clicking a day with an entry
  opens it; an empty day is picked, and a row under the calendar offers
  **Create** — no dialog over a calendar that has the day in it. Opening
  another day, or turning the month, lets the pick go.
  Right-clicking one of the latest
  entries opens the same menu as its row in the file tree: open it in
  a new tab or beside the note, rename it, move it, and the rest.
- **Phone**: the calendar icon in the Files bar opens the Journal
  screen. Tap a day to pick it; its card opens the entry or makes it.
- Everywhere: the day in the strip over an entry, or *Journal: Show the
  calendar* in the command palette.

The **+** button on the phone's Files tab starts with *Today's journal
entry*.

## The day's events

A `calendar.txt` at the library root (the plain-text calendar
[terokarvinen.com/2021/calendar-txt](https://terokarvinen.com/2021/calendar-txt/))
has its events shown where the day is read: in the dock's journal pane and
in the phone's day card, in an **Events** section above **Due**, with the
day's goals — the week's, the month's, the year's — as a header over them
(`Week 42`, `October`, `2026`), in the goal green a goal's head wears in
`calendar.txt`. **Settings → Journal → Calendar → Event times** reads an
event's time as the file writes it (`9-12`) or as a clock (`09:00–12:00`,
in the device's own zone, a `Z` time included); the setting never changes
the file.

Each event reads as it is written: its time (`9-12`, `08:15`, `0600Z`),
its text with `+project`, `@context` and `#tag` picked out and a
`( … )` aside dimmed, and a bell with the time of its `rem:`. On the
calendar itself a day with events wears a second dot, amber beside the
entry's. Tapping an event opens `calendar.txt` at that line.

**Add event**, beside Today in the dock (a second row of the day card on
a phone), opens a form for the day: a start time and an optional end, the
text — with the `+project`, `@context` and `#tag` tokens both files
already use a tap away — **Remind me** with its lead time, and the exact
line that will be written, so what is about to be added is read before it
is. **Add task** opens the task dialog with the day as its due date; the
task then shows under the day's **Due**. A day with no entry yet offers
**New journal** beside them, which makes the day's entry and opens it.

A reminder rides on the event's own line (`rem:16:30`), so moving or
deleting the event moves or deletes it, and it feeds the same alarms a
task's `rem:` does ([tasks](tasks.md)) — tapping the notification opens
the journal on that day. It is a clock time on the line's own day: an
event at `0600Z` with `rem:0530` reminds at half past five where the
phone is, whatever the `Z` says. On an event that repeats it fires on every
occurrence — see [Recurring events](#recurring-events) below.

The file is otherwise yours: `calendar.txt` opens in the source editor,
coloured, and a write touches only the line an event was written to —
every other line comes back byte for byte, its own line ending included.
A day line whose week number or weekday does not match its date is flagged
in the editor (a wavy underline) and never corrected: the date is what is
read.

The **Events today** tile on the Home shows today's goals over its
events, and opens the journal on that day.

## Recurring events

An event repeats when its line says so, with the same `rec:` a task uses:

```text
2026-10-21 w43 Wed  9-9:30 Standup @work rec:1w until:2026-12-31 except:2026-11-04. 17-18 jogging
```

The event is written once, on the day line of its first day, and Niman shows
it on every day the rule reaches from there on. It never writes those days
out. `rec:` takes the same values as on a task (the table is in
[tasks](tasks.md#recurring-tasks)): `rec:1d` every day, `rec:2w` every two
weeks, `rec:1m` every month, `rec:1y` every year, `rec:3b` every three
business days, `rec:1w;mo,we,fr` on those weekdays, `rec:1m;2tu` on the
second Tuesday of the month. Two things differ from a task:

- an event is never completed, so there is no completion day to count
  from: the rule is counted from the event's own first day, and `rec:+1w`
  means the same as `rec:1w`;
- the days are the first day plus whole steps, not each from the one
  before, so an event on the 31st with `rec:1m` falls on the last day of a
  shorter month and is back on the 31st after it.

Two more tags, written on the same event, bound the rule:

- `until:2026-12-31` is the last day an occurrence may fall on, that day
  included;
- `except:2026-11-04,2026-11-18` lists days the event does not happen on, a
  comma-separated list of dates (more than one `except:` on an event add
  up). Listing the event's own first day hides it there too.

An `until:` or `except:` whose date cannot be read is ignored, and, like a
`rec:` that cannot be read, is flagged in the editor with a wavy underline;
the event then shows only on the day it is written.

Where it shows: every occurrence is listed wherever an event is — the day
card, the dock's journal pane, the **Events today** tile on the Home — and
the days it falls on carry the events dot in the month. Each one has the
repeat icon and the rule in words (`every 2 weeks`), as a task's row has.
Tapping an occurrence does what tapping the event does: on a desktop the
file opens at the rule's line, on a phone the sheet opens. A lone `+project`
or `@context` in the search lists the rule's line once, with the rule in
words ([search](search.md#tasks-and-events)).

### Moving an event to another day

The event form's **Day** row is the day the event is written on. On an added
event it is the day you started from, and changing it writes the event there.
On an edit of an event that does not repeat it moves the event: it leaves its
line and is written on the new day's, which is made when the day has none, and
the two lines are the only ones that change. On an edit of *This event* of a
repeating one it moves that one occurrence: its day is added to the rule's
`except:` and a plain event goes on the day you picked. A desktop opens the
calendar in place under the row, a phone the system's date picker. On *This
and following* and *All events* the row is shown and off, since a series
moves by changing its rule (Repeat). The preview shows the exact line, or the
two lines, the write will make.

### Making an event repeat

The event form has two more rows under the text: **Repeat** — Never, every
day, every weekday, every week on this day, every month on this date, every
month on the 2nd (or whichever) weekday, every year, or **Custom** — and
**Ends**, which is *Never ends* or a date. Custom opens in place under the row
on a desktop and in a sheet on a phone: every N days, weeks, months or years,
on which weekdays, on the Nth weekday of the month. The date an Ends row asks
for is the last day an occurrence may fall on, and cannot be before the
event's first day. The row's choices write `rec:` and `until:` on the event;
the days it skips (`except:`) are not on the form and are never lost by it.
Ends is off until there is a rule to end.

### One occurrence, or the rest

Right-click an event in the dock's journal pane on a desktop (long-press it
on a touch screen that has the dock), or tap it on a phone for its sheet: **Edit**, **Skip**, **Delete** and **Open in
calendar.txt**. **Open in calendar.txt** goes to the rule's line, whichever
occurrence you opened it on. **Skip** leaves that one occurrence out; it is
there for every event and only works on one that repeats.

**Edit** and **Delete** on an event that repeats ask first which events they
mean — *This event*, *This and following events* or *All events* — in a sheet
on a phone and a small menu on a desktop. What each writes into `calendar.txt`:

| You choose | The file gets |
| --- | --- |
| Skip, or Delete → this event | the day added to the rule's `except:` |
| Edit → this event | the day in `except:`, and a plain event with your change on the Day you chose, this one by default (no `rec:`) |
| Edit → this and following | `until:` the day before on the rule, and a new rule event with your change on this day's line |
| Delete → this and following | `until:` the day before on the rule (from its first day on, the event is deleted) |
| Edit, Delete → all events | the rule's own event, changed or deleted |

On an edit of this event only, Repeat and Ends are off: it becomes an
ordinary event. On this and following, the days the old rule skipped before
this one stay with it; the ones after come along to the new rule, and so
does its end. An `except:` grows by a date for every skip, and a rule that
has run for years with many of them is best ended and started again with
*This and following*. Each action changes only the lines it must: every other
line of the file is as it was, byte for byte.

Two devices that skip different days of the same event, or one that ends
it while another skips a day, merge into one event on the line, with both
skips and the earlier end: nothing is asked. A rule edited in its text on
one device and its skips on another is two edits, and both events are kept.

A reminder (`rem:`) on an event that repeats goes off on each occurrence, at
the same time of day (`rem:16:30`) or, for a full `rem:2026-10-20T08:00`, the
same number of days before or after it. Niman schedules the next two weeks of
them — at most four occurrences of each event — and renews them every time the
app runs, so open it at least once every two weeks for them to go on. A
skipped day (`except:`) has no reminder. How it works is in
[tasks](tasks.md#reminders).

Another tool that reads `calendar.txt` sees the event only on its first
day, with one more word in it: that is the price of keeping the file as
you wrote it, and `grep` finds the rule on that day.

## The strip over an entry

Any note that is an entry — wherever it was opened from — wears a strip
above it, on every platform: its day in full (with *Today* on today's),
and on either side the entry before and after it, by date. A side whose
day has no entry yet is drawn softer: tapping it offers to make one. The
next side stops at today.

## What an entry starts with

With no template set, an entry starts with its date as a heading
(`# Wednesday 23 September 2026`) and the caret under it.

With one, the template is filled in as for any
[template](templates.md), with one difference: the date is the entry's
day, not the moment it was made, so an entry made for last Monday says
Monday — and `{{date|-1d}}` links it to the Sunday before
(`[[{{date|-1d}}]]`), a calendar day back even across a clock change.
`{{time}}` still says when it was written. The
template's own questions are asked; its `niman:` directives are not
followed, since the journal already says where the entry goes and what
it is called. A template that cannot be read is said so, and the entry
is made without it. With the [Templates feature](features.md) off, the
template is not used: an entry starts with its date as a heading, and the
setting is kept for when Templates is on again.

