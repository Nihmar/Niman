# Todo reminders — the 5 to 10 minute delay

**Status:** cause found 2026-09-08 from a device log; the fix is in,
device confirmation outstanding · **Depends on:**
`todo-tab.md` T-TD-07 (reminders, landed) · **Evidence:** a device log of
a reminder set for 14:50 that never rang.

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
- [x] **T-RL-03** Act on the measurement. The measurement said the app
  was cancelling its own deferred alarms, so `wantedReminders` now keeps
  a reminder for `reminderGrace` (one hour) past its own moment: the
  sweep leaves the alarm pending, scheduling still skips it. *AC: after
  the fix, a reminder set for `now + 2 min` with the screen off arrives,
  three times running.* Confirmed on device 2026-09-08 (see below), on
  one run rather than three.
- [x] **T-RL-04** Keep the evidence. Recorded below and in
  `plan/android.md`. *AC: the next person does not re-derive it.*

## The answer (2026-09-08 device log)

None of the four candidates. **Copist was cancelling its own alarms.**

The log of a reminder set for 14:50, with the app in the foreground the
whole time:

```text
14:43:32 reconcile 1 wanted, alarms exact, battery unrestricted
14:43:32 armed 1424219112 for 2026-09-08T14:50:00.000 (in 6m) test
14:43:32 1 pending after reconcile [1424219112]
...
14:53:12 reconcile 0 wanted, ...
14:53:12 cancelled 1 stale
```

The alarm was armed exact and the OS still held it at 14:53 — three
minutes past its own time, which is a deferral. `cancelled 1 stale`
proves both halves at once: the sweep only cancels ids the OS reports as
pending, so the alarm had not fired, and Copist then removed it.

Why it was considered stale: `wantedReminders` dropped any reminder whose
moment had passed, and reconciliation is a full replace — anything
outside the wanted set gets its pending alarm cancelled. So every
reconcile after a reminder's time (a todo reload, a resume, a file
change) silently killed an alarm that was still going to ring. Whether
the user heard the reminder came down to whether Android fired before
Copist swept.

This also explains the shape of the complaint. A short deferral that beat
the next reconcile arrived late; one that did not arrived never.

Two things this does *not* explain, both worth keeping in mind:

- **The deferral itself.** Android held an exact,
  allow-while-idle alarm at least three minutes past its time. The fix
  stops Copist from making that fatal; it does not make Android prompt.
- **`alarms inexact` in most lines.** Noise, not a finding: `_reconcileOnce`
  computes `exact` as `granted && wanted.isNotEmpty && ...`, so every
  reconcile with an empty set reports `inexact` without asking the
  platform. The one line with a reminder in it says `exact`.

### The confirming run (2026-09-08 17:35 log)

Same device, with the fix in:

```text
16:45:49 armed 945943890 for 2026-09-08T16:47:00.000 (in 1m) test
16:45:49 1 pending after reconcile [945943890]
17:18:08 overdue 945943890 due 2026-09-08T16:47:00.000 (31m ago),
         no longer pending, fired, alarms exact, battery unrestricted
17:18:08 skipped 945943890, 2026-09-08T16:47:00.000 already passed
```

The reminder arrived. Three things the old build got wrong are right
here at once: the alarm was not cancelled, `no longer pending, fired`
says the OS delivered it, and `skipped ... already passed` says nothing
tried to re-arm an instant in the past. The overdue line exists at all
only because of `reminderGrace` — this is the line that stayed silent on
the run that caught the bug.

One run, not the three the AC asked for, and the log does not say whether
the screen was off.

### Why T-RL-01 did not catch it

`_logOverdue` takes the *wanted* set, which by construction could not
contain a past reminder — so on the very run that caught the bug it
logged nothing. The instrumentation was downstream of the thing it was
measuring. With `reminderGrace` in place the wanted set does carry
overdue reminders and the line now fires.

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
