# Links

## Wikilinks

Forms (target, heading, alias combine freely):

- `[[note]]` — link to a note
- `[[note|alias]]` — displayed as `alias`
- `[[note#heading]]` — jumps to the heading
- `[[note#heading|alias]]`
- `[[note\|alias]]` — the same inside a table cell, where a bare `|` would
  split the cell; renaming the note keeps the `\|`. An embed reads it the
  same way, so `![[photo.png\|200]]` in a table cell is the file
  `photo.png` — in the read view, the live view, a completion and an export
- `[[note#heading#subheading]]` — a subheading, by its path
  (see *Heading links* below)
- `[[note#^id]]` — jumps to a block (see *Block links* below)
- `[[#heading]]` / `[[#^id]]` / `[[|alias]]` — the current note

Click (or Ctrl+click in the source editor) to navigate. While the
opening modifier is held over a link the pointer becomes a hand, so the
click that would open it is announced before it is made; without the
modifier it stays the text caret, a plain click placing the caret. What
the editor highlights, the preview links, and the indexer records are
the same set: links inside code fences, math blocks, inline code, and
frontmatter are never links, everywhere.

An embed follows the same way, modifier held: `![[photo.png]]` opens the
file it names — the picture, the PDF or the book in the note pane, a
`#page=` or `#chapter=` landing where it says — and `![[A note]]` opens
the note, as its link would. This is the `![[…]]` embed's rule alone: a
Markdown image, `![alt](img.png)`, is not a link, so a Ctrl+click on it
follows nothing — by design, as *Markdown links* below says.

While a link is typed, a small panel lists what can go there, in both
editors, under the caret. Only typing opens it: a caret moved into a link
already written — an arrow key, a click — opens nothing, and the keys stay
the note's. The panel lists:

- after `[[` — the library's notes, the name shown and the folder dimmed
  (what tells two same-named notes apart). A note is matched by its name
  **and** by its frontmatter aliases, prefix matches first; a row found
  through an alias says which one. Choosing a note whose name another
  note shares writes as much of its folder as it takes to name that one
  (`[[Work/Meeting]]`), so the link opens the note that was picked. A note
  whose name holds `#`, `|`, `[` or `]` is not listed: a `[[…]]` target
  has no escape for them, and the row would write a link that reads back
  as another note — link to one of those with a Markdown link instead
  (`[C# tips](C%23%20tips.md)`);
- after `![[` — an embed — the attachments instead: the files of the
  attachments folder (**Settings → Folders and paths**) and its
  subfolders first — pictures, audio, video, PDFs, whatever is there —
  then the attachments kept elsewhere in the library (a picture beside
  its note), then the notes, which an embed transcludes. They are
  matched by the typed name as the notes are, and the row writes the
  file's name with its extension (`![[photo.png]]`), with as much of its
  folder as it takes when another file shares the name. A Markdown
  embed, `![](…)`, has no panel, as a Markdown link has none;
- after a `#` — the headings of the note just named, filtered the same
  way. `[[#` — no target — lists the headings of the note being edited.
  After a second `#` (`[[note#Part#`) the same list is filtered by the
  level being typed;
- after `#^` — the block ids of the note just named, each with the first
  words of its block, filtered by the id or by those words. `[[#^`
  lists the ids of the note being edited;
- after `##` — `[[##` — the headings of **every note of the library**, each
  with its note dimmed beside it, filtered by what follows (`[[## team]]`
  lists the headings that hold the word *team*). Choosing one writes the
  whole link, `[[Team notes#Team plan]]`, with the note named as the note
  rows name it (as much of its folder as it takes to tell it from a note
  of the same name); a heading of the note being edited is written
  `[[#Team plan]]`, as Obsidian writes the link to the note it is in;
- after `^^` — `[[^^` — the block ids of every note of the library, with
  the same rows and the same choice: `[[^^idea]]` lists the ids and
  blocks that hold *idea*, and choosing one writes `[[Plan#^idea-1]]`
  (`[[#^idea-1]]` for this note). The library-wide lists show at most 50
  rows, from the library's word index, so they cost the same in a library
  of a million notes as in one of a hundred: type more of the heading to
  narrow them, as the word is matched by its start (`tea` finds *Team*)
  and without its accents (`resume` finds *Résumé*). When more notes hold
  the words than the list reads, it reads the ones where they weigh most
  — a short heading made of them before a long one that mentions them;
- after a `#` on a PDF or an EPUB — the place form to type, `page=` or
  `chapter=`. Once the form's key is written, what follows the `=` is the
  number you type: the panel is not offered again there, so `⏎` or `Tab`
  cannot write the form over it.

The panel does not open inside code or maths: a `[[` in a fenced or
indented code block, in display maths or in an inline code or maths span is
the code's own text, and completing it there would write a note name and a
`]]` into it. In a very long note whose colours are still being read, the
panel waits for them — the next keystroke in the link opens it.

`↑`/`↓` move, `⏎` or `Tab` complete the link, `Esc` closes the panel and
leaves the text as it was; a tap or a click on a row completes the link with
that row. The panel's footer names those keys only where there is a keyboard
to press them: on a phone or a tablet it shows once a physical keyboard has
been used, and the rows are taller there, to be tapped. Typed into a link already closed, the choice
replaces the whole name (or heading) up to its `#`, `|` or `]]`; what
follows is kept. The panel writes nothing but the link that was
chosen: no note is created from it, and a name that matches nothing is
left as typed (see *Dead links* below for where a new note comes from).
The rows come from the index the app already keeps; nothing is scanned to
fill the panel.

## Heading links

`[[note#heading]]` lands on the heading, whatever its case or punctuation
(`## A Heading!` is `[[note#a heading]]`). A heading that shares its text
with another one — two notes' worth of `## Details` in a long note — is
told apart by its parents: `[[note#Part one#Details]]` is the `Details`
inside the section of `Part one`, however deep below it, and
`[[#Part one#Details]]` is the same inside the note being edited. The path
is read by the outline's levels: `A#C` finds `C` only in the section of
`A` (up to the next heading as high as `A`), so a `C` under another
heading is not it. A single heading still lands on the first one of that
name. Moving or renaming the note rewrites the target and keeps the whole
path.

A `#` in a heading's own text is fine: `[[note#Issue #12]]` and
`[[note#C#]]` land on the headings `Issue #12` and `C#`. The path is tried
first (`Issue` and, inside it, `12`); when the note has no such path, the
whole text is read as one heading. The same rule is used when you follow the
link, in the link preview and in an exported page. A heading holding a `|` or
a bracket cannot be written in a link, so the panels do not offer it.

## Block links

`[[note#^id]]` links to one **block** — a paragraph, a list item, a quote —
instead of the whole note or a heading. The block carries a name at its
end, a space and a caret and the id (` ^37066d`); the id is letters,
digits and dashes, so a readable one works too (`^quote-of-the-day`).

- a paragraph, a list item or a heading ends with it:
  `This is the idea. ^37066d`;
- a quote, a callout, a table, or a whole list takes it on **a line of its
  own below it**, after a blank line:

  ```
  > A quote worth keeping.

  ^quote-of-the-day
  ```

  Only the whole block is a target: a part of a quote, a callout or a
  table is not (Obsidian's limit too). A line that is only an id is not a
  block itself: a second id on a line of its own right below it names
  nothing.

Choose an id from the panel (`[[note#^`) or write it. The id is matched
**literally**, case included; following the link brings the block into view
at its first line (for a paragraph of several lines, the one it starts
on, not the one that ends with the id). A link to an id the note does
not have says *Block not found*. The ids of a note are the same in the
editor and in the index; an id in a code block (indented code included), a
formula or the frontmatter is not one, an id in the middle of a block is
not one either, and if two blocks carry the same id the first owns it.

The read view leaves the ` ^id` out of the text, as Obsidian's reading view
does; the editor (`live` and `source`) keeps showing it, and the note's
file is never changed by hiding it. Renaming or moving the note carries
`#^id` along like any other fragment.

A heading that carries an id is still linked by its text: `## Title ^abc` is
reached by `[[note#Title]]` as well as by `[[note#^abc]]`; the outline, the
heading panels and an exported page's heading ids leave the ` ^abc` out.

An exported page (HTML, PDF, EPUB) leaves the ` ^id` out of the text of
headings, paragraphs and list items, as the read view does, and keeps the id
on the block as `block.abc` — so a `[[note#^abc]]` link into an exported page
still lands on the block. A line that is only an id (the form a quote, a
table or a list takes) draws nothing and leaves the anchor where it stands.

> **Only Obsidian reads them.** Block references are specific to
> Obsidian, not part of standard Markdown: in another editor `^37066d`
> is plain text at the end of a line, and a `[[note#^id]]` link is not
> followed there. Niman writes nothing of the kind on its own; a block
> link is only what you type or choose.

## Links to this note

Links go both ways in a library, and the open note shows the other one: the
notes that **link to it**, each with the line it says the link on. It is in
three places, one list:

- **under the note**, a header — *Links to this note*, with the count — that
  opens onto the list and shuts again. It is always there while a library is
  open, so it never appears under your thumb; with no one linking in, it opens
  onto the words that say so. A note opened from outside a library has none;
- **in the side panel** on a wide window (beside the note from 1000 px up,
  over it below), the *Links* pane beside Outline, Tags and History,
  following the note in the focused pane;
- **as a sheet on a phone**, from the note's ⋮ menu — *Links to this note* —
  as the Outline and Tags are (see [platforms](platforms.md)).

A row is the note's name, its folder dimmed, and the line it says the link
on, cut to two rows of the list (a long line is a window around the link, with
`…` where it was cut; a list or quote mark is taken off its head). A tap opens
the note that holds the link. A note that links to this one in more than one
way is one row, shown by its link; one that only **embeds** it (`![[note]]`,
`![](note.md)`) is one row too, marked *embed*. The list is in path order and
holds the first 200 notes; the count says `200+` past that.

What is listed is what the index records as a link: a wikilink or a Markdown
link that resolves to this note, wherever the writer is in the library, and
embeds. A note's own link to itself is not a mention, and a link to a note that
does not exist yet (a [dead link](#dead-links)) is no one's mention — it
names no note — until the note is made: created from the dead link or by hand,
restored from the trash, or arrived by sync, it lists the notes that were
waiting to link to it, without any of them being saved again, and renaming it
then rewrites those links like any other. The list is one indexed lookup however large the library is;
the line of each row is read from the note that holds it only as the row is
drawn (so only the rows you scroll to), off the app's main thread, and kept
until that note changes. The list is read again a moment after the library's
index changes.

**Unlinked mentions** — a note's name written in another note's text without a
link, which Obsidian's panel lists too — are not shown: finding them is a
search over the text of the whole library, and turning one into a link is a
separate feature. Only linked mentions are here.

## Markdown links

Standard `[text](href)` links, and reference links — `[text][label]` with a
`[label]: href` line anywhere in the note. `href` may be a relative path
to a note or any other file of the library (`Books/Dune.epub`), a
`#anchor`, or an external URL — `https://…`, but `mailto:` and `tel:` too,
which the system opens and which are never drawn as dead links. The path may be percent-encoded, as
Obsidian writes it: `[x](My%20Note.md)` is `My Note.md`. A path with no
extension is not followed. `![alt](src)` images are not links,
and neither is a footnote reference (`[^1]`); a link written inside a
footnote's own text is.

A path is read the way Markdown reads it, against the library:

- `/docs/a.md` is `docs/a.md` **from the library root**, and no other note
  whose path merely ends in it;
- `../Notes/a.md` walks **from the folder of the note it is written in**
  (in `Deep/Sub/b.md` it is `Deep/Notes/a.md`, in `Sub/b.md` it is
  `Notes/a.md`), and names exactly that path. One that climbs out of the
  library names nothing: the link is dead, it never falls back to a note of
  the same name elsewhere;
- a plain path (`a.md`, `sub/a.md`) is tried **beside the note first**:
  in `Sub/b.md`, `[x](a.md)` is `Sub/a.md` when there is one. When there is
  not, it is found as a wikilink is: by its name, and the note's folder
  qualifies it (`sub/a.md` matches `x/sub/a.md`), the picker offering the
  candidates when more than one fits.

A wikilink is a name, not a path, so a plain `[[a]]` is never read beside
the note; `[[/docs/a]]` and `[[../Notes/a]]` follow the same rules as the
Markdown forms. A note outside the library is not in the index and so is
not a link target. `\` in a path is `/`.

Moving a note, or a folder of them, moves what its relative links name: the
backlinks and dead links follow the new folder at once, without opening or
editing the note. A link that names another note by its name only
(`[[a]]`) does not care where either note is. A link written with a path
*to* a note that moved, from a note that did not, is read again when that
note is next indexed.

### Updating the links to what moved

Renaming or moving a note, or a folder of them, also rewrites the links
*other* notes hold to it, so they keep finding it: a path link and a
Markdown link follow the new path (a reference link's `[label]: path` line
included), and a link by name follows a rename (see
[organization](organization.md) for what else follows the note). Only the
links that pointed at what moved are rewritten: with two notes of the same
name in different folders, a link to the other one is left as it is.
**Settings →
Editor → Update links after rename or move** chooses what happens:

- **Automatically** (the default) rewrites every note that links to what
  moved.
- **Ask each time** moves first, then asks one question for the whole move
  — a folder rename included, not one per note — naming how many notes
  would change: *Update* rewrites their links, *Leave as is* (or closing the
  question) leaves them as written. A move that would change no link asks
  nothing.
- **Never** leaves the links as written; the ones that no longer find their
  target show as dead links, which is what you may want after renaming a
  note on purpose.

The setting is about the links alone. Whatever the choice, the move still
carries the note's history, reading positions, the settings and the Home
that name it, and the index. The setting is the library's own, the same on
every device.

## Links into a PDF or a book

A link can point at a place inside a PDF or an EPUB book; following it
opens the file in the note pane **there**, instead of where you left it.
Wikilinks and Markdown links alike:

- `[[Dune.pdf#page=34]]`, `[p. 34](Dune.pdf#page=34)` — page 34 of a
  PDF, the form Obsidian and PDF readers use. Other parameters, such as
  an Obsidian embed's `height=400`, are passed over.
- `[[Dune.epub#chapter=OEBPS/ch5.xhtml&line=12]]` — line 12 of a
  chapter of a book, the chapter named by its file inside the EPUB (its
  name alone is enough, `chapter=ch5.xhtml`). Niman's own form: there is
  no common one for books, and Obsidian opens the book, ignoring it.
- `&chars=3-40` after either names a passage: its characters in the PDF
  page's text, or in the text of the book's paragraph on that line. An
  annotation's link carries it, for the file to mark just the passage;
  following it goes to the page or the paragraph.
- `&highlight=green` makes the link a highlight's, in that colour
  (`yellow`, `green`, `blue`, `pink`; see
  [organization](organization.md#highlighting-a-pdf-or-a-book)); following
  it goes to the place as any other does.

You rarely write one by hand: the **link** button on the row under a PDF
or a book copies a link to the place you are reading — the page, or the
chapter's line at the top of the view — as the library writes links
(`[[Books/Dune.pdf#page=34|Dune, p. 34]]`, or
`[Dune, p. 34](Books/Dune.pdf#page=34)` with Markdown links), ready to
paste into a note. The button is disabled for a file opened from outside
a library.

A link to a file already open moves it to the place; the same link
followed again goes back there. A place the file no longer has (a page
past its end, a chapter it lost) opens it where you left it.

## Dead links

A link whose target note does not exist is a *dead link*, and a dead
link is where a note comes from.

**A dead link is drawn muted**, before it is clicked: in the editor (`live`
and `source`) and in the read view, a wikilink or a Markdown link to a file
the library does not hold takes the quieter colour of the markers around the
text, still underlined, in the light and the dark theme alike; a live link
keeps the link colour. So a typo, and a note you have named but not written
yet, are told from a link that works. Only a link to a *file* is judged: a
web address, a `#anchor` in the same note, and an href with no extension
(which Niman does not follow either) are never dead. A name that several
notes share is not dead, it is ambiguous. And it is the note that counts:
`[[Note#Nope]]` and `[[Note#^nope]]` stay live as long as `Note` exists —
Niman, like Obsidian, marks a link at the level of the note, not of its
heading or block. A label-first link, `[[a label|filename]]`, is dead only
if neither `a label` nor `filename` is a note.

The links of the open note are resolved against the library's index in one
batch, off the drawing: when the note opens, a short pause after you stop
typing (the same pause the word count waits), and whenever the library's index
changes — a note made, renamed or deleted anywhere turns the links to it live
or dead without touching the note. A link you have just typed is drawn as a
live one until the next resolution. Nothing is read from the disk for it, and
a note too long to read twice (over 32 MB) keeps its links drawn as they were.

In the editor, **Ctrl+click**
(**Cmd+click** on macOS), the same gesture that follows a link, is its
own confirmation: the note the link names is created on the spot and
opened, and the writer is left in it.

Anywhere else — a tap in the preview, or on a touch screen, where
there is no Ctrl — following a dead link *offers* to create it: a
dialog shows the proposed path with **Create** and **Cancel**. Create
makes an empty note there (no frontmatter) and opens it in the editor;
Cancel changes nothing — no file, no error, no second prompt. On a
desktop the offer is a small menu where the link was clicked, with the
path and **Create**; clicking away is the Cancel.

A link that more than one note answers asks which one: on a desktop in a
menu where it was clicked, on a phone in a sheet.

Where the new note lands is the library setting `newItemLocation`
(Settings → Editor → **New notes and folders go to**), the one rule every
new note and folder follows (see
[organization](organization.md#where-new-notes-and-folders-go)); the note
open is the one the link was clicked in:

- `openNoteFolder` (default) — the folder of the note where the link was
  clicked: `[[Foo]]` in `Notes/Current.md` creates `Notes/Foo.md`
- `libraryRoot` — the library root: `[[Foo]]` creates `Foo.md`

A library written before the rule had its own setting for this,
`missingNoteLocation`; its value carries over (`currentFolder` is
`openNoteFolder`).

A target that names a folder (`[[Sub/Foo]]`) keeps that folder, whatever
the setting says, **and the folders are made with the note**:
`[[Projects/Three laws]]` creates `Projects/` if the library has none, and
the note inside it, as Obsidian does — a folder the library already has
under another spelling is that folder. The confirmation dialog names the
whole proposed path, so you see what is about to be made, and Cancel makes
neither the note nor its folders. Each name is cleaned the way a note's
name is, and an empty segment is dropped. A leading `/` or a `.`/`..`
segment is walked as a link is read (see *Paths* above): `[[../X/Y]]` in
`A/B/n.md` creates `A/X/Y.md`, `[[/X/Y]]` creates `X/Y.md`, and one that
climbs out of the library makes nothing, so a link never creates anything
outside the library. A segment that starts with a dot names a hidden folder,
and the link is refused rather than made there. If a name on the way is
already a file, or the disk refuses, nothing is made and the link stays dead.
Targets with an extension (`[[photo.png]]`) are attachments, not notes: they
are never created. External URLs keep their behavior.

Notes opened without a library (editor-only mode) keep the old
"link not found" outcome.

## Preview a link

A link can show what it points at before you go there. The card is the note,
rendered as the read view renders it, in a box of a fixed size that scrolls —
a note of any length — and it never navigates:

- **in the read view**, rest the pointer on a link for a moment (a sweep
  across the page opens nothing);
- **in the editor** (`live` and `source`), hold **Ctrl** (**⌘** on a Mac) over
  the link — the same key that follows it, so the card says *this is where it
  goes* — and the card opens at once. Without the key the pointer stays the
  text caret and nothing opens;
- **on a touch screen**, press and hold a link in the read view: the same
  note opens as a **bottom sheet** with an **Open** button that follows the
  link, as a tap does. A tap still follows it. The Android editor has no
  preview: it has no pointer to rest on a link, and a long press there
  selects text (see [platforms](platforms.md)).

The card stands at the pointer, inside the window. It stays while the pointer
is on it, so you can scroll it, and closes when the pointer leaves the link
and the card, on **Esc**, when the note scrolls, when you press anywhere, and
when the note is edited. A link to a `#heading`, a `#heading#subheading` or a
`#^block` opens the card scrolled to it. A link that names nothing — a dead
link, a name several notes share, a web address, a file that is not a note,
the note the link is written in — has no card.

It reads the first 256 KB of the note off the app's main thread, once for each
revision of it, keeping the last sixteen: moving across a page of links does
not read a note twice. A heading further down a longer note than that is not
found, and the card shows the top. A note that is open with edits the disk
does not have yet is shown as its buffer holds it, not as the file still is.

**Settings → Editor → Preview links** (on by default) turns the cards, and the
sheet, off for the library.

## Dropping a file from the tree

On Linux and Windows a row of the tree dragged onto an open note writes a
link to that file where it is let go: the caret follows the pointer while
the row is over the note, and the link goes in as one edit, undone in one
step. It is written in the library's link format, as the link button and
the panel write one — `[[Meeting]]`, with as much of the folder as another
file of that name makes it take, or `[Meeting](../Work/Meeting.md)`,
relative to the note. A picture or an audio file is embedded instead
(`![[photo.png]]`, `![photo.png](Media/photo.png)`), as one added from the
editor is; a PDF, a book or any other file is linked. A folder dragged
onto the note writes nothing, and the read view, with no caret, takes no
drop. So do several rows marked together (#996): that drag is a move, and
the link is one file's gesture. The tree's own drops are unchanged: let
go on a folder, the row moves into it.

## Link button

The editor's link button inserts a wikilink by default; set the
library's `linkType` to `markdown` to insert `[…](…)` instead.
