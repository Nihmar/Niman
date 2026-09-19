# Shortcuts

## Keyboard (desktop)

App-level accelerators, as Niman ships them. Settings → Keyboard
shortcuts lists them and lets you change them:

- `Ctrl/⌘+Shift+P` — the command palette: commands and notes in one
  search
- `Ctrl/⌘+O` — go to a note by name (the palette, on notes alone)
- `Ctrl/⌘+Shift+O` — open a Markdown file outside any library (see
  [organization](organization.md#opening-a-file-outside-any-library))
- `Ctrl/⌘+N` — new note
- `Ctrl/⌘+Shift+N` — new list note
- `Ctrl/⌘+Shift+A` — new voice note
- `Ctrl/⌘+T` — new todo
- `Ctrl/⌘+Q` — quick note
- `Ctrl/⌘+B` — show or hide the sidebar
- `Ctrl/⌘+W` — close the note on screen (its tab)
- `Ctrl/⌘+Tab` / `Ctrl/⌘+Shift+Tab` — next / previous open note
- `Ctrl/⌘+\` — split the window right with the note on screen
- `Ctrl/⌘+Shift+B` — show or hide the side panel (outline, tags, history)
- `F11` — Zen mode: the note and nothing else; `Esc` or `F11` again
  leaves it (see [editing](editing.md#zen-mode))
- `Ctrl/⌘+Shift+T` — typewriter mode on or off: the line being written
  stays in the middle (see [editing](editing.md#typewriter-mode))
- `Ctrl/⌘+1…5` — Files, Todo, Search, Quick note, Settings tabs (on a
  wide window Settings opens as a floating window)

Moving and selecting in the source editor, on Windows and Linux:

- `Ctrl+←` / `Ctrl+→` — jump a word
- `Ctrl+Shift+←` / `Ctrl+Shift+→` — select a word
- `Home` / `End` — start and end of the line, `Shift` to select
- `Ctrl+Home` / `Ctrl+End` — start and end of the note

Editor find/replace follows the familiar bindings:

- `Ctrl/⌘+F` — find
- `Ctrl/⌘+Alt+F`, or classic `Ctrl+H` on non-mac desktop — replace
- `Esc` — close the find bar
- `PageUp` / `PageDown` — move in results

Links: `Ctrl+click` a link in the source editor to follow it.

## Changing a shortcut

Settings → **Keyboard shortcuts** lists every command, with its keys or
with *No shortcut*. Settings → **Commands** lists the same commands with
when each one can run: the palette and the keys offer a command only
where it can, so one that needs an open note is not there without one.

- **Change.** Tap a command and press the new combination. While the
  window is recording it takes every key, Esc and Tab included, so leave
  with **Cancel**, or by holding Esc down. A key on its own is refused,
  because a plain letter is for typing; function keys (F1…F24) may stand
  alone.
- **Conflicts.** A combination another command already has is never
  taken silently. The screen names that command and asks whether to
  move the keys; if you do, that command is left with no shortcut.
- **Keys the text fields and the editor use.** Copy, paste, cut, select
  all, undo, redo, find and replace may be taken, after a plain warning:
  your command takes them there too.
- **Remove and restore.** **×** removes a command's shortcut. A command
  with none is still one `Ctrl+Shift+P` away in the command palette.
  **↺** puts back the key Niman ships, and **Restore defaults** puts back
  every one.

A key you chose wins everywhere, both editors included: Niman looks for
it before the editor hears the key. The keys as shipped are chosen not
to collide with the editor's own.

The shortcuts belong to this device: they are kept in its settings,
never in a library, so a library synced to another computer does not
bring this keyboard's keys with it.

Some combinations never reach an app. `Win`+anything on Windows, and the
ones your Linux desktop keeps for itself, are taken before Niman sees
them. Niman cannot tell which these are, so a shortcut set on one simply
never fires.

## The command palette

`Ctrl+Shift+P` opens one field over whatever is on screen. It searches
the app's commands and your notes by name at once:

- **Names.** Commands are named `Group: Verb`, such as *Editor: Switch to
  the WYSIWYG editor* or *Library: Re-index now*. A trailing `…` means
  the command will ask you something before it acts (*Note: Move…*).
- **Keys.** A command that has a key shows it beside its name.
- **Moving and choosing.** `↑`/`↓` move through the list, `↵` runs the
  command or opens the note, and `Esc` closes the palette. The line at
  its foot says so.
- **Order.** Before you type, it offers the commands you used last and
  the notes you had open. Once you type, what you used lately still
  comes first.
- **Only what works here.** It lists the commands that can run where you
  are: nothing about the note when none is open, no panes on a phone.

Some commands have no key at all, such as renaming the note on screen or
re-indexing the library: the palette is how you reach them.

On a phone the **Search** tab is the palette: whatever you type lists
the matching commands above the notes found, and a tap runs one.

In the file tree, `Ctrl+click` a note (or middle-click its tab to close
it) to open it in a tab of its own — see
[editing](editing.md#open-notes-and-tabs).

## Launcher quick actions (Android)

Long-press the app icon for dynamic shortcuts (labels localized,
published at startup):

- **Quick note** — opens the quick note
- **New todo** — opens the Todo tab's add-task dialog
- **New note** — the Files FAB's "New note" flow
- **New list note** — the Files FAB's "New list note" flow
- **New voice note** — the Files FAB's "New voice note" flow (desktop
  tray only; Android launchers show the first four)

Each shortcut runs the same flow as its in-app button, so the two can
never drift.

## CLI launch flags (desktop)

Desktop builds accept `--quick-note`, `--new-todo`, `--new-note`,
`--new-list`, `--new-voice`, routed through the same handler as the
launcher actions.

A path opens that file: `niman ~/project/README.md` opens it the way
**Open file** does (see
[organization](organization.md#opening-a-file-outside-any-library)). A
relative path is read from where the command was typed.

There is only ever one Niman per session. With Niman already running,
`niman <file>` or `niman --quick-note` hands itself to that Niman, which
comes to the front and does it, and the new launch ends without
opening a window. That is also what keeps two processes from holding
one library.
