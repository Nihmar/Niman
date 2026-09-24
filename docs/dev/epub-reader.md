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
  on any error. The book is a `MarkdownReadView` in the shell's note
  column; its pictures resolve through `embedResolver`, `epub-link:N`
  taps `jumpToLine`, the rest go to `launchUrl`. The whole pane, its row
  included, sits in a `Theme` of the books' look (`epubThemeOf`) and a
  `MediaQuery` at their text size (`epubTextScalerOf`), rebuilt on
  `EpubLooks.revision`.
- The books' look — `lib/src/epub/epub_look.dart`: `EpubLook` (theme id
  or null for the app's, `AppBrightness` or null for the app's,
  `EpubFont`, text scale), four device keys of the library's settings
  (`epubTheme`, `epubBrightness`, `epubFont`, `epubTextScale`), part of
  `LibraryConfig` as `epubLook`. `LibrarySession.epubLook` /
  `setEpubLook` read and keep it; the session publishes it, with the
  theme it names resolved (a custom theme from the app database, none
  when it is gone), to the global `EpubLooks` (`epub_looks.dart`) when
  the library opens, when it is set, and when a custom theme is saved or
  deleted; closing the library resets it. `lib/src/ui/epub_theme.dart`
  turns it into the pane's `ThemeData`: the app's own theme untouched
  when the books ask for nothing else, otherwise `buildAppTheme` at the
  books' brightness, its `textTheme` in the books' face. The faces:
  Literata, bundled (`assets/fonts/literata/`, regular, italic, bold,
  bold italic, SIL OFL 1.1 with its `OFL.txt` as an asset); `serif` and
  `monospace` with the common platform faces as fallbacks (Windows has
  no `serif` alias); the app's own for sans serif. Code blocks stay
  monospace whatever the face.
- `lib/src/ui/epub_look_sheet.dart` — `showEpubLookSheet` /
  `EpubLookPanel`: theme and brightness dropdowns, a chip per face (each
  named in itself), a text-size slider that publishes to `EpubLooks`
  while it moves and keeps the size when let go. The book's **Aa**
  button opens it (`EpubPane.onEditLook`, from the shell through
  `ShellDetailPane` / `AttachmentView`), and so does Settings →
  Appearance → *Book appearance* (`SettingsKeys.epubLook`, in the
  settings search too), whose value is `epubLookSummary`.
- `lib/src/ui/attachment_bar.dart` — `AttachmentBar`, the row under
  every attachment, with an `actions` slot left of *Open in default
  app*. The book puts its **Aa** and **Outline** buttons there (Outline
  disabled while the book is read or when it has no contents): a sheet
  of the contents indented by depth, the chapter at the top of the view
  marked, a tap jumps.

Tests: `test/unit/xhtml_markdown_test.dart`,
`test/unit/epub_document_test.dart` (books built by
`test/fakes/epub_builder.dart`), `test/unit/epub_look_test.dart`,
`test/widget/epub_pane_test.dart`, `test/widget/epub_look_sheet_test.dart`,
`test/widget/epub_look_settings_test.dart`.

## Later, maybe

- Keep the reading position per book (the read view's `topAnchor` /
  `showAnchor`, stored per path like tab mementos).
- A chapter-per-scan cache if very long books open slowly: today every
  open converts the whole book on an isolate.
