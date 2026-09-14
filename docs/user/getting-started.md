# Getting started

Niman keeps notes as plain Markdown files. One note = one `.md` file on
disk; the app's SQLite database is only a rebuildable index.

## Core ideas

- **Library:** just a folder. Its settings live inside it as
  `.niman/settings.json`, so copying the folder to another machine moves
  everything (see [settings](settings.md)).
- **Disk is source of truth:** anything the app knows can be rebuilt from
  the files. Never edit the `.niman/` or `.history/` folders by hand,
  but everything else is yours.
- **Multiple libraries:** open several folders from a remembered list and
  switch anytime. Each library has its own settings.

## First steps

1. Open (or create) a folder as a library.
2. Create a note with the Files FAB: **New note** or **New list note**.
3. Write in the source editor or switch to WYSIWYG per note or per
   library (see [editing](editing.md)).
4. Organize with folders, [wikilinks](links.md), tags and frontmatter
   (see [organization](organization.md)).
5. Find notes with full-text [search](search.md).

## Next

- [Editing](editing.md) — Markdown, math, images, spellcheck, preview.
- [Organization](organization.md) — trash, history, templates, tags.
- [Tasks and reminders](tasks.md) — todo.txt plus `rem:` alarms.
- [Home-screen widgets](widgets.md) — todo and note widgets (Android).
- [Platforms](platforms.md) — Android / Linux / Windows notes.
- [Sync](sync.md) — moving a library between machines today.
