# Widget follow-up requirements (issue 6, round 2)

> TEMPORARY FILE — delete this file before merging to `main`.
> Formalizes the four follow-up requests from on-device testing.
> Implementation must satisfy the acceptance criteria below.

## R1 — Library chooser at placement

When a widget is placed, a dialog must ask which library it reads from.
With a single known library the dialog is skipped (auto-select).

- Both providers get `android:configure` pointing to a single
  `WidgetConfigActivity` (kind passed as extra: todo vs note).
- Library source: a `known_libraries` JSON mirror in `SharedPreferences`,
  written by Dart (`WidgetLibraryMirror`) on every registry touch and on
  startup resume. Entry: `{path, name, indexDb}` (`indexDb` = absolute
  path of that library's index file, so native code never re-derives
  paths). The database stays the source of truth; the mirror is a cache.
- Mirror empty (fresh install, nothing ever opened) → the activity shows
  "Open Niman and open a library first" with a button launching
  `MainActivity`, then `RESULT_CANCELED`.
- Exactly one library → select it and finish with `RESULT_OK`
  immediately, no visible dialog.
- Two or more → list (name + path), tap selects.
- The choice is written to per-instance prefs, `todo_<id>_config` /
  `note_<id>_config` = `{"library": path}`. No drift writes from native
  code, ever.
- Dart adopt flow (`refreshTodoWidgets` / `refreshNoteWidgets`) prefers
  the per-id config over the open library, falls back to the open
  library (todos) / pin (notes) when absent, and clears the config key
  after a successful adopt.
- Manifest: config activity `exported="false"` first; if the launcher
  refuses to start it on-device, flip to `true` (verify on device).

Acceptance:

- Two libraries known → placing either widget shows both; picking B
  while A is open shows B's content.
- One library → no dialog, widget follows it.
- Zero libraries → explanatory message, widget not placed.

## R2 — Checkable todos from the widget

Todo rows get a checkbox; tapping it completes/uncompletes the task
without opening the app.

- Row layout gains a `CheckBox` (RemoteViews collection rows support
  checkable views with fill-in intents). The fill-in URI carries
  `appWidgetId` + file line, e.g.
  `niman://todo-toggle?id=<id>&line=<lineIndex>`.
- The tap fires a `home_widget` background intent
  (`HomeWidgetBackgroundIntent.getBroadcast`) to a Dart background
  entrypoint (`@pragma('vm:entry-point')`, registered via
  `HomeWidget.registerBackgroundCallback`). The background isolate:
  1. parses the URI (id → payload key `todo_<id>` → library from the
     payload's `library` field; no separate lookup),
  2. toggles the line via `TodoStore` (`Isolate.run` not needed there —
     the background isolate may do I/O directly),
  3. re-pushes the payload and calls `updateWidget`.
- Works with the app closed (same sandbox, `MANAGE_EXTERNAL_STORAGE`
  already granted).
- Open point: toggling can affect reminders (`rem:` tags). Reuse the
  existing `ReminderService.reconcile` path in the background callback
  if cheap; otherwise record it as a known limitation here.

Acceptance:

- Tap checkbox → row disappears from the widget, line moves to
  `done.txt` (verified on disk), count updates.
- Works with the app swiped away.
- No full app launch (no activity comes to foreground).

## R3 — Add-todo button on the widget

The todo widget header gets a "+" button opening the app's add-task
dialog — the same flow as the launcher shortcut.

- No new Dart code: the button fires the existing shortcut intent
  (`ACTION = dev.niman.niman.SHORTCUT`, `EXTRA_ID = "new_todo"`),
  already handled by `ShortcutsBridge.handleIntent` → `_runShortcut` →
  add-task dialog.
- Wire `R.id.widget_todo_add` in `TodoWidgetProvider` with
  `FLAG_UPDATE_CURRENT or FLAG_IMMUTABLE`, request code = `appWidgetId`.
- Layout: "+" `TextView`/`ImageView` at the header end; keep it
  tappable at minimum 48dp touch target (header height may grow).

Acceptance:

- Tap "+" → app opens with the add-task dialog (identical to the
  launcher shortcut behavior).

## R4 — Note file picker (replaces pin confusion)

Placing the note widget must show a file picker for the note, instead
of silently adopting whatever was pinned in-app. The current
pin-then-place flow is kept as a fallback.

- `WidgetConfigActivity` (note kind): after the library step (R1),
  shows the library's `.md` files in a searchable list (`EditText`
  filter + `ListView`), sourced READ-ONLY from that library's
  `IndexDatabase` via framework `SQLiteDatabase` (`indexDb` path comes
  from the mirror entry — no path derivation natively). Query: notes
  table, `isDir = 0`, order by name, limit 1000. Reads only; WAL-safe
  for short read transactions alongside the drift writer.
- Picking writes `note_<id>_config` = `{library, note}` to prefs,
  activity finishes `RESULT_OK`.
- Dart adopt priority for unknown note instances: per-id config >
  pin > leave unconfigured (provider keeps showing "Pin a note in
  Niman…" placeholder).
- The in-app tree action "Pin to home widget" stays as the alternative
  path (pin consumed only when no config exists).

Acceptance:

- Place note widget → library step (or skipped) → searchable `.md`
  list → pick → widget shows that note's excerpt/checklist.
- Tap → opens that note in the editor of the right library.
- Search filter narrows the list; 1000-row cap documented in the UI
  when hit ("showing first 1000 — refine the search").
- Deleted note afterwards → widget shows "Note not found" (existing
  `missing` payload path).

## Shared / non-functional notes

- No `SharedPreferences` key renames: payload keys `todo_<id>` /
  `note_<id>` unchanged; new keys only (`*_config`, `known_libraries`
  mirror, pin key unchanged).
- R8: any new drawable referenced only by name gets a `tools:keep`
  entry (`dev_niman_niman_keep.xml` precedent).
- Tests: unit tests for mirror JSON, adopt-priority (config > pin >
  none), checklist/excerpt unchanged; widget tests for config-adopt
  via fakes; on-device verification for R2 background toggle with app
  closed and R4 picker on a large library.
- Suggested implementation order: R3 (trivial) → R1 (mirror + todo
  config + adopt priority) → R4 (note list + config) → R2 (background
  toggle, biggest unknown).
