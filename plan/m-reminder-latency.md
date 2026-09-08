# Todo reminders — the 5 to 10 minute delay

**Status:** T-RL-01 and T-RL-02 done 2026-09-08; the next device log
decides T-RL-03 · **Depends on:**
`todo-tab.md` T-TD-07 (reminders, landed) · **Evidence so far:** the user
reports notifications arriving, but sometimes 5–10 minutes late.

## The symptom

Reminders are delivered, so the alarm, the channel, the icon and the boot
receiver all work. What slips is *when*: sometimes minutes after the
scheduled minute. A reminder that is reliably late is a reminder the user
stops trusting, so this is worth chasing even though nothing is lost.

## What the code does today

`todo/reminder_backend_plugin.dart` schedules through
`zonedSchedule(... androidScheduleMode: exact ? exactAllowWhileIdle :
inexactAllowWhileIdle)`, where `exact` comes from
`canScheduleExactNotifications()`. `USE_EXACT_ALARM` is declared in the
manifest and is auto-granted at install, so the exact branch should be
the one taken. `reminders.dart` already tracks a `ReminderHealth` and the
banner offers the battery-optimization and notification settings screens.

## The candidates, most likely first

1. **The inexact fallback is what is running.** If
   `canScheduleExactNotifications()` returns false on this ROM, every
   alarm is `inexactAllowWhileIdle`, which Doze batches — minutes of slip
   is exactly its signature. The health state already knows this; nothing
   has checked it on the device while a late reminder happened.
2. **Doze's per-app quota.** Even exact-and-allow-while-idle alarms are
   rate limited per app while the device is idle. A single reminder is
   under any quota, so this only bites a burst.
3. **The OEM battery manager.** The device is a ROM that freezes
   background apps aggressively; `AGENTS.md` already records that some of
   them drop pending alarms outright on a swipe away. Battery
   optimization exemption is offered in the app but may not be granted.
4. **The clock the alarm was computed from.** `tz.local` falls back to
   UTC when the platform timezone cannot be read; the schedule is
   instant-preserving so this would show as hours, not minutes. Ruled out
   by the symptom, but cheap to confirm in the log.

## Tasks

- [x] **T-RL-01** Make the delay measurable. On resume (and on every
  reconcile) log one line per pending reminder whose scheduled instant is
  already in the past — it should have fired and did not — together with
  the exact/inexact state, the battery-optimization state and the
  resolved timezone. *AC: a device log after a late reminder says which
  of the candidates is true.*
- [x] **T-RL-02** Report the health where it is visible. If the state is
  `inexactOnly`, the banner already exists; make sure a late-alarm run
  surfaces it rather than leaving the user guessing. *AC: with exact
  alarms unavailable, the tab shows the banner.*
- [ ] **T-RL-03** Act on the measurement. One of: force the exact branch
  when the permission is actually granted (candidate 1); prompt for the
  battery exemption when a late alarm is detected (candidate 3); or, if
  the platform is simply deferring, say so in the UI rather than
  pretending minute precision. *AC: after the fix, a reminder set for
  `now + 2 min` with the screen off arrives inside the minute, three
  times running.*
- [ ] **T-RL-04** Keep the evidence. Whatever the cause turns out to be,
  record it in this file and in `plan/android.md`, which is where the
  platform traps of this project live. *AC: the next person does not
  re-derive it.*

## What the log now says

Every reconcile with a reminder whose moment has passed writes one line
per reminder:

```text
todo reminders: overdue 867842594 due 2026-09-08T10:30:00.000
  (12m ago), STILL PENDING, never fired, alarms exact, battery optimized
```

`STILL PENDING` means the OS is holding an alarm past its own time — the
deferral signature, and the answer is on the same line (candidate 1 or
3). `no longer pending, fired` means the alarm went off and the lateness
was in the delivery. Nothing is logged while every reminder is still
ahead, and the check adds no query.

The health banner already covers the `inexactOnly` and
`batteryRestricted` states in the Todo tab, so a run with either one
tells the user without an export.

## Exit criteria

- A device log identifies the cause instead of a guess.
- A reminder set two minutes out arrives within the minute, repeatedly,
  with the screen off and the app closed.
- If the platform cannot promise that, the app says so instead.

## Risks / open questions

- **Not reproducible on demand.** The delay is intermittent, so T-RL-01
  matters more than any speculative fix: without it every change is
  unfalsifiable.
- **Nothing in-app sees the delivery.** The plugin reports no "delivered
  at" time; the pending-after-its-time check is the closest available
  proxy.
