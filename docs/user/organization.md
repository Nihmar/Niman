# Organization: trash, history, frontmatter, tags

## Trash

Deletes go to `.trash/` (soft delete) or remove the file permanently
(hard delete), depending on the library's `trashEnabled` setting
(default true). Restore by moving the file back out of `.trash/`.

**Emptying it on its own.** *Settings → Auto-empty trash* is **Never**
until you set it: pick a wait (a week, a month, a year) and every
deletion that has sat in `.trash/` longer than that is deleted for good
the next time the library opens. It happens quietly and there is no
undo, which is why nothing is deleted until you choose a wait. Only what
Niman put in the trash is counted — a file you moved into `.trash/`
yourself carries no deletion date and is left where it is.

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

## Moving a note or a folder

Long-press a row in the tree (right-click on desktop) and pick **Move**.
The dialog lists the library root and every folder, one radio each, the
same way the folder settings ask for a folder — and, like them, it has a
**New folder** button, so a note can be moved somewhere that does not
exist yet without leaving the dialog. A folder is never offered itself
or anything inside it as a target.

## Opening a note outside Niman

A note is also a file, and sometimes you want it where Niman is not: to
attach it to a mail, to drag it somewhere, to open it in another editor.
Long-press a note in the tree (right-click on desktop) and pick:

- **Show in file manager** — opens the note's folder with the note
  itself selected. On Windows that is Explorer; on Linux it is whichever
  file manager answers the freedesktop interface (Nautilus, Dolphin,
  Nemo, Thunar, …), falling back to just opening the folder when none
  does.
- **Open in default app** — hands the `.md` to whatever application the
  system opens Markdown with, or to the default text editor when
  nothing claims `.md`.

Both entries are desktop only (Linux and Windows) and appear on notes,
not on folders. Neither changes the note or moves anything: if the file
is not on disk, or the system refuses to open it, Niman says so and the
note stays exactly as it was.

### Files that are not notes

The tree also shows the files that are not text — the images and audio
clips in the attachments folder, a PDF or an e-book dropped into the
library.

- **Pictures** (PNG, JPEG, GIF, WebP, BMP) and **PDFs** open in the note
  pane, on every platform: a picture fitted to the pane, zoomed with a
  pinch or the mouse wheel and dragged around; a PDF page after page,
  zoomed the same way. The row under them names the file and, on
  desktop, offers **Open in default app**.
- The row under a PDF or a book has a **link** button: it copies a link
  to the place being read, to paste into a note (see
  [links](links.md#links-into-a-pdf-or-a-book)).
- **A PDF or a book opens where you left it**: its page, or its chapter
  and the line in it, is kept for the library in `.niman/reading.json`
  and syncs with it, so a book put down on the phone opens on the
  desktop where the phone stopped. Only reading moves it: opening a
  book and closing it again changes nothing. A file moved or renamed in
  Niman, or a folder holding it, keeps its place.
- **EPUB books** open in the note pane too, on every platform, and read
  like a note, in the note column. The book's own styles are not used —
  its headings, emphasis, lists, quotes, tables and pictures are, in
  Niman's typography. The **Outline** button on the row below lists the
  book's table of contents, the chapter being read marked, and jumps to
  the entry picked; a link inside the book jumps within it, a web link
  opens in the browser.
- Books have **a look of their own**, apart from the notes: the **Aa**
  button on the book's row opens it, and so does Settings → Appearance →
  **Book appearance**, on the same values. **Theme** is any of the app's
  themes, your own included, or *Same as the app*; **Brightness** is
  light, dark, the system's, or the app's; the **font** is Literata (a
  typeface made for reading on screen, shipped with Niman, the same on
  every platform), the system's serif, the app's own sans serif, or
  monospace; **Text size** shows on the book as the slider moves. Every
  choice applies at once to every book of the library, and is kept per
  library on this device, like the note text size. A fresh library reads
  its books in Literata, in the app's colours.
- **Anything else** (an audio clip, an archive) does not go
  in the editor: the pane says the file is not a text note, and on
  desktop offers **Open in default app** right there.

### Annotating a PDF or a book

A PDF or a book is annotated in a note of its own, its **companion
note**, without leaving the file:

- In a book, **select a passage** — long-press a word and drag the
  handles on a phone; drag with the mouse on desktop, where a double
  click selects a word and a triple click a paragraph — and pick
  **Annotate** in its menu; the same menu copies the text, or a link to
  the passage (on a phone, behind ⋮). The **annotate** button on the
  book's row annotates the passage selected, or the paragraph at the top
  of the view when nothing is.
- In a PDF, **select a passage** and pick **Annotate** in its menu. The
  **annotate** button on the PDF's row annotates the passage selected,
  or the page being read when nothing is — a scanned PDF has no text to
  select.

A sheet (a dialog on a wide window) shows the place and the passage and
takes your comment, which may stay empty. **Save** writes it and leaves
you where you were; the message that says so offers **Open note**, which
opens the companion at the annotation.

Each annotation is a section of the companion: a heading naming the
place, the passage quoted with a link back to it, and your comment:

```markdown
## Dune, p. 34

> The spice must flow.
> — [[Books/Dune.pdf#page=34&chars=120-180|Dune, p. 34]]

Remember this.
```

The link goes back to the passage (see [links](links.md#links-into-a-pdf-or-a-book)),
so you can go back and forth between the file and the note. The note's
outline is the list of its annotations.

The file shows where it was annotated: in a book, the annotated
paragraph is tinted as a highlighter marks it; in a PDF, the passage is,
and a page annotated as a whole wears a note button at its top right
corner. **Tap a mark** to open its annotation in the companion note;
where several annotate the same place, a sheet asks which. The marks are
read from the companion notes: edit or delete an annotation there, and
the file follows.

A companion is a plain note that names its file in its frontmatter,
`annotates: "[[Books/Dune.pdf]]"` — not by its name or its folder: it can
live anywhere and be renamed, and you can write one by hand. The first
annotation of a file that has none makes one in the **annotations folder**
(Settings → Folders and paths, `Annotations` by default), named after the
file: `Dune - Annotation.md`. Later ones are added at its end. A file with
several companions gets its annotations in the first, by path.

Nothing is written to such a file, ever — it is never reported as saved,
because there is nothing of it in the editor to save. A picture, a PDF or
a book is shown, not edited, so the editor's controls are not offered
around it: no editor/preview switch, and its ⋮ menu (on a phone) keeps
the file's own actions — rename, move, delete — without the outline,
tags, typewriter, **Tidy Markdown**, cheatsheet or history. The palette
leaves those commands out too.

## Opening a file outside any library

Not every Markdown file belongs in a library: a project's README, a
draft from another app, a downloaded article. On Linux and Windows,
**Open file** (`Ctrl+Shift+O`, or *Note: Open file…* in the command
palette) opens one on its own, with Niman's editor and nothing else. The
screen that opens a library offers the same button, so no library is
needed at all. Double-clicking a `.md` file in the file manager does the
same once Niman is its app (see [platforms](platforms.md)), and so does
`niman <file>` on the command line.

The file gets the editor, both of them, and the preview. It gets none of
what a library adds:

- **Saved where it is**, as it is. Nothing is written beside it.
- **Not indexed**: search, tags and backlinks never see it.
- **No history, no sync, no trash.**
- **Links shown, not followed** into a library. Its frontmatter is text:
  a `type:` in it draws no list.
- **No image button**: there is no attachments folder to copy an image
  into. Images next to the file still show in the preview.

It opens over whatever was showing, with a thin bar naming the file and
the folder it sits in. Opening another adds a tab (`Ctrl+Tab` between
them, `Ctrl+W` closes one), and closing the last, or going back, lands
where you were. If another program changes the file while it is open,
the change comes in, unless you have unsaved edits of your own; those
win. As everywhere in Niman, edits save on their own after a pause.

A file inside the library you have open is one of its notes, and opens
as one, with its history and its links. Opening it on its own would put
two editors on one file.

On Android a picked file arrives as a copy that cannot be saved back, so
this is not offered there yet.

## Dropping files on the window

On Linux and Windows, files and folders dragged from the file manager
onto Niman's window are taken in, over whichever screen is showing. A
frame around the window says so while you drag.

- **A Markdown file** (`.md`, `.markdown`, `.txt`) opens the way
  [Open file](#opening-a-file-outside-any-library) opens one: as its
  note when it is inside the open library, on its own otherwise. Drop
  several and each opens, in a tab of its own.
- **A folder of the open library** is shown in the tree, with the
  folders above it opened on the way.
- **A folder from anywhere else** is offered for import. Its Markdown
  files are copied into a new folder of the library named after it
  (`Drafts`, or `Drafts 2` when that is taken), with their layout kept.
  Nothing else comes along: not images, not hidden folders such as
  `.git` or `.obsidian`. The folder you dropped is left exactly as it
  was.
- **With no library open**, a dropped folder opens as the library, the
  way *Open existing* would open it.
- **Anything else** is left alone, and a message names it.

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
