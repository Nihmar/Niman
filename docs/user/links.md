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

Standard `[text](href)` links. `href` may be a relative `.md` path, a
`#anchor`, or an external URL. `![alt](src)` images are not links.

## Link button

The editor's link button inserts a wikilink by default; set the
library's `linkType` to `markdown` to insert `[…](…)` instead.
