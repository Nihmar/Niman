# M4 — Frontmatter & templates

**Status:** Planned · **Depends on:** M3 · **Spec:** *Requirements*
(frontmatter, templates), *Milestones → M4*

## Purpose

YAML frontmatter parsed, indexed, and editable; known fields driving the UI
(title, tags, date, pinned, aliases); any other key indexed and filterable.
Plus the template system: configurable template folder, placeholder engine,
and create-from-template with frontmatter merge.

## Current state

M3 indexes files but ignores frontmatter; new notes are created blank.

## Tasks

- [ ] **T-M4-01** Frontmatter parser: general YAML in a leading `---` block;
  tolerant validation (unknown keys OK, malformed YAML surfaced to the user).
  Parsed at index time and on edit (debounced). *AC: unit tests over valid,
  empty, and malformed frontmatter.*
- [ ] **T-M4-02** `frontmatter_fields` index (design.md): all keys stored;
  known fields — `title`, `tags`, `date`, `pinned`, `aliases` — extracted and
  used: title overrides the display name, aliases join the link-resolution
  index (T-M3-02 hook), date shown in tree, pinned drives the pinned section.
  *AC: change a frontmatter key → index updates in one watcher cycle.*
- [ ] **T-M4-03** Arbitrary-key filtering: any frontmatter key queryable
  (filter notes by `key = value` in the search UI). *AC: filter by a
  non-standard key works.*
- [ ] **T-M4-04** Pinned section in the sidebar tree (pinned notes at top,
  independent of folder location). *AC: pin/unpin toggles the section.*
- [ ] **T-M4-05** Template repo: configurable template folder (default
  `Templates/`, library setting); list templates from it. *AC: renaming the
  folder in settings changes the source.*
- [ ] **T-M4-06** Placeholder engine: `{{title}}`, `{{date:YYYY-MM-DD}}`
  (format extensible), `{{time}}`, `{{now}}`, `{{uuid}}`. *AC: unit tests per
  placeholder incl. timezones/locales sanity (local time).*
- [ ] **T-M4-07** Create-from-template: from the tree/new-note flow — pick a
  template, placeholders substituted, template frontmatter (after
  substitution) merged into the new note's frontmatter. *AC: new note carries
  substituted content + frontmatter; editor opens it.*
- [ ] **T-M4-08** Tests: unit (parser, placeholder engine, frontmatter merge,
  pinned logic) and widget (template dialog, pinned section). *AC: green in
  CI.*

## Technical design

See [design.md](design.md) → *Data model (drift)* (`frontmatter_fields`),
*Module layout* (`frontmatter/`, `templates/`). M4 slice:

- **YAML:** `yaml` package (add to deps in T-M4-01); frontmatter = text
  between the first two `---` lines; edited in the source editor as plain
  text (it is part of the file) with parse feedback, no separate form UI.
- **Field extraction:** `tags` (string or list), `title` (string), `aliases`
  (list), `pinned` (bool), `date` (ISO date); others kept as-is.
- **Link index join:** `aliases` + filename → resolution index used by T-M3-02.
- **Template engine:** string substitution, no full template language;
  `{{date:FMT}}` uses a small format map (default `YYYY-MM-DD`); `{{now}}` =
  local datetime; `{{uuid}}` = v4 (crypto RNG).
- **Merge rule:** new note has no frontmatter of its own; the template's
  frontmatter (substituted) becomes the note's frontmatter.

## Exit criteria

- Frontmatter is parsed and indexed on a mixed library (known + unknown keys);
  title/pinned/aliases visibly work in tree, links, and display.
- Templates: folder configurable, placeholders substitute correctly,
  create-from-template produces a valid note with merged frontmatter.
- Unit + widget tests green in CI.

## Risks / open questions

- Frontmatter-heavy large files: parse cost is small (leading block only) —
  no expected risk; verify on M6 fixture.
- `{{date}}` formatting scope: keep to the spec list; a full date-format
  language is out of scope.
- Template folders inside `.trash`/`.history`: excluded by indexer rules
  (existing), confirm with tests.
