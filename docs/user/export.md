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
  open it — a mail attachment or a USB stick is enough.
- **PDF** — the same page printed: A4, its paper style, its formulas and
  pictures in place. The machine prints it with its own browser — Edge on
  Windows, a Chromium-family browser on Linux, the system WebView on
  Android — so the text stays real: it can be selected, searched and
  copied. On a desktop that has none of those browsers the note is drawn
  instead: a picture of its pages, which cannot be selected, and Niman
  says so when the file is written.

A wikilink becomes highlighted text on a page exported on its own: one
page has nothing to point at. Export a folder, below, and its links
become links.

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
  the other files are copied beside them. Links between notes point at
  the other PDFs. Printing a folder needs something to print with, as a
  note's PDF does; where the machine has neither a browser nor Android's
  WebView, the format is not offered.

Folders whose name starts with a dot (`.niman`, `.trash`, `.history`) are
not part of an export, and neither is anything inside them.

The zip is streamed while it is written, one entry at a time, so a
library of any size exports without the whole of it ever being in memory.
A progress dialog shows the entry being written and can stop the run; a
cancelled export removes the half-written zip.

## Where it lands

The save dialog on the desktop, or the system picker on Android, decides.
Niman says where the file went when it is done.
