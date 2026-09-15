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
  library. Each vocal carries a title and a description: the `> …`
  blockquote lines right above its embed are the title, the ones right
  under it the description (a quote run sitting between two vocals stays
  the description of the upper one). A vocal without a title reads as
  `Recording 1`, `Recording 2`, … Each vocal bubble has a round
  play/pause button, a progress track you can tap or drag to seek, and
  the elapsed and total time (WAV lengths are read from the file before
  playing; other formats show theirs once played). Its ⋮ menu — also
  opened by a long press or a right click — edits the title and the
  description, renames the audio file (updating its link) and deletes
  the vocal. Written notes are sent from the field at the bottom as
  plain lines (right bubbles); tap one to edit it, long-press or
  right-click it to delete it. The round button beside the field is the
  microphone while the field is empty and becomes send as soon as you
  type; the paperclip inside the field attaches an audio file. While
  recording, the field shows a red bar with the elapsed time, a pause
  button (the clock holds and the dot breathes until you resume) and a
  discard button, and the round button stops and saves; the bar reads
  `Saving…` until the new vocal is in the note. Recording
  writes WAV (PCM 16-bit: playable on Android, Linux and Windows with no
  extra codec); attaching keeps the file's own format (`.mp3`, `.m4a`,
  `.ogg`, `.opus`, `.aac`, `.flac`, …). On Linux recording needs
  `pulseaudio-utils` and `ffmpeg` installed.
- **Templates:** live under `templateFolder` (default `Templates`).
  See [templates](templates.md).
