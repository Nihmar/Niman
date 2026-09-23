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
- **The tray icon**, where the desktop provides one. Its menu has *Open
  Niman* at the top, the five quick actions, and *Quit*. By default the
  window's × **hides Niman to the tray** and leaves it running, so
  desktop reminders keep firing; Settings → Appearance → *Close to the
  tray* turns that off, and then the × quits as it used to. *Quit* asks
  about unsaved notes exactly as the × does.
  On Linux the click on the icon **is** the menu — a StatusNotifier item
  has no right click of its own — and *Open Niman* is how the window
  comes back. On Windows the right click opens the menu and a left click
  brings the window back.
- Markdown files open in Niman: the desktop entry declares
  `text/markdown`, so Niman is offered for `.md` files and can be made
  their default app. Double-clicking one opens it in the Niman already
  running, or starts one.
- A tree row's right-click menu can show the note in the file manager
  (over `org.freedesktop.FileManager1`, falling back to `xdg-open` on
  the folder) or open it in the default app — see
  [organization](organization.md#opening-a-note-outside-niman).

## Windows

- Ships its own SQLite (`sqlite3` package bundles the native library via
  Dart build hooks — Windows has no system `sqlite3.dll`). First build
  on a machine needs network to fetch the prebuilt binary.
- Ships the Visual C++ runtime too (`msvcp140.dll`, `vcruntime140.dll`,
  `vcruntime140_1.dll`, next to `niman.exe`), so the installer and the
  zip run on a Windows that never had the redistributable installed. A
  release build fails if they are missing.
- spellcheck via hunspell, same setting as Linux, plus the per-library
  personal dictionary.
- The app draws its own title bar, as on Linux. The window keeps its
  system behaviours — resizing from the edges, Aero Snap, `Win`+Arrow —
  because the frame is still there underneath; the app only paints over
  the caption.
- The installer can associate `.md` and `.markdown` files with Niman
  (a checkbox, on by default). Niman joins the files' *Open with* list;
  Windows leaves the choice of default app to you, so it becomes the
  default only when nothing else claims `.md`, or when you pick it.
  Double-clicking one opens it in the Niman already running, or starts
  one.
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

The **command palette** is `Ctrl+Shift+P` on the desktop. On a phone it
is its own thing, apart from the library's search: **two fingers dragged
down** anywhere open it, and so do the ⚡ on the Search tab's bar and
*Command palette* in an open note's ⋮ menu. The Search tab searches
notes. Either way the palette offers only the commands that can run
where you are; Settings → **Commands** lists them all, with their keys
and what each one needs to show (an open note, a wide window, the
desktop, and so on).

On a device that has never had a hardware keyboard, nothing mentions
keys you cannot press: the palette's rows and Settings → Commands drop
the key column (what a command needs is still there), and the palette's
footer says the pin is a tap. Plug a keyboard in and they come back.

Typing in the palette also finds **settings**, listed after the commands
and the notes: pick one and the settings open on that row. The rows of
the keyboard and Commands pages are left out, since the palette already
lists those commands itself.

**Pinned commands** head the palette before anything is typed, above the
ones used lately. The pin on a command's row pins and unpins it, and
`Alt+P` does the same to the selected row. Pins belong to the device,
like the shortcuts, and a pinned command still shows only where it can
run.

**Keyboard shortcuts** can be changed wherever there is a keyboard: on
Linux and Windows, and on Android with a hardware keyboard attached, the
same screen under Settings. Without a keyboard the screen says so
instead of opening.

**Zen mode** (`F11`, see [editing](editing.md#zen-mode)) is Linux and
Windows only. It needs the app's own title bar, which is where its thin
bar goes, and a phone is already one note on one screen. The window is
maximized for it; if the window manager declines, Zen still hides
everything but the note.

**Dropping files and folders on the window** (see
[organization](organization.md#dropping-files-on-the-window)) is Linux
and Windows only: a phone has nothing to drag from.

**Opening a file outside any library** (`Ctrl+Shift+O`, see
[organization](organization.md#opening-a-file-outside-any-library)) is
Linux and Windows only for now: Android's picker hands over a copy of
the file, which could be read but not saved back.

The **side panel** (outline, tags, history beside the note, and the
[journal](journal.md)'s calendar) shows on
any window at least 1000 px wide: desktops, tablets, a phone in
landscape if it is that wide. A phone upright has no room for a note
and a panel side by side, so this is a decision rather than an
omission: the note's ⋮ menu opens the same three there, the outline and
the tags as sheets and the history as its screen.

## Not yet

Share-in on Android — tracked as
[#39](https://github.com/Nihmar/Niman/issues/39).
Debug-signed APKs until release keys land (see
[releasing](../dev/releasing.md)).
