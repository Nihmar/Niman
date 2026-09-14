# Search

Full-text search across titles, body, and tags, powered by SQLite FTS5.
Designed to stay fast up to ~1M notes: queries hit the index, never a
full file scan.

## Word search

Type words; every token is matched literally (quotes, hyphens, FTS
operators in your input are text, not syntax). Only the last token gets
prefix matching, so search grows as you type.

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
