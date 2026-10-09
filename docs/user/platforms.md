# Platform notes

Supported today: **Android** (minSdk 35), **Linux** (Wayland),
**Windows**. macOS/iOS are not built yet, but the code is kept portable.
New tests must be portable too (see [conventions](../dev/conventions.md)).

Export is one feature on every platform: Markdown, HTML, PDF and EPUB
are in both choosers, note and folder alike. EPUB is platform-neutral
Dart — no engine, no WebView — so a book is built the same way
everywhere; PDF goes through each platform's own printer (below).

Slide notes ([slides](slides.md)) present on every platform, the screen
kept on while they do: Android through the window's keep-screen-on flag,
Linux through GTK's idle inhibit (the desktop's own screen saver and
lock wait), Windows through `SetThreadExecutionState`. The presenter
view shares the one window with the slides: putting the slides on a
second screen and the presenter view on the first needs a second window,
which Flutter offers only behind an experimental flag on the desktops and
not at all on Android — a decision for now, not an omission (#534). On a
second screen, present from the window placed there.

## Android

- **Storage:** plain `dart:io` file access, gated by
  `MANAGE_EXTERNAL_STORAGE`. SAF tree grants are not a substitute — they
  only open `content://`, never the filesystem.
- **FUSE cost:** every file stat/list is a round trip, so all disk reads
  run off the UI isolate (`Isolate.run`); Drift writes stay on main.
- **Reminders:** exact alarms fire with the screen off or the process
  killed. Grant notification permission and, in Niman's **App info** page
  (*Informazioni app*), turn on **Allow background usage** (*Consenti
  l'utilizzo in background*) — an app the system will not start in the
  background never fires an alarm.
- **Launcher shortcuts:** long-press the icon (see
  [shortcuts](shortcuts.md)).
- **Home-screen widgets:** the Niman Todos and Niman Note widgets
  (see [widgets](widgets.md)).
- **PDF export:** through the system WebView's print adapter, in-process:
  no browser is installed or run, and the PDF's text stays selectable.
  A folder's PDF zip prints each note the same way, one PDF per note.
  A WebView that refuses the print (a broken system component) falls
  back to drawing the note page by page, pictures included; that PDF is
  a picture and cannot be selected, and the app says so when the file is
  written.
- **Text recognition:** the engine (64-bit ARM, or x86-64 for an
  emulator) is a 2.3–2.7 MB download, loaded from the app's private
  storage; nothing ships in the APK. A recognition pauses when Android
  freezes the app in the background and goes on when you come back; the
  strip under the top bar follows it on any note (see
  [text recognition](text-recognition.md)).
- **Web capture:** a page is captured with Niman off screen, under a short
  foreground service and its notification; a page with too little text is
  run in a hidden WebView of the app's own (see
  [web capture](web-capture.md)).
- **Paste as Markdown:** in the editor's menu. Android's clipboard holds
  the HTML a browser copies but not the page it came from, so the paste
  is not linked to its page, and links written relative to it stay as
  the page wrote them (see
  [web capture](web-capture.md#paste-as-markdown)).

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
  Niman* at the top, the quick actions (today's journal entry among
  them), and *Quit*. By default the
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
- **The `niman` command** is the package's, not the AppImage's. The Arch
  package installs it at `/usr/bin/niman`, so it is on `PATH`. The
  `.tar.gz` ships a `niman` launcher at its root beside the bundle: put
  the extracted folder on `PATH`, or symlink that launcher into
  `~/.local/bin`, to get the command. The AppImage puts nothing on
  `PATH`: run its own file with the same arguments —
  `./niman-<version>-linux-x64.AppImage --quick-note`, or
  `./niman-<version>-linux-x64.AppImage note.md` — or symlink the AppImage
  itself as `niman`. The flags are under
  [shortcuts](shortcuts.md#cli-launch-flags-desktop).
- **Dropping files and folders on the window** is the window's own GDK
  drop destination, which takes the `text/uri-list` a file manager
  offers. The frame around the window says a drag is over it, and the
  drop opens or imports what it names
  ([organization](organization.md#dropping-files-on-the-window)). The
  portal's file-transfer target is not taken: it carries a one-time key
  to resolve over D-Bus rather than paths, and preferring it is what left
  a drop on KDE/Wayland doing nothing at all (#224). A drag from a
  sandboxed app that offers that target alone is therefore not taken
  either, and says so in the log.
- A tree row's right-click menu can show the note in the file manager
  (over `org.freedesktop.FileManager1`, falling back to `xdg-open` on
  the folder) or open it in the default app — see
  [organization](organization.md#opening-a-note-outside-niman).
- **PDF export:** printed headless by the first Chromium-family browser
  on `PATH` — Chromium, Google Chrome, Microsoft Edge, Brave, Vivaldi,
  Helium: one engine under many names. On a machine without one, a note
  is drawn as pictures of its pages — pictures included, but not
  selectable — and the export asks before it starts, because a long note
  is minutes of drawing; a folder's PDF zip is not offered.
- **Text recognition:** the distribution's Tesseract (4.1 or later) when
  it is installed, with no download; otherwise a 2.9 MB engine built for
  glibc 2.34 and later (see [text recognition](text-recognition.md)).
- **Web capture:** a page with too little text is run headless in the
  same Chromium-family browser, with a throwaway profile. Without one, such
  a page is saved as its title, description and picture, under a notice
  to open the link (see [web capture](web-capture.md)).
- **Paste as Markdown:** the clipboard's HTML is read through GTK, on X11
  and Wayland alike; the page it came from is the one Chromium-family
  browsers and Firefox name beside it (see
  [web capture](web-capture.md#paste-as-markdown)).

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
- Hovering the maximise button opens the Windows 11 **Snap Layouts**
  flyout: the runner answers the hit test over the button's rectangle,
  which the title bar reports on every layout it takes, so the flyout
  follows the bar's real layout rather than a fixed spot (#169). The
  three buttons are non-client for that, so the app no longer draws
  their hover highlight on Windows; the × still meets the unsaved-edits
  check.
- The installer can associate `.md` and `.markdown` files with Niman
  (a checkbox, on by default). Niman joins the files' *Open with* list;
  Windows leaves the choice of default app to you, so it becomes the
  default only when nothing else claims `.md`, or when you pick it.
  Double-clicking one opens it in the Niman already running, or starts
  one.
- **The `niman` command** is the `niman.exe` in the install folder
  (`%LOCALAPPDATA%\Programs\Niman` for the per-user install). The
  installer puts nothing on `PATH`, so call it by path or add that folder
  yourself; the flags are under
  [shortcuts](shortcuts.md#cli-launch-flags-desktop).
- **Dropping files and folders on the window** takes the paths Win32
  hands the window (`WM_DROPFILES`), and the drop opens or imports what
  it names. The frame that Linux draws while a drag is over the window is
  **not** drawn here: reporting a drag that is over the window and has
  not landed needs an OLE `IDropTarget` registered on the Flutter view,
  which this pass does not do (#224). The drop itself is unaffected.
- A tree row's right-click menu can show the note in Explorer (selected)
  or open it in the default app — see
  [organization](organization.md#opening-a-note-outside-niman).
- **PDF export:** printed headless by Edge, found through the shell's
  App Paths key or its install folder. A note falls back to being drawn
  as page pictures where Edge is missing — asking before it starts, as
  on Linux — and a folder's PDF zip is not offered then.
- **Text recognition:** a 3.9 MB engine downloaded into the app folder,
  with the C runtime built in, so nothing else needs installing (see
  [text recognition](text-recognition.md)).
- **Web capture:** a page with too little text is run headless in Edge,
  with a throwaway profile (see [web capture](web-capture.md)).
- **Paste as Markdown:** the clipboard's `HTML Format`, which the
  browsers write with the page it came from (see
  [web capture](web-capture.md#paste-as-markdown)).

## Home

On Linux, Windows and a wide Android window the [Home](home.md) is a grid
of tiles; on a phone it is a column of the same tiles. One Home, one file:
only the shape changes.

## Density

On Linux and Windows the note tree and its right-click menu are drawn
for a mouse: shorter rows, a narrower slot for the folder chevron and
the note icon, and a tighter menu. A phone or a tablet keeps the
thumb-sized rows and the long-press sheet. The choice follows the
platform's own density (compact on a desktop), not the window's width,
so a tablet in landscape keeps the touch sizes.

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

**Back and forward** through the notes looked at work everywhere from a
keyboard (`Alt+←` / `Alt+→`). The mouse's side buttons do it on Linux and
Windows; on Android a mouse's back button is the system's Back, which
keeps its meaning — closing the note, leaving a screen.

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
and Windows only: a phone has nothing to drag from. The window draws a
frame while a drag is over it, on Linux and on Windows alike, where the
window's drop target is OLE's (#531). A link dropped the same way is a
[web capture](web-capture.md); on a phone, the browser's Share does it.

**Opening a file outside any library** (`Ctrl+Shift+O`, see
[organization](organization.md#opening-a-file-outside-any-library)) is
Linux and Windows only for now: Android's picker hands over a copy of
the file, which could be read but not saved back.

**Sharing into Niman (Android)** goes the other way: another app's
**Share** menu offers Niman for text and for a Markdown file, and a file
manager's **Open with** does for a `.md`. A web page or a passage of one
shared from the browser opens the [web capture](web-capture.md) sheet,
saved in the background with Niman off screen. Other shared text is
appended to the
[quick note](organization.md#folders-quick-note-list-notes-voice-notes)
and the note opens; with no quick note chosen yet, the choose/create
screen opens and the text lands in whatever note it picks. A shared file
is copied into the library root as a new note — its name kept, uniquified
like any other — and opened. A copy, because Android hands the sender's
file as a read-only `content://` reference, not a path Niman could edit
in place. A Notion export (a `.zip`) shared the same way is
[imported](organization.md#importing-a-notion-export) instead of copied
as one note. That copy is made in the background, so the app stays
responsive while a large share is read, and it is capped at 512 MB: past
that the share is refused rather than copied — the sender's text arrives
instead, if it attached any.

The **side panel** (outline, tags, history beside the note, and the
[journal](journal.md)'s calendar) shows on
any window at least 1000 px wide: desktops, tablets, a phone in
landscape if it is that wide. A phone upright has no room for a note
and a panel side by side, so this is a decision rather than an
omission: the note's ⋮ menu opens the same three there, the outline and
the tags as sheets and the history as its screen. Where the panel shows,
its left edge drags to make it wider or narrower, like the tree's edge.
It stops growing before the note gets narrower than 360 px, and it
keeps its width for the next launch.
