# Tasks and reminders

The Todo tab reads `todo.txt` files (todo.txt grammar: `x (A)
2016-05-20 2016-04-30 description +project @context #tag key:value`).

## Line anatomy

- `x ` marks completion; `(A)`…`(Z)` is priority; dates are
  completion-then-creation on done lines, creation-only otherwise.
- `+project`, `@context`, `#tag` tokens carry filing meaning and power
  the filter chips.
- `key:value` tags are annotations. Known: `due:YYYY-MM-DD` (badge,
  filter) and `rem:YYYY-MM-DDTHH:MM` (schedules a reminder).
- Untouched lines round-trip byte-stable; edits normalize spacing.

## Reminders

Add `rem:2026-09-20T09:00` to a task and Niman schedules an exact alarm
in local wall-clock time. It fires with the screen off, the app in the
background, or the process killed (Android). The app warns when
notification or battery-optimization permissions could block delivery.

Notification text is the task's prose without `key:value` tags (and
without `+`/`@`/`#` markers unless the library's `reminderShowTokens`
is true).

## Settings

Per library (`.niman/settings.json`): `reminderShowTokens` (default
false). Global debug log (last 5 000 lines, exportable, survives
reboots) helps diagnose missed reminders.
