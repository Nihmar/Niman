# Getting started

Niman keeps notes as plain Markdown files. One note = one `.md` file on
disk; the app's SQLite database is only a rebuildable index.

## Core ideas

- **Library:** just a folder. Its settings live inside it as
  `.niman/settings.json`, so copying the folder to another machine moves
  them too; only how it looks on each screen (tree width, text size,
  editor) stays with the device (see [settings](settings.md)).
- **Disk is source of truth:** anything the app knows can be rebuilt from
  the files. Never edit the `.niman/` or `.history/` folders by hand,
  but everything else is yours.
- **Multiple libraries:** open several folders from a remembered list and
  switch anytime. Each library has its own settings. On a wide window the
  layers button at the foot of the rail opens the library window: the
  known libraries to switch to, **Open existing**, **Create new** and
  **Close library**, which goes back to the opening screen. Open notes
  are saved first; a note that cannot be saved keeps the library open
  and says why. On a phone the same actions are in Settings →
  Maintenance.
- **Forgetting a library** takes it off that list; the folder, its notes
  and its settings stay where they are, and opening it again brings it
  back. It is in the row's own menu (⋯, right-click on a desktop, or a
  long press on a phone), and the library open right now closes first.

## First steps

1. Open (or create) a folder as a library.
2. Create a note with the Files FAB: **New note** or **New list note**.
3. Write in the source editor or the live (WYSIWYG) editor — switch per
   note or per library, and read the note in the read view (see
   [editing](editing.md)).
4. Organize with folders, [wikilinks](links.md), tags and frontmatter
   (see [organization](organization.md)), and let the
   [journal](journal.md) make one note a day for you.
5. Find notes with full-text [search](search.md).

## Next

- [Editing](editing.md) — Markdown, math, images, spellcheck, the read view.
- [Organization](organization.md) — trash, history, templates, tags — and
  reading pictures, PDFs and books.
- [Journal](journal.md) — one note per day, with a calendar and a template.
- [Tasks and reminders](tasks.md) — todo.txt plus `rem:` alarms.
- [Themes](themes.md) — the shipped palettes, and a theme of your own.
- [Home-screen widgets](widgets.md) — todo and note widgets (Android).
- [Platforms](platforms.md) — Android / Linux / Windows notes.
- [Sync](sync.md) — moving a library between machines today.
