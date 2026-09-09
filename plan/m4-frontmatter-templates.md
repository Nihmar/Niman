# M4 — Frontmatter & templates

**Status:** Done · **Depends on:** M3 · **Spec:** *Requirements*
(frontmatter, templates), *Milestones → M4*

## Purpose

YAML frontmatter parsed, indexed, and editable; known fields driving the UI
(title, tags, date, pinned, aliases); any other key indexed and filterable.
Plus the template system: configurable template folder, placeholder engine,
and create-from-template with frontmatter merge.

## Current state

Built. The frontmatter block is real YAML, every key is indexed and
filterable, the tree shows titles/dates and a pinned section, and notes
can be created from templates in a configurable folder.

## Tasks

- [x] **T-M4-01** Frontmatter parser: general YAML in a leading `---` block;
  tolerant validation (unknown keys OK, malformed YAML surfaced to the user).
  Parsed at index time and on edit (debounced). *AC: unit tests over valid,
  empty, and malformed frontmatter.*
- [x] **T-M4-02** `frontmatter_fields` index (design.md): all keys stored;
  known fields — `title`, `tags`, `date`, `pinned`, `aliases` — extracted and
  used: title overrides the display name, aliases join the link-resolution
  index (T-M3-02 hook), date shown in tree, pinned drives the pinned section.
  *AC: change a frontmatter key → index updates in one watcher cycle.*
- [x] **T-M4-03** Arbitrary-key filtering: any frontmatter key queryable
  (filter notes by `key = value` in the search UI). *AC: filter by a
  non-standard key works.*
- [x] **T-M4-04** Pinned section in the sidebar tree (pinned notes at top,
  independent of folder location). *AC: pin/unpin toggles the section.*
- [x] **T-M4-05** Template repo: configurable template folder (default
  `Templates/`, library setting); list templates from it. *AC: renaming the
  folder in settings changes the source.*
- [x] **T-M4-06** Placeholder engine: `{{title}}`, `{{date:YYYY-MM-DD}}`
  (format extensible), `{{time}}`, `{{now}}`, `{{uuid}}`. *AC: unit tests per
  placeholder incl. timezones/locales sanity (local time).*
- [x] **T-M4-07** Create-from-template: from the tree/new-note flow — pick a
  template, placeholders substituted, template frontmatter (after
  substitution) merged into the new note's frontmatter. *AC: new note carries
  substituted content + frontmatter; editor opens it.*
- [x] **T-M4-08** Tests: unit (parser, placeholder engine, frontmatter merge,
  pinned logic) and widget (template dialog, pinned section). *AC: green.*

## Technical design

See [design.md](design.md) → *Data model (drift)* (`frontmatter_fields`),
*Module layout* (`frontmatter/`, `templates/`). M4 slice:

- **YAML:** `yaml` package (added in T-M4-01); frontmatter = text between
  the first two `---` lines; edited in the source editor as plain text (it
  is part of the file) with parse feedback, no separate form UI.
- **Field extraction:** `tags` (string or list), `title` (string), `aliases`
  (list), `pinned` (bool), `date` (ISO date); others kept as-is.
- **Link index join:** `aliases` + filename → resolution index used by T-M3-02.
- **Template engine:** string substitution, no full template language;
  `{{date:FMT}}` uses a small format map (default `YYYY-MM-DD`); `{{now}}` =
  local datetime; `{{uuid}}` = v4 (crypto RNG).
- **Merge rule:** new note has no frontmatter of its own; the template's
  frontmatter (substituted) becomes the note's frontmatter.

## What was built differently

- **`frontmatter_fields` is keyed on (note, key, value)**, not the
  UNIQUE(note_id, key) the design sketched. A key whose value is a list is
  one field with several values, and `projects = alpha` has to match a note
  that lists alpha among others — one row per key cannot say that.
- **Three known fields are also columns on `notes`** (`title`, `date`,
  `pinned`). The tree reads them for every visible row on every paint, and a
  join per paint is a cost it does not have to pay. The table still holds
  them, so a filter treats them like any other key.
- **The index file goes to schema 2 by being wiped.** Every row in it is
  derived from disk, so dropping the tables and letting the next scan refill
  them costs a walk and saves a migration chain for a cache.
- **Two YAML behaviours changed with the real parser:** a bare `#tag` inside
  a flow list is a comment (quote it), and a duplicate key is an error rather
  than first-wins. `tags: a, b` still splits on commas, because that is what
  people write; the same applies to `aliases` and to nothing else.
- **Pinning writes the note's own frontmatter**, edited on lines rather than
  by re-emitting YAML, so comments, key order and spacing survive. Unpinning
  removes the key and an emptied block with it.
- **The editor shows the parse error** (T-M4-01's "surfaced to the user"):
  a line above the status row carrying the parser's message, on the stats
  debounce.
- **No merge was needed at creation.** The design's own rule is that a new
  note has no frontmatter of its own, so the template's block becomes the
  note's block whole; `frontmatter/edit.dart` holds the set/remove helpers
  the pin flow needs and any later merge would build on.

## Exit criteria

- [x] Frontmatter is parsed and indexed on a mixed library (known + unknown
  keys); title/pinned/aliases visibly work in tree, links, and display.
- [x] Templates: folder configurable, placeholders substitute correctly,
  create-from-template produces a valid note with merged frontmatter.
- [x] Unit + widget tests green.

## Risks / open questions

- Frontmatter-heavy large files: parse cost is small (leading block only) —
  the block scan reads to the closing fence instead of splitting the note,
  so it is safe on the editor's per-edit path too.
- `{{date}}` formatting scope: kept to the spec list plus quoting for
  literal text; a full date-format language is out of scope.
- Template folders inside `.trash`/`.history`: excluded by the indexer's
  hidden-entry rule, confirmed by a test in `template_repo_test.dart`.
