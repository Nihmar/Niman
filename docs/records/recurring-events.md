# Recurring events in calendar.txt (#1153)

How an event in `calendar.txt` repeats: the rule it is written with, the
days it is shown on, skipping, moving and changing occurrences, its
reminders, and the sync merge. Written before the code (2026-10-26), as
the plan the work follows. The grammar of `rec:` is the one tasks use,
settled in [recurring-tasks.md](recurring-tasks.md); the file's format and
its merge are in [calendar-txt.md](calendar-txt.md).

`calendar.txt` has no recurrence of its own — one line per day, an event
on the line it is written on — and the constraint stays the one that
record keeps: **the file is the user's, other tools read it, and Niman
writes only the line it was asked to change.**

## Options weighed

1. **Expand ahead**: write the occurrences into the file for a horizon.
   Every reader sees them, but the file grows, the rule has to live
   somewhere else, and editing "all occurrences" means rewriting many
   lines another device may be editing too. Rejected.
2. **A rule on the event, read virtually.** Chosen (below).
3. **A separate rules file** (`.niman/recurring.txt`): `calendar.txt`
   stays untouched, but part of the calendar is then state that is not in
   the plain file, which the design rules forbid. Rejected.

## Decisions (2026-10-26)

1. **The rule is a `rec:` token on the event**, on the day line of its
   first occurrence:

   ```
   2026-10-21 Wed w43  9-9:30 Standup @work rec:1w. 17-18 jogging
   ```

   Niman shows the event on every day the rule matches, from that day on,
   and never writes the occurrences out. Another calendar.txt reader sees
   it once, on its first day, with one more word in it. A `rec:+` is the
   same as `rec:` here: an event is never completed, so there is no
   completion date to count from.
2. **Occurrences are counted from the first day**, not from the previous
   occurrence: the k-th is the first day plus k steps, so a monthly event
   on the 31st falls on the last day of a short month and is back on the
   31st after it — no drift, unlike a task's chain. `rec:1b` is every
   weekday; the extensions (`rec:1w;mo,we`, `rec:1m;2tu`, `rec:1m;-1fr`)
   are the weekly-on-days and Nth-weekday presets.
3. **Exceptions are tokens on the rule**, after RFC 5545:
   - `until:2026-12-31` — the last day an occurrence may fall on,
     inclusive;
   - `except:2026-11-04,2026-11-18` — occurrences that do not happen, a
     comma-separated list of the dates they would have fallen on.

   The actions are made of those two and of ordinary events:
   - **Skip this occurrence**: add its date to `except:`.
   - **Move or edit this occurrence**: `except:` its date, and write a
     plain event (no `rec:`) on the new day with the change. It is an
     ordinary event from then on.
   - **This and following**: `until:` the day before on the rule, and a
     new rule event, changed, on the occurrence's own day line.
   - **All occurrences**: edit the rule event itself.
   - **Delete** offers the same three: this one (skip), this and following
     (`until:`), all (the rule's event is deleted).

   An `except:` list grows by a date per skip; a rule that has run for
   years with many skips is ended and restarted by This and following,
   which drops the past list.
4. **"Done" means nothing for an event.** Events are not completed; only
   their reminders recur.
5. **Every occurrence is shown everywhere an event is**: the journal's
   events dot in the day cell, the dock pane and the phone's day card, the
   Home tile *Events today*. An occurrence carries the repeat icon
   (outline) and the rule in words. The lone-token search lists the rule's
   line once, with the rule in words — it is one line in the file.
6. **Reminders keep a short horizon.** A rule event with `rem:` schedules
   its occurrences that fall in the next 14 days, at most 4 per rule, and
   every reconciliation (app start, file change, a fired reminder handled)
   recomputes that set — so the alarms run on for days without the app
   being opened. A clock `rem:16:30` is that time on each occurrence's
   day; a full `rem:` date-time keeps its offset from the first day. Ids
   come from the event's namespace salted with the occurrence's date, so
   each occurrence is its own alarm and a skip cancels exactly one. The
   existing soonest-`pendingLimit` cut remains the backstop.
7. **The editor.** The event form gets the Repeat row tasks get (Never,
   Daily, Weekdays, Weekly on this day, Monthly on this day / on the Nth
   weekday, Yearly, Custom) and an **Ends** row (never, on a date). Opening
   an occurrence — the dock's context menu on the desktop, the event sheet
   on a phone — offers Edit, Skip, Delete and Open in calendar.txt; Edit
   and Delete then ask *This event / This and following / All events*.
   Open in calendar.txt goes to the rule's line. The source editor colours
   `rec:`, `until:` and `except:` as it colours `rem:`.
8. **Sync: rule events are paired by identity, and their exceptions
   merged.** The calendar merge (`calendar-txt.md`, decision 2B) merges a
   day's events as a set, so two devices each skipping a different
   occurrence of the same rule would leave two rule events — and every
   occurrence shown twice. The merge therefore pairs the rule events of a
   day line by the event with `except:` and `until:` taken out; a pair
   merges into one event whose `except:` is the union and whose `until:` is
   the earlier of the two. Any other difference is a real edit, and both
   are kept, as for any event.

## Where it lives

The rule model and its arithmetic are `lib/src/core/recurrence/`, shared
with tasks. `lib/src/calendar/` gains the expansion — occurrences of every
rule in a date range, from the parsed file, for the journal's visible
month and the dock — the writer's actions above, and the merge's rule
pairing. The reminder horizon extends the calendar half of
`lib/src/todo/reminders.dart`.

## Risks

- **Other readers see a rule event once.** That is the price of keeping
  the file as written; the user guide says so, and that `grep` finds the
  rule on its first day.
- **Android caps an app's pending alarms** (500 per app), and no backend
  reports that cap today (`pendingLimit` is null on Android). The horizon
  keeps recurring alarms bounded — at most 4 per rule — but the Android
  backend should report a limit below the cap, so a library with many
  rules degrades to "the soonest are scheduled" instead of an exception.
- **`Z` times and occurrences across midnight** follow the existing rule:
  an occurrence stays on its day, and the reminder fires at the right
  instant.
- **A rule event moved by hand** to a later day line simply starts there;
  its `except:` dates before that day no longer matter.
- **37 locale files** for the presets, the rule in words and the three-way
  choice.
</content>
</invoke>
