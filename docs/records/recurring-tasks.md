# Recurring tasks in todo.txt (#1153)

How a task repeats: the `rec:` it is written with, the copy completing it
makes, its reminder, and what the sync merge sees. Written before the code
(2026-10-26), as the plan the work follows. Events repeat too; their half
of the issue is [recurring-events.md](recurring-events.md), and both share
the grammar below.

The constraint is the one every plain-text file here keeps: **the file is
the user's, and other todo.txt tools read and write it.** A recurring task
is one ordinary line with one more word, and its history is its done lines.

## Where things stood

- The parser keeps `rec:` verbatim as an unknown tag (`lib/src/todo/parser.dart`),
  and nothing acts on it. `due:` and `rem:` are understood; `t:` (the
  threshold date other tools write) is kept as an unknown tag too.
- Completing a task removes its line from `todo.txt` and appends
  `x <today> …` to `done.txt` (`TodoStore`, `completeTodoLine`); the
  Android widget completes through the same Dart path.
- Sync merges `todo.txt` and `done.txt` record by record
  (`lib/src/diff/record_merge.dart`): a line either side added is in, a
  line both added once is in once.
- Reminders: one wanted set over `todo.txt` and `calendar.txt`, the soonest
  `pendingLimit` scheduled where the system caps them (64 on iOS).

## Decisions (2026-10-26)

1. **The grammar is Simpletask's, with two extensions.** The todo.txt
   community's de facto syntax (Simpletask, topydo, sleek):

   | Token | Meaning |
   |-------|---------|
   | `rec:1w` | one week after the task is **completed** |
   | `rec:+1w` | one week after its **due date** (strict) |
   | `rec:Nd` / `Nw` / `Nm` / `Ny` | days, weeks, months, years |
   | `rec:Nb` | business days (Monday to Friday) |

   Niman adds two forms, after a `;`, for what the presets need and the
   base grammar cannot say:

   | Token | Meaning |
   |-------|---------|
   | `rec:1w;mo,we,fr` | every week, on those weekdays |
   | `rec:1m;2tu` | every month, on its second Tuesday |
   | `rec:1m;-1fr` | every month, on its last Friday |

   Weekday codes are RFC 5545's two letters (`mo` … `su`) in every app
   language: the file is not localised. Another tool reads an extended
   token as one it does not know — the line is untouched, it just does not
   repeat there. A `rec:` Niman cannot read is kept verbatim, flagged in
   the editor (a wavy underline) and does nothing, as an unknown tag does
   today.
2. **Completing makes the next copy.** The line goes to `done.txt` as now,
   `rec:` kept on it, and the next copy is appended to `todo.txt`:
   - its `due:` is the step applied to the **base**: the due date for a
     strict `rec:+`, the completion date otherwise; a task with no `due:`
     uses the completion date and gains a `due:`;
   - `t:` and `rem:` move by the same number of days as `due:` (a `rem:`
     keeps its clock time);
   - priority, text, links and every other tag are kept;
   - the creation date, if the line has one, becomes the completion date,
     as Simpletask writes it.

   Month steps clamp to the month's last day (31 January + `1m` is 28 or 29
   February), and a strict chain can drift from the 31st after it — the
   line holds only its current due date, and the format has nowhere to keep
   the first one. Documented, as Simpletask documents it.
3. **No catching up.** A strict task overdue by three periods moves one
   period, as every other tool does: completing it again moves it again.
   Each completion is one done line, so the history stays honest.
4. **Reopening a done line does not remove the copy.** The two lines are
   linked only by their text; reopening one puts it back as it was, and the
   user deletes whichever they do not want. (Completing has no undo today;
   if one is added, it takes back both writes, since it knows them.)
5. **Sync: deterministic copies merge once.** The copy is a pure function
   of the line and the completion day, so two devices that complete the
   same task on the same day write the same done line and the same next
   copy, and the record merge keeps each once — nothing new in the merge.
   Two devices that complete it on different days write different copies,
   and both are kept: a real disagreement the user sees, never a lost task.
6. **Reminders need no horizon.** A task's `rem:` belongs to the current
   copy; completing it drops that reminder and the copy's own `rem:` is
   scheduled, both through the existing wanted set.
7. **The task dialog gets a Repeat row**, under the reminder, on every
   platform: Never, Daily, Weekdays (`rec:1b`), Weekly on today's weekday,
   Monthly on this day, Yearly, and Custom — every N days, weeks, months or
   years, the weekdays, the Nth weekday, and "from the due date / from
   completion". The row writes the token; a `rec:` typed in the text is the
   same thing and the row shows it. Desktop picks Custom inline under the
   row, as the due date does; Android opens a sheet.
8. **The list shows a rule**: a repeat icon (outline) and the rule in words
   ("every 2 weeks", "every month, 2nd Tuesday") beside the due badge, on
   the row, in the widget and in a note's tasks. The source editor colours
   `rec:` as it colours `due:` and `rem:`.

## Where it lives

The grammar and the date arithmetic are pure Dart, shared with events:
`lib/src/core/recurrence/` — the rule model and its parser, next occurrence
from a base, occurrences in a range, the words for a rule. The completion
copy is a function beside `completeTodoLine` in `lib/src/todo/parser.dart`,
called by `TodoStore` in the same write as the archive.

## Risks

- **Other tools differ at the edges**: topydo and sleek disagree with
  Simpletask on month ends and on a task with only `t:`. Niman follows
  Simpletask, the original, and the property tests pin the edges.
- **The creation date changes on the copy**, so a filter on it sees every
  copy as new. That is what the other tools do.
- **37 locale files** for the presets and the rule in words.
</content>
</invoke>
