# macOS and iOS — plan

Niman on a Mac, an iPhone and an iPad. Written before any code
(2026-10-16), as the plan the port follows, with the owner's decisions on
it at the end. Nothing here was built or run: the host this was
written on is Windows, so every Apple-side statement is either read from
Apple's or a package's documentation or marked **to verify** — those are
what the first spike on a Mac has to settle.

Two rules from `AGENTS.md` shape all of it:

- **The disk is the source of truth**: one note is one `.md` in a folder
  the user owns. iOS has no such folder by default, and a sandboxed Mac
  app reaches one only through a grant. The storage model is the first
  problem, not a detail.
- **Every platform ships every feature**, or `docs/user/platforms.md`
  says why not, as a decision. Two new platforms double the surfaces a
  feature has to reach; the plan says per feature what each one gets.

## Where the code stands

There is no `macos/` or `ios/` folder. The Dart code is portable by
construction (`package:path`, isolates, no `/tmp` literal, case-insensitive
path handling already counting macOS and iOS in `core/files.dart`), and a
platform it does not know falls through to a no-op rather than a crash.
That is the good news and the problem: on a Mac today most desktop
features would be **silently off**, not broken.

### The platform gates

The code asks "Linux or Windows?" where it means "a desktop", and
"Android?" where it means "a phone":

| Gate | Where | What macOS / iOS get today |
|---|---|---|
| `desktop = isLinux \|\| isWindows` | `lib/main.dart:36` | No single-instance claim, no launch arguments, no file-open forwarding |
| The same test, repeated | `ui/shell.dart` (close to tray, mouse side buttons, `CommandNeed.desktop`), `ui/window_controller.dart`, `core/tray.dart`, `core/drop_in.dart`, `ui/file_tree_context.dart`, `ui/open_library.dart`, a dozen more | The desktop chrome, the tray, the drop, the tree's *Show in folder*: all off |
| `createReminderService` | `todo/reminders.dart:84` | `NoopReminderService`: **no reminders at all** |
| `checkForUpdate` | `update/update_check.dart:91` | A Mac would be offered the **Linux `.tar.gz`** as its update — a latent bug |
| `phone = Platform.isAndroid` | `transcription/transcription_models.dart:34` | An iPhone would be offered every whisper model, the 3 GB one included |
| `packageConverts = isAndroid` | `transcription/transcription_queue.dart:40` | Non-WAV audio refused ("only WAV on this platform") |
| `findPdfEngine` | `export/pdf_printer.dart:198` | No engine: the picture fallback, no folder PDF |
| `findPageBrowser` | `capture/browser/page_browser.dart:91` | No browser fallback for a script-built page |
| Clipboard HTML | `capture/paste/platform_clipboard_html.dart` | Paste as Markdown pastes plain text |
| Keep awake | `core/keep_awake.dart:30` | Slides let the screen sleep |
| Spell check | `spellcheck/hunspell_spell_checker.dart:21` | Hunspell looked up by bare name, dictionaries in Linux folders: off |
| OCR engine | `ocr/ocr_engine_build.dart:76` | No target for the ABI: nothing to download |

Some places already list macOS (`ui/todo_date_panel.dart:19`,
`ui/kinds/list_note.dart:197`, `markdown/render/focus_return.dart:93`) and
others pointedly do not (`ui/shell.dart`'s `_desktop`), so the platform
answer is not even consistent across files. Touch detection is in better
shape: the `defaultTargetPlatform == android || iOS` checks in the editor,
the link preview and the tree drag already treat an iPhone as touch.

### Native code that has to be written again

Everything Android does natively goes over a named `MethodChannel`; the
two desktop runners add two more. Each is a contract an Apple runner
implements, or a feature that stays off:

| Channel | Android / Linux / Windows | macOS | iOS |
|---|---|---|---|
| `niman/storage` | All-files access (Android) | Folder grant (bookmark) | Folder grant (bookmark) |
| `niman/reminders` | Battery-optimisation health (Android) | — (not needed) | — (not needed) |
| `niman/screen` | Keep screen on (Android, Linux; Windows by FFI) | `IOPMAssertion` | `isIdleTimerDisabled` |
| `niman/clipboard` | HTML + source URL (Android, Linux; Windows by FFI) | `NSPasteboard` | `UIPasteboard` |
| `niman/pdf` | WebView print (Android) | WebKit print | WebKit print |
| `niman/page_reader` | Hidden WebView (Android) | Hidden `WKWebView` | Hidden `WKWebView` |
| `niman/drop` | GDK drop, OLE `IDropTarget` | `NSDraggingDestination` | — (no window drop) |
| `niman/window` | Snap Layouts hit test (Windows) | — (native traffic lights) | — |
| `niman/share` | Share intents (Android) | Services menu, *Open With* | Share extension |
| `niman/shortcuts` | Launcher shortcuts (Android) | Dock menu | Home-screen quick actions |
| `niman/widgets` | Widget launch targets (Android) | WidgetKit (later) | WidgetKit |
| `niman/task` | `moveTaskToBack` for web capture (Android) | — | — |
| `niman/update` | APK install (Android) | Opens the `.dmg` (direct build only) | — (the App Store updates) |

**Most of the Swift is one implementation for both.** WebKit, the
pasteboard (behind a thin type switch), the bookmarks and the spell
checkers have the same shape on macOS and iOS. The plan puts them in one
local Flutter plugin in the repository (`packages/niman_apple/`, Swift,
`sharedDarwinSource: true` so one `darwin/` folder builds into both
runners), not in each runner. The runners keep only what is the window's:
the drop, the menu bar, the file-open events.

### The plugins

| Package | iOS | macOS | Note |
|---|---|---|---|
| `drift`, `sqlite3` | yes | yes | The build hooks ship a prebuilt SQLite for both, FTS5 on by default |
| `pdfrx` | yes | yes | PDFium as an XCFramework |
| `record`, `audioplayers` | yes | yes | `NSMicrophoneUsageDescription`; on a sandboxed Mac `device.audio-input` |
| `flutter_local_notifications` | yes | yes | `zonedSchedule` on `UNUserNotificationCenter`; **iOS keeps 64 pending** |
| `flutter_secure_storage` | yes | yes | Keychain; `keychain-access-groups` entitlement, or the legacy keychain on macOS |
| `file_picker` | yes | yes | Picks a directory on both, but returns a **path** — no bookmark, and on iOS an old issue reports a copy in a temporary folder (**to verify**) |
| `connectivity_plus` | yes | yes | `NWPathMonitor`; needs Xcode 26.1.1+ |
| `path_provider`, `package_info_plus`, `url_launcher`, `flutter_timezone` | yes | yes | — |
| `whisper_ggml` | yes (15.6+) | yes | Pulls `ffmpeg_kit_flutter_new_min` on Apple too (a community fork; LGPL) |
| `window_manager` 0.5.2 | — | yes | Close interception and the hidden title bar on macOS: **to verify** |
| `nativeapi` 0.2.4 | — | listed | "Work in progress"; a macOS tray source exists, the menu is **to verify** |
| `home_widget` | yes | **no** | WidgetKit on iOS through an App Group; nothing for macOS (its issue #241 closed without it) |
| `dynamic_color` | **no** | yes | The accent colour on macOS; iOS takes the fallback palette |
| `archive`, `katex_dart`, `html`, `xml`, `yaml`, `highlight` | pure Dart | pure Dart | — |

No package blocks the port. The gaps are the widgets on macOS,
`dynamic_color` on iOS (a fallback already exists), and the folder grant,
which no package does for a folder on iOS.

## Storage: the library on Apple platforms

Today a library is an absolute path string: picked by
`FilePicker.getDirectoryPath` (`ui/library_picker.dart:57`), remembered in
`knownLibraries` and `lastLibraryPath`, read and written with plain
`dart:io` from worker isolates, and its index file is named after a digest
of that path (`library_state.dart:1976`). Each of those assumptions breaks
somewhere on Apple platforms.

### macOS

- **Not sandboxed** (direct distribution with a Developer ID): a path is a
  path. The library works exactly as on Linux, `~/Documents`, an external
  disk and an iCloud Drive folder (`~/Library/Mobile Documents/…`)
  included. With *Optimise Mac Storage* on, an iCloud file may be
  *dataless*: a stat is free, the first read downloads it. A full scan
  only stats, so it stays cheap; opening a note waits for its download.
**Decided: not sandboxed** (2026-10-16). The rest of this section is what
a sandbox would ask, kept for the day it is wanted.

- **Sandboxed** (required by the Mac App Store, and by nothing else): a
  folder the user picked is reachable while the app runs, and across
  launches only through a **security-scoped bookmark** — bookmark data
  minted at the pick (`files.bookmarks.app-scope` entitlement), resolved
  at the next launch, opened with `startAccessingSecurityScopedResource`.
  The grant is the process's, so the worker isolates' `dart:io` sees the
  folder like the UI isolate does (**to verify**, it is how sandbox
  extensions work but no Flutter app was found saying so).

### iOS

An iOS app owns one folder, its container, and reaches any other only
through the document picker's grant. Three places a library can live:

| Where | How Niman reaches it | For | Against |
|---|---|---|---|
| **The app's Documents** (shown in Files as *On My iPhone › Niman* with `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace`) | Plain `dart:io`, no grant | Fast, every API works, nothing materialises lazily; the user and other apps see the `.md` files in Files | Leaves the phone only through Niman's WebDAV sync or a manual copy; deleting the app deletes the library |
| **Niman's iCloud container** (`iCloud.dev.niman.niman`, shown as *iCloud Drive › Niman*) | `dart:io` under the ubiquity container URL; files may be evicted placeholders, reads need `NSFileCoordinator` | The Apple user's own sync, no server; the same folder on a Mac | Evicted files must be downloaded before a scan can read them — a 1M-note library cannot be read whole; iCloud's conflict copies are a second conflict model beside the sync's |
| **A folder picked anywhere** (iCloud Drive, *On My iPhone*, a File Provider such as Nextcloud) | Bookmark from `UIDocumentPickerViewController`, resolved at each launch, coordinated access | The user's own folder, the Android model | Third-party File Providers materialise files lazily and unreliably: Obsidian, which tried, documents Dropbox, Google Drive and OneDrive as not working |

**The container path moves.** An iOS app's container path changes across
reinstalls and can change across updates; the documentation says to keep
paths relative to it. The index file named after the absolute path would be
thrown away and rebuilt after such an update — a full scan of a large
library for nothing. So a library on iOS is remembered as *(where, relative
path)*: the container plus a relative path, or a bookmark.

**Decided: the app's container** (2026-10-16). The first iOS release keeps
its libraries in its own Documents, visible in Files, and leaves the phone
through Niman's WebDAV sync. A folder picked elsewhere and Niman's iCloud
container are not in it; the abstraction below leaves room for both.

### What changes in the code

One abstraction, on every platform, so the grant is not an iOS special
case scattered through the library code:

- **`LibraryLocation`** replaces the bare path in `knownLibraries`: a path
  (Linux, Windows, Android, unsandboxed macOS), a container-relative path
  (iOS), or bookmark data (sandboxed macOS, a picked folder on iOS). The
  bookmark is device state that cannot be rebuilt from disk, so it lives
  in `AppDatabase` beside the known libraries — the same exception the
  sync's state already makes (`docs/records/sync.md`, Principles). With
  macOS unsandboxed and iOS in its container (both decided), the first
  round needs the first two kinds only; the bookmark is the kind a later
  sandbox or picked folder adds, and nothing else changes when it does.
- **Opening a library resolves its location to a path** and holds the grant
  until the library closes. Everything after that point — the scan, the
  watcher, `NoteOps`, the sync — keeps working on a path, unchanged.
- **The index file is named after the library's identity**, not its
  absolute path: the location's stable part, so an iOS container move does
  not orphan it. (`IndexDatabase` is rebuildable, so getting this wrong
  costs a scan, never data.)
- **A stale bookmark** (the folder moved or was renamed) is refreshed when
  it resolves as stale, and a bookmark that no longer resolves sends the
  library to the picker with its name, as a missing folder does today.

### File watching and the rescan

- **macOS**: `Directory.watch(recursive: true)` runs on FSEvents, which is
  recursive natively and works inside a granted folder. The watcher
  (`library/file_watcher.dart`) is used as it is.
- **iOS**: `dart:io` does not support watching there — the plan assumes
  `FileSystemEntity.isWatchSupported` is false (**to verify**). The
  watcher must ask before subscribing, which it does not today
  (`file_watcher.dart:161`). Without it, changes from outside (the Files
  app, the sync, a widget) are found by the reconcile (#302, a directory at
  a time) on resume and by the five-minute rescan while the app is in the
  foreground. Inside the app's container nothing but Niman, Files and the
  sync writes, so that is enough; a picked iCloud folder adds an
  `NSFilePresenter` on the root, which tells a running app what changed.
- **Unicode normalisation**: a name typed on a Mac or shared from another
  app can reach the disk decomposed (NFD) while a wikilink typed in Niman is
  composed (NFC). APFS treats the two as the same file, so `File` works,
  but string comparison in the index does not: `[[Città]]` would not find
  `Città.md` written decomposed. Names are compared NFC-normalised. The same
  can already happen on Linux; Apple makes it common.

## Desktop: the Mac

The Mac is the Linux and Windows desktop: the same shell, rail, tree,
panes and tabs. What changes is where the Mac puts things.

- **The title bar**: the native traffic lights stay, over a transparent,
  full-size title bar (`window_manager`'s hidden style on macOS keeps
  them), and Niman's own bar — the sidebar toggle, the tabs — is drawn
  beside them with their inset. The Windows caption-button hit test
  (`niman/window`) has no Mac counterpart; nothing is needed.
- **The menu bar**: a Mac app is expected to have one, and Flutter has
  `PlatformMenuBar`. It is **built from the command registry**, the one
  Settings → Commands lists, so a command has one definition and appears
  in the palette, the keymap and the menu: Niman (About, Settings… `⌘,`,
  Hide, Quit), File, Edit, View, Note, Window, Help.
- **Keys**: the defaults use `Ctrl` in about 75 `SingleActivator`s
  (`ui/app_shortcuts.dart`, `editor/editor_shortcuts.dart`). A *primary
  modifier* — `⌘` on Apple, `Ctrl` elsewhere — replaces the hard-coded
  `control: true`; the find and replace keys already do this
  (`platformModifierIsMeta`, `app_shortcuts.dart:497`), and the source
  editor already maps `⌘C/⌘V/⌘Z`. Text motion follows the Mac:
  `⌥←/→` by word, `⌘←/→` to the line's ends, `⌘↑/↓` to the note's.
  Defaults that collide with the system move: `⌘H` (Hide), `⌘M`
  (Minimise), `⌘Q` (Quit, which keeps its meaning and its unsaved-edits
  check), `` ⌘` `` (next window); `F11` for Zen becomes `⌃⌘F`, the Mac's
  full-screen key. The key map already stores `meta`, so a user's own
  bindings carry over. Keys are shown as glyphs (`⌘⇧P`), not "Meta".
- **The tray is the menu bar extra**: `nativeapi`'s tray on macOS is an
  `NSStatusItem` (**to verify** with its menu), with a template image so it
  follows the menu bar's colour. Its menu is the tray's: Open Niman, the
  quick actions, Quit.
- **Closing**: on a Mac, closing the window leaves the app running in the
  Dock, and `⌘Q` quits. That replaces *Close to the tray*, whose reason —
  keeping desktop reminders alive — does not apply here: reminders on a Mac
  are the system's (below). The setting is not shown on macOS.
- **One instance is the system's**: macOS opens one copy of an app, so the
  lock file and loopback socket (`core/single_instance.dart`) are not
  needed; in a sandbox the socket would also need the network-server
  entitlement. **Opening a file** arrives as an Apple Event
  (`application(_:open:)`), not as an argument: the runner forwards it to
  `LaunchRequests.openFile`. The `.md` association is `CFBundleDocumentTypes`
  in `Info.plist`. The quick actions (`--quick-note`, `--journal-today` …)
  become the **Dock menu**; the `niman` command is a small shell launcher
  shipped in the disk image, as the `.tar.gz` ships one (`open -a Niman
  --args …`).
- **Dropping files and links** on the window: the runner registers the
  view for file and URL drags and speaks `niman/drop`'s four methods, as
  the other two runners do, with the frame during a drag.
- **Show in Finder** is `NSWorkspace.activateFileViewerSelecting`, which
  works in a sandbox (`open -R` would not); *Open in the default app* is
  `url_launcher` as today.
- **PDF export and web capture**: Linux and Windows run a headless
  Chromium-family browser. A Mac has Chrome or Edge only sometimes, and a
  sandboxed app cannot run them. Both go through WebKit instead, the way
  Android goes through its WebView: `niman/pdf` prints the export's HTML
  into a paginated PDF with selectable text, `niman/page_reader` loads a
  page off screen and returns its DOM. The same Swift serves iOS. Chrome
  found in `/Applications` can still be the first choice on an
  unsandboxed Mac, if WebKit's print turns out worse than Chrome's (**to
  verify**: pagination, the columns' CSS, the math).
- **Date created**: a Mac has the creation time Windows has, and the save's
  rename over the note loses it the same way. The save carries it over as
  `core/creation_time.dart` does on Windows (`setattrlist` through FFI),
  and the scan reads it (`st_birthtime`) where it reads Windows' today.
- **Multi-window**: Flutter's multi-window API is still experimental, so the
  Mac keeps one window, as the other desktops do (#534's decision stands).
- **The math rasteriser** (`preview/math_raster.dart:67`) is on for Linux
  and Windows because their renderers draw paths without MSAA. Whether the
  Mac needs it is **to verify** on screen.

## Phones and tablets: iOS

An iPhone is the Android phone's layout and an iPad the Android tablet's:
the layouts already follow the window's shortest side, not the OS. An iPad
with a hardware keyboard gets the keymap with `⌘` and the palette's keys,
as an Android tablet with a keyboard does.

- **No processes**: `Process.start` does not exist on iOS. Every feature
  that runs a program — the headless browser, `xdg-open`, the updater —
  has to be behind a gate that iOS answers, and none may be the fallback
  (`page_browser.dart`'s *else* is the process path today; it returns null
  safely because no engine is found, but by luck).
- **No downloaded code**: iOS will not load a native library the app
  downloaded, App Store or not. The OCR engine is bundled (below). Data
  downloads — whisper models, OCR languages — are allowed.
- **No self-update**: the update check and its settings are off on iOS;
  the App Store or TestFlight updates the app.
- **Quick actions**: the long-press menu on the icon
  (`UIApplicationShortcutItem`) is Android's launcher shortcuts: the same
  six ids over `niman/shortcuts`.

### Background work

iOS suspends an app seconds after it leaves the screen, and offers no
equivalent to Android's foreground service. What that does to each
feature:

| Feature | Android | iOS |
|---|---|---|
| Sync when the app leaves (`paused` → quick sync) | Runs | Runs inside a background task (`beginBackgroundTask`, about 30 s): enough for a quick sync, not a full one |
| Periodic sync | Foreground only already | Same; a `BGAppRefreshTask` when the system grants one (best effort, maybe never) |
| Web capture from Share | Off screen, under a short foreground service | Queued by the share extension, captured when the app is next opened (decided) |
| Transcription, OCR of a long PDF | Pauses when frozen, resumes | Same: the queue already survives a pause; nothing runs while suspended |
| Reminders | Exact alarms | The system's notifications (below) — no app code runs |

### The share extension

Android's Share → Niman becomes an iOS share extension (and on a Mac, the
same extension appears in the share menu). An extension is a separate
process with a tight memory limit and no Flutter engine of the app's. It
does not capture: it writes what was shared — the URL, the title, the
selected text, a file — into the App Group's inbox and finishes, and the
app processes the inbox the next time it is opened, through the same
`niman/share` contract `core/share_in.dart` reads today.
`receive_sharing_intent` does this, App Group included, but is iOS only;
the extension's Swift is small enough to own in `packages/niman_apple/`
and use on the Mac as well.

## Widgets

The three Android widgets — Todos, Note, Study — become WidgetKit widgets.
The model underneath stays the one the Android widgets use:

- **The payload is the same JSON**: `widget_payload.dart` already builds
  `todo_<id>`, `note_<id>`, `study_<id>`, with the theme. On iOS
  `home_widget` writes it to the App Group's `UserDefaults`
  (`group.dev.niman.niman`) instead of Android's preferences. WidgetKit
  has no per-instance ids, so the key is per configuration (the library,
  and the note for the Note widget) rather than per placed widget.
- **Rendering** is SwiftUI, one view per widget family (small, medium,
  large), drawing the same rows: sections and their counts, the meta line,
  the checklist.
- **Configuration** is an App Intent (`AppIntentConfiguration`, iOS 17):
  the library chosen from the `known_libraries` mirror the app already
  writes, and the note for the Note widget. It replaces
  `WidgetConfigActivity`.
- **Taps**: a row toggle is an App Intent (`Button(intent:)`, iOS 17). On
  Android a tap runs Dart in the background (`widgetToggleCallback`), which
  edits `todo.txt` with the app's own code and pushes a new payload. Where
  `home_widget`'s iOS background intent runs — the app's process, where
  Dart can run, or the extension's, where it cannot — decides whether that
  stays true (**to verify**, the first thing the widget spike answers). If
  only the extension's, the toggle would need `todo.txt`'s rules written a
  second time in Swift, and the plan does not accept that: the fallback is
  a tap that opens the app on the task.
- **The library must be reachable from where the tap runs**: a library in
  the app's own container is not visible to the widget extension. Another
  reason the edit should run in the app's process.
- **On the Mac**, WidgetKit widgets live on the desktop and in Notification
  Center (macOS 14), with the same SwiftUI. `home_widget` has no macOS
  side, so the Dart side writes the App Group and reloads the timelines
  over `niman/widgets`. A widget extension is always sandboxed, and needs
  the App Group even when the app is not.

## Reminders and notifications

`flutter_local_notifications` schedules through `UNUserNotificationCenter`
on both, and the system delivers with Niman closed — better than Linux and
Windows, whose reminders are an in-process timer. `createReminderService`
gains the Apple case: `LocalReminderService` with the plugin's backend, as
on Android.

- **iOS keeps the 64 most recently scheduled notifications.** A library
  with more future reminders than that schedules the **next 64 by time**
  and tops the list up whenever the app is opened or refreshed in the
  background. A phone not opened for a long time can therefore miss the
  65th reminder onwards; `docs/user/platforms.md` says so. macOS documents
  no such limit.
- The Android health checks (`niman/reminders`, battery optimisation) have
  no counterpart; the permission prompt is the only one.
- The `calendar.txt` reminders (#730) take the same path.

## OCR, transcription, spell check

- **OCR**: the Tesseract engine cannot be downloaded on iOS, and on a Mac a
  downloaded library must be signed by the same team to load under the
  hardened runtime. Two ways:
  - **Bundle Tesseract** (decided 2026-10-16):
    `scripts/ocr-engine.sh` gains `macos-universal` (a `.dylib`, `ld64`'s
    `-dead_strip` and an exported-symbols list in place of the version
    script and `--gc-sections`) and `ios-arm64` (a static library in an
    XCFramework, found with `DynamicLibrary.process()`). The locator's
    *bundled* step already exists for this (`ocr_engine_locator.dart`). The
    languages are still downloaded. Same engine, same lines, same boxes on
    every platform.
  - **Apple's Vision** (`VNRecognizeTextRequest`): nothing to bundle or
    download, Italian among its languages, line boxes included; but a
    second engine, whose results differ from the other platforms'.
- **Transcription**: `whisper_ggml` supports both (Metal and Accelerate).
  The phone's reduced model list follows "a phone", not "Android". Non-WAV
  imports are converted with AVFoundation (`AVAudioConverter`, through
  `packages/niman_apple/`) rather than the FFmpeg `whisper_ggml` pulls on
  Apple, if that FFmpeg can be left out (**to verify**, as it could not on
  Android). Apple's own on-device speech (SpeechAnalyzer, iOS and macOS 26)
  is an alternative engine, not part of this plan.
- **Spell check**: Windows already uses the system's checker
  (`windows_spell_checker.dart`, COM `ISpellChecker`) rather than hunspell.
  Apple does the same: `NSSpellChecker` on macOS, `UITextChecker` on iOS,
  behind one channel that checks a **paragraph per call** and returns the
  misspelt ranges (a call per word would be thousands of round trips). The
  languages offered are the system's; the personal dictionary stays
  `.niman/dictionary.txt`, applied by Niman on top, as on Windows.

## Builds, flavors, signing

- **Two flavors, as on Android**: Xcode schemes `official` and `beta`
  (Flutter's `--flavor` maps to schemes on Apple), with bundle ids
  `dev.niman.niman` and `dev.niman.niman.beta`, app names *Niman* and
  *Niman (Testing)*, and App Groups `group.dev.niman.niman` and
  `group.dev.niman.niman.beta`. The beta keeps its own container and
  support folder by bundle id, so `appSupportDirectory`'s `-testing`
  sibling (`core/app_channel.dart:44`, already skipped on iOS) is skipped on
  macOS too. `scripts/niman.sh` gains `macos [beta]` and `ios [beta]`.
- **An Apple Developer Program membership** is needed for almost all of it:
  Developer ID signing and notarisation, App Groups (the widgets), the
  keychain entitlement, and any install on an iPhone beyond a week-long
  personal build.
  - **macOS without it** still works: the `.dmg` goes on the GitHub
    release, signed ad hoc (Apple silicon runs nothing unsigned, and the
    linker signs ad hoc by itself). What it costs is the first launch:
    Gatekeeper refuses an app that is not notarised, and since macOS 15 the
    right-click *Open* no longer gets past it — the user allows it in
    System Settings → Privacy & Security → *Open Anyway*. The secure
    storage falls back to the legacy keychain, which needs no entitlement.
  - **iOS without it** does not exist: no TestFlight, no App Store, no App
    Group, and a personal build on one's own iPhone expires after seven
    days.
- **macOS, direct**: a universal (arm64 + x86_64) app, signed with a
  Developer ID certificate under the hardened runtime, notarised with
  `notarytool`, stapled, shipped as `niman-X.Y.Z-macos.dmg` (and a `.zip`)
  on the GitHub release beside the others. The in-app updater downloads the
  `.dmg` and opens it — `release_asset.dart` gains a macOS asset, and the
  update check never falls back to another platform's.
- **macOS, App Store**: not planned (decided 2026-10-16: the `.dmg`
  only). It would be the same app sandboxed, signed for distribution,
  uploaded with the iOS pipeline, without the in-app updater.
- **iOS**: TestFlight and the App Store are the only realistic routes. An
  `.ipa` on the GitHub release is of no use to anyone and is not attached.
  TestFlight is the iOS **beta**: internal testers get every build, external
  ones after Apple's beta review.
- **Version**: `+N` becomes `CFBundleVersion`, which App Store Connect
  requires to rise on every upload — the same rule `AGENTS.md` already sets
  for Android's `versionCode`.
- **App Store paperwork**: a privacy manifest (`PrivacyInfo.xcprivacy`) with
  the required-reason APIs Niman touches — file timestamps (every scan
  stats), disk space, `UserDefaults` for the App Group; the encryption
  question answered as exempt (HTTPS only: Niman encrypts nothing of its
  own); the microphone and notification usage strings, in every language
  the app ships.

## CI and release

The repository is public, so GitHub's macOS runners cost no money; they
cost time (three cores, one queue).

- **`check.yml`**: from phase 2 on, on every PR, a third job on `macos-26`
  (arm64, Xcode 26): `flutter
  test`, `flutter build macos --debug --flavor beta`, the Swift unit tests
  (`xcodebuild test` for `packages/niman_apple/`, as the Kotlin job runs
  the Android ones), and `app_boot` headless. The read view's goldens get a
  `macos/` set beside `linux/` and `windows/` (CoreText rounds glyphs its
  own way).
- **`release.yml`**: a `macos` job — build, sign, notarise, staple,
  `.dmg` + `.zip` into `github-release`'s files — and an `ios` job that
  builds the `.ipa` and uploads it to TestFlight. New secrets: the
  Developer ID certificate (`.p12`, base64) and its password, the team id,
  an App Store Connect API key (id, issuer, `.p8`) for notarisation and
  upload, and the provisioning profiles. Without the secrets the `macos` job
  signs ad hoc and skips notarisation, as the Android job falls back to the
  debug key; the `ios` job does not run.
- **`ocr-engine.yml`**: `macos-universal` and `ios-arm64` on a macOS
  runner, on the next `ocr-engine-N` tag.
- **A Mac mini joins the hosts** (expected within days of 2026-10-16). The
  CI builds and tests; debugging a runner, a widget or an entitlement
  happens there, in Xcode.

## Testing

- **Dart**: the unit and widget suites already run anywhere; the macOS job
  runs them on a Mac. Platform branches are tested the way
  `createReminderService({isAndroid, isDesktop})` already is — the host
  platform injected — so the iOS branches run on any host. That pattern
  becomes one `HostPlatform` value (phase 0) instead of a boolean per call
  site.
- **Swift**: XCTest for the shared plugin — the payload
  parsing the widgets do (as `TodoWidgetItemsTest.kt` does for Android),
  the pasteboard's HTML reading.
- **Integration**: `app_boot` on the macOS runner; `sync_e2e` on
  `-d macos`; on iOS, `app_boot` in the simulator.
- **By hand, on devices**: an Apple silicon Mac, an iPhone, an iPad with a
  keyboard. The storage grants, the widgets, the share extension and the
  background limits only show on a device.

## Phases

One feature branch per phase, one PR into `main` each, a commit per step.
Phase 0 runs on today's hosts; everything after it needs a Mac.

0. **Ground work, no Apple code** (Windows or Linux):
   - `HostPlatform`: *desktop*, *phone*, *touch*, *Apple*, answered once
     and injectable; the `isLinux || isWindows` gates become *desktop*.
   - The primary modifier in every default binding; keys shown as glyphs
     on Apple.
   - `LibraryLocation` with a path-only implementation; the index named
     after the library's identity.
   - The watcher asks `isWatchSupported`; names compared NFC.
   - The update check offers nothing to a platform it has no asset for.
   - The transcription's phone list keyed on *phone*.
1. **Spike on a Mac** (a week, throwaway branch): `flutter create
   --platforms=macos,ios`, boot both; answer every **to verify** above —
   `Directory.watch` on iOS, the container's path across an app update,
  `window_manager`
   and `nativeapi` on macOS, `home_widget`'s intent process, WebKit's PDF
   against Chrome's, FFmpeg's removal. The answers are written into this
   record before phase 2 starts.
2. **macOS**: the runner, flavors and entitlements; the desktop gates on;
   title bar, menu bar from the command registry, keys, menu bar extra,
   close semantics, file-open events, Dock menu, drop; `packages/niman_apple/`
   with WebKit PDF and capture, pasteboard, keep awake, spell check;
   reminders; bundled OCR engine; creation time; Show in Finder; the
   updater's `.dmg`; CI and the release's `.dmg`; `docs/user/platforms.md`
   gains a macOS section.
3. **iOS**: the runner, flavors, App Group; storage (the container), the
   rescan on resume; quick actions; the
   share extension and its inbox; notifications and the 64 cap;
   background sync; transcription and OCR; no updater; TestFlight in
   `release.yml`; the iOS section of `platforms.md`.
4. **Widgets**: WidgetKit on iOS — the three widgets, configuration,
   interactive toggles; then the same on macOS.
5. **The App Store, iOS only**: privacy manifest, review, release. The
   Mac stays on the `.dmg`.

Until phase 4 ends, `platforms.md` lists macOS and iOS as **preview**, with
what each still lacks — the decision `AGENTS.md` asks for, made explicit,
not a platform quietly behind.

## Risks

- **One Mac, few devices**: the Mac mini covers macOS and the iOS
  simulator. The share extension, the widgets and the background limits
  show truly only on an iPhone and an iPad (still open, below).
- **iCloud and File Provider folders on iOS**: lazy materialisation and a
  million-note scan do not mix. The plan keeps them out of the default and
  measures before promising them.
- **Five platforms per feature**: from the first macOS release, every
  feature has five surfaces to land on. That is the real cost of the port,
  paid on every PR after it.
- **Pre-1.0 desktop packages** (`window_manager`, `nativeapi`) carry the
  Mac's window and tray; both are pinned exactly already, and the spike
  tests them first.

## What the spike answered (2026-10-20 and 21)

Phase 1 ran on the Mac mini: the macOS port went on to most of phase 2 on
`spike/macos`, and the iOS runner boots in the simulator on `spike/ios`.
The **to verify** items above, answered:

- **`window_manager` 0.5.2 on macOS:** the hidden title bar keeps the
  traffic lights over a transparent bar, and close interception
  (`setPreventClose`) works; the bar leaves the lights their room.
- **`nativeapi` 0.2.4's tray on macOS:** the status item and its menu
  work; a click opens the menu. Its Dart API does not expose the template
  image, so `cnativeapi`'s C call does that (a direct dependency, pinned).
- **`file_picker`:** on an unsandboxed Mac its Darwin handler refuses every
  dialog over entitlements the app has no use for, unless
  `skipEntitlementsChecks()` is called at startup. On iOS it returns the
  picked folder's path, with no copy, no security scope and no bookmark.
- **The sandbox's folder grant** is moot on the Mac: `flutter create`
  turns the App Sandbox on, and the runner turns it off (decision 3).
- **`Directory.watch` on iOS:** `isWatchSupported` is false and the call
  throws; the watcher checks first and leaves the folder to the rescan.
- **The math rasteriser** stays off on a Mac: Impeller on Metal smooths
  the paths' edges itself.
- **FFmpeg can be left out of the Apple builds:** an Android-only copy of
  `ffmpeg_kit_flutter_new_min` replaces it (its 2.1.0 iOS frameworks also
  have no arm64 simulator slice), and AVFoundation decodes other formats
  in `packages/niman_apple`.
- **WebKit's PDF against Chrome's:** paginated A4 with real text through
  the print operation (`createPDF` makes one endless page); pagination,
  columns and math checked on the Mac.
- **`home_widget`'s intent process:** not answered yet — the widget spike.

And what the plan did not foresee:

- On macOS the Dart UI isolate runs on the main thread, so the system's
  spell checker is a synchronous FFI call, as Windows' COM one is.
- WebKit ends its print on a thread of its own: a channel answered from
  there reached Dart only at the next event. And a background isolate's
  channel replies stalled the same way on a Mac, so the folder export's
  isolate asks the UI isolate to print each page.
- Tesseract picks its SIMD sources for one processor: the universal OCR
  engine is two builds joined with `lipo`. CMake 4 needs Leptonica's
  policy version named.
- The Mac's FSEvents reports the watched folder itself, and the read
  view's goldens need a `macos/` set (CoreText); the integration files run
  the real app, in the host's language.
- A Swift package of the app's own needs the runner at macOS 14.

## Decided (2026-10-16)

1. **A Mac mini** joins the hosts within days; the native work happens
   there.
2. **macOS ships as a `.dmg`** on the GitHub release, beside Linux and
   Windows. No Mac App Store.
3. **Not sandboxed** on macOS: a library is a path, as on Linux.
4. **iOS keeps its libraries in the app's container**, visible in Files,
   synced through WebDAV. A picked folder and iCloud are not in the first
   iOS release.
5. **iOS 17 and macOS 14** at least.
6. **A universal Mac app** (arm64 and x86_64).
7. **Tesseract, bundled**, is the OCR engine on both.
8. **A share waits in the inbox**: the extension queues it, the app
   captures it when it is next opened.
9. **The system's spell checker** on macOS and iOS, as on Windows; the
   personal dictionary stays Niman's.
10. **Widgets on the Mac come after the iOS ones**, with the same SwiftUI;
    until then `platforms.md` says so.
11. **Closing follows the Mac**: the window closes, the app stays in the
    Dock, `⌘Q` quits; *Close to the tray* is not shown on macOS; the menu
    bar extra is on by default.
12. **The macOS CI job runs on every PR** from phase 2 on.
13. **macOS and iOS are preview** in `platforms.md` until the widgets land,
    then full members of "every platform ships every feature".
14. **Bundle ids** `dev.niman.niman` and `dev.niman.niman.beta`, App Groups
    `group.dev.niman.niman` and `group.dev.niman.niman.beta`.

## Still open

- **The Apple Developer Program** (99 $ a year; as an individual, whose
  name the store shows, or as an organisation, which needs a D-U-N-S
  number). Not needed until phase 2's first release: macOS can ship
  without it, at the cost of Gatekeeper's *Open Anyway* on first launch
  (see *Builds, flavors, signing*). iOS cannot ship at all without it, so
  it is needed before phase 3 reaches anyone's phone.
- **An iPhone and an iPad to test on**: the Mac covers the simulator, not
  the share extension, the widgets or the background limits on a device.
