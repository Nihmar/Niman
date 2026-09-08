# App quick actions — launcher long-press shortcuts

**Status:** Implemented 2026-09-08 (Android host + Dart routing + icons;
analyze and tests green) — the on-device launcher check is still to be
done by the user · **Depends on:** M4 (frontmatter, for the `new list`
action's `type: list` note) and the Todo tab (todo-tab.md, for the
`new todo` action), both landed · **Spec:** user request (quick actions in
the launcher long-press menu, Android).

## Purpose

Add the launcher **quick actions** (the options shown when long-pressing the
app's icon in the app drawer / launcher). Four actions:

- **New note** — open the new-note creation flow (today's FAB "New note").
- **New todo** — open the **add-task dialog** (the Todo tab's add-a-task
  dialog), not merely the tab.
- **New list** — open a new `type: list` checklist note (the FAB "New list
  note" from [`m-type-note-kinds.md`](m-type-note-kinds.md)).

Each action launches (or foregrounds) the app and lands the user **at the
relevant screen**, not in a detached background task. This is the Android
**App Shortcuts** mechanism (dynamic shortcuts set at runtime), which shows
in the same long-press menu as static shortcuts.

## Terminology

Launcher long-press options are **App Shortcuts** on Android (the launcher's
long-press flyout). "Quick actions" is how iOS describes the equivalent;
this plan targets **Android v1**. Desktop (Linux/Windows) has no equivalent
launcher long-press menu in v1 (Windows taskbar jumplists / macOS dock menu
are out of scope and noted below).

## Agreed decisions (design)

1. **Android only for v1.** The long-press shortcut menu is an Android
   launcher feature. Linux/Windows: no-op in v1 (documented as a
   limitation; taskbar jumplists / a desktop-equiv menu are future work).
2. **Dynamic shortcuts, set at runtime.** Use `ShortcutManager`
   (dynamic shortcuts, API 25+) so the app can publish all four, choose
   labels/visibility, and refresh. This needs a method channel to the host
   Kotlin `MainActivity` (plain Dart can't call `ShortcutManager`). Static
   `res/xml/shortcuts.xml` is not used for the four actions (they'd be
   frozen at build time), though it can host a couple of always-available
   ones if wanted later.
3. **Shortcuts are launchers, not background tasks.** Each shortcut sends an
   intent to `MainActivity` (custom `action` + extras like `"new_list"`),
   which delivers it to Flutter; the app then navigates to the target screen
   exactly as if the user had tapped the equivalent button. No shortcut runs
   work with the app closed beyond bringing it to the foreground.
4. **Behavior mirrors the in-app action.** The action lands on the same
   flow the equivalent in-app control uses (same dialog, same persistence
   path), so behaviour is consistent. e.g. "New note" reuses the shell's
   `_createNote`; "New list" reuses the `type: list` creation; "New todo"
   opens the Todo tab's add-task dialog; "Quick note" selects the Quick
   note tab.
5. **Count/cap.** Android shows at most a handful per launcher (commonly up
   to 4; the platform enforces a max, extra shortcuts are dropped). We plan
   exactly four, so all are published; on launchers that show fewer, the
   four still publish in order and the launcher picks.
6. **Icons** (API 33+ must be adaptive/maskable for proper launcher
   display). Shortcut icons are supplied in the shortcut `extra` (an Intent
   with Icon; adaptive icons via `android:icon` XML or a bundled vector). We
   use the app's existing mockup glyphs re-tinted per action, drawn as
   vectors.
7. **Ordering + labels.** Fixed order (Quick note, New todo, New note, New
   list) matching the user's list; labels are the exact user strings. No
   in-app reordering in v1.

## Shortcut dependency table

| Shortcut | Target screen | Blocks on |
|----------|---------------|-----------|
| Quick note | Quick note tab (library root scratch note) | exists today |
| New note   | shell `_createNote` (FAB "New note") | exists today |
| New todo   | Todo tab **add-task dialog** | Todo tab (`todo-tab.md`) — landed |
| New list   | `type: list` note creation | `type` notes (`m-type-note-kinds.md`) + M4 frontmatter — landed |

Both dependencies were in place when this shipped, so all four actions
publish; nothing had to be deferred.

## Tasks

- [x] **T-SC-01** Method channel plumbing. A `MethodChannel` (`copist/shortcuts`)
  between Dart and the host `MainActivity`: Dart registers a handler for
  incoming shortcut intents; Kotlin overrides `onCreate`/`onNewIntent` to
  read the shortcut `action`/`extra` and forward it to the channel. Also a
  Dart→Kotlin method to publish/refresh the dynamic shortcut set. *AC: a
  test shortcut intent received by the activity surfaces a callback in
  Dart.*
- [x] **T-SC-02** Shortcut model + publish. `core/shortcuts.dart` (or
  `ui/shortcuts.dart`): a `ShortcutAction` enum (quickNote, newTodo,
  newNote, newList), each with id, label, icon. A `publishShortcuts()`
  method builds the four `ShortcutInfoCompat`/`ShortcutInfo` objects (via
  the channel) and calls `setDynamicShortcuts`. Called once at app start
  (and on library/settings changes that affect the target paths, e.g. the
  quick-note path). *AC: publishing pushes four dynamic shortcuts; the
  launcher long-press shows them.*
- [x] **T-SC-03** Routing: shortcut → in-app navigation. Map each incoming
  `ShortcutAction` to the existing app flow (switch on the enum, reuse the
  shell's tab select / `_createNote` / list-creation / todo-add). Landing on
  a creation flow opens the same dialog the FAB uses. *AC: each shortcut
  lands on the matching screen; a cold start and a warm start both work.*
- [x] **T-SC-04** Quick note shortcut. Foregrounds the app and selects the
  Quick note tab (widening to the scratch note if the tab isn't focused).
  *AC: quicknote lands on the quick note.*
- [x] **T-SC-05** New note shortcut. Launches the shell's new-note flow
  (the same `_nameDialog` + `createNote` the FAB uses). *AC: newnote shows
  the new-note dialog and creates on confirm.*
- [x] **T-SC-06** New todo shortcut. Opens the **Todo tab's add-task dialog**
  (the same dialog the Todo tab's "add" control opens), not just the tab.
  Blocked on the Todo tab; when it lands, this taps the same add path. If
  the Todo tab is still a stub, defer this shortcut — a v1 can ship with
  three shortcuts (quicknote, newnote, newlist) plus a disabled/absent
  new-todo. *AC: newtodo opens the todo add-task dialog ready to type a
  new task.*
- [x] **T-SC-07** New list shortcut. Opens the `type: list` creation flow
  (reusing `m-type-note-kinds.md`'s "New list note": creates a note with
  `type: list` in the configured `Lists/` folder and opens the list GUI).
  Blocked on that feature. *AC: newlist creates a `type: list` note in the
  configured folder and opens it.*
- [x] **T-SC-08** Adaptive/maskable shortcut icons. Vector shortcut icons for
  each action (API 33+ correct display), drawn from the app's mockup glyphs.
  *AC: shortcuts render correctly on an API 33+ emulator/device.*
- [x] **T-SC-09** Strings + tests. Strings in `strings.dart`; Dart-side unit
  tests for the action→flow mapping and the publish payload; an
  Android-side test for the intent → channel handoff where feasible. *AC:
  mapping tests green; on-device long-press shows the four shortcuts and
  each lands correctly.*

## Technical design

- **Host side (Android).** `MainActivity` (Kotlin) implements the channel:
  - Receives shortcut intents in `onCreate` (cold start) and `onNewIntent`
    (warm). Both funnel to a `handleShortcut(intent)` that reads the
    `action`/`extra` and calls the Dart method-channel handler.
  - Exposes a Dart-callable method `publishShortcuts(List<…>)` that builds
    `ShortcutInfo` objects and calls `ShortcutManager.setDynamicShortcuts`.
  - Shortcuts are declared once via a minimal static placeholder is *not*
    required for dynamic shortcuts — dynamic shortcuts appear in the
    long-press menu without a `shortcuts.xml` entry on modern launchers;
    but a small `shortcuts.xml` with the four intent templates (declaring
    the action + extras) improves launcher compatibility. Decide in T-SC-01.
- **Dart side.** `lib/src/core/shortcuts.dart` (or `ui/`) holds the action
  enum and `ShortcutsService`; it calls the channel to publish and listens
  for incoming shortcut events. On a shortcut event it asks the shell to
  navigate (via the existing controller/ops). The shortcut handler is
  registered at app start and is resilient to the library not being open yet
  (launch → open library → then act).
- **No data model.** Shortcuts carry no note data; they only select a screen
  or creation flow. Nothing new in drift.
- **Cap/launcher behaviour.** Four shortcuts fit the common cap; if a
  launcher shows fewer, the platform picks by rank. We set a fixed rank
  order and accept that some launchers may not show all four.
- **Cold vs warm start.** Cold start: the shortcut intent arrives in
  `onCreate`; the app must open (or reopen) the library and then perform the
  action, possibly after the first-frame/async init. Warm start: the app is
  already running and foregrounds with the action. Both handled in T-SC-03.

## Exit criteria

- Long-pressing the Copist launcher icon on Android shows all four actions
  (or, until the Todo tab / `type` notes land, the subset that's ready).
- Each action brings the app to the matching screen/creation flow, via both
  cold and warm starts, and reuses the exact in-app behaviour.
- Shortcut icons render correctly on API 33+ (adaptive/maskable).
- Desktop (Linux/Windows): no crash, no shortcut (documented limitation).
- Dart-side mapping/publish unit tests green.

## Risks / open questions

- **Dependency gating.** Resolved: the Todo tab and the `type: list`
  feature both landed first, so all four shipped in one batch.
- **Launcher cap/visibility.** Some launchers show fewer than four shortcuts;
  behaviour is launcher-dependent and can't be fully controlled. Accept the
  platform's cap.
- **Shortcut icons on API < 33.** Non-adaptive icons need a fallback (a plain
  vector) for older devices so they don't render as a blob.
- **Desktop equivalents.** Windows taskbar jumplists / macOS dock menu are a
  real but separate feature; out of scope for v1 Android. Confirm desktop is
  explicitly deferred.
- **"New todo" semantics.** Resolved: it opens the **add-task dialog**
  (the Todo tab's add control), not just the tab. The exact dialog design
  follows `todo-tab.md`'s add flow once that lands.
- **Library not yet open.** On a cold start via a shortcut, the library may
  not be open yet; the action must wait for it. Confirm the launch sequence
  (open library → navigate) is acceptable vs. failing fast.
- **Milestone slot.** Mostly independent plumbing + a few navigation hooks.
  Candidate: a small slice after M2a, or folded into M6 (polish) once the
  todo tab and `type` notes exist. Not on the M0→M7 critical path; it
  depends on those two features for the full set.
