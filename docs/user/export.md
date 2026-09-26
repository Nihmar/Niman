# Export: a note, a folder, the library

Niman writes what it holds out as plain files, through the system's own
pickers. Nothing leaves the app except what you ask for, and what leaves
is yours to keep: no account, no format of ours to get back in.

## A note

The note's ⋮ menu (**Export…**) or the palette (*Note: Export…*) writes
one file:

- **Markdown** — the note as it stands, under its own name (`Notes/it.md`
  becomes `it.md`).
- **HTML** — one self-contained page: the note as it reads, its pictures
  inside it as `data:` URIs, its formulas drawn as SVG, and a style that
  follows the reader's light or dark system. Nothing else is needed to
  open it — a mail attachment or a USB stick is enough. The picture
  types it can carry are PNG, JPEG, GIF, WebP and BMP; a picture of
  another type (an SVG, say) stays as the note wrote it rather than
  breaking the page.
- **PDF** — the same page printed: A4, its paper style, its formulas and
  pictures in place. The machine prints it with its own browser — Edge on
  Windows, a Chromium-family browser on Linux (Chromium, Chrome, Brave,
  Vivaldi, Helium), the system WebView on Android — so the text stays
  real: it can be selected, searched and copied. On a desktop that has
  none of those browsers the note is drawn instead: a picture of its
  pages, which cannot be selected. That is not what everyone asked for,
  so Niman says it *before* it starts drawing and lets you stop there,
  and says it again when the file is written. The drawn pages show the
  note's pictures too — the fallback reads and draws them, it does not
  leave them out — and their pages break between two lines, so a page
  never cuts one in half. A PDF export says it is running while it runs —
  the engine printing, or the pages being drawn one by one — and can be
  stopped from the same dialog: a long note is minutes of work, not a
  hang.
- **EPUB** — the note as a book of one chapter, for an e-reader: the same
  page (`NoteHtml`) as XHTML, formulas as vectors, pictures inside the
  file. A `cover:` key in the note's frontmatter names a picture the book
  opens on. A wikilink out has nothing to point at, exactly as on a
  single HTML page.

A link to another note becomes the text it shows on a page exported on
its own — a wikilink highlighted, a Markdown link its own words — since
one page has nothing to point at; a link to a website stays a link.
Export a folder, below, and its note-to-note links become links.

### A book's metadata

An EPUB takes its metadata from the frontmatter: the note's own for a
single note, `index.md`'s for a folder or the library — the note the
book's author writes the metadata in, when the exported folder has one at
its root. When there is no `index.md`, or it carries no frontmatter, the
export asks first: the book would carry the folder's name and no author,
cover or series, and the dialog lets you stop and write the note before
going on. The keys are the usual ones, so a note written for another tool
reads the same here:

```
---
title: The book
author: [Ada Lovelace, Alan Turing]
language: en
series: Notes
series_index: 2
cover: cover.png
tags: [geometry, notes]
description: What the book is.
publisher: Niman Press
published: 2026-09-25
rights: Public domain
---
```

`title` and `language` override the export's own (the note's display name
and the app's language), `tags` become the book's subjects, `cover:`
names the picture the book opens on, and `published:` — not `date:`,
which is the note's own — the book's date. The Markdown cheatsheet
carries the same example, under **EPUB metadata**.

## A folder, or the whole library

The row menu on a folder (**Export folder…**), the tree's empty space
(**Export library…**), or the palette (*Library: Export library…*) writes
one zip:

- **Markdown** — the subtree as it is on disk, attachments included.
- **HTML** — every Markdown note as a page at its own relative path, the
  other files copied beside it. A picture used by several notes is stored
  once. A wikilink between two notes of the export becomes a relative
  link; a link to a note outside the folder — which the zip does not
  hold — stays as the note wrote it, so nothing points at a page that is
  not there.
- **PDF** — every Markdown note as **its own PDF**, one file per note, at
  the note's own relative path (`Notes/it.md` becomes `Notes/it.pdf`);
  the other files are copied beside them, and each page carries its own
  note's pictures inside it. Links between notes point at the other
  PDFs. Printing a folder needs something to print with, as a note's PDF
  does; where the machine has neither a browser nor Android's WebView,
  the format is not offered.
- **EPUB** — the folder (or the library) as **one book**: every Markdown
  note is a chapter, in the tree's own order, with a table of contents
  and links between the chapters. The pictures the chapters show travel
  inside the book, each one once; an attachment no chapter shows is left
  out. The book's metadata and cover are the `index.md` frontmatter at the
  exported folder's root. One EPUB, not one per note — a folder is a book,
  and the format is what its reader expects.

Anything whose name starts with a dot (`.niman`, `.trash`, `.history`,
`.draft.md`) is not part of an export, folders and files alike: those
are the app's own corners, and the tree that lists a library does not
show them either. An empty folder is kept in the Markdown, HTML and PDF
zips; a book has no folders to keep, and a folder with no Markdown note
at all is refused there — there would be no chapter to read.

The zip is streamed while it is written, one entry at a time, so a
library of any size exports without the whole of it ever being in memory.
A progress dialog shows the entry being written and can stop the run; a
cancelled export removes the half-written zip — unless Windows has not
let go of the file yet, and then the app says so. An export never
overwrites the last one: a second zip of the same folder is written as
`name (2).zip` beside it.

## Where it lands

The save dialog on the desktop, or the system picker on Android, decides.
Niman says where the file went when it is done.
