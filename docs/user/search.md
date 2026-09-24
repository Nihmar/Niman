# Search

Full-text search across titles, body, and tags, powered by SQLite FTS5.

The index keeps the words of every note, not a copy of its text: it stays
small, whatever the size of your notes. The text shown under a result is
read from the note itself, when its row comes on screen.

## Word search

Type words; every token is matched literally (quotes, hyphens, FTS
operators in your input are text, not syntax). Only the last token gets
prefix matching, so search grows as you type. Accents do not matter:
`perche` finds `perché`.

A word search asks the index, so it stays fast up to ~1M notes.

## Contains

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
