# calendar.txt — the screens, and the decisions

The mockups #730 was agreed against (2026-10-12), before any code: six
desktop screens and five phone screens, in `html/`. They are drawn to look
like Niman, in the Night palette of `lib/src/ui/theme/niman.dart`; where a
mockup and the app disagree, the app is what ships. The plan they belong to
is the record [calendar-txt.md](../../records/calendar-txt.md).

| Screen | Desktop | Phone |
|---|---|---|
| **The journal with its events**: a second dot in the day cell for "events here" beside the entry's, the day's goals (week, month, year) as a header, **Events** above **Due**, times as written, an aside dimmed, `+project` / `@context` coloured, a bell on the event with a reminder; **Add event** and **Add task** in a row of their own that never moves | [Desktop-1-Dock](html/Desktop-1-Dock.html) | [Phone-1-Journal](html/Phone-1-Journal.html) |
| **Add event**: start and optional end, the text with the `+ Project` / `@ Context` / `# Tag` chips and the suggestions the todo add has, **Remind me** with its lead time, and the exact line that will be written; inline under the calendar in the dock, a bottom sheet on a phone | [Desktop-2-AddEvent](html/Desktop-2-AddEvent.html) | [Phone-2-AddEvent](html/Phone-2-AddEvent.html) |
| The same day with **Event times: Clock** — `09:00–12:00`, a `Z` time in the device's zone | [Desktop-3-ClockTimes](html/Desktop-3-ClockTimes.html) | — |
| An event tapped: on a phone a sheet with **Edit**, **Delete**, **Open in calendar.txt**; on the desktop the tap opens the file at that line | — | [Phone-3-EventSheet](html/Phone-3-EventSheet.html) |
| `calendar.txt` in the source editor, coloured: goals, day heads, empty template days, times, `rem:`, an aside, and a weekday and a week number that do not match their date, flagged and never fixed | [Desktop-4-Editor](html/Desktop-4-Editor.html) | — |
| Settings › Journal: **Event times**, As written / Clock, and where the file is | [Desktop-5-Settings](html/Desktop-5-Settings.html) | — |
| A lone `+project` search: the **Tasks and events** group above the notes | [Desktop-6-Search](html/Desktop-6-Search.html) | — |
| The Home's **Events today** tile, with the week's goal | — | [Phone-4-Home](html/Phone-4-Home.html) |
| **Add task** from a day: the todo add, its due date already that day | — | [Phone-5-AddTask](html/Phone-5-AddTask.html) |

## Decided with them

- **The file is `calendar.txt` at the library root**, beside `todo.txt`: a
  constant, not a setting. It travels and syncs with the library, and
  `grep +thesis calendar.txt todo.txt` keeps working. No file, nothing
  shown; the first Add event creates it.
- **Sync merges it line-wise, in the same round as the writing.**
  `calendar.txt` joins the record-merge files, and a calendar-aware merge
  pairs lines by their key (the date for a day, the head for a goal) and
  merges the events of a key as a set. Two devices adding to the same day
  — the common collision — is then no conflict.
- **Times are shown as written, or as a clock**: a setting, *As written*
  by default. The file is never touched by it.
- **Add event is a time picker, the text and the todo add's chips**, with
  suggestions drawn from both files, and a preview of the exact line.
  Inline in the dock, because a dialog does not go over a calendar (#712);
  a bottom sheet on a phone.
- **Weekdays in every language the app speaks**: the parser knows the
  abbreviated names of all its locales and whatever the file itself uses;
  a new line follows the file's own convention, English when the file is
  new or gives no clue.
- **A reminder lives on the event's line**, in todo.txt's own `rem:` key
  (`17-18 jogging @park rem:16:30.`); to another tool it is one more word.
  It feeds the same reminder machinery as `todo.txt`, and moving or
  deleting the event moves or deletes it.
- **Add task from a day**: the todo add, its due date set to that day; the
  task then shows under the day's Due.
- **Every line not edited comes back byte for byte**, its own line ending
  included; a BOM is kept; a file that is not UTF-8 is shown, never
  written.
- **A Home tile, "Events today"**, with the day's goals over it; it opens
  the journal on that day.
- **Search does not index the lines.** A query that is one lone `+project`
  or `@context` answers from the tasks and events already in memory, in a
  group of its own.
- **The editor colours the file** with its own theme tokens, shown in the
  theme editor beside todo.txt's.
- **Nothing moves under a thumb.** Add event and Add task are always there
  for the day, in a row of their own: beside Today in the dock, at the
  foot of the day card on a phone. The card's first row keeps one height
  whether the day has an entry or not.
