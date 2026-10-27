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

## As built: skip, move, this and following, merge (#1191, 2026-10-26)

What the code does where the plan left a choice, or where the plan met the
file.

- **The actions are pure line transformations**
  (`lib/src/calendar/calendar_occurrence_edits.dart`), one per action and
  scope, over the file's lines with their own endings; `calendar_rule_tokens.dart`
  rewrites one `until:` or `except:` in an event in place (or closes the event
  with a new one), and `calendar_splice.dart` holds the line-level helpers
  both writers share. Each answers null — a no-op, nothing written — when the
  file no longer holds the event, or when the rule does not reach the day it
  was asked about (a skip of a day already skipped, say), so a double tap or a
  file moved under the screen never edits the wrong thing.
- **`except:` is sorted and kept in one token.** A skip rewrites the first
  readable `except:` of the event as the sorted union with the new day, or
  closes the event with a new token when it has none; an `except:` it cannot
  read is left as written.
- **Edit this one** writes the plain event on the day the form's Day row
  says: the occurrence's own by default, or another day, which is the move.
- **The Day row** is the task dialog's due-date pattern: the calendar in place
  on a window with the room, the system's date picker elsewhere. The draft
  carries the day (`CalendarEventDraft.day`, null when the form did not say),
  and the writer reads it: an added event goes there, a plain event that is
  edited leaves its line for that day's (two lines change, the new one made
  in date order when missing), and one occurrence is `except:`ed and written
  there. For *This and following* and *All events* the row is shown and off,
  and the draft carries no day: a series moves by changing its rule. An event
  that does not repeat is edited with no scope (nothing to ask), so its row is
  on. The preview shows every line the write changes, not only the day's.
- **Edit this and following from the rule's first day** is the same as All
  events (`until:` the day before would end the rule before it began), and so
  is a Delete of this and following, which deletes the event instead.
- **The draft carries the rule.** `CalendarEventDraft` has a `recurrence`
  (rule, end, skipped days); an edit reads an event into a draft *without* its
  `rec:`, `until:`, `except:` and clock `rem:` in the text, the form shows and
  changes them apart, and the writer puts them back after the text. That also
  ends a bug of the old edit, which left a `rem:` in the text and wrote a
  second one from the reminder.
- **Ask first, then the form.** Edit and Delete ask the scope before anything
  else, so the form's preview is the writer's own answer for that scope. For
  *this event* the form's Repeat and Ends rows are off and say Never — the
  event becomes a plain one. Ends is off while there is no rule to end;
  neither row is ever hidden.
- **The three-way question is the app's list of choices**
  (`showActionSheet`): a sheet on a phone and a small menu at the pointer on
  a window, as every other list of choices is, not a dialog over the calendar
  (#712). The dock's context menu is the same: right click an event, or long
  press it on a touch screen that has the dock, whose tap still opens the file.
- **Skip is on every event's menu and off for one that does not repeat**, so
  the rows do not move with the event shown.
- **The presets of an event** are Daily, Weekdays, Weekly on the day, Monthly
  on the date, Monthly on the Nth weekday (the last, when the day is a
  fifth), Yearly — none strict, and the custom editor has no "from the due
  date or the completion" choice: it is the task's row, with those two
  options turned off.
- **The merge pairs by the event without `until:` and `except:`** (spaces
  normalised), and only when every `until:` and `except:` of both copies can
  be read. `except:` is a three-way set merge — a day either side added is in,
  and a day the base had is out when either side took it away — which is the
  plan's union whenever nobody un-skips. `until:` follows the side that changed
  it; when both did, or there is no base, the earlier wins and no end counts
  as later than any. A side that left the event as the base had it gives the
  other's text to the character. Everything else stays the set merge: a
  different text, time or rule is a different event and both are kept.

## As built: reminders (#1192, 2026-10-26)

What the code does where the plan left a choice.

- **The window is the occurrence's day, today to today + 13** (fourteen days,
  today included), then the soonest four whose reminder is not more than
  `reminderGrace` behind. The first day itself is an occurrence like the
  others, and behaves as a plain event does.
- **Ids.** The rule's first day keeps the id the event always had
  (`calendarReminderId(day, text)`), so an event that gains a `rec:` does not
  re-arm its first alarm; the later occurrences are salted with the series'
  first day and their own date (`calendarOccurrenceReminderId`). The text the
  id comes from is the event's without `until:` and `except:`: a skip or an
  end rewrites those words, and the alarms that remain must keep their ids,
  or a skip would cancel and re-arm every one instead of cancelling one. (An
  event with neither word has exactly the old id.)
- **A full `rem:` date-time on an event is read** — it was ignored before,
  for any event. A plain event fires at that stamp; a rule's keeps its
  distance in calendar days from the first day. A distance after the
  occurrence widens the window backwards by as many days, so a reminder still
  ahead is not lost when its occurrence is behind. The notification opens the
  journal on the occurrence's day.
- **The horizon moves forward from the triggers that already exist.**
  Reconciliation runs at app start (the shell opens the controller), on every
  return to the foreground, and on every change of `todo.txt` or
  `calendar.txt`, and each computes the window from the clock. A notification
  tap that starts the app is an app start, and one while it runs returns it to
  the foreground. What was missing was a desktop left running: its timers
  fire in the process and nothing else touches it, so the window would run dry
  after a few days. The backends gain a `fired` stream — the desktop's
  emits after a notification is shown, the OS-alarm backends never do — and
  the todo controller reconciles on it. No timer, no background job. On
  Android and Apple, with the app closed, nothing runs: the user guide says to
  open the app every two weeks.
- **Android's limit is 400**, `androidPendingAlarmLimit`, below the 500
  concurrent alarms per app. Only `PluginReminderBackend` (Android) reports
  it; iOS keeps 64 and the desktops none.

## As built: review fixes (#1218-#1227, 2026-10-27)

What the review of the first release of the editor changed.

- **The form's rule is the only rule in the line (#1227).** A draft that
  carries a rule writes its `rec:`, `until:` and `except:` and takes every
  such token out of its text first, readable or not. The first `rec:` and
  the first `until:` of an event are the ones read, so an `until:2026-1-31`
  the grammar cannot read, left in the text, used to win over the end the form
  wrote (and the event ran for ever); a second `rec:` or `until:` typed by
  hand is replaced, not kept beside the form's. A draft with no rule leaves
  the text as it is: a `rec:` nobody can read is kept and flagged.
