# Web capture

Niman can save a web page — or a passage of one — as a note: the article
in clean Markdown, without the menu, the banners and the footer around
it, and its pictures in the library's attachments folder. A passage
copied in the browser can also be [pasted as Markdown](#paste-as-markdown)
into the note being written. The work is tracked in
[#531](https://github.com/Nihmar/Niman/issues/531).

## On the desktop

Three ways in, all to the same dialog:

- **Capture web page** in the command palette, or `Ctrl/⌘+Shift+W`. When
  the clipboard holds a web address, the dialog starts on it.
- **A link pasted** where no text field takes the paste — the tree, the
  read view. A link pasted into the editor or a field stays a paste.
- **A link dropped** on the window, dragged from the browser's address
  bar or a page: the frame says **Drop to capture this page**. Files
  dropped on the window still open as they always have.

The dialog says each step as it happens — **Downloaded · 212 KB**, then,
for a page that builds its text with a script, **Only 40 words found**
and **Running the page in a browser…** (see below). Then the note it will
be:

- its **title**, the **folder** (the library's
  [web captures folder](#where-the-note-goes), or another one picked) and
  its **tags** (`#web` to start with);
- a **preview**: the author, how many words and minutes, the first lines;
- **Download the 7 images to assets/** — off, the note points at the
  pictures on the web instead;
- the **frontmatter** the note starts with, and what was **removed** from
  the page: scripts and styles, the navigation menu, a cookie banner, the
  words around the article.

**Save note** downloads the pictures, writes the note and opens it. A page
that cannot be had says why — no connection, an error from the site, not
a web page at all — and the address can be corrected and read again.

## Where the note goes

A captured page, and a quote kept as a new note, go in the library's
**web captures folder**: `Clippings` until another is chosen in
**Settings → Folders and paths → Web captures folder** (`captureFolder`
in the [library settings](settings.md)). The folder is made by the first
capture that goes there. The dialog and the sheet start on it, and
**Folder** picks another for that one capture. The folder the tree has
selected plays no part, so a capture made with a picture selected no
longer lands among the attachments.

The pictures go in the attachments folder whatever folder the note is
in: the note links them from there.

## On a phone

**Share → Niman** from the browser. What the browser shares decides what
opens:

- **A page** — its address, alone or with its title (the share's
  subject, or a line of its own above the address): the **Save to
  Niman** sheet, on its **Page** tab, with the title, the folder, the tags
  and the pictures to download. The page is read as soon as the sheet
  opens, so it says how many pictures there are.
- **A quote** — text selected on the page and shared with its link (the
  browser's *share highlight*, or text in quotation marks before the
  address): the same sheet on its **Quote** tab. The quote goes at the end
  of the note on screen (**Append**), of another note picked, or into a
  new note in a folder (the web captures folder, or another one picked).
- **Anything else** goes to the quick note, as shared text always has.

**Save** sends you back to the browser at once; the page is read and saved
in the background. A notification says how it goes: **Reading
example.com…**, with **Cancel**, then **Saved: …** with **Open** and
**Show folder** — or **Saved without the article** when nothing could be
read, or **Could not capture …** with the reason. A tap on it opens the
note. A capture keeps Niman alive for at most 150 seconds — Android allows
a short task three minutes — and gives up past that. **Cancel** brings
Niman to the front: a notification's button that did not would have to
start a second copy of the app's engine. Once the pictures are being
saved, a capture can no longer be cancelled.

**New ▸ Capture web page** opens the same sheet inside the app, with the
address to type — the clipboard's, when it holds one.

## What the note holds

```markdown
---
source: https://app.example.com/blog/offline-first
captured: 2026-10-07
author: Dana Ortiz
tags: [web]
---

# Offline-first, ten years later

When we started, a phone without signal was an edge case…
```

- the frontmatter: where the page was (`source`), the day it was captured,
  its author when the page names one, and the tags;
- the title as the heading, and the article in Markdown — headings,
  lists, quotes, tables, code, links made absolute;
- the pictures embedded as the library embeds its own, downloaded into
  the attachments folder and named by their content, as pasted pictures
  are: at most 60 of them, 15 MB each.

A quote is written as a passage quoted from a book or a PDF:

```markdown
> Conflicts should read as a choice, not an error.
> — [Offline-first, ten years later](<https://app.example.com/blog/offline-first>)
```

## Paste as Markdown

A passage copied in the browser can go into the note as Markdown rather
than as plain text: its headings, emphasis, lists, quotes, tables, links
and pictures kept, the page's styling left behind.

- **Desktop**: `Ctrl/⌘+Shift+V` in the editor, or **Editor: Paste as
  Markdown** in the command palette. `Ctrl/⌘+V` still pastes the plain
  text.
- **Phone**: **Paste as Markdown** in the editor's menu, under Paste.

It goes where the cursor is, in place of the selection, as a paste does.
When the browser said which page it was copied from, the paste ends in a
line linking to it — the page's title when the copy carries one, its
address's host otherwise — and links and pictures written relative to the
page are made absolute:

```markdown
**Conflicts** should read as a *choice*, not an error.

- Show both versions side by side

- Keep the time of each change visible

— [app.example.com](<https://app.example.com/blog/offline-first>)
```

A message says **Pasted as Markdown · with the link to app.example.com**,
with **Undo**: it puts the clipboard's plain text in the paste's place,
as `Ctrl/⌘+V` would have — as long as that part of the note has not been
changed since.

- **Pictures** stay on the web: the note points at them, nothing is
  downloaded. One that is not on the web — drawn into the page itself, or
  a relative address with no page to resolve it — is left out.
- **No HTML on the clipboard** — text copied from a text editor, a
  terminal — and the plain text is pasted, with nothing to undo.
- **The page it came from** is known on Windows and Linux, where the
  browsers put it on the clipboard beside the HTML (Chromium-family
  browsers and Firefox both do). Android's clipboard does not carry it,
  so on a phone the paste is not linked to its page.

## When the page has too little text

Some pages build their text with scripts, and the download alone holds a
few words. Then the page is run in a browser and read again:

- **Windows**: Edge, run hidden;
- **Linux**: a Chromium-based browser found on `PATH` — Chromium, Chrome,
  Edge, Brave, Vivaldi — the one the PDF export already uses;
- **Android**: a WebView Niman keeps hidden.

The browser runs with a profile of its own, deleted afterwards: your own
browser, its sign-ins and its cookies are never used.

When even that finds no article — a page behind a sign-in, a bot check,
or a Linux without such a browser — the note keeps what the page says of
itself: its title, its description and its picture, under a notice to
open the link.

## Limits

- Only `http` and `https` pages, at most 5 redirects, 15 seconds to
  connect and 30 in all, 10 MB, HTML only — a PDF or a picture is not a
  page.
- Pages in UTF-8, UTF-16, Latin-1 or Windows-1252 are read as
  downloaded; any other charset is read through the browser, which
  decodes it.
