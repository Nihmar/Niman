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

A passage's place carries its characters: a PDF's in the page's text
(`PdfLocation.chars`, fragment `page=34&chars=120-180`), a book's in the
text of the paragraph it starts in, as a reader sees it
(`EpubLocation.chars`, `chapter=…&line=12&chars=3-40`, #283), for the file
to mark it (#285). A book's passage that runs on past its paragraph keeps
the paragraph's place, quoting all of it.

## The surface

- The read view's text is selectable when it is given `selectionActions`
  (#283, `markdown/render/read_selection.dart`): Flutter's `SelectionArea`
  over the blocks — handles and a toolbar on a phone, a mouse drag and a
  context menu on desktop — and a `SelectionListener` per block reporting
  the part of it selected to a `ReadSelectionScope`. The view's `selection`
  is the first block's line, the start in its text, the end when the
  selection ends in that block, and the text. The actions join the menu —
  the first before Copy, where a phone keeps it in sight, the rest after.
  `blockTextAt(line)` gives a block's text as a reader sees it
  (`plainTextOf`). The book's pane (`EpubPane`, its places in
  `EpubPlaces`) offers **Annotate** and **Copy link to this place** on a
  selection, and its row's annotate button annotates the selection, or
  the paragraph at the top of the view.
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

## Marks (#285)

Marks are read from the companions, never stored. `annotationLinksIn`
(`annotation_mark.dart`, pure, run in an isolate: a companion may be
long) finds the links of a note that name a place (`BookLocation.fromFragment`),
each with the section it belongs to: the heading above it, or its own
line. `CompanionNotes.marksOf` resolves their targets (once each) and
keeps the ones pointing at the file: `AnnotationMark` — the note, the
offset its annotation starts at, the place, the heading.

A pane asks an `AnnotationMarkSource` (the shell's `ShellAnnotationFlow`)
through `FileMarks`, which reads the marks when the file opens and again
half a second after the library's index changes (`LibrarySession.events`:
a companion edited, an annotation written). A tap goes through
`openAnnotationMarks`: one mark opens its note at the annotation, several
ask which.

- A book: `epubBlockMarks` maps the marks to lines of the book's text
  and a passage's characters; the read view (`marks`, `MarkedBlock`) tints
  a block marked whole, and only the characters of a passage
  (`RangeHighlight`, which paints the boxes of the block's paragraphs,
  their text read in order as the selection counts it), in the
  highlighter colour of `==mark==`, and reports a tap on one
  (`onTapMark`) with its lines, which `epubMarksBetween` turns back into
  marks.
- A PDF: `PdfMarkLayer` reads, per marked page, the page's structured text
  (the one pdfrx's selection indexes, so `chars=` means the same
  characters), turns each passage into one rectangle per run of text it
  covers (`passageRects`), and draws them with pdfrx's
  `pageOverlaysBuilder`, scaled to the page. A page annotation, or a
  passage whose characters the page no longer has, is pinned at the page's
  corner.

The file's pane moves to a link's place on its own counter of links
followed (`_linksFollowed`), not on the note reload token, which also moves
on a resume, a sync, and an annotation written.

Tests: `test/unit/annotation_test.dart`, `companion_notes_test.dart` (a
real index and `NoteOps`), `visible_text_test.dart`,
`test/widget/annotation_sheet_test.dart`, `shell_annotation_flow_test.dart`,
the `#284` group of `epub_pane_test.dart`. The PDF view has no widget test:
pdfium does not load under `flutter test`.
