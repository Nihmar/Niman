# Annotations (#284)

A PDF or a book is annotated in **companion notes**: plain notes naming
the file in their frontmatter, `annotates: "[[Books/Dune.pdf]]"`. Disk is
the source of truth: nothing about annotations is kept but in notes, and
the index only answers which notes declare the key.

## The model — `lib/src/annotations/`

- `Annotation`: the file (library-relative), the place (`BookLocation`,
  `lib/src/reading/`), a label naming it, the passage quoted, the comment.
  `toMarkdown` writes the section a companion holds: `## label`, the quote
  as a blockquote ending in `> — <link back>` (`placeLink`,
  `lib/src/links/place_link.dart`), the comment. The quote and the heading
  are escaped as a book's text is (`markdown/text_escape.dart`, shared
  with `XhtmlMarkdown`), so a `#` in a PDF never becomes a tag. A place
  with no passage has the link on its own line.
- `CompanionNotes`: `of(path)` asks `FieldSource.fieldValues('annotates')`
  — every note declaring the key, with its values, one join — and resolves
  each value (a wikilink, a Markdown link or a bare path) through the
  `LinkSource`; the notes whose value resolves to the file are its
  companions, in path order. The number of rows is the number of
  companions in the library, not of notes. `write` appends to the first
  (`NoteOperations.appendToNote`), or creates `<folder>/<file> - <suffix>.md`
  with the frontmatter, and returns where the annotation starts in the
  note, for the note to open there.

A PDF passage's place carries its characters in the page's text
(`PdfLocation.chars`, fragment `page=34&chars=120-180`), for the file to
mark it (#285). A book's paragraph is its chapter line; a part of a
paragraph (#283) will add the same key to `EpubLocation`.

## The surface

- The read view offers `onBlockMenu` (long press, secondary click) with
  the block's first line and its text (`plainTextOf`,
  `markdown/render/visible_text.dart`), and `blockTextAt(line)`. The book's
  pane (`EpubPane`, its places in `EpubPlaces`) turns a paragraph into an
  `Annotation` from its menu (`epub_paragraph_menu.dart`, which also copies
  a link to it) or from the row's annotate button (the paragraph at the top
  of the view).
- `PdfDocumentView` adds **Annotate** to pdfrx's selection menu
  (`customizeContextMenuItems`) and tracks the selection
  (`onTextSelectionChange`) for the row's button, which annotates the
  selection, or the page when there is none.
- `ShellAnnotationFlow` takes the `Annotation` from either: asks for the
  comment (`showAnnotationSheet`: a bottom sheet above the keyboard on a
  phone, a dialog at `wideBreakpoint` and up), saves every open note
  (`UnsavedTracker.saveAll`, so an editor holding the companion does not
  write its copy back over the annotation), writes, bumps the shell's note
  reload token (a clean note on screen re-reads), and shows a snackbar
  whose **Open note** opens the companion with the caret at the
  annotation (the template flow's `_onTemplateNoteFiled`).

The file's pane moves to a link's place on its own counter of links
followed (`_linksFollowed`), not on the note reload token, which also moves
on a resume, a sync, and an annotation written.

Tests: `test/unit/annotation_test.dart`, `companion_notes_test.dart` (a
real index and `NoteOps`), `visible_text_test.dart`,
`test/widget/annotation_sheet_test.dart`, `shell_annotation_flow_test.dart`,
the `#284` group of `epub_pane_test.dart`. The PDF view has no widget test:
pdfium does not load under `flutter test`.
