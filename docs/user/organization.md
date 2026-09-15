# Organization: trash, history, frontmatter, tags

## Trash

Deletes go to `.trash/` (soft delete) or remove the file permanently
(hard delete), depending on the library's `trashEnabled` setting
(default true). Restore by moving the file back out of `.trash/`.

## History

Niman keeps past versions of every note under `.history/`, so an edit
you regret can be undone.

**When a version is kept.** A version is the text a save is about to
replace — never a copy of what is already on screen:

- when you start editing a note (the note as it was before you touched
  it);
- while you write, at most once every few minutes
  (`historyIntervalMinutes`, default 5);
- right before a restore, before a library-wide replace, and (with sync)
  before a download overwrites the note.

A version identical to the newest one is not kept twice, and an empty
note (one just created) has nothing to keep. Autosave runs
every half second, so without the interval ten versions would last five
seconds.

**How many.** The last `historyVersions` versions per note (default 10;
0 keeps none). Older ones are dropped as new ones arrive. Both settings
live in **Settings → Library** and in `.niman/settings.json`;
out-of-range values in a hand-edited file read back as the defaults.

**Browse and restore.** Long-press a note in the tree (right-click on
desktop) or open the note's ⋮ menu and pick **History**. Versions are
listed newest first, grouped by day, each with why it was kept and how
many lines differ from the note as it is now (`+` added since, `−`
gone since) — the same comparison the version opens on. Open one to see what changed against
the current note (removed lines in red, added in green; tap a folded
row to show the unchanged lines) or to read its whole text. **Restore
this version** keeps the current text as a version first, then puts the
old one back — the snackbar's **Undo** swaps them again.

**Following the note.** Renaming or moving a note (or its folder) moves
its history too. A note in the trash keeps its history until the trash
is emptied or the item deleted for good; a hard delete (trash off)
removes it at once.

**On disk.** `.history/<path>.v<n>` holds each version byte for byte,
and `.history/<path>.json` lists them (time, reason, size, hash). The
folder is plain files: if the list is lost it is rebuilt from the
version files. It is never indexed, searched, or synced.

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
acts on: `title`, `tags`, `date`, `pinned`, `aliases`, `type` (`list`
shows the checklist, `audio` shows the recordings). Everything else is
your own vocabulary — stored, searchable, but driving nothing.

`pinned: true` notes appear in the tree's pinned section.

## Tags

Two places, both searchable:

- Frontmatter `tags` (list or string).
- Inline `#tags` in the note body.

Search a single tag with `#tag` (see [search](search.md)).

## Folders, quick note, list notes, voice notes

- Notes live in plain folders inside the library.
- **Quick note:** one tap target for scratch text. Defaults to
  `Quick note.md` at the library root; `quickNotePath` overrides it.
- **List notes:** created under `listNoteFolder` (default `Lists`).
- **Voice notes:** a note with `type: audio` frontmatter shows a chat
  instead of the editor — vocals on the left, written notes on the
  right. Record (or attach) appends a vocal; clips are plain audio
  files under the attachments folder
  (`attachmentsFolder`, default `assets`), content-addressed like images
  and linked in the library's link format (`![[…]]` for wikilink
  libraries, `![](…)` for Markdown ones), so they travel with the
  library. Each vocal carries a description: the `> …` blockquote lines
  right under its embed in the `.md`, shown as a bubble under the vocal
  and editable from the page. The input field sends written notes as
  plain lines (right bubbles). The rename action renames the audio file
  and updates its link. Recording writes WAV (PCM 16-bit: playable on Android,
  Linux and Windows with no extra codec); attaching keeps the file's own
  format (`.mp3`, `.m4a`, `.ogg`, `.opus`, `.aac`, `.flac`, …). On Linux
  recording needs `pulseaudio-utils` and `ffmpeg` installed. While
  recording, a red `Recording…` hint shows above the input.
- **Templates:** live under `templateFolder` (default `Templates`).
  See [templates](templates.md).
