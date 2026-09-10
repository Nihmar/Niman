# Platform parity — Android ↔ Linux/Windows

**Status:** In progress (T-PP-16 spike done on 3 packages; T-PP-11, T-PP-06b and T-PP-22 landed — `window_manager` owns the window and its close veto, `nativeapi` the tray, and the desktop chrome is app-bar-free) · **Depends on:** M4 (everything compared exists) ·
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

- [x] **T-PP-01** Turn the table above into widget/unit probes where cheap:
  a test that `createReminderService`/`createShortcutService` return the
  Noop off Android already exists in shape — assert the documented
  limitations stay documented (strings + banner) until each phase lands.
  *AC: a new platform-only capability cannot ship silently Noop on the
  other side; the limitation string or the feature goes with it.* Tests
  may differ per platform where the chrome does (narrow bottom bar vs
  wide rail): size the surface explicitly (`setSurfaceSize`) and assert
  the layout under test, instead of forcing one layout's expectations
  onto the other.
  Done: the four factories (`createShortcutService`, `createReminderService`,
  `createTrayService`, `createWindowController`) take an optional platform
  override (`isAndroid`/`isDesktop`), so a plain unit test covers *both*
  branches on any host; the default still reads `Platform.*`. Every Noop is
  asserted inert (streams done, no-op calls, `health` stays `ok`,
  `customTitleBar` false). `test/unit/platform_services_test.dart`.

### P1 — Desktop reminders (the big one)

- [x] **T-PP-02** Spike: `flutter_local_notifications` on Linux (libnotify)
  and Windows (toasts) from this tree — schedule, reboot/restart survival,
  closed-app behaviour. The expected answer is "fires while running, not
  with the process dead" (no AlarmManager equivalent). *AC: a one-page
  note in this file records what each desktop OS actually guarantees.*
  Spike result (from the tree's resolved packages, not a device run):
  `flutter_local_notifications` 22.3.0 already pulls
  `flutter_local_notifications_linux` 8.0.1 and
  `flutter_local_notifications_windows` 3.1.1 (`pubspec.lock`), so both are
  available with no pubspec change.
  * Linux (libnotify/DBus, no native code): the backend implements only
    `initialize`, `show`, `getCapabilities`, `getSystemIdMap`.
    `zonedSchedule`, `cancel`, `cancelAll` and `periodicallyShow` fall
    through to the platform interface and throw `UnimplementedError`.
    There is no OS scheduler and no daemon: a notification can only be
    shown while the process runs, and a reboot loses everything. A
    reminder must be held by an in-process timer and shown at the moment
    it is due; a missed one (app closed, machine asleep) fires late on the
    next run or not at all, and the app has to say so in-app.
  * Windows (C++/WinRT toasts): `zonedSchedule` is real —
    `ScheduledToastNotification` handed to `ToastNotifier.AddToSchedule`,
    so the OS owns the schedule and fires it with the app closed and
    across a reboot. `periodicallyShow` throws `UnsupportedError` (no
    repeating toasts). `cancel`/`getActiveNotifications` need MSIX package
    identity; in an unpackaged zip they no-op/return empty, so a scheduled
    toast cannot be reliably withdrawn before packaging.
  Consequence for T-PP-03: one `DesktopReminderBackend` with an in-process
  timer as the floor (Linux, and unpackaged Windows), delegating future
  occurrences to `zonedSchedule` on Windows when packaged; health =
  notifications allowed *and* app running, with the banner stating the
  closed-app limit on Linux. No desktop equivalent of AlarmManager exists.
- [x] **T-PP-03** `DesktopReminderBackend` behind the existing
  `ReminderBackend` interface (`todo/reminder_backend.dart`): same full-
  replace reconciliation, new backend; `createReminderService` picks it on
  Linux/Windows. Health becomes "notifications allowed + app running",
  with the banner pointing at the desktop notification settings (or saying
  so when there is no API). *AC: a `rem:` fires as a desktop notification
  with the app running; closed-app limits are stated in-app, not found
  out.*
  Landed: `todo/reminder_backend_desktop.dart` arms a `Timer` per wanted
  reminder (its pending map is what `pendingIds` reads back) and posts
  through `todo/desktop_notifier.dart` (`PluginDesktopNotifier` over
  `flutter_local_notifications`); `createReminderService(isAndroid:
  false, isDesktop: true)` builds it and the shared `LocalReminderService`
  reconcile runs unchanged. Health stays `ok` on desktop because
  `PlatformReminderSettings.isBatteryExempt()` is true off Android and the
  timer is exact; the "app running" caveat is stated in the Todo help
  (`todoHelpRemDesktop`, shown on Linux/Windows) rather than a banner,
  since a running app is the normal state.
  Owed: a hand run on this Plasma session watching a `rem:` one minute out
  produce a libnotify popup, and the Windows-host pass. Windows
  `zonedSchedule` (an OS-held toast that survives a reboot) is deferred
  with M7 MSIX packaging, which `cancel` needs. Tests:
  `test/unit/desktop_reminder_backend_test.dart`.
- [ ] **T-PP-04** Device-and-desktop verification: the T-RL-01 overdue line
  (`STILL PENDING` vs `fired`) must read sensibly on desktop backends too.
  *AC: one log each from Linux and Windows next to the Android one.*

### P2 — Quick-action equivalents + CLI (desktop side of shortcuts)

- [x] **T-PP-05** CLI args as the shared floor: `--quick-note`,
  `--new-note`, `--new-todo`, `--new-list`, plus `<file>` (feeds P3).
  Route through the same `_runShortcut` paths the Android shortcuts use
  (`ui/shell.dart:648`), so the flows cannot drift. *AC: each flag lands
  on the same screen as its launcher twin.*
  Landed: `core/launch_args.dart` parses the four flags to the same
  `ShortcutAction`s; `main` overrides `shortcutServiceProvider` with
  `CliShortcutService(action)` (one-shot, like the platform's), so the
  shell's existing `consumeLaunchAction` -> `_runShortcut` route is the
  only path. Unknown flags are ignored (a desktop session adds its own).
  `<file>` is parsed into `LaunchArgs.openPath` and logged, not opened:
  that is the P3 single-instance slice. `test/unit/launch_args_test.dart`
  plus the CLI cold-start widget test in `test/widget/shortcuts_shell_test.dart`.
- [x] **T-PP-06** Desktop surface: Linux `.desktop` `Actions=` (four
  entries calling the CLI flags) shipped in the tar.gz/AppImage/pkg;
  Windows jumplist tasks (or documented deferral with reason). *AC:
  right-clicking the desktop icon offers the same four entries, or the
  Risks section says why not yet.*
  Landed (Linux): `linux/dev.copist.copist.desktop` carries the four
  `Actions=` (quick-note / new-todo / new-note / new-list, each `Exec`
  calling the T-PP-05 flag) and `Keywords=` covering the same actions for
  KRunner; `linux/CMakeLists.txt` installs it into the release bundle, so
  `./scripts/copist.sh linux` ships it. `test/unit/desktop_entry_test.dart`
  feeds every `Exec` back through `parseLaunchArgs`, so the entry cannot
  drift from the CLI. Owed: M7 packaging (T-M7-03) installs the file into
  `~/.local/share/applications` with an absolute `Exec` and an icon; the
  right-click hand check rides on that.
  Windows jumplist deferred: it needs a stable AppUserModelID and an
  `.lnk`/jump-list writer that Flutter's Windows runner does not provide
  — native shim is M7+ work, and the CLI floor (T-PP-05) already covers
  the four actions there.
- [ ] **T-PP-06a** KRunner discoverability (KDE): spike what KRunner
  actually lists — the main `.desktop` entry (via `Name`/`GenericName`/
  `Keywords=`) is found, but individual `Actions=` are task-manager/dock
  surface and are not separate KRunner results. Candidates for one-hit
  quick actions from KRunner: four extra `.desktop` files (menu clutter),
  a `org.kde.krunner1` DBus plugin (heavy), or CLI-on-PATH + keywords so
  `copist --new-note` runs from KRunner's command line (documented).
  *AC: the spike records which one KDE shows, and the chosen one ships;
  at minimum the main entry carries keywords covering all four actions.*
- [x] **T-PP-06b** Tray quick actions (`nativeapi`, which the T-PP-16
  verdict reserves for this surface only): a StatusNotifier tray icon whose
  context menu offers the same four actions, each running the existing
  `_runShortcut` flow in-process. Two seams from the spike: import
  `nativeapi` with `hide WindowManager` (both export one) and never call its
  `WindowManager.getCurrent()` — `window_manager` owns the window. Route it
  through a `createTrayService()` seam (Noop off Linux/Windows) like
  `ShortcutService`, version-pinned. *AC: the four actions are on the tray
  menu and land on the same screens as their launcher/CLI twins; the GNOME
  AppIndicator caveat and the Windows-host pass are recorded here.*
  Landed: `core/tray.dart` (the `nativeapi` StatusNotifier tray behind the
  `TrayService` seam, the four actions on a `ShortcutAction` stream the
  shell subscribes to beside the launcher's; icon click → `window.show()`),
  `assets/branding/tray.png` (32 px downscale of the placeholder feather —
  M7 closes the branding). Linux verified on this Plasma/Wayland session:
  the SNI watcher lists our item with the `Copist` tooltip, the app log
  reads `tray ready (4 actions)`. Owed: a hand click through all four menu
  entries; the Windows-host pass; on GNOME the icon needs the AppIndicator
  extension (ecosystem limit, as recorded in the spike).

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
- [x] **T-PP-22** Desktop chrome without the window app bar (user,
  2026-09-10): the wide layout drops the `AppBar` — the rail already names
  the app. The tree's controls move to a 44 px footer at the base of its
  column: **+ New** (a menu: note / list note / from template / folder,
  replacing the FAB with its mini-FABs and scrim), the trash and the sort
  toggle. An open note gets a 44 px header inside the detail pane with its
  file name and folder plus the note controls the bar held (kind, layout,
  preview); the Todo format help moves to the tab's top row so it survives
  the wide bar. The phone keeps its app bar and FAB untouched. *AC: wide
  shows no AppBar and no note FAB, the footer creates and opens the trash,
  the header names the open note and its folder; narrow is unchanged.*
  Follow-up from the same review (2026-09-10): the wide layout keeps its
  tab bodies mounted like the narrow stack — the old swap-in/swap-out
  re-ran the tree's per-level queries and re-inflated Search/Settings
  (28-62 ms build frames in the desktop log, vsync waits aside); the
  + New menu opens in 120 ms; the Todo format help opens as a dialog so
  the rail stays; on the desktop the Todo panel folds Open/Done in as its
  leading control and gains Add task plus help (the FAB is gone there);
  the A-Z priority fallback is a compact fixed-width dialog instead of a
  full-window grid.
  Preview performance (same review, T-PP-22): on the 934 KB geometry
  note (10.3k lines, 3551 blocks, ~841 display-math, ~26k inline formulas)
  the side-by-side scroll stalled on the preview: images changed block
  heights after the map measured them, the map itself was a pure line
  fraction, and every mounted formula rebuilt on every other formula's
  render. Landed: aspect-reserving images, a block-height scroll map fed
  to a `SliverVariedExtentList` (a jump lays out only the blocks it lands
  on, extents frozen per block so the varied list never asserts),
  per-widget math rebuilds, and typesetting deferred during a scroll.
  Measured with a two-pass 120-step scroll: widget probe 16.3 s total /
  1.5 s worst frame before, 0.70 s / 75 ms after; real-engine
  profile-mode run (`flutter drive ... -d linux --profile`, harness
  removed after use): p90 build 19 ms, p90 raster 2.2 ms, worst frame
  140 ms over 121 frames. Second round, same note: the map now carries
  its measured heights across re-parses (a typing pause used to wipe
  them, so the preview re-measured every block on screen), and profiling
  with the settle timers actually running puts a scroll at ~20 ms
  gesture frames and ~11 ms settle frames. The math cache keeps its 512
  entries: a corrected A/B (the first harness reused `MarkdownPreview`'s
  state across runs and never fired the settle timer, both fixed) shows
  512 hitting 515 of 1164 spans over a pass, with 4096 within noise.
  Two measurement traps worth remembering: `pumpWidget` reuses a same-
  shaped tree's state, and a deferred render never resumes in fake async
  unless a pump advances the settle timer.
  Second pass on the same review: the view controls move from the editor
  header into the note's status row (the header is about the file); Linux
  runs frameless with the app's own title bar (`ui/title_bar.dart`:
  sidebar toggle, drag area, window buttons over the `WindowController`
  seam, so Close still meets the unsaved-edits guard), Ctrl+B toggles the
  tree and the rail always stays. Windows gets the same bar after its
  pass.
  **To test by hand (owed, user had no way to try them yet):** the
  frameless window on Linux — drag, double-click maximize, the three
  window buttons, Close with a dirty note (must ask), Ctrl+B, and the
  tree toggle leaving the rail up; plus the view controls now reading in
  the note's status row rather than the editor header.

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
- [x] **T-PP-11** Dirty-check on window close (desktop) / task removal
  (Android): the note pipeline already knows "saved" (`ui/note_view.dart`
  status row) — hook it to `window_manager`'s `WindowListener.onWindowClose`
  + `setPreventClose(true)` while dirty (package chosen in T-PP-16, spike
  notes) instead of growing a second source of truth. *AC: closing with
  unsaved edits asks, on desktop; no behaviour change on Android.*
  Landed: `ui/window_controller.dart` (the pinned `window_manager` seam, a
  Noop off desktop), `ui/unsaved_notes.dart` (the tracker over each
  NoteView's live revision pair — no second source of truth), and
  `ui/close_guard.dart` (veto + Save and close / Cancel ask), wired under
  the MaterialApp in `app.dart`. Save and close writes the notes first; a
  failed write keeps the window open. A platform that refuses to connect
  degrades to tracking only. Linux build + launch smoke only so far: the
  close-veto ask owes a hand check on this session.
- [x] **T-PP-16** Evaluate the desktop window-chrome packages — `nativeapi`
  v0.2.3, `window_manager` v0.5.2 (both leanflutter), `bitsdojo_window`
  v0.1.6 — on a real Plasma / Wayland session; see *Spike notes* below.
  Outcome: **`window_manager` owns the window** (only one with a
  runtime-verified close-request event + real Linux drag), **`nativeapi`
  stays for the tray only** (the piece the other two lack), **bitsdojo
  rejected** (stale, no close event, no tray). Custom titlebar unblocked
  on Linux behind `window_manager`. Windows-host pass owed for both adopted
  packages. *AC: spike note records Wayland behaviour (hidden bar,
  drag-to-move, window controls, close event, tray) + API-stability
  judgement, and T-PP-11 names the chosen package (`window_manager`).*

### P6 — Verification hooks (no new code without a device)

- [ ] **T-PP-12** T-M6-09 close-out per platform: one inserted image,
  opened from its library-relative link, on Android (shared storage),
  Linux (Wayland session), Windows. *AC: three checkmarks in T-M6-09, or
  the failing platform's row here says what broke.*
- [ ] **T-PP-13** Secure-storage first-run on all three (fresh profile, no
  keychain/dbus): credentials save/load, clean degradation. *AC: covered
  by hand, recorded here.*

## Spike notes — desktop window packages (T-PP-16, 2026-09-09/10)

Ran locally: one scratch Flutter app (`/tmp/copist/nativeapi-spike`,
not committed), `flutter build linux`, executed on this machine's real
Plasma 6.6.5 / Wayland session, switched between the three candidates and
exercised the same surface each time: frameless/hidden titlebar,
drag-to-move, tray, and the close-request path. Findings verified against
the package sources in `~/.pub-cache/hosted/pub.dev/`.

### `window_manager` v0.5.2 (same leanflutter team as nativeapi)

Method-channel plugin (federated; C++ on Linux, no getCurrent heuristic —
the plugin connects directly to the Flutter view's `GtkWindow`). 42
published versions; latest 0.5.2 = 2026-07-04, changelog active through
#550. Ships Flutter widgets for the chrome: `DragToMoveArea`,
`DragToResizeArea`, `VirtualWindowFrame`, `WindowCaption`.

- **Close-request event works, verified at runtime**: `WindowListener
  .onWindowClose` + `setPreventClose(true)` — the Linux `delete_event`
  handler emits `close` and returns the prevent flag. Self-test passed:
  with `setPreventClose(true)`, `close()` fired the event and the window
  stayed alive. This is exactly the T-PP-11 dirty-check surface.
- **Real Linux drag**: `startDragging` → `gtk_window_begin_move_drag`
  (resize via `begin_resize_drag`) — not a stub. Frameless via
  `setAsFrameless`/`titleBarStyle` applied cleanly, no `Gdk-CRITICAL`
  (the window is resolved by the plugin, not by device-position probing).
- **No tray** in the current line (`TrayManager` existed in the 0.1.x era
  and was dropped; absent from lib/ entirely).
- Adds a small extra dep: `screen_retriever`.

### `bitsdojo_window` v0.1.6

Federated (linux/windows/macos sub-packages), C++/GTK on Linux.
Latest 0.1.6 = 2023-12-23 — ~2.5 years stale as of this spike.
Description literally says "Windows and macOS"; Linux is a second-class
federated package. Global `appWindow` + `doWhenWindowReady(callback)`
callback style (no listener object).

- Builds and ran on the Plasma/Wayland session (frameless via
  `gtk_window_set_decorated(FALSE)` + RGBA visual, `titleBarHeight=32`);
  `startDragging` is real (`gtk_window_begin_move_drag`), ships
  `WindowBorder`/`WindowCaption`/`WindowButton`/`MoveWindow` widgets.
- **No close-request event**: `close()` is programmatic-only; there is no
  `onWindowClose`/`preventClose` in the platform interface, and the Linux
  impl never surfaces `delete_event` to Dart. T-PP-11 cannot ride it.
- **No tray.**

### `nativeapi` v0.2.3 (previous notes, condensed)

**Pros**
- The tray works on Wayland/KDE: the `TrayIcon` registers a StatusNotifier
  item (confirmed via `gdbus` on `org.kde.StatusNotifierWatcher`) with a
  context menu of `MenuItem`s + click callbacks — the third quick-action
  surface next to `.desktop` Actions / KRunner, no app-side native code.
- Build is ordinary: an FFI plugin; `cnativeapi` compiles a vendored
  `libnativeapi` C++ fork (~140 files) via CMake inside `flutter build`, no
  script or manual step. (Windows side is not cross-buildable from Linux —
  needs a Windows-host pass.)
- Clean Dart API (typed event listeners per object), MIT, actively developed
  (0.2.x over the last month).
- `titleBarStyle = hidden` + hidden control buttons apply without crashing
  on Wayland: the Linux impl walks the GTK tree, finds the runner's
  `GtkHeaderBar` and hides it (falls back to
  `gtk_window_set_decorated(false)`) — it composes with
  `linux/runner/my_application.cc` instead of fighting it.
- `MessageDialog` exists for the confirm-on-close dialog (T-PP-11) if/when a
  close event exists.

**Cons / blockers**
- **No close-request event in v0.2.3.** Window events are only
  `focused/blurred/minimized/maximized/restored/moved/resized`
  (`cnativeapi/.../capi/window_c.h`), so the dirty-check-on-close (T-PP-11)
  cannot ride this package today; the upstream `setWillCloseHook` PR is
  still closed-without-merge. The window hooks stop at will-show/will-hide.
- **`startDragging()` is a no-op on Linux** ("stub implementation",
  `platform/linux/window_linux.cpp`), along with ~10 property setters
  (`isResizable`, `isMovable`, `isClosable`, `hasShadow`, …). A
  Flutter-drawn titlebar with `titleBarStyle = hidden` would therefore make
  the window **unmovable on Linux**. Windows/macOS do implement dragging
  (`WM_NCLBUTTONDOWN/HTCAPTION`, `performWindowDragWithEvent:`).
- **`getCurrent()` race / Wayland fragility:** returns `null` right after
  startup (window not realized yet) and logged a `Gdk-CRITICAL`
  (`gdk_device_get_window_at_position_double … != GDK_SOURCE_KEYBOARD`) on
  every attempt — the same failure as open upstream issue #6 (KDE Plasma +
  Wayland). Succeeded on a ~500 ms retry here; the fallback is
  "first visible toplevel", a heuristic that will mis-target once the app
  has more than one window (dialogs, a second library).
- **New Linux build dependency:** the plugin's CMake requires GTK3, X11 and
  `ayatana-appindicator3` dev packages, so the Linux tar.gz/AppImage build
  host gains a native dep (and the C++ lands in the bundle — build time +
  binary size). The plugin is declared for all five platforms, so the
  Android APK build compiles it too.
- **Tray reach on Linux is SNI-dependent:** Plasma shows it; GNOME needs the
  AppIndicator extension (ecosystem limit, same as any SNI app).
- **Churn:** pre-1.0 with a "Work in Progress" banner; 0.2.0 was a full Dart
  API regeneration + event rework; the README already lags the current API
  (`Image.fromAsset` in the docs vs `fromFile`/`fromBase64` shipped in 0.2.3).
  Pin exact versions and treat the API as moving.

**Judgement (three-way)**
- **`window_manager` wins the window job.** It is the only candidate with a
  *released, runtime-verified* close-request event (`onWindowClose` +
  `setPreventClose`, self-test passed: programmatic close vetoed, window
  stayed alive) and a *real* Linux drag (`gtk_window_begin_move_drag`).
  Frameless applies cleanly with no `Gdk-CRITICAL` (the plugin owns the
  window handle, unlike `nativeapi getCurrent()`'s device-position probe).
  Adopt it behind the same "one seam, fakes in tests" pattern as
  `ShortcutService` — `WindowManager.instance` + a `WindowListener` in the
  `ui/` layer, faked in tests. Windows/macOS behaviour is unverified here
  (Windows-host pass owed, same as nativeapi).
- **`nativeapi` stays for the tray only** — the third quick-action surface —
  which is the piece `window_manager` dropped (no `TrayManager` in 0.5.x)
  and `bitsdojo_window` never had. Same author family as `window_manager`
  (leanflutter). **Coexistence verified in the spike** (both in one app,
  one Linux build): the tray registered with KDE SNI while
  `window_manager` owned the window — frameless applied and the close-veto
  self-test passed with nativeapi loaded. Two seams to keep: import
  `nativeapi` with `hide WindowManager` (both export one), and don't call
  `nativeapi`'s `WindowManager.getCurrent()` once `window_manager` owns the
  window (that `Gdk-CRITICAL`/null race is a `nativeapi` failure mode we no
  longer need). Version-pin both (nativeapi is pre-1.0 with a moving API).
- **Custom titlebar: now unblocked on Linux** via `window_manager`
  (`titleBarStyle hidden` + `DragToMoveArea` + the shipped `VirtualWindowFrame`/
  `WindowCaption` widgets). Scope it to P1/P2 like the other chrome; do
  not adopt the hidden bar until the drag region is exercised on a real
  Wayland session.
- **`bitsdojo_window`: rejected.** Stale (0.1.6 = 2023-12-23), its own
  description scopes it to Windows/macOS with Linux a second-class
  federated package, no close-request event (T-PP-11 can't ride it), no
  tray. The only useful confirmation: a real GTK-based frameless/drag
  implementation exists and ran on this session — useful prior for the
  others, not a dependency.
- **T-PP-11 is named: `window_manager`.** The mechanism is
  `WindowListener.onWindowClose` + `setPreventClose(true)` while a note is
  dirty (the `ui/note_view.dart` "saved" status row already knows), show
  the confirm-on-close, then `setPreventClose(false)` + `close()` on yes.

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
- **`nativeapi` adds a native build chain to desktop** (verified in the
  spike): a C++ FFI plugin — GTK3/X11/`ayatana-appindicator3` dev packages
  and ~140 C++ files compiled into the Linux/Windows builds, plus the same
  on the Android APK build. The Linux build host needs the new dev
  packages; treat it as build-infrastructure, not just a dependency.
  Version-pin it (pre-1.0, moving API). `window_manager` adds a smaller
  second native plugin (C++/GTK on Linux, `screen_retriever` dep); pin it
  too. The two coexist (spike-verified: one build, one process — tray
  registered with KDE SNI + close veto working simultaneously); the
  combined surface is still owed a Windows-host pass.
- **Single-instance on desktop** is new native surface (one small plugin);
  keep it behind the same "one seam, fakes in tests" pattern as
  `ShortcutService`/`ReminderBackend`.
- **Scope guard:** M5/M6/M7 keep their own milestones; this slice wires
  platform surfaces only and lands shared features through their files.
