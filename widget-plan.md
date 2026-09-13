# Plan — Issue 6: Android home-screen widgets

> TEMPORARY FILE — delete this file when the widget work is finished.
> It exists only to persist the plan on the `feat/widget` branch.
> Do NOT ship it: remove it before merging to `main`.

Issue: https://github.com/Nihmar/Niman/issues/6

## Goal

Two Android home-screen widgets:

1. **Todo widget** — view of the currently opened todos, ordered by due date
   and priority.
2. **Note widget** — view of a chosen note (changeable). Standard `.md` shows
   a preview and tapping opens the note in the editor. `type: list` notes show
   a checklist (MVP: read-only + tap to open).

## Agreed decisions

- "Opened todos" = all not-done tasks of `todo.txt` (`TodoSnapshot.todo`),
  sorted `due ASC (nulls last)` → `priority A-first (nulls last)` →
  `creationDate`/`lineIndex` tiebreak.
- Widget list cap: 20 rows.
- Note rendering in widget = plain-text excerpt with minimal spans for normal
  notes (RemoteViews cannot render full Markdown: no images, tables,
  code-highlight, KaTeX); checklist text rows for `type: list`. Full Markdown
  preview stays inside the app.
- Widget config persistence = new `WidgetConfigs` table in `AppDatabase`
  (currently v18 with `AppSettings` + `KnownLibraries`), migration v19.
- No `docs/` updates for now (per user request; `docs/` does not exist).
- Order: Todo widget first, note widget after.
- No full in-widget editing (reorder/edit/add): not feasible with RemoteViews.
  MVP = read-only + tap to open; checkbox toggle via `BackgroundIntent` only
  if trivial (timeboxed spike in Phase 2).

## Technical approach: option A (chosen)

`home_widget: ^0.9.4` as data transport (`saveWidgetData` / `updateWidget` /
background intents) + hand-written minimal Kotlin/XML
(`AppWidgetProvider`, layouts, `res/xml/*appwidget-provider*.xml`).

Rejected:
- B. Fully manual native (zero deps, but all boilerplate by hand) — fallback
  if `home_widget` blocks us, no Dart-architecture change needed.
- C. Jetpack Glance — adds Compose/Glance to the APK, still RemoteViews
  underneath (no editing unlocked), overkill for two text lists.
- D. `flutter_android_widgets` codegen — too new/immature, extra layer.

## Multi-library + multi-instance design (required)

Each placed widget instance has its own Android `appWidgetId` and its own
config row — never assume "last opened library":

- `WidgetConfigs{androidWidgetId PK, provider: todo|note, libraryPath,
  notePath?, updatedAt}`; `onDeleted` + "forget library" cleanup.
- Configuration activity per instance: pick library (from `KnownLibraries`
  registry) + pick note (note widget). Todo widget defaults to last opened
  for retro-compatibility.
- Per-instance payload keys in `SharedPreferences`
  (`todo_<id>_json`, `note_<id>_json`); provider renders per-id.
- `updatePeriodMillis="0"` — push updates only, no polling.
- Taps carry `libraryPath (+ notePath)`: new intents
  `ACTION_OPEN_NOTE` / `ACTION_OPEN_TODO`; `MainActivity.handleIntent` opens
  that library first, then routes to `_openNoteFromLink` / `_openTodo`.
  Needs a new "open library by path" flow (permission + missing-library
  states). Dart side never lets the native provider walk the filesystem or
  open Drift; native reads only the snapshot.
- App-dead widgets show the last snapshot (passive, per AppWidget rules).

## Key code touchpoints

- `lib/src/todo/parser.dart` (`TodoTask.due/priority`), `todo_store.dart`,
  `todo_filter.dart`, `todo_controller.dart`, `lib/src/ui/shell.dart`
  (`_openNoteFromLink`, `_openTodo`, shortcut routing), `lib/main.dart`
  (`parseLaunchArgs` logs "file argument not opened yet").
- `android/app/src/main/kotlin/dev/niman/niman/MainActivity.kt`,
  `ShortcutsBridge.kt`, `android/app/src/main/AndroidManifest.xml`,
  `res/raw/dev_niman_niman_keep.xml` (R8 pinning precedent).
- `lib/src/db/app_database.dart` (v18 → v19), `lib/src/ui/kinds/list_parser.dart`,
  `lib/src/ui/kinds/list_note.dart`, `lib/src/frontmatter/*`.

## Phases

### Phase 0 — Foundations (once, serves both widgets)

1. `sortTodosForWidget()` pure function + portable unit tests.
2. `WidgetConfigs` table + migration v19 + DAO + codegen
   (`dart run build_runner build`).
3. Intents `ACTION_OPEN_NOTE` / `ACTION_OPEN_TODO` + channel + shell routing
   + open-library-by-path.
4. New `lib/src/widget/` (per-instance serialization, throttled
   `WidgetUpdater.push`, `Isolate.run` reads); manifest/res base + `tools:keep`.

### Phase 1 — Todo widget (first)

Provider + collection (or static top-N) per `appWidgetId`, tap → Todo tab
of that library, refresh action, empty/error states (no `todo.txt`,
library closed, permissions missing).

IMPLEMENTATION NOTE (adopt-first): no configuration activity yet. Dart
enumerates placed ids (`WidgetBridge.getWidgetIds` → `WidgetHostService`)
and unknown instances adopt the open library (`adoptTodoWidget`); a
placed widget is therefore pinned to the library open at placement time.
A native library picker (reconfigure) is deferred — the provider is
already per-id, so no rework. Known limitation: `WidgetConfigs` rows of
deleted instances are reaped on a later refresh (payloads are cleared
natively in `onDeleted`); a full sync rides with the picker.

Acceptance: N instances on N libraries show correct distinct orderings; edit
in app reflects in widget quickly; tap opens the right library's Todo.

### Phase 2 — Note widget (after)

Provider + library+note config (reconfigurable on Android 12+), plain excerpt
/ read-only checklist, tap → editor of that library; "note not found" state.

IMPLEMENTATION NOTE (pin flow, no native picker): the tree row menu
pins a note (`saveWidgetPin` → SharedPreferences, Android-only); the
next `refreshNoteWidgets` lets unknown placed note instances adopt the
pin when it names the open library (other-library pins are put back).
Excerpts are plain text, checklists `☐`/`☑` rows in one scrolling
TextView — RemoteViews cannot render Markdown. Strings use English
fallbacks in `strings/base.dart` until translated (only `it` added).

Acceptance: config change updates widget; tap opens the right note in the
right library; deleted note → clean missing-note state.

## Verify (per AGENTS.md, Linux)

- `dart fix --apply` then `dart format lib test tool` before analyze/tests.
- `./scripts/niman.sh check` (log `/tmp/niman/niman-check.log`).
- `flutter analyze --fatal-infos`, `flutter test`.
- New tests portable: `p.join`, no `chmod`.
- Rebuild + report outcome + artifact path after each commit.

## Work discipline for this branch

- Multiple small commits + push during development (mandatory).
- One logical change per commit; never bundle unrelated changes.
- Delete THIS file before merging to `main`.
