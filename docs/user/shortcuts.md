# Shortcuts

## Keyboard (desktop)

Editor find/replace follows the familiar bindings:

- `Ctrl/⌘+F` — find
- `Ctrl/⌘+Alt+F`, or classic `Ctrl+H` on non-mac desktop — replace
- `Esc` — close the find bar
- `PageUp` / `PageDown` — move in results

Links: `Ctrl+click` a link in the source editor to follow it.

## Launcher quick actions (Android)

Long-press the app icon for dynamic shortcuts (labels localized,
published at startup):

- **Quick note** — opens the quick note
- **New todo** — opens the Todo tab's add-task dialog
- **New note** — the Files FAB's "New note" flow
- **New list note** — the Files FAB's "New list note" flow

Each shortcut runs the same flow as its in-app button, so the two can
never drift. Desktop has no equivalent menu.

## CLI launch flags (desktop)

Desktop builds accept `--quick-note`, `--new-todo`, `--new-note`,
`--new-list`, routed through the same handler as the launcher actions.
