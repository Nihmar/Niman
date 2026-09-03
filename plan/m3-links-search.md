# M3 — Links & search

**Status:** Planned · **Depends on:** M2 (and on the stable row ids from
M1.5) · **Spec:** *Requirements* (links, tags, search), *Milestones → M3*

## Purpose

Navigation and retrieval: wikilink + standard Markdown links that resolve and
are clickable, FTS5 full-text search (title + body) with an instant results
UI, and the tag list.

## Current state

M2 edits/preview notes; links are inert text; no search, no tag list.

## Tasks

- [ ] **T-M3-01** Link parser: `[[wiki]]`, `[[wiki|alias]]`, `[[wiki#heading]]`
  plus standard Markdown links; extracted from the note during indexing and on
  edit. *AC: unit tests cover all four forms + edge cases (empty, unicode).*
- [ ] **T-M3-02** Link resolution: by unique filename first, path fallback on
  ambiguity; a resolution index (filename → note) maintained by the indexer.
  Alias-field resolution hooks in now (aliases land in M4). *AC: resolves in
  O(1) on the index; ambiguous names disambiguated by path.*
- [ ] **T-M3-03** Click-to-navigate: editor link tap and preview link render →
  open target note (heading anchor scrolls to the heading). *AC: navigating
  opens the right note on the 10k-note fixture and heading anchors land;
  the 1M fixture is M6's gate, not this one.*
- [ ] **T-M3-04** FTS5 index: create `notes_fts` per the schema settled
  in design.md — a standalone table holding its own copy of title and
  body, `rowid` = `notes.id`, `unicode61 remove_diacritics 2` — in a
  drift migration, and have the indexer write its rows in the same
  transaction that writes `notes` (title from frontmatter when present,
  filename fallback). Only notes whose content actually changed are read;
  reading happens on the isolate that already hashes them, returning
  digest and text from one read, in batches of a couple of hundred notes.
  *AC: incremental index, no full body re-read on an unchanged rescan;
  a rename touches no FTS row; delete db → rescan reproduces FTS content.*
- [ ] **T-M3-05** Search UI: query box debounced (~150 ms), ranked
  results with path + snippet and match highlighting, paging, results of
  a superseded query dropped, click → open note. Includes the toggle
  between the two modes of T-M3-08. *AC: instant results on the 10k-note
  fixture; typing stays responsive.*
- [ ] **T-M3-06** Tag list UI: tags screen listing tags with counts
  (frontmatter + inline sources, design.md); tap tag → notes carrying it.
  *AC: inline `#tags` and frontmatter `tags:` both reflected.*
- [ ] **T-M3-07** Tests: unit (parser, resolver, FTS queries, MATCH and
  LIKE building against inputs containing quotes, hyphens, parentheses
  and wildcards) and widget (search screen in both modes, link
  navigation). *AC: green.*
- [ ] **T-M3-08** Substring search: an explicit "contains" mode beside
  the word search, scanning the text the index already holds with `LIKE`
  rather than reopening note files — one database file in internal
  storage, so nothing goes through FUSE. Results in path order, excerpt
  cut around the first match in Dart (`snippet()` only works with
  `MATCH`), pattern escaped with the existing `_sqlLikeEscape` in
  `db/dao.dart`. *AC: `ell` finds `hello` in this mode and nothing in
  word mode; the mode is visible in the UI, never a silent fallback.*

## Technical design

See [design.md](design.md) → *Data model (drift)* (FTS5, tags tables). M3
slice:

- **Modules:** `links/` (parser, resolver), `search/` (query,
  search_repo, tag_repo), `ui/search_screen.dart`, `ui/tags_screen.dart`.
- **Resolution order:** exact unique filename → shortest unique path prefix →
  ambiguous → picker listing candidates.
- **`#heading`:** heading slug = normalized heading text; target scrolls in the
  opened note (editor + preview).
- **FTS:** kept in sync by the indexer on index ops; see design.md for
  the table. Note that the indexer only became capable of incremental row
  updates in M1.5 — before that it deleted and re-inserted the whole
  table, which would have rebuilt the entire FTS content on every scan.
- **Query building** (`search/query.dart`): user text is not an FTS5
  expression. Split on whitespace, quote each token doubling internal
  quotes, append `*` to the last token only so results narrow while
  typing, and treat empty input as no query rather than as "match
  everything". Otherwise a stray `-` or `(` is a syntax error.
- **Ranking:** `bm25(notes_fts, 10.0, 1.0)` weights the title ten times
  the body and returns lower values for better matches, so ascending
  order is the ranking.
- **Tag normalization:** lowercase, strip leading `#`; frontmatter `tags:`
  (string or list) and inline `#tag` both written to `note_tags`.

## Exit criteria

- All link forms resolve and are clickable from editor and preview.
- Search returns ranked, highlighted results instantly on a 10k-note fixture;
  the FTS index is incremental and rebuildable.
- Contains mode finds matches inside words, and says it is doing so.
- Tag list shows counts for both tag sources; tapping filters notes.
- Unit + widget tests green.

## Risks / open questions

- Filename collisions across folders — path-fallback picker needs a UI pass;
  keep M3 minimal (list + select), polish in M6.
- FTS rebuild cost at 1M notes is deferred to M6 (incremental index keeps M3
  fast; the M6 perf pass validates the gate). The first build over an
  existing library still reads every note once — the same problem as
  T-M6-11, whose progress mechanism it should reuse.
- Contains mode is a scan bounded by the total text: instant on a normal
  library, seconds at a million notes. If the M6 gate rejects it, the
  additive fix is a second FTS5 table with the `trigram` tokenizer, which
  indexes substrings at two to three times the text on disk. That is why
  the cost is not paid up front.
- Heading slug algorithm must match across parser, editor, and preview —
  single shared implementation in `links/`.
