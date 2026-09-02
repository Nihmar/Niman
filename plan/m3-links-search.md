# M3 — Links & search

**Status:** Planned · **Depends on:** M2 · **Spec:** *Requirements* (links,
tags, search), *Milestones → M3*

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
  from a 1M-note fixture opens the right note; heading anchors land.*
- [ ] **T-M3-04** FTS5 index: `notes_fts` (design.md) created with the schema;
  indexer upserts title + body in the same transaction that writes `notes`
  (title from frontmatter when present, filename fallback). *AC: incremental
  index; delete db → rescan reproduces FTS content.*
- [ ] **T-M3-05** Search UI: query box, ranked results with path + snippet and
  match highlighting, click → open note. *AC: instant results on the 10k-note
  fixture; typing stays responsive.*
- [ ] **T-M3-06** Tag list UI: tags screen listing tags with counts
  (frontmatter + inline sources, design.md); tap tag → notes carrying it.
  *AC: inline `#tags` and frontmatter `tags:` both reflected.*
- [ ] **T-M3-07** Tests: unit (parser, resolver, FTS queries) and widget
  (search screen, link navigation). *AC: green in CI.*

## Technical design

See [design.md](design.md) → *Data model (drift)* (FTS5, tags tables). M3
slice:

- **Modules:** `links/` (parser, resolver), `search/` (search_repo,
  tag_repo), `ui/search_screen.dart`, `ui/tags_screen.dart`.
- **Resolution order:** exact unique filename → shortest unique path prefix →
  ambiguous → picker listing candidates.
- **`#heading`:** heading slug = normalized heading text; target scrolls in the
  opened note (editor + preview).
- **FTS:** external-content table kept in sync by the indexer (insert/update/
  delete triggers on index ops); queries use FTS5 match expressions with a
  small ranking; results paged.
- **Tag normalization:** lowercase, strip leading `#`; frontmatter `tags:`
  (string or list) and inline `#tag` both written to `note_tags`.

## Exit criteria

- All link forms resolve and are clickable from editor and preview.
- Search returns ranked, highlighted results instantly on a 10k-note fixture;
  the FTS index is incremental and rebuildable.
- Tag list shows counts for both tag sources; tapping filters notes.
- Unit + widget tests green in CI.

## Risks / open questions

- Filename collisions across folders — path-fallback picker needs a UI pass;
  keep M3 minimal (list + select), polish in M6.
- FTS rebuild cost at 1M notes is deferred to M6 (incremental index keeps M3
  fast; the M6 perf pass validates the gate).
- Heading slug algorithm must match across parser, editor, and preview —
  single shared implementation in `links/`.
