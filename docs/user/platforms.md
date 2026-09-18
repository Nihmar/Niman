# Platform notes

Supported today: **Android** (minSdk 35), **Linux** (Wayland),
**Windows**. macOS/iOS are not built yet, but the code is kept portable.
New tests must be portable too (see [conventions](../dev/conventions.md)).

## Android

- **Storage:** plain `dart:io` file access, gated by
  `MANAGE_EXTERNAL_STORAGE`. SAF tree grants are not a substitute — they
  only open `content://`, never the filesystem.
- **FUSE cost:** every file stat/list is a round trip, so all disk reads
  run off the UI isolate (`Isolate.run`); Drift writes stay on main.
- **Reminders:** exact alarms fire with the screen off or the process
  killed. Grant notification permission and exempt the app from battery
  optimization when prompted, or alarms may not arrive.
- **Launcher shortcuts:** long-press the icon (see
  [shortcuts](shortcuts.md)).
- **Home-screen widgets:** the Niman Todos and Niman Note widgets
  (see [widgets](widgets.md)).

## Linux

- Wayland supported; window owns close-request handling (dirty-check on
  close rides it).
- The app draws its own title bar — sidebar toggle, window title, and the
  minimise / maximise / close buttons — in place of the system one. The
  close button meets the same unsaved-edits check the system close does.
- Closing the window ends the process there and then, skipping the
  library teardown libc runs on the way out: on NVIDIA that teardown
  segfaults inside the EGL driver and left a core dump behind every
  close. Nothing of ours is skipped — the dirty-check ran, the notes are
  written and the engine is down before the window goes.
- Spellcheck via hunspell (`spellDictionaries` in library settings), plus
  a per-library personal dictionary (right-click *Add to dictionary*,
  `<library>/.niman/dictionary.txt`).
- Tray support where the desktop provides one.
- A tree row's right-click menu can show the note in the file manager
  (over `org.freedesktop.FileManager1`, falling back to `xdg-open` on
  the folder) or open it in the default app — see
  [organization](organization.md#opening-a-note-outside-niman).

## Windows

- Ships its own SQLite (`sqlite3` package bundles the native library via
  Dart build hooks — Windows has no system `sqlite3.dll`). First build
  on a machine needs network to fetch the prebuilt binary.
- spellcheck via hunspell, same setting as Linux, plus the per-library
  personal dictionary.
- The app draws its own title bar, as on Linux. The window keeps its
  system behaviours — resizing from the edges, Aero Snap, `Win`+Arrow —
  because the frame is still there underneath; the app only paints over
  the caption.
- A tree row's right-click menu can show the note in Explorer (selected)
  or open it in the default app — see
  [organization](organization.md#opening-a-note-outside-niman).

## Open notes

On Linux and Windows the open notes are **tabs** in the title bar, and
the ones you were working in come back when you open the library again
— see [editing](editing.md#open-notes-and-tabs). The desktop window
also splits into two panes, each with its own tabs.

On an Android tablet, or any wide window without the app's own title
bar, the same tabs head the notes instead of sitting in the title bar.

On an Android phone the same open notes are reached from a **switcher** instead
of tabs: a count on the note bar opens the list. One note is on screen
at a time, and the phone has no split: a phone's width holds one note.

The **side panel** (outline, tags, history beside the note) shows on
any window at least 1000 px wide: desktops, tablets, a phone in
landscape if it is that wide. A phone upright has no room for a note
and a panel side by side, so this is a decision rather than an
omission: the note's ⋮ menu opens the same three there, the outline and
the tags as sheets and the history as its screen.

## Not yet

Share-in on Android, file association on desktop, single-instance guard
— tracked as [#39](https://github.com/Nihmar/Niman/issues/39).
Debug-signed APKs until release keys land (see
[releasing](../dev/releasing.md)).
