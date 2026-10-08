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
- **Notes are UTF-8.** A note from elsewhere that is not — a Latin-1 file
  from an old vault — still opens, searches and exports with its accents:
  each byte UTF-8 has no place for is read as the Windows-1252 character
  it stands for there (`café`, not `caf�`). Saving writes the note as
  UTF-8, so its words stay and its encoding becomes the app's.
- **Multiple libraries:** open several folders from a remembered list and
  switch anytime. Each library has its own settings. On a wide window the
  layers button at the foot of the rail opens the library window: the
  known libraries to switch to, **Open existing**, **Create new** and
  **Close library**, which goes back to the opening screen. Open notes
  are saved first; a note that cannot be saved keeps the library open
  and says why. On a phone the same actions are in Settings →
  Maintenance, and they save the open notes the same way.
- **Forgetting a library** takes it off that list; the folder, its notes
  and its settings stay where they are, and opening it again brings it
  back. It is in the row's own menu (⋯, right-click on a desktop, or a
  long press on a phone), and the library open right now closes first.

## The first run

A fresh install opens on a short **welcome**: what Niman is — notes as
files, three ways to write one, links and templates, search, export and
import, tasks, sync, and what your device adds — and then one question:
**have you written Markdown before?** The answer only decides how your
first library starts. *Never* opens notes in the live editor and does not
offer the Markdown source; *A little* opens live with both editors
offered; *All the time* opens the source, as the app has always come.
Settings → Editor has the switches whenever you change your mind, and the
deck is shown once: it lives under Settings → Diagnostics and info as
*What Niman can do*.

The last page can ask for a **tour** instead (*Show me around*), and so
can the command palette later (*Take the tour*, which resumes a tour left
halfway and starts a finished one over). It points at the real controls —
the tree, the create menu, the note and its three modes, the toolbar,
the tabs, the dock — and ends by opening the **Markdown cheatsheet**
(#265), every construct written beside how a note shows it. Stop it at
any step; nothing of it is left in your library.

## First steps

1. Open (or create) a folder as a library.
2. Create a note with the Files FAB: **New note** or **New list note**
   (see [list notes](lists.md)).
3. Write in the source editor or the live (WYSIWYG) editor — switch per
   note or per library, and read the note in the read view (see
   [editing](editing.md)).
4. Organize with folders, [wikilinks](links.md), tags and frontmatter
   (see [organization](organization.md)), and let the
   [journal](journal.md) make one note a day for you.
5. Find notes with full-text [search](search.md).

## Next

- [Editing](editing.md) — Markdown, math, Mermaid diagrams, images,
  spellcheck, the read view.
- [List notes and shopping lists](lists.md) — checklists, quantities, and
  the ⋮ switch between the two.
- [Slide notes](slides.md) — a note as a deck: presented full screen, with
  speaker notes, and exported as a PDF of slides.
- [Organization](organization.md) — trash, history, templates, tags — and
  reading pictures, PDFs and books.
- [Export](export.md) — a note, a folder or the library out as Markdown,
  HTML, PDF or EPUB.
- [Journal](journal.md) — one note per day, with a calendar and a template.
- [Tasks and reminders](tasks.md) — todo.txt plus `rem:` alarms.
- [Themes](themes.md) — the shipped palettes, and a theme of your own.
- [Home-screen widgets](widgets.md) — todo and note widgets (Android).
- [Platforms](platforms.md) — Android / Linux / Windows notes.
- [Sync](sync.md) — moving a library between machines today.
