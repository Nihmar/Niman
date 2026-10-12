# Journal

One note per day, made the first time you open that day.

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
phone is, whatever the `Z` says.

The file is otherwise yours: `calendar.txt` opens in the source editor,
coloured, and a write touches only the line an event was written to —
every other line comes back byte for byte, its own line ending included.
A day line whose week number or weekday does not match its date is flagged
in the editor (a wavy underline) and never corrected: the date is what is
read.

The **Events today** tile on the Home shows today's goals over its
events, and opens the journal on that day.

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
is made without it.

