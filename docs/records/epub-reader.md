# EPUB reader (#280)

EPUBs open in the note pane, beside pictures and PDFs
(`lib/src/ui/attachment_view.dart`), on Android, Linux, Windows, macOS and
iOS.

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

- `lib/src/epub/epub_archive.dart` — `EpubArchive` (#1138): the zip,
  decoded from the file and never held whole, read within bounds — at most
  100,000 entries and 1 GiB declared or inflated in all, 32 MiB for one
  file read as text, every entry inflated against what is left of the
  budget (`import/bounded_entry.dart`, the Notion import's reader) — and a
  book whose spine files `META-INF/encryption.xml` lists is refused as
  protected (DRM; an obfuscated font is listed there too and is harmless).
  `EpubRefused` says why: not a book, protected, too large.
  `looksLikeEpub` tells a book by its first entry, `mimetype`, whatever the
  file is called.
- `lib/src/epub/epub_book.dart` — `parseEpub`: the book read into its parts
  (`EpubBook`: metadata, spine, chapters as Markdown, contents, the pictures
  and links the chapters name), one parse for the reader and the
  conversion; `epub_info.dart` reads the package's metadata.
- `lib/src/markdown/from_html/html_markdown.dart` — `HtmlMarkdown` (it began
  here as `XhtmlMarkdown` and is shared with web capture and the HTML
  import): one chapter's XHTML to Markdown, called with `xhtml: true`
  (`MarkdownWithAnchors`: the text, and `id` → line for the links into
  it). Headings, paragraphs, emphasis, strike, inline code,
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
  joined in spine order with a `---` between, line numbers tracked. The
  join is `epubBookText`'s, the conversion's own: a contents entry or a
  link on a spine page with no text opens at the next chapter. A text file
  is decoded by its byte order mark (UTF-8, UTF-16), else the `encoding`
  of its XML declaration (ISO-8859-1 and windows-1252 as Windows-1252),
  else as UTF-8 (`epub_text_bytes.dart`); a chapter's self-closed
  non-void elements (`<title/>`, `<a id="x"/>`) are written as empty pairs
  before the HTML parser reads it (`xhtml_source.dart`); an archive entry
  can be read as often as it is asked for (the spine may list the nav, or
  a page twice).
  Table of contents from the EPUB 3 nav (`properties` containing `nav`,
  `nav[epub:type=toc] ol`) or the EPUB 2 NCX (`spine@toc`), as
  `EpubContentsEntry (title, line, depth)`. Pictures named
  `epub-picture:N` and extracted once to `pictureDir/N.ext`, the folder
  named by a sha1 of the book's path, size and mtime (`pictureDirOf`)
  under `<app cache>/epub`. A picture is written to a temp name of its
  folder and renamed in, so a crash leaves a temp file, never a cut-short
  picture; a stale temp is removed when the book is read again. The cache
  is bounded (#1311, `epub_picture_cache.dart`): each read marks its folder
  as used (`.used`, a file whose time says when), and `openEpub` prunes
  after the book is read, on the reader's isolate, the least recently used
  folders past 512 MiB or 200 books, the one in use never. Links into the
  book named `epub-link:N`
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
  `LibraryConfig` as `epubLook`. `LibrarySession.librarySettings`'
  `epubLook` / `setEpubLook` read and keep it; the session publishes it, with the
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

Tests: `test/unit/html_markdown_test.dart`, `test/unit/xhtml_source_test.dart`,
`test/unit/epub_document_test.dart` (books built by
`test/fakes/epub_builder.dart`), `test/unit/epub_archive_bounds_test.dart`,
`test/unit/epub_text_bytes_test.dart`, `test/unit/epub_marks_test.dart`,
`test/unit/epub_picture_cache_test.dart`,
`test/perf/epub_marks_perf_test.dart`, `test/unit/epub_look_test.dart`,
`test/widget/epub_pane_test.dart`, `test/widget/epub_look_sheet_test.dart`,
`test/widget/epub_look_settings_test.dart`.

## How far it has been read (#1275)

`lib/src/epub/epub_progress.dart`: `EpubCounts` counts the book's
Markdown once, a line at a time — its characters, whitespace left out,
and its words, kept in halves so a script written without spaces counts a
word every two characters — on the isolate that reads the book
(`readEpub`), into `EpubDocument.counts`. `EpubProgress` looks a place up
in them against the chapters' first lines: the chapter (a binary search),
how far into it and into the book, and the minutes left to each at 250
words a minute. In characters, not lines or laid-out pixels: a book's
paragraphs vary too much in length for lines to be fair, and the pixels
are known only for the part built so far.

`lib/src/ui/epub_progress_line.dart` — `EpubProgressLine`, one button
(its semantics a container of its own: the label is what it shows, the
hint what a tap shows next) cycling `EpubProgressView` chapter → book →
time; a tooltip has the three at once. The pane follows the view's top
anchor into a `ValueNotifier` on every scroll, and the book's end once the
view can go no further, so only the line rebuilds. `EpubBar` puts it over
the row below 600 logical pixels and beside the book's name from there
(`AttachmentBar.beside`, flexible, two thirds of the room the actions
leave). The view is the books' look's `progress` (`epubProgress`), shown
on every open book at once through `EpubLooks` and kept through
`EpubPane.onProgressView` → `keepEpubProgressView`.

Tests: `test/unit/epub_progress_test.dart`,
`test/widget/epub_progress_line_test.dart`. The mockups and what was
decided with them: [docs/design/book-progress](../design/book-progress/README.md).

## Read aloud (#1276)

Android only, for now (`docs/user/platforms.md`): the other platforms have
no `ReadAloudEngine` (`ReadAloudEngine.platform` is null) and the row has
no button.

- `lib/src/epub/read_aloud_text.dart` — what is spoken, off the blocks the
  read view draws (`MarkdownReadViewState.readBlocks`): a heading's or a
  paragraph's `ReadInline.plainOf`, pictures written as nothing, split by
  `splitSentences` (a stop, any closing quote, then a space and no
  lowercase word; cut at a space past 4000 characters, the engine's
  limit). A leaf block's sentences carry their characters, so the view
  marks them where they are; a list item's or a quote's mark the whole
  block, whose drawn text has more than its words.
- `lib/src/ui/epub_read_aloud.dart` — `EpubReadAloud`, the reading: a
  sentence handed to the engine at a time with the next queued behind it
  (no gap), utterance ids so what a flush dropped is not listened to,
  chapters read when reached (two kept), the place told back
  (`onSpoken` → `ReadingTracker.moved`). Pause is a stop that keeps the
  sentence. The pace and the voice last picked are kept for the session.
- `lib/src/ui/epub_read_aloud_engine.dart` — the engine's seam and the
  `niman/read_aloud` channel; `epub_read_aloud_host.dart` — what the pane
  holds: the no-voice dialog, the mark, following until a drag
  (`ScrollStartNotification.dragDetails`), *Back to the voice*;
  `epub_read_aloud_bar.dart`, `epub_read_aloud_sheet.dart` — the player
  and the voice sheet.
- Android: `ReadAloudBridge.kt` over `TextToSpeech` and its
  `UtteranceProgressListener`, audio focus (lost → `pause`, never resumed
  by itself) and `ACTION_AUDIO_BECOMING_NOISY`, a platform `MediaSession`
  for the outside controls; `ReadAloudService.kt`, a `mediaPlayback`
  foreground service under a `Notification.MediaStyle` notification,
  stopping the reading when the task is removed; `ReadAloudVoices.kt`,
  the voices of a language, its country's first, offline before network.
  The manifest asks `FOREGROUND_SERVICE_MEDIA_PLAYBACK` and queries
  `TTS_SERVICE` (package visibility).

Tests: `test/unit/read_aloud_text_test.dart`,
`test/unit/epub_read_aloud_test.dart` (over
`test/fakes/fake_read_aloud_engine.dart`),
`test/widget/epub_read_aloud_pane_test.dart`,
`android/app/src/test/.../ReadAloudVoicesTest.kt`. The mockups:
[docs/design/book-read-aloud](../design/book-read-aloud/README.md).

## Where the reader was left (#281)

`lib/src/reading/`: a `BookLocation` is a place in a document in its own
terms — a PDF's page and how far down it, an EPUB's chapter (its spine
path), a line of that chapter and how far into it. Per chapter, not per
line of the whole book: the book is Markdown converted from its XHTML, so
a change to `HtmlMarkdown` moves lines, and kept per chapter the place
moves within one chapter at most (`EpubDocument.chapters`,
`locationAt`, `lineOfLocation`, which keeps a place past a shortened
chapter inside it). Links into a document (#282) and annotations (#284)
point with the same type, with room for a character range (#283).

A link names a place in its `#fragment` (#282): `BookLocation.fromFragment`
reads `page=N` (the PDF open-parameters form Obsidian uses, other keys
passed over) and `chapter=<path>&line=N`, values percent-decoded
(`core/percent.dart`); `toFragment` writes them, escaping what would end
the fragment or the link. `EpubDocument.lineOfLocation` finds a chapter
by its exact path, else whatever its case (a Markdown href's fragment),
else its file name alone, through maps built once (#1306), and keeps a
place of the last chapter within `lineCount`, the book's lines counted
as it is read. The pane places a book's marks once per change of the
marks or the book (`EpubBlockMarksCache`), not in every build. The shell hands the fragment to the pane as the
tab's `anchor`, the one a note gets for a heading, with the reload token
for the same link followed again; the pane goes there on open, over the
saved position, and on a new fragment or token later — not on the same
fragment handed again as a tab comes back.

The link button on the row of a book (`EpubBar`) and of a PDF
(`PdfDocumentView`, which now brings its own row) is a `PlaceLinkButton`:
it asks the pane for the place being read — the book's top line, the next
one when the view is mostly past it, labelled with the contents entry
being read; the PDF's page, labelled `pdfPageLabel` — and copies
`placeLink` (`lib/src/links/place_link.dart`): the library-relative path,
which always resolves, the fragment, and the label as the alias or the
Markdown text, the href percent-encoded as Obsidian writes one.

`ReadingPositions` keeps them in `.niman/reading.json`, by library-relative
path, each with the time it was read (`at`); it is a library state file,
synced and merged book by book (`mergeReadingJson`, see `sync.md`).
Nothing is cached: a pane reads the file when it opens a document, and the
writes of a library run one after the other, each reading the file afresh.
`NoteOps` carries the entries of a file or folder it moves or renames.

`ReadingTracker` is what a pane feeds: `placed` once the document is set
where it was left, `moved` as the view moves (the EPUB pane from the read
view's `topAnchor` on every scroll, the PDF view from pdfrx's
`visibleRect` against its page layout), `flush` when it lets the document
go. It writes a place once the reader rests a second, and never a place
the view merely settled on (`BookLocation.isNear`): a book opened and not
moved is not a reading, and must not outdate, by its newer `at`, the place
another device wrote.

Tests: `test/unit/reading_positions_test.dart`,
`test/unit/pdf_location_test.dart`, `test/unit/note_ops_reading_test.dart`,
the `#281` groups of `test/widget/epub_pane_test.dart` and
`test/unit/state_merge_test.dart`. The PDF view has no widget test:
pdfium does not load under `flutter test`.

## Converting a book into notes (#1138)

The same parse (`parseEpub`) feeds the conversion, on an isolate of its
own (`epub_convert_job.dart`, driven from the UI by `epub_conversion.dart`
with a cooperative cancel): the reader's text, joined by `epubBookText`,
is planned into notes by the book's contents (`epub_convert_plan.dart`
over `import/book/book_plan.dart`, shared with the HTML book), each note's
pictures and links rewritten to the library's files
(`epub_convert_render.dart` — only where the converter wrote a
placeholder, never words of the book that look like one), and the whole
written into a hidden `.epub.niman-tmp-<micros>` folder moved in at the end
(`import/book/book_move_in.dart`). The pictures are named by their content
and typed by their bytes (`epub_picture_type.dart`). What a user sees:
[organization](../user/organization.md#converting-a-book-into-notes).

Tests: `test/unit/epub_convert_test.dart`,
`test/unit/epub_convert_plan_test.dart`, `test/unit/epub_picture_type_test.dart`,
`test/widget/epub_convert_dialog_test.dart`,
`test/widget/epub_convert_flow_test.dart`.

## Later, maybe

- A chapter-per-scan cache if very long books open slowly: today every
  open converts the whole book on an isolate.
