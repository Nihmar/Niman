# Search

Full-text search across titles, body, and tags, powered by SQLite FTS5.

On a wide window Search is a **sidebar view** beside the note: picking it
shows the field and the results in the left island, with the tree, the
panes and the dock where they were, and opening a result keeps the
results on screen while the note takes the pane (#712). The result you
opened stays highlighted in the list, and `F4` / `Shift+F4` step to the
next / previous one from wherever the keyboard is, wrapping at either
end. `Ctrl/⌘+Shift+F` shows the sidebar and puts the cursor in the field,
from any destination. Choosing *Files* brings the tree back. A phone
keeps Search as a tab of its own.

In the field, `↓` / `↑` move through the results without opening them and
`Enter` opens the one marked. A right click on a result opens its menu:
*Open*, *Open in new tab*, *Open to the side*, *Reveal in tree* and
*Replace in this note*; a middle click or `Ctrl`+click opens it in a new
tab. On a phone a long press gives *Replace in this note*.

**Replace all and the notes you have open.** A replace saves the notes open
with unsaved edits first, so it rewrites what you see; if one of them cannot
be saved the replace does not start. When it is done, the open notes show the
rewritten text at once — the editor never saves the old words back over it.

The index keeps the words of every note, not a copy of its text: it stays
small, whatever the size of your notes. The text shown under a result is
read from the note itself, when its row comes on screen.

A library opened for the first time shows its tree at once and reads its
notes behind it. While it does, the tree's footer counts the notes read
(*Indexing… 412 of 10000 notes*), and Search, Tags and a note's *Links to this
note* say that what they list may be incomplete. The tree's titles and pins
fill in as the notes are read.

## Word search

Type words; every token is matched literally (quotes, hyphens, FTS
operators in your input are text, not syntax). Only the last token gets
prefix matching, so search grows as you type. Accents do not matter:
`perche` finds `perché`.

A word search asks the index, so it stays fast up to ~1M notes.

## Tasks and events

A query that is one lone `+project` or `@context` (`+thesis`, `@phone`)
also answers from `todo.txt` and the library's `calendar.txt`, in a
**Tasks and events** group above the notes:

- the events whose line carries the token, with their time as written and
the day they are on;
- the week, month and year goals that carry it — `Week 42 goal`,
`October goal`;
- the open tasks that carry it, with their due date (`Due today`, `No
date`).

Each row names the day it is about and the file it comes from. Tapping one
opens it: a task opens the task list, an event or a goal opens
`calendar.txt` at its line. The group is read from the two files as they
are already in memory, never from the index, so it appears the moment you
type the token and follows the files as they change.

The notes are still searched below — `+thesis` finds the notes that say
*thesis*, in a **Notes** group of its own. Mixed input (`+thesis extra`),
a `#tag` and Contains all stay a note search.

## Contains

On a phone, **Words** and **Contains** are the two halves of the switch
under the search field. On a desktop, and wherever the search pane is
narrow, the switch is the **abc** button at the right end of the field:
lit means *Contains*, and its tooltip names the mode it is in. The field's
clear button appears to its left once something is typed, so the switch
never moves under the pointer.

**Contains** finds any piece of text, inside words too (`ell` finds
`hello`), ignoring case and accents. It reads the notes themselves, in
path order, each only as far as its first match — so it is slower than a
word search, and slower the larger the library. Typing again stops the
search in progress.

## Tag search

A lone `#tag` token searches that tag (`#work`). Mixed input
(`#work extra`) stays a word search.

## Field search

`key = value` finds notes whose frontmatter declares it:

- `status = draft`, `status=draft`
- `status =` — every note declaring the key
- `author = "Ada Lovelace"` — quote values with spaces

Matching is case-insensitive on key and value. Anything that is not
`key = value` (e.g. `x = y + 1`, a second `=`) is a plain text search.
