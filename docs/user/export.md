# Export: a note, a folder, the library

Niman writes what it holds out as plain files, through the system's own
pickers. Nothing leaves the app except what you ask for, and what leaves
is yours to keep: no account, no format of ours to get back in.

## A note

The note's ⋮ menu (**Export…**) or the palette (*Note: Export…*) writes
one file:

- **Markdown** — the note as it stands, under its own name (`Notes/it.md`
  becomes `it.md`).
- **HTML** — one self-contained page: the note as it reads — read as the
  app reads it, GitHub's Markdown and Niman's own, footnotes and callouts
  included — its pictures
  inside it as `data:` URIs, its formulas drawn as SVG, and a style that
  follows the reader's light or dark system. Nothing else is needed to
  open it — a mail attachment or a USB stick is enough. The picture
  types it can carry are PNG, JPEG, GIF, WebP, BMP and SVG (an SVG goes
  in as a `data:image/svg+xml` URI); a picture of another type stays as
  the note wrote it rather than breaking the page.
- **PDF** — the same page printed: on the paper picked in **Settings →
  Export** (A4 unless another is), its paper style, its formulas and
  pictures in place. The machine prints it with its own browser — Edge on
  Windows, a Chromium-family browser on Linux (Chromium, Chrome, Brave,
  Vivaldi, Helium), the system WebView on Android, WebKit on a Mac or an
  iPhone, with nothing to install — so the text stays real: it can be
  selected, searched and copied. On a desktop that has
  none of those browsers the note is drawn instead: a picture of its
  pages, which cannot be selected. That is not what everyone asked for,
  so Niman says it *before* it starts drawing and lets you stop there,
  and says it again when the file is written. An engine that is there and
  cannot print — a browser that refuses, a print that times out — is not
  the same as no engine at all: the note is drawn anyway, and the message
  names the reason. The engine prints with a profile of its own, never
  the one your browser is using, so having Edge open does not stop the
  export. The drawn pages show the note's pictures too — the fallback
  reads and draws them, it does not leave them out — and their pages
  break between two lines, so a page never cuts one in half. A PDF export
  says it is running while it runs — the engine printing, or the pages
  being drawn one by one — and can be stopped from the same dialog: a
  long note is minutes of work, not a hang.
- **EPUB** — the note as a book, for an e-reader: the same page
  (`NoteHtml`) as XHTML, formulas as vectors, pictures inside the file (an
  SVG as an `images/img-N.svg` entry). A book carries the picture types
  EPUB itself does — PNG, JPEG, GIF, WebP and SVG — so a BMP is left out
  of it, though the HTML page still shows it. A book holds its pictures
  inside it, so a picture that is not in the book — one on the web
  (`![w](https://…)`), or one of a type the book cannot carry — is its
  description instead: the text, as a link to where the picture was when it
  was on the web. The HTML page and the PDF keep a picture on the web as it
  is written.
  A `cover:` key in the note's frontmatter names a picture the book opens
  on. A wikilink out has nothing to point at, exactly as on a single HTML
  page.

  The book has a chapter per heading of the **shallowest level the note
  uses at least three times** — the rule the import of a
  [page that is a book](organization.md#a-page-that-is-a-book) reads
  chapters by. A note whose chapters are `#` keeps its `##` as sections
  inside them; a novel kept as one note — a `# Title`, then
  `## Chapter 1`, `## Chapter 2`, … — is a chapter per `##`, each opening
  on a page of its own and listed in the reader's contents by its
  heading. What comes before the first chapter (the title, a summary, the
  author's notes) is a page of its own, named after the note; the
  footnotes are at the end of the last chapter, and a footnote mark or a
  link to a heading of the note still lands where it points. A note with
  no level used three times is one chapter.

A task item prints as the box that marks it, the bullet off, so a
checklist reads as one in the HTML, the PDF and the EPUB — inside a kanban
board's columns and cards too.

A slides note has one more entry in its ⋮: **Export slides as PDF**, one
16:9 page per slide and no speaker notes, printed the same way as the PDF
above (see [slide notes](slides.md#export)).

A `todo` block (see
[a list of tasks in a note](tasks.md#a-list-of-tasks-in-a-note)) is printed as
the list it is **at the moment of the export** — ☐ and ☑ and the words of each
task, links by their labels — in the HTML, the PDF (printed or drawn) and the
EPUB, not as its source; a block with an error prints its error lines. A
folder's or the library's export has no tasks at hand and prints the block as
the code it is on disk.

A kanban board exports as its board, in every format, while Kanban boards
are on in [Features](features.md) (off, it exports as its sections and
tasks). Each column is a section headed by its name and its number of
cards; each card is a box with its box, its title, its tags and `due:`
as chips, and its body. Links, footnotes and pictures in a card work as
in the rest of the note. Obsidian's settings footer is left out.

- **HTML** — the columns side by side, scrolling sideways; stacked on a
  narrow screen.
- **PDF** — a board prints on its paper on its side when its columns
  fit one row of it, each at least 60 mm wide — up to four on **A4
  landscape**, three on Letter, five on A3 — and standing up otherwise, as
  many to a row as fit (two on A4). A card is never split across two pages. Without a browser
  engine the board is drawn the same way, as pictures of the pages.
- **EPUB** — the columns one after another, since an e-reader's page is
  narrow.

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
identifier: 978-3-16-148410-0
---
```

`title` and `language` override the export's own (the note's display name
and the app's language), `authors:` is read as `author:` and `lang:` as
`language:`, `identifier:` — or `isbn:` — is the book's identifier (an
ISBN is written `urn:isbn:` and its digits),
`tags` become the book's subjects, `cover:`
names the picture the book opens on, and `published:` — not `date:`,
which is the note's own — the book's date. The Markdown cheatsheet
carries the same example, under **EPUB metadata**.

A reader — Apple Books, Kobo, KOReader, Calibre — knows a book by its
identifier, and keeps the reading position and the highlights on it. Export
the same note or folder again and it is still **the same book**: with no
`identifier:` or `isbn:`, the identifier is made from the note's or the
folder's path in the library, so it is the same on every export (rename or
move the note and it is a new book). Two notes are two books.

## A folder, or the whole library

The row menu on a folder (**Export folder…**), the tree's empty space
(**Export library…**), or the palette (*Library: Export library…*) writes
one zip:

- **Markdown** — the subtree as it is on disk, attachments included.
- **HTML** — every Markdown note as a page at its own relative path, the
  other files copied beside it. A picture used by several notes is stored
  once. A wikilink between two notes of the export becomes a relative
  link, and so does a link — wikilink or Markdown — to any other file of
  the folder, a PDF or an attachment in whichever subfolder it sits: it
  points at the copy beside the pages, `../attachments/target.pdf` from
  a page one folder down, though the note names it `[[target.pdf]]`. A
  link to a note or a file outside the folder — which the zip does not
  hold — stays as the note wrote it, so nothing points at a page that is
  not there.
- **PDF** — every Markdown note as **its own PDF**, one file per note, at
  the note's own relative path (`Notes/it.md` becomes `Notes/it.pdf`);
  the other files are copied beside them, and each page carries its own
  note's pictures inside it. Links between notes point at the other
  PDFs, and a link to another file of the folder at its copy. Printing a
  folder needs something to print with, as a note's PDF does; where the
  machine has neither a browser nor a system WebView (Android's, or
  WebKit on a Mac or an iPhone), the format is not offered.
- **EPUB** — the folder (or the library) as **one book**: every Markdown
  note is a chapter, in name order (below), with a table of
  contents — nested by folder: a folder is an entry with its chapters
  under it, and a folder's `00 …` note, the page a part opens on, is that
  entry — and links between the chapters. The pictures the chapters show travel
  inside the book, each one once; an attachment no chapter shows is left
  out. The book's metadata and cover are the `index.md` frontmatter at the
  exported folder's root, and that note is also the book's first chapter,
  after the cover page, wherever its name sorts: the page with the title
  and the contents opens the book. One EPUB, not one per note — a folder is a book,
  and the format is what its reader expects. It is the way back from
  [converting a book into notes](organization.md#converting-a-book-into-notes):
  the converted folder's `index.md`, numbered chapters and pictures make
  the book again, with its metadata and cover.

**The order** of a folder's contents, in every format, is by name, numbers
in numeric order, as the tree sorts names — folders and notes together:
capitals and small letters are not told apart, nor accents, and numbers go
by their value, so `Chapter 2` comes before `Chapter 10`. (The tree itself
lists folders before notes; an export does not, so that `01 Preface.md`,
`02 Part One/` and `03 Epilogue.md` read in that order.) In a book that is
the order of the chapters, the contents and the spine: a book you convert
into notes (and so number its chapters and parts) reads in order when you
export it again, with `index.md` first.

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

On a desktop the progress of every export — a folder's zip or book, a
note's PDF or EPUB — is a card in the window's bottom-right corner rather
than a dialog (#712): you can keep writing while a long PDF is drawn, and
**Cancel** on the card stops it. A phone keeps the dialog.

## Where it lands

The save dialog on the desktop, or the system picker on Android, decides.
Where it opens is the library's choice (**Settings → Folders and paths →
Export folder**, #1286): wherever the system opens it — the home folder on
Linux, the last one used elsewhere — or **this library's folder**. On
Android the library's folder is the place the picker starts from when a
note is saved; a folder's zip is placed with the system's folder picker,
which takes no starting place. On a Mac and an iPhone the system chooses
(see [platforms](platforms.md#where-an-exports-dialog-opens)).
Niman says where the file went when it is done. The banner goes away on its
own after a few seconds; on a wide window it also has a close button, and on
desktop it offers **Show in file manager** to open the folder with the file
selected. Nothing waits for you to press it.
