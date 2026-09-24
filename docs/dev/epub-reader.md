# EPUB reader — work in progress (#280)

Branch: `feat/epub-reader`, off `integration/unmerged` at `124f116`
(pictures and PDFs already open in the note pane: `lib/src/ui/attachment_view.dart`).

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

## Done (compiles, `flutter analyze --fatal-infos lib/src/epub` clean, no tests yet)

- `pubspec.yaml`: `archive: ^4.3.0` and `html: ^0.15.7` as direct
  dependencies (both resolve alongside `pdfrx`; `archive` came through it
  already). **Still to do:** a comment above each, like the others.
- `lib/src/epub/xhtml_markdown.dart` — `XhtmlMarkdown`: one chapter's
  XHTML to Markdown (`ChapterMarkdown`: the text, and `id` → line for the
  links into it). Headings, paragraphs, emphasis, strike, inline code,
  `<br>` as a hard break, lists (nested, `start=`), blockquotes, `<pre>`,
  `<hr>`, tables (GFM, first row as header), pictures (`img`, SVG
  `image`), links. Every text character Markdown or the app's own
  extensions read as syntax is backslash-escaped (`#` tags, `$` math,
  `[[` links, `*`, `|`, `=`, `~`, `^`, `&`, `!`…; the extension masker
  and `findInlineMath` honour the backslash), and a paragraph opening
  with `-`, `+` or `1.` is escaped too. Pictures and links go through
  callbacks that name them (`picture(src)`, `link(href)`).
- `lib/src/epub/epub_document.dart` — `readEpub(path, pictureDir)` /
  `openEpub` (on an isolate): `META-INF/container.xml` → OPF (elements
  matched by local name, `<opf:item>` too) → manifest and spine → every
  chapter converted and joined in spine order with a `---` between, line
  numbers tracked. Table of contents from the EPUB 3 nav (`properties`
  containing `nav`, `nav[epub:type=toc] ol`) or the EPUB 2 NCX
  (`spine@toc`), as `EpubContentsEntry (title, line, depth)`. Pictures
  named `epub-picture:N` and extracted once to `pictureDir/N.ext`
  (`EpubDocument.pictures`: name → absolute path). Links into the book
  named `epub-link:N` (`EpubDocument.lineOfLink`), external ones
  (`http:`, `mailto:`…) kept as they are.

## Still to do

1. **The pane.** In `AttachmentView` (`lib/src/ui/attachment_view.dart`),
   `.epub` → a new stateful widget in its own file (one class per file),
   e.g. `lib/src/ui/epub_pane.dart`:
   - picture folder: `getApplicationCacheDirectory()` / `epub` / a digest
     (`crypto` sha1) of path + size + mtime;
   - `openEpub` on open; a spinner meanwhile, `AppStrings.attachmentUnreadable`
     on a `FormatException`/any error;
   - `MarkdownReadView(buffer: SourceBuffer.fromText(doc.markdown),
     parser: BlockParser(), mathCache: MathCache() /* dispose it */,
     embedResolver: (t) async => doc.pictures[t], onTapLink: …,
     column: …)` wrapped like `NoteView` does
     (`MediaQuery…copyWith(textScaler: noteTextScalerOf(context))`,
     theme `markdownThemeOf(context, scaler: noteTextScalerOf(context))`),
     a `GlobalKey<MarkdownReadViewState>` to jump;
   - `onTapLink`: `epub-link:N` → `jumpToLine(doc.lineOfLink(href))`;
     `http(s)`/`mailto` → `launchUrl`;
   - the bottom row: move `_AttachmentBar` out of `attachment_view.dart`
     into its own file with an `actions` slot, and add a contents button
     (`Icons.toc`, tooltip `AppStrings.outlineTooltip`) opening a bottom
     sheet of `doc.contents` (indented by depth) that jumps on tap;
   - pass the shell's `NoteColumn` into `AttachmentView` (both builders:
     `ShellDetailPane._view` and `_LibraryShellState._phoneNoteView`) so
     a book reads in the note column.
   - `isShownAttachment` in `attachment_view.dart`: add `.epub`.
2. **Tests** (portable paths, `p.join`):
   - `test/unit/xhtml_markdown_test.dart`: each construct; escaping
     (`#tag`, `$5 and $6`, `[[x]]`, `*a*`, `a|b` in a table, `1. at a
     paragraph start`); nested lists; anchors → lines; pictures and links
     through the callbacks;
   - `test/unit/epub_document_test.dart`: build EPUBs in the test with
     `archive` (`ArchiveFile.string`, `ZipEncoder().encode`) — an EPUB 2
     with an NCX and an EPUB 3 with a nav, `<opf:item>` prefixes, a
     picture (bytes written and resolvable), links across chapters with
     fragments, a missing chapter file, not-an-EPUB → `FormatException`;
   - a widget test of the pane with a small EPUB (the read view draws a
     chapter; contents sheet jumps) — mount under `tester.runAsync`, the
     isolate is real I/O.
3. **Docs:** `docs/user/organization.md` ("Files that are not notes"):
   EPUBs open in the pane, set in the app's typography (the book's own
   CSS is not read), contents from the bottom row; `pubspec.yaml`
   comments.
4. Commit (`feat(ui): EPUBs open in the note pane`), merge into
   `integration/unmerged` with `--no-ff`, close #280 with a comment.

## Later, maybe

- Keep the reading position per book (the read view's `topAnchor` /
  `showAnchor`, stored per path like tab mementos).
- A chapter-per-scan cache if very long books open slowly: today every
  open converts the whole book on an isolate.
