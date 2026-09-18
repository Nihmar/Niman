# Shortcuts

## Keyboard (desktop)

App-level accelerators (listed in-app under Settings → Keyboard):

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
