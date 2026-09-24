# EPUB reader (#280)

EPUBs open in the note pane, beside pictures and PDFs
(`lib/src/ui/attachment_view.dart`), on Android, Linux and Windows.

## Why not a package

`epub_view` was tried and dropped (spike result in #280): every `epubx`
wants `xml` ^6, `image` ^3 and `archive` ^3 against the app's `xml` ^7 and
`pdfrx`'s `image` ^4.8 / `archive` ^4, and with overrides it still does not
compile (`epubx` imports `xml`'s removed `src/xml/builder.dart`;
`flutter_html` 3.0.0 does not compile on the current `html`/`csslib`).
`flutter_epub_viewer_kit` sits on the same two packages, has no Windows or
Linux, and loads `google_fonts` from the network.

## The way taken

Read the EPUB with what the app has, draw it with the app's read view.

## How it is built

- `lib/src/epub/xhtml_markdown.dart` — `XhtmlMarkdown`: one chapter's
  XHTML to Markdown (`ChapterMarkdown`: the text, and `id` → line for the
  links into it). Headings, paragraphs, emphasis, strike, inline code,
  `<br>` as a hard break, lists (nested, `start=`), blockquotes, `<pre>`,
  `<hr>`, tables (GFM, first row as header), pictures (`img`, SVG
  `image` — inline, as a browser has them), links. Every text character
  Markdown or the app's own extensions read as syntax is
  backslash-escaped (`#` tags, `$` math, `[[` links, `*`, `|`, `=`, `~`,
  `^`, `&`, `!`…; the extension masker and `findInlineMath` honour the
  backslash), and a paragraph opening with `-`, `+` or `1.` is escaped
  too. Pictures and links go through callbacks that name them
  (`picture(src)`, `link(href)`). The book's CSS is not read.
- `lib/src/epub/epub_document.dart` — `readEpub(path, pictureDir)` /
  `openEpub(path, cacheDir)` (on an isolate, the file stat'ed there too):
  `META-INF/container.xml` → OPF (elements matched by local name,
  `<opf:item>` too) → manifest and spine → every chapter converted and
  joined in spine order with a `---` between, line numbers tracked.
  Table of contents from the EPUB 3 nav (`properties` containing `nav`,
  `nav[epub:type=toc] ol`) or the EPUB 2 NCX (`spine@toc`), as
  `EpubContentsEntry (title, line, depth)`. Pictures named
  `epub-picture:N` and extracted once to `pictureDir/N.ext`, the folder
  named by a sha1 of the book's path, size and mtime (`pictureDirOf`)
  under `<app cache>/epub`. Links into the book named `epub-link:N`
  (`EpubDocument.lineOfLink`), external ones (`http:`, `mailto:`…) kept
  as they are.
- `lib/src/ui/epub_pane.dart` — `EpubPane`: `AttachmentView` hands it
  every `.epub`. A spinner while the book is read, the unreadable message
  on any error. The book is a `MarkdownReadView` at the note text size
  (`noteTextScalerOf`), in the shell's note column; its pictures resolve
  through `embedResolver`, `epub-link:N` taps `jumpToLine`, the rest go
  to `launchUrl`.
- `lib/src/ui/attachment_bar.dart` — `AttachmentBar`, the row under
  every attachment, with an `actions` slot left of *Open in default
  app*. The book puts its **Outline** button there (disabled while it is
  read or when it has no contents): a sheet of the contents indented by
  depth, the chapter at the top of the view marked, a tap jumps.

Tests: `test/unit/xhtml_markdown_test.dart`,
`test/unit/epub_document_test.dart` (books built by
`test/fakes/epub_builder.dart`), `test/widget/epub_pane_test.dart`.

## Later, maybe

- Keep the reading position per book (the read view's `topAnchor` /
  `showAnchor`, stored per path like tab mementos).
- A chapter-per-scan cache if very long books open slowly: today every
  open converts the whole book on an isolate.
