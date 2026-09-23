# Journal

One note per day, made the first time you open that day.

An entry is an ordinary note: it lives in the library like any other,
syncs, is found by search and links to and from other notes. What makes
it an entry is where it is and what it is called, set in the library's
settings (see [settings](settings.md)):

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

## What an entry starts with

With no template set, an entry starts with its date as a heading
(`# Wednesday 23 September 2026`) and the caret under it.

With one, the template is filled in as for any
[template](templates.md), with one difference: the date is the entry's
day, not the moment it was made, so an entry made for last Monday says
Monday — and `{{date|-1d}}` links it to the Sunday before
(`[[{{date|-1d}}]]`). `{{time}}` still says when it was written. The
template's own questions are asked; its `niman:` directives are not
followed, since the journal already says where the entry goes and what
it is called. A template that cannot be read is said so, and the entry
is made without it.

