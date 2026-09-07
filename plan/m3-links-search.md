# M3 — Links & search

**Status:** Planned (plan of record updated 2026-09-06 — task order
re sequenced, decisions locked in *Decisions* below) · **Depends on:** M2
(and on the stable row ids from M1.5) · **Spec:** *Requirements* (links,
tags, search), *Milestones → M3*

## Purpose

Navigation and retrieval: wikilink + standard Markdown links that resolve and
are clickable, FTS5 full-text search (title + body) with an instant results
UI, and the tag list.

## Current state

M2 edits/previews notes; links are inert text; no search, no tag list.
`re_editor` 0.10.0 exposes **no public position-at-point API**
(`setPositionAt` is on a private render object), which shapes T-M3-07's
editor tap. The tokenizer (`editor/highlighting.dart`) already emits
`wikilink`/`_link`/`_image` token ranges per line (pure Dart — reusable on
the index isolate), `NoteView` already owns the editor scroll map + outline
jump and the preview scroll map, and `MarkdownPreview.onTapLink` exists but
is **not wired**.

## Decisions (locked 2026-09-06)

1. **Frontmatter in M3 is a minimal reader** (`frontmatter/parser.dart`,
   key:value YAML): title, tags, aliases only. M4's T-M4-01 replaces it with
   the `yaml` package and adds the full `frontmatter_fields` table; the M3
   reader writes no fields table — title → FTS, tags → `note_tags`,
   aliases → `note_stems` (source `alias`).
2. **Editor link taps = desktop Ctrl+click only.** On tap the caret lands
   under the pointer, so the event handler reads
   `controller.selection.extentIndex` and looks the token range up in
   `HighlightSync` (new `tokensOf(line)` accessor). Mouse-style taps on
   mobile/tablet stay edit-only — navigation there is the preview tap.
3. **http/https links open externally** via `url_launcher` (added in
   T-M3-07); in-library `.md` links navigate in-app.
4. **Two screens, two shell action icons**: `SearchScreen` and
   `TagsScreen`.
5. **`note_links` is written at index time** (resolved edges only:
   from/to note ids + kind `wiki|md`; unresolved links are skipped — a
   dead-link UI is future work). M4's aliases join the same
   `note_stems` index.

## Tasks

- [x] **T-M3-01** Link parser + heading slug: `[[wiki]]`, `[[wiki|alias]]`,
  `[[wiki#heading]]`, `[[#heading]]`, `[[|alias]]` plus standard Markdown
  links `[text](href)`, and the shared heading slug algorithm (single
  implementation in `links/` — parser, editor and preview agree on it).
  *AC: unit tests cover all forms + edge cases (empty, unicode, unclosed);
  the slug matches the same heading in editor, outline, and preview.*
- [x] **T-M3-02** Schema v6 (all M3 tables) + resolution: `note_stems`,
  `tags`, `note_tags`, `note_links` (drift) and `notes_fts`
  (`CREATE VIRTUAL TABLE … fts5(title, body, tokenize = 'unicode61
  remove_diacritics 2')`, raw SQL — no drift class; rowid = `notes.id`);
  `links/resolver.dart` resolves exact stem → unique? shortest unique path
  prefix → ambiguous picker (minimal list + select, polish M6). Indexer
  fills `note_stems` on insert/rename/delete. *AC: resolves in O(log n) on
  the index; ambiguous names disambiguated by path; a rename moves the
  stem rows; migration v5→v6 keeps app_settings rows.*
- [x] **T-M3-03** Indexer content pipeline: one isolate read per *changed*
  note returns digest **and** text; parse frontmatter (title/tags/aliases,
  `frontmatter/parser.dart`) and inline `#tags` (skip fences/math — reuse
  `HighlightDocument`) on that isolate; one transaction writes notes rows +
  FTS upsert (`UPDATE notes_fts SET title, body WHERE rowid = ?` via
  raw SQL) + `note_tags` delete+insert + `note_links` (resolved after the
  notes rows are committed — links inside one scan can point at notes
  indexed later in the same walk) + stems. `deleteSubtree` extends to
  wipe dependent rows (FTS by rowid, stems/tags/links by note id) in the
  same transaction. *AC: incremental — unchanged rescan reads no body
  (FTS/tags rewritten only when the digest changed; a rename-with-unchanged-
  content touches no FTS row); delete db → rescan reproduces FTS, tags,
  stems and links; content reads batched a few hundred per isolate call.*
- [x] **T-M3-04** Search data side: `search/query.dart` (user text is never
  an FTS expression — split on whitespace, quote each token doubling
  internal quotes, append `*` to the last token only, empty input = no
  query), `search/search_repo.dart` (words: `bm25(notes_fts, 10.0, 1.0)`
  ascending + `snippet()`; tags: `#tag` answered from
  `tags`/`note_tags`, never FTS; superseded-query guard by invocation
  id). *AC: unit tests over inputs with quotes, hyphens, parentheses,
  wildcards, empty; MATCH vs LIKE behaviors.*
- [x] **T-M3-05** SearchScreen: query box debounced (~150 ms), ranked
  results with path + snippet and match highlighting, paging, results of a
  superseded query dropped, click → open note. Includes the word/contains
  toggle (T-M3-08). *AC: instant results on the 10k-note fixture; typing
  stays responsive.*
- [ ] **T-M3-06** TagsScreen: tag list with counts (frontmatter + inline
  sources), tap tag → notes carrying it (join `notes`, path order) → open.
  *AC: inline `#tags` and frontmatter `tags:` both reflected; tag
  normalization (lowercase, strip leading `#`).*
- [ ] **T-M3-07** Click-to-navigate: wikilinks render clickable in the
  preview (custom inline syntax + element builder — the math pipeline's
  pattern) and `onTapLink` is wired (`…md` relative → in-app,
  http(s) → `url_launcher`); editor desktop Ctrl+click (Listener around
  `NoteEditor`, pointer kind = mouse, caret-at-token check via
  `HighlightSync.tokensOf`); heading anchors (`[[x#Heading]]`) jump to the
  heading — editor outline jump + preview scroll-map block. Shell wiring:
  `NoteView.onOpenNote(relPath, {anchor})` — wide: select + expand in the
  tree; phone: push the note screen; unresolved link → snackbar (strings in
  `strings.dart`). *AC: navigating opens the right note on the 10k-note
  fixture; heading anchors land; external links launch the browser.*
- [ ] **T-M3-08** Contains mode: explicit "contains" search beside word
  search, scanning the index's own copy of the text with `LIKE` (pattern
  escaped with the existing `_sqlLikeEscape` in `db/dao.dart`), results in
  path order, excerpt cut around the first match in Dart (`snippet()` only
  works with `MATCH`). Mode visible in the UI, never a silent fallback.
  *AC: `ell` finds `hello` in contains mode and nothing in word mode.*
- [ ] **T-M3-09** Tests + verification: unit (parser, slug, resolver,
  query builder, FTS incremental/rebuild/cascade, tag normalization, v6
  migration); widget (search screen both modes + debounce + supersede,
  preview link tap, editor Ctrl+click, anchor landing, tags counts + tap);
  perf-ish: 10k-note fixture built on the fly in `setUpAll` (temp dir
  walk + index, generous latency assertion). On-device pass on the real
  library (index build + search latency + tag list). *AC: green; release
  builds rebuilt and reported after the milestone.*

## Technical design

See [design.md](design.md) → *Data model (drift)* (FTS5, tags tables —
`note_stems` and `note_links` added there for M3). M3 slice:

- **Modules:** `links/` (parser, resolver, slug), `search/` (query,
  search_repo, tag_repo), `frontmatter/` (minimal reader), `ui/`
  (search_screen, tags_screen). Runs with the M2 stack (drift 2.34 +
  sqlite3_flutter_libs — FTS5 on Android/Windows; Linux uses the system
  sqlite3, also FTS5-enabled distributions; verified at T-M3-02).
- **Resolution order:** exact stem (unique) → shortest unique path prefix →
  ambiguous picker listing candidates. `note_stems` holds filename stems
  and alias rows (source column `file|alias`); resolution is a
  `COLLATE NOCASE` lookup + `notes.path` prefix filter.
- **`#heading`:** heading slug = normalized heading text (shared
  implementation); target scrolls in the opened note (editor + preview).
- **FTS:** kept in sync by the indexer (T-M3-03); `rowid` = `notes.id`,
  no path column, so a rename touches no FTS row. Delete = plain
  `DELETE FROM notes_fts WHERE rowid IN (…)` (verify FTS5 rowid DELETE —
  normal DML is supported on the virtual table) in the note's delete
  transaction.
- **Indexer sequencing:** phase A = walk + `(size, mtime)` change decision;
  phase B = batched isolate reads returning digest+text (one read per
  changed note — never re-read unchanged ones); phase C = write
  (transactions): notes rows → resolve links against the now-current
  index → FTS/tags/stems/links rows.
- **Ranking:** `bm25(notes_fts, 10.0, 1.0)` weights title ten times body,
  lower is better, ascending order.
- **Tag normalization:** lowercase, strip leading `#`; frontmatter `tags:`
  (string or list, minimal reader) and inline `#tag` (scanner skipping
  code fences/math — `HighlightDocument`) both land in `note_tags`.

## Exit criteria

- All link forms resolve and are clickable from editor (desktop Ctrl+click)
  and preview; heading anchors land; external links open the browser.
- Search returns ranked, highlighted results instantly on a 10k-note fixture;
  the FTS index is incremental and rebuildable.
- Contains mode finds matches inside words, and says it is doing so.
- Tag list shows counts for both tag sources; tapping filters notes.
- Unit + widget tests green; release builds rebuild clean after the
  milestone.

## Risks / open questions

- **re_editor has no position-at-point API** — Ctrl+click works because the
  caret lands under the pointer (the package's own tap handling sets it).
  Verify this assumption with a widget test early in T-M3-07; if the caret
  doesn't track the click on some platform, fall back to the caret
  position after a plain Ctrl+click read of `selection.extentIndex`
  (same mechanism), or scope editor navigation to the preview-only on
  that platform.
- Filename collisions across folders — path-fallback picker needs a UI pass;
  keep M3 minimal (list + select), polish in M6.
- FTS rebuild cost at 1M notes is deferred to M6 (incremental index keeps M3
  fast; the first build over an existing library still reads every note
  once — the same problem as T-M6-11, whose progress mechanism it should
  reuse).
- Contains mode is a scan bounded by the total text: instant on a normal
  library, seconds at a million notes. If the M6 gate rejects it, the
  additive fix is a second FTS5 table with the `trigram` tokenizer. The
  cost is not paid up front.
- **FTS5 availability check** (T-M3-02): the unit test suite runs on the
  host sqlite3 — confirm FTS5 is compiled in there and on-device
  (sqlite3_flutter_libs) before wiring the whole indexer; if a host
  sqlite3 lacks FTS5, the tests pin `sqlite3_flutter_libs` or run
  against it.
- `note_links` stores resolved edges only — a broken-link indicator and
  references/backlinks UI stay future work (vocabulary: "references").
