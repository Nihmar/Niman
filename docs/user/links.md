# Links

## Wikilinks

Forms (target, heading, alias combine freely):

- `[[note]]` — link to a note
- `[[note|alias]]` — displayed as `alias`
- `[[note#heading]]` — jumps to the heading
- `[[note#heading|alias]]`
- `[[#heading]]` / `[[|alias]]` — the current note

Click (or Ctrl+click in the source editor) to navigate. What the editor
highlights, the preview links, and the indexer records are the same set:
links inside code fences, math blocks, inline code, and frontmatter are
never links, everywhere.

## Markdown links

Standard `[text](href)` links, and reference links — `[text][label]` with a
`[label]: href` line anywhere in the note. `href` may be a relative path
to a note or any other file of the library (`Books/Dune.epub`), a
`#anchor`, or an external URL. The path may be percent-encoded, as
Obsidian writes it: `[x](My%20Note.md)` is `My Note.md`. A path with no
extension is not followed. `![alt](src)` images are not links,
and neither is a footnote reference (`[^1]`); a link written inside a
footnote's own text is.

## Dead links

Clicking a link whose target note does not exist offers to create it:
a dialog shows the proposed path with **Create** and **Cancel**. Create
makes an empty note there (no frontmatter) and opens it in the editor;
Cancel changes nothing — no file, no error, no second prompt.

Where the new note lands is the library setting `missingNoteLocation`
(Settings → Editor):

- `currentFolder` (default) — the folder of the note where the link was
  clicked: `[[Foo]]` in `Notes/Current.md` creates `Notes/Foo.md`
- `libraryRoot` — the library root: `[[Foo]]` creates `Foo.md`

A target that names a folder (`[[Sub/Foo]]`) keeps that folder; Niman
does not create intermediate folders, so a missing folder shows an
error. Targets with an extension (`[[photo.png]]`) are attachments,
not notes: they are never created. External URLs keep their behavior.

Notes opened without a library (editor-only mode) keep the old
"link not found" outcome.

## Link button

The editor's link button inserts a wikilink by default; set the
library's `linkType` to `markdown` to insert `[…](…)` instead.
