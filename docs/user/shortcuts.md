# Shortcuts

## Keyboard (desktop)

App-level accelerators (listed in-app under Settings → Keyboard):

- `Ctrl/⌘+Shift+P` — the command palette: commands and notes in one
  search
- `Ctrl/⌘+O` — go to a note by name (the palette, on notes alone)
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
- `Ctrl/⌘+1…5` — Files, Todo, Search, Quick note, Settings tabs

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
