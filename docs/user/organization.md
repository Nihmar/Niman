# Organization: trash, history, frontmatter, tags

## Trash

Deletes go to `.trash/` (soft delete) or remove the file permanently
(hard delete), depending on the library's `trashEnabled` setting
(default true). Restore by moving the file back out of `.trash/`.

## History

Each library keeps the last N versions of every note under `.history/`
(`historyVersions`, default 10, 0–100; out-of-range values in a
hand-edited `settings.json` read back as 10). Set 0 to keep no history.
A history viewer (browse/restore) is planned
([#55](https://github.com/Nihmar/Niman/issues/55)); today, restore by
copying the wanted version back over the note.

## Frontmatter

A note may open with a YAML block:

```markdown
---
title: My note
tags: [work, urgent]
date: 2026-09-01
pinned: true
aliases: [My alias]
---
```

Any key is stored and filterable (`key = value` in search). Keys the app
acts on: `title`, `tags`, `date`, `pinned`, `aliases`. Everything else is
your own vocabulary — stored, searchable, but driving nothing.

`pinned: true` notes appear in the tree's pinned section.

## Tags

Two places, both searchable:

- Frontmatter `tags` (list or string).
- Inline `#tags` in the note body.

Search a single tag with `#tag` (see [search](search.md)).

## Folders, quick note, list notes

- Notes live in plain folders inside the library.
- **Quick note:** one tap target for scratch text. Defaults to
  `Quick note.md` at the library root; `quickNotePath` overrides it.
- **List notes:** created under `listNoteFolder` (default `Lists`).
- **Templates:** live under `templateFolder` (default `Templates`).
  See [templates](templates.md).
