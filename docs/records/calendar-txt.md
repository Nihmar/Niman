# calendar.txt (#730)

Reading and writing a [calendar.txt](https://terokarvinen.com/2021/calendar-txt/)
file — Tero Karvinen's plain-text calendar, one line per day — beside
`todo.txt`, and showing its events where the journal shows a day. Written
before the code (2026-10-12), as the plan the work follows; the screens
are in [docs/design/calendar-txt](../design/calendar-txt/README.md).

The constraint that shapes all of it is the one `todo.txt` already keeps:
**the file is the user's, and other tools read and write it.** Niman reads
everything, writes only the line it was asked to change, and gives every
other line back byte for byte.

## The format, as it is — corrections to the issue

The issue described the format from memory; the page says otherwise in
four places, and the parser follows the page.

- **Events are not separated by `;`.** Each event ends with a full stop,
  the last one's optional. The `;` appears only in the page's own `grep`
  output. A line such as `9-11 John 12-16 architecture meeting` has no
  separator at all: Niman keeps it as one event, honestly, rather than
  guess where the second begins.
- **Goals carry a full head.** A week's goal is the date of its Monday and
  the week, `2021-02-15 w07  Architecture week`; a month's is
  `2021-04  Grand rollout`; a year's `2022  The year of foobar`. Two
  spaces separate a head from its text, on goals and on days alike.
- **Search has no `tag:` or `@context` filter today**, and does not index
  `.txt` files. "The filters cross tasks and events" was not something to
  extend; it is a new, small query mode (below).
- **The spec's template writes every day**, empty ones included, until
  2033. For a user who started from it, creating a missing day line is the
  rare path; for an empty file it is the main one. Both are tested.

## Decisions (2026-10-12)

1. **Location.** `calendar.txt` at the library root, beside `todo.txt`: a
   constant, not a setting. It travels and syncs with the library, and
   `grep +lp calendar.txt todo.txt` — the format's own promise — keeps
   working. No file means nothing is shown; the first Add event creates
   it.
2. **Sync: both merges, in the same round as the writing.**
   - **(A)** `calendar.txt` joins the record-merge files
     (`lib/src/diff/record_merge.dart`, today `todo.txt` and `done.txt`):
     a line either side added is in, a line removed from the base is out.
   - **(B)** a calendar-aware merge on top of it: lines are paired by
     their **key** — the date for a day line, the head for a goal — and
     the events of one key are merged **as a set**: an event added on
     either side is in, one removed from the base on either side is out,
     one added on both is in once. The merged set is spliced back into
     one line, in time order. Lines with no key follow the record rule.
     Two devices adding an event to the same day — the common collision —
     then merge with nothing asked.

   The parser tolerates duplicate day lines anyway (a hand edit, another
   tool's merge): their events are shown together, and a write goes to the
   first.
3. **Times shown both ways, a setting.** "Event times: As written (`9-12`)
   / Clock (`09:00–12:00`, in the app language's 12- or 24-hour form)".
   Default: as written. The file is never touched by the setting.
4. **Add event** is a time picker (start, optional end) and the text, with
   the same `+ Project` / `@ Context` / `# Tag` chips and completion the
   todo add has; the suggestions are drawn from both `todo.txt` and
   `calendar.txt`. A preview shows the exact line that will be written.
   Desktop: an inline row under the calendar in the dock — no dialog over
   a calendar (#712). Phone: a bottom sheet.
5. **Weekdays in every language.** The parser recognises the abbreviated
   weekday names of every locale the app ships (from `intl`'s data —
   `Mon`, `Mo`, `lun.`, `ke`, …) and whatever names the file itself
   already uses. A new line is written in the file's own convention,
   learned from its existing day lines; English — the spec's form — when
   the file is new or gives no clue.
6. **Reminders: on the event's line, in todo.txt's syntax** —
   `17-18 jogging @park rem:16:30.` To another tool it is one more word.
   Niman reads it and feeds the **same** reminder machinery as `todo.txt`
   (`lib/src/todo/reminders.dart`): one wanted set across both files, ids
   from a namespace of their own (a salt in the hash `todoReminderId`
   uses), and a payload whose tap opens the journal on that day instead of
   the Todo tab. Moving an event moves its reminder; deleting it deletes
   it. Add event has a **Remind me** switch with a lead time. A time with
   `Z` is converted through UTC.
7. **Add task from a day.** The day's panel — the dock and the phone's
   day card — has **Add task** next to **Add event**: the todo add,
   prefilled with `due:` that day. The day's Due section then shows it.
8. **Line endings kept per line.** Every line not edited comes back byte
   for byte. `todo.txt`'s file model (`todo_files.dart`) normalises mixed
   endings to one; `calendar.txt`'s must not, because a template file
   edited on two systems is exactly where they mix. A BOM is kept; a file
   that is not valid UTF-8 is shown, and never written.
9. **A Home tile, "Events today"**, headed by the day's goals, opening the
   journal on that day.
10. **The parser's rules.**
    - Five kinds of line: day, week goal, month goal, year goal, other.
      "Other" is kept and shown as written.
    - A weekday or week number that does not match the date is flagged in
      the editor (a wavy underline) and never fixed: the date is what is
      read.
    - Times: `8`, `08:15`, `0815`; ranges `8-1345`, `-12:00`; a `Z` suffix
      for UTC.
    - An event ends at `.` or `;` followed by a space or the end of the
      line — so `v1.2` does not cut an event, and neither does the `.`
      that ends `rem:16:30.`
    - `( … )` asides are shown dimmed.
    - `+project`, `@context`, `#tag` are tokens as in `todo.txt`, trailing
      punctuation stripped.
    - **A leading number is an hour.** That is the format's own rule, and
      it means `3 copies of the report` reads as an event at three. It is
      documented in the user guide rather than guessed around.
11. **Search.** Calendar lines do not enter the notes' full-text index. A
    query that is one lone `+project` or `@context` gets a mode of its
    own: it answers from the in-memory `todo.txt` and `calendar.txt`
    snapshots and shows a **Tasks and events** group above the notes.
12. **The editor.** `calendar.txt` opens in the source editor with its own
    colouring — goal heads, the date, week and weekday, times, asides,
    tokens, `rem:`, the mismatch flag — through new theme tokens, shown in
    the theme editor and defined by every built-in palette.
13. **The journal.** An **Events** section above Due, in the dock pane and
    in the phone's day card; the day's goals (week, month, year) as a
    header over the events; a second dot, in a colour of its own, in the
    day cell for "events here" beside the entry's dot. Tapping an event
    opens `calendar.txt` at its line on the desktop, and on a phone a
    sheet with Edit, Delete and Open in calendar.txt.

## Where it lives

`lib/src/calendar/`, one concern per file, next to `lib/src/todo/`:
the line model and parser (raw text kept per line, its ending included),
the writer, the store (read and parsed off the UI isolate with
`Isolate.run`, as the todo store reads), the controller the journal, the
Home and search listen to, the editor's token colouring, and the merge.
The reminder wiring extends `reminders.dart` rather than copying it.

## Phases

0. **This record and the mockups.**
1. **Read.** The parser, with round-trip property tests (any input, parsed
   and written back unedited, is the same bytes); the store off-isolate;
   the controller; the editor colouring and its theme tokens; the
   journal's dock pane, day card and second dot; the Home tile; the user
   guide.
2. **Search.** The lone-token mode and its group.
3. **Write.** The writer, with property tests (an edit changes only its
   own line; every other line keeps its bytes and its ending); Add, edit
   and delete event; Add task from a day; reminders; both sync merges;
   the Event times setting; the user guide.

Each phase lands on Android, Linux and Windows together.

## Risks

- **A weekday or a goal?** `2026-10-12 w42 Mo  …` in a language Niman
  does not know reads as a week goal whose text starts with `Mo`. The
  harm is display only — the line is never rewritten — and the file's
  own day lines teach the parser its names.
- **Leading numbers read as hours**, by the format's rule. Documented, not
  worked around.
- **37 locale files** for every new string.
- **External writers race the app**: another tool, or a sync, may change
  the file between Niman's read and its write. The write re-reads the file
  inside the write chain and applies its edit to what is on disk then, as
  `todo.txt` does.
- **`Z` events across midnight**: `2300Z` on one day is the next day in
  Rome. The event stays on the line it was written on; the clock display
  says the local time, and the reminder fires at the right instant.
- **The record merge takes the line ending from the local side**; the
  calendar merge must keep each line's own.
