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
