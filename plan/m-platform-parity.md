# Platform parity — Android ↔ Linux/Windows

**Status:** Planned · **Depends on:** M4 (everything compared exists) ·
**Spec:** *Requirements → Platforms* (Android + Linux + Windows now)

## Purpose

Android and desktop share the whole library/editor/search stack, but every
feature that touches the OS exists on one side only. This slice inventories
the split and aligns the two sides: desktop gets what Android has (where a
desktop equivalent exists), Android gets what is missing on both sides, and
what has no equivalent is written down instead of silently absent.

## Current state

Core is shared and needs no work: library open/watch/index (isolate walk +
`.md`-only digests), tree CRUD, trash, history, editor (`re_editor` +
incremental tokenizer), preview (markdown + KaTeX), links, FTS5 search,
tags, frontmatter, templates, `type: list` GUI, Todo parsing/filtering,
localization, toolbar customization, `file_picker` image insert.

The split is at the OS boundary. Each row is verified against the tree
(file:line), not assumed from the spec.

| Feature | Android | Linux / Windows | Gap |
|---------|---------|-----------------|-----|
| Todo reminders (OS notify) | Full: exact alarms via `setExactAndAllowWhileIdle` (`USE_EXACT_ALARM`), boot receivers, battery/notification health + banner (`todo/reminder_backend_plugin.dart`, `todo/reminders.dart:77`, `android/app/src/main/AndroidManifest.xml`) | `NoopReminderService` — due badges only, documented limitation (`todo/reminders.dart:22`) | **Desktop behind.** `flutter_local_notifications_linux` / `_windows` exist in the dependency tree but no desktop backend is wired (`linux/flutter/generated_plugins.cmake` registers no notifications plugin). |
| Launcher quick actions | 4 dynamic shortcuts via `ShortcutManager` over `copist/shortcuts` (`core/shortcuts.dart:85`, `ShortcutsBridge.kt`) | `NoopShortcutService` (`core/shortcuts.dart:72`) — documented v1 limitation (`plan/m-app-shortcuts.md`) | **Desktop behind by design.** No long-press menu exists; equivalents are `.desktop` Actions / Windows jumplist / CLI flags — none implemented. |
| Storage permission | `MANAGE_EXTERNAL_STORAGE` gate over `copist/storage` (`core/storage_access.dart`, `MainActivity.kt:131`) | Always `true` — no restriction | No gap (correctly platform-specific), but every new file-IO path must keep passing through plain `dart:io` so the statement stays true. |
| Reminder health screens | Battery-optimization + notification settings via `copist/reminders` (`todo/reminder_settings.dart`, `MainActivity.kt:71`) | Inert (`!Platform.isAndroid` early-returns) | Follows the reminder gap: desktop needs its own health concept (notification daemon present? app must be running — there is no AlarmManager with a dead process). |
| Share-in / open-with | Missing: manifest has only `MAIN`/`LAUNCHER`, no `SEND`/`VIEW` filter. The `PROCESS_TEXT` entry under `<queries>` is package visibility for the engine's selection menu, not a share target. | Missing: no file association, no CLI file argument, no drag-drop. | **Both behind.** Symmetric gap, one design. |
| Spellcheck | Free via the system IME (no app code — zero `spell` hits in `lib/`) | Nothing on Linux (stretch goal 4, backlog); spec says "where available" | **Desktop behind.** Needs an explicit scope decision, not a bugfix. |
| Keyboard / menus | Editor find/replace activators only (`editor/find_panel.dart:208`); no app-level accelerators | Same code, same gap — desktop expects Ctrl+N/F/S, Esc, a menu bar; phone expects system-back handling | **Both behind**, felt on desktop. |
| Layout chrome | Bottom nav + FAB + full-screen Edit/Preview eye switch | Sidebar + draggable split (`PreviewLayoutMode`, `splitRatio`) via `splitBreakpoint` (`ui/shell.dart:432`) | No gap — adaptive by design. New screens must keep both branches working. |
| Image-insert paths | Shared `file_picker` + `importImageToLibrary` (`ui/note_view.dart:573`); **T-M6-09** keeps the on-device verification open | Same shared code, same open verification | Verification gap, not implementation. Stays with T-M6-09. |
| Notifications icon | Pinned against R8 shrinking (`dev_copist_copist_keep.xml`) | N/A | No gap, but renaming the drawable must update the keep file (AGENTS.md). |
| Packaging | APK/AAB (M7) | tar.gz + AppImage + Arch pkg / Windows zip (M7) | No feature gap; M7 must ship the same version on all artifacts. |
| Secure storage | Keystore via `flutter_secure_storage` | libsecret (Linux) / Credential Manager (Windows) via the same API | Same API, different daemons — verify, not rebuild (first-run without `dbus`/keychain must degrade cleanly). |

Out of scope for this slice: M5 sync, M6 themes/encryption/tabs (both
sides equally absent — they land shared), M7 branding/packaging execution.

## Tasks

### P0 — Lock the inventory

- [ ] **T-PP-01** Turn the table above into widget/unit probes where cheap:
  a test that `createReminderService`/`createShortcutService` return the
  Noop off Android already exists in shape — assert the documented
  limitations stay documented (strings + banner) until each phase lands.
  *AC: a new platform-only capability cannot ship silently Noop on the
  other side; the limitation string or the feature goes with it.* Tests
  may differ per platform where the chrome does (narrow bottom bar vs
  wide rail): size the surface explicitly (`setSurfaceSize`) and assert
  the layout under test, instead of forcing one layout's expectations
  onto the other.

### P1 — Desktop reminders (the big one)

- [ ] **T-PP-02** Spike: `flutter_local_notifications` on Linux (libnotify)
  and Windows (toasts) from this tree — schedule, reboot/restart survival,
  closed-app behaviour. The expected answer is "fires while running, not
  with the process dead" (no AlarmManager equivalent). *AC: a one-page
  note in this file records what each desktop OS actually guarantees.*
- [ ] **T-PP-03** `DesktopReminderBackend` behind the existing
  `ReminderBackend` interface (`todo/reminder_backend.dart`): same full-
  replace reconciliation, new backend; `createReminderService` picks it on
  Linux/Windows. Health becomes "notifications allowed + app running",
  with the banner pointing at the desktop notification settings (or saying
  so when there is no API). *AC: a `rem:` fires as a desktop notification
  with the app running; closed-app limits are stated in-app, not found
  out.*
- [ ] **T-PP-04** Device-and-desktop verification: the T-RL-01 overdue line
  (`STILL PENDING` vs `fired`) must read sensibly on desktop backends too.
  *AC: one log each from Linux and Windows next to the Android one.*

### P2 — Quick-action equivalents + CLI (desktop side of shortcuts)

- [ ] **T-PP-05** CLI args as the shared floor: `--quick-note`,
  `--new-note`, `--new-todo`, `--new-list`, plus `<file>` (feeds P3).
  Route through the same `_runShortcut` paths the Android shortcuts use
  (`ui/shell.dart:648`), so the flows cannot drift. *AC: each flag lands
  on the same screen as its launcher twin.*
- [ ] **T-PP-06** Desktop surface: Linux `.desktop` `Actions=` (four
  entries calling the CLI flags) shipped in the tar.gz/AppImage/pkg;
  Windows jumplist tasks (or documented deferral with reason). *AC:
  right-clicking the desktop icon offers the same four entries, or the
  Risks section says why not yet.*
- [ ] **T-PP-06a** KRunner discoverability (KDE): spike what KRunner
  actually lists — the main `.desktop` entry (via `Name`/`GenericName`/
  `Keywords=`) is found, but individual `Actions=` are task-manager/dock
  surface and are not separate KRunner results. Candidates for one-hit
  quick actions from KRunner: four extra `.desktop` files (menu clutter),
  a `org.kde.krunner1` DBus plugin (heavy), or CLI-on-PATH + keywords so
  `copist --new-note` runs from KRunner's command line (documented).
  *AC: the spike records which one KDE shows, and the chosen one ships;
  at minimum the main entry carries keywords covering all four actions.*

### P2b — Desktop tab chrome (nav rail)

- [x] **T-PP-14** Fixed left `NavigationRail` on the wide layout,
  always visible, mirroring the narrow bottom bar: same five tabs (Files,
  Todo, Search, Quick note, Settings), same `_onDestinationSelected`
  routing, same kept-alive bodies. Files (and the open quick note, whose
  body is the detail pane) keep the tree + detail split; Todo/Search/
  Settings render their tab bodies inline instead of pushed routes only.
  Pushed routes (`_openTodo`, `_openQuickNoteChooser` on wide) stay until
  T-PP-15 retires them. *AC: on a ≥600 px window the rail switches tabs
  without losing tree state; widget tests cover the rail at desktop
  size (tests may differ per platform — see T-PP-01).*
- [x] **T-PP-15** Retire the wide pushed routes: the app-bar Todo button
  is gone (reminder taps select the rail tab), the quick-note chooser is
  inline on all layouts, and the app-bar Settings button is gone too —
  the rail owns the Settings tab, so navigation has one model per layout
  and no pushed `SettingsScreen` on wide. *AC: no duplicate Todo/Settings
  surfaces on wide.*
- [x] **T-PP-17** Editor toolbar placement: `NoteView(toolbarTop: true)`
  in the wide detail pane puts the formatting bar above the editor
  (desktop chrome), with a divider setting it off the text; the phone
  keeps it below, extending the keyboard. The bar hides in fullscreen
  preview on both (regression-tested). The editor|preview split divider
  is 1 px visual (grab box unchanged). The status row stays at the
  bottom on both. *AC: bar-above on wide, bar-below on narrow, covered
  per layout in widget tests.*
- [x] **T-PP-18** Phone-only settings: the keyboard-on-open row shows on
  Android/iOS only (desktop has no on-screen keyboard to show). The
  split/switch choice is no longer a settings row at all: a layout menu
  in the wide note app bar (side-by-side / full-screen, persisted to the
  same library setting) replaces it. *AC: keyboard row hidden on
  desktop; layout menu flips the effective layout from the editor.*
- [x] **T-PP-20** Tree context menu on right-click (desktop): the same
  entries as the long-press sheet (one shared model, two presentations)
  in a cursor menu; long-press stays for touchscreens. *AC: right-click
  opens the menu at the cursor and runs the same actions.*
- [x] **T-PP-21** Resizable tree pane (wide): a draggable divider between
  the tree and the detail pane (1 px visual, wide grab box, resize
  cursor — the editor split's shape) resizes the tree; the lift persists
  the width to the library settings (clamped 200–600, default 340) and
  the next launch restores it. *AC: dragging changes the width live and
  a relaunch restores the last one; the phone layout is untouched.*

### P3 — Share-in / open-with (both sides)

- [ ] **T-PP-07** Android: `SEND`/`VIEW` intent-filters for `text/plain`
  and `.md`, extended `MainActivity.onCreate`/`onNewIntent` → Dart (same
  channel pattern as shortcuts): plain text becomes a quick-note insert,
  a file becomes an import into the open library. *AC: sharing text/a
  `.md` from another app lands in Copist.*
- [ ] **T-PP-08** Desktop: MIME/file association (`.md` opens with Copist)
  + single-instance handoff (second launch forwards `<file>` to the
  running window) + optional drag-drop onto the tree. *AC: double-clicking
  a `.md` opens it in Copist; a second launch does not open a second
  library window.*

### P4 — Spellcheck scope (desktop side)

- [ ] **T-PP-09** Decide and implement the Linux (/Windows) spellcheck:
  candidates are Flutter's `SpellCheckConfiguration` where the platform
  supplies one vs a bundled hunspell dictionary (stretch goal 4). Android
  keeps IME behaviour unchanged. *AC: the spec line "spellcheck (where
  available)" names each platform's actual provider, or the backlog entry
  is promoted into tasks here.*

### P5 — Keyboard / window integration (felt mostly on desktop)

- [ ] **T-PP-10** App-level accelerators (new note/todo, find, save,
  tab switch — the set the editor activators started in `find_panel.dart`)
  that do not fight the editor's own bindings; Esc closes dialogs before
  windows; system-back on Android keeps its current behaviour. *AC: the
  list of accelerators is documented in-app (settings or help) and
  identical shortcuts do identical things on all three OSes.*
- [ ] **T-PP-11** Dirty-check on window close (desktop) / task removal
  (Android): the note pipeline already knows "saved" (`ui/note_view.dart`
  status row) — hook it to window-close events (see T-PP-16 for the
  package choice) instead of growing a second source of truth. *AC:
  closing with unsaved edits asks, on desktop; no behaviour change on
  Android.*
- [ ] **T-PP-16** Evaluate `nativeapi` (leanflutter.dev, v0.2.3, MIT —
  Flutter bindings over FFI for window/tray/menu/dialog APIs on all five
  platforms) for the desktop window chrome: custom titlebar
  (`titleBarStyle = hidden` + a Flutter-drawn bar), tray icon with the
  four quick actions in its context menu, native menus, and the
  close-request events T-PP-11 needs. Spike on a Wayland session first:
  the package is pre-1.0/WIP (API churn is the risk), it adds a native
  FFI dependency where desktop currently has none, and a hidden titlebar
  must coexist with the runner's GNOME header-bar logic
  (`linux/runner/my_application.cc`) rather than fight it. If the spike
  passes, `nativeapi` replaces the `window_close` candidate in T-PP-11
  and the tray menu becomes the third quick-action surface next to
  `.desktop` Actions and KRunner. *AC: spike note records Wayland
  behaviour (hidden bar, drag-to-move, window controls) + API-stability
  judgement, and T-PP-11 names the chosen package.*

### P6 — Verification hooks (no new code without a device)

- [ ] **T-PP-12** T-M6-09 close-out per platform: one inserted image,
  opened from its library-relative link, on Android (shared storage),
  Linux (Wayland session), Windows. *AC: three checkmarks in T-M6-09, or
  the failing platform's row here says what broke.*
- [ ] **T-PP-13** Secure-storage first-run on all three (fresh profile, no
  keychain/dbus): credentials save/load, clean degradation. *AC: covered
  by hand, recorded here.*

## Technical design

- **Reminders:** the `ReminderBackend` seam (`todo/reminder_backend.dart`)
  already isolates the platform; P1 adds an implementation, not a
  redesign. Do not promise AlarmManager semantics on desktop — the honest
  contract is "fires while the app runs, plus whatever the OS scheduler
  offers", surfaced through `ReminderHealth` like the Android states.
- **Shortcuts/CLI:** `ShortcutAction` ids are the wire format
  (`core/shortcuts.dart:22`) — CLI flags map onto the same enum so Android
  intents and desktop launches converge in `_runShortcut`. No drift by
  construction (the rule `m-app-shortcuts.md` already sets).
- **Share-in:** Android extends the existing `MainActivity` intent funnel
  (same shape as `ShortcutsBridge.handleIntent(..., running)`); desktop
  needs a single-instance guard first, otherwise `<file>` opens a second
  process against the same library.
- **What stays divergent:** storage permission (Android-only),
  bottom-bar vs left-rail chrome (width-adaptive by design, T-PP-14),
  reminder exactness (OS capability, surfaced not hidden).

## Exit criteria

- Every row in the table is either shared, has a desktop equivalent, or
  names its documented limitation in-app.
- A `rem:` fires on all three platforms with the app running; closed-app
  limits are stated where the OS imposes them.
- The four quick actions are reachable on all three (launcher menu on
  Android, `.desktop` Actions/jumplist + CLI elsewhere) and run the same
  flows.
- Sharing a text/`.md` into Copist works from Android and from the desktop
  file manager; spellcheck provision per platform is written in the spec
  line, not tribal knowledge.
- No `Platform.isAndroid` gate remains that silently degrades desktop —
  each has a tracked task or a documented reason above.

## Risks / open questions

- **Desktop closed-app reminders** may be impossible without a
  login-item/background daemon — the T-PP-02 spike decides whether P1
  promises "while running" only. Do not build a daemon in this slice if
  the answer is no; say so.
- **Windows jumplist / MSIX** interacts with M7 packaging (installer
  decision in T-M7-07): jumplist tasks may need the installer route. If
  so, P2 ships CLI + Linux Actions first and records Windows as blocked
  on T-M7-07.
- **Linux notification daemons vary** (GNOME/KDE/Wayland compositors) —
  libnotify presence and closed-app behaviour need the real sessions, not
  CI.
- **Single-instance on desktop** is new native surface (one small plugin);
  keep it behind the same "one seam, fakes in tests" pattern as
  `ShortcutService`/`ReminderBackend`.
- **Scope guard:** M5/M6/M7 keep their own milestones; this slice wires
  platform surfaces only and lands shared features through their files.
