# Export: plan (#24, #63)

Export a note, a folder or the library as Markdown, HTML and PDF. The
decisions are in the #24 thread
(<https://github.com/Nihmar/Niman/issues/24#issuecomment-5834935542>).
This file is the working plan: what is done, what is left, and in what
order. Tick the steps off as they land.

## Done (branches `feat/24-export`, then `feat/63-pdf`)

| Commit | What |
|---|---|
| `a8c0349b` | `nimanInlineSyntaxes`: `==mark==` and `<u>`/`<sup>`/`<sub>` shared by the read view and the export |
| `85cfa667` | `MathSvg`: a formula as inline SVG from `katex_dart`. The fonts are stripped from each drawing and declared once by the page, and only when a drawing writes text |
| `f3d52926` | `wikiDisplayText`: one rule for what a wikilink shows |
| `aaa94d20` | `NoteHtml` + `htmlPage`: a note as one self-contained HTML page (see below) |
| `f693ad30` | `ExportSources`: the embed resolver shared with the read view; pictures gathered and read as `data:` URIs off the UI isolate |
| `2b5cc8ac` | A note as Markdown or one HTML page, behind the `SaveExportFile` seam; the ⋮ menu and the palette |
| `73e98c8a` | A folder or the library as one zip, streamed with progress and cancel; the tree menus and the library palette command |

**How `NoteHtml` works.**
- One `md.Document` parse over the whole note, with GFM plus the shared inline syntaxes.
- Before the parse, the blocks the read view draws itself are replaced by tokens: fences (highlighted by `highlight`), math blocks, raw HTML blocks (shown as source) and callouts (`<details>` when they fold).
- Inside every other block, the constructs `ExtensionMasker` finds become tokens too.
- Tokens are put back after the parse. In an attribute they become the construct's plain text.
- Pictures and link targets come in resolved, in `NoteHtmlSource`. Building a page reads nothing, so it can run on any isolate.

Checked in a browser on the 10 KB and 50 KB fixtures, light and dark:
- Tables, task lists, stretchy delimiters and inline formulas render right.
- About 0.1–0.2 s per note. The KaTeX fonts, about 500 KB, are added once when needed.

## 1. Finish HTML (#24)

### 1.1 Resolving the sources
- [x] Extract `NoteViewState._resolveEmbed` into a shared `resolveEmbedPath(target, notePath, root, linkSource)`, used by the read view and the export. Its lookup order stays as it is: library root, then the note's folder, then `LinkSource.resolveWiki`.
- [x] `ExportSources` collects a note's picture targets:
  - an embed's (`ExtensionMasker` spans of kind `embed`);
  - an image's (`md` `img` `src`, as written and decoded).

  Each target is resolved with the shared resolver. Only `EmbedView.imageExtensions` count as pictures.
- [x] Bytes become `data:` URIs off the UI isolate (`Isolate.run`), with the MIME type from the extension. There is no size cap; a picture that cannot be read stays as written, and the skip is logged.
- [x] The page is built off the UI isolate too: `Isolate.run(() => htmlPage(NoteHtml(source).body() …))`.
- [x] Tests: the resolver's order, an unreadable picture, a note with none.

### 1.2 Single note
- [x] `.md`: the note's bytes as they are on disk.
- [x] `.html`: the page above. Its title is the note's display name (`displayNameOf`) and its `lang` is the app language.
- [x] Save through `FilePicker.saveFile(bytes: …)`, as `theme_files.dart` does. Put it behind an injectable typedef so widget tests can replace it. On Android this goes through SAF; on desktop, a save dialog.

### 1.3 Folder and library
- [x] **Zip of `.md`:** the subtree as it is on disk, attachments included, dot folders (`.niman`, `.trash`, `.history`) left out.
  - The zip is streamed to a file (`archive`'s `ZipFileEncoder`), never built in memory: a library can be a million notes. Keep the design rule "no O(n) in memory on a hot path".
  - Destination: a folder picked with `FilePicker.getDirectoryPath`, written with `dart:io`. Android can do this too, because the app already has all-files access (`storage_access.dart`); SAF would need the bytes up front.
- [x] **Zip of HTML pages:** every note becomes `path/Name.html` at its own relative path.
  - `links` and `images` resolve **inside the exported subtree**: a target there becomes a relative URL, one that is not stays as the note wrote it. *Changed from the plan's `LinkSource.resolveBatch`: the index lives on the UI isolate, and resolving against the tree keeps the whole export on the export isolate and gives the behavior the export wants anyway.*
  - Pictures are copied into the zip at their tree-relative paths, and `images` maps them to relative URLs instead of `data:`, so a picture used by many notes is stored once.
  - Non-note files, and notes that are not Markdown, are copied as they are.
- [x] Work runs one entry at a time in a background isolate, with progress and cancellation. A cancelled export deletes its partial zip.
- [x] Tests:
  - zip contents and relative hrefs across folders;
  - the heading anchor of `[[Note#Part]]`;
  - a link to a note outside the exported folder, which becomes highlighted text;
  - cancellation.

## 2. PDF (#63), on its own branch after #24

The PDF is the exported HTML page, printed. `htmlPage` already has
`@media print` rules. Add `@page { size: A4; margin: 18mm; }` and keep
`break-inside: avoid` on blocks.

### 2.1 Engines
- [x] A `PdfPrinter` interface: `Future<PdfOutcome> print(String htmlPath, String pdfPath)`. `PdfOutcome` is one of: printed, no engine, or failed (with a message).
- [x] **Windows: Edge.** Find `msedge.exe` through the `App Paths` registry key, then `Program Files (x86)\Microsoft\Edge\Application`. Run it with:
  - `--headless=new --disable-gpu --no-pdf-header-footer`
  - `--print-to-pdf=<out> file:///<page>`

  Use a timeout that kills the engine, and check that the file exists and is not empty.
- [x] **Linux: Chromium.** Search `PATH` for `chromium`, `chromium-browser`, `google-chrome`, `google-chrome-stable`, `microsoft-edge`, `brave-browser`, with the same flags.
- [x] **Android: WebView.** A `MethodChannel` (`niman/pdf`) in `MainActivity`:
  1. An offscreen `WebView` loads the page with `loadDataWithBaseURL`.
  2. On `onPageFinished`, call `createPrintDocumentAdapter`.
  3. `layout` and `write` go to a file through a small helper in the `android.print` package, because its callback constructors are package-private.
  4. A4, no margins beyond the CSS.

  A `cancel` call destroys the view and answers a waiting print, so a
  cancelled export leaves no busy bridge. No on-device test yet (§4).
- [x] Tests: engine discovery with a fake `PATH` and a fake file system; the command line that is built; the outcomes.

### 2.2 Raster fallback (Linux without Chromium)
- [x] Lay out `MarkdownExportView` offscreen at the page's content width. The pipeline (`RenderView`, `BuildOwner`, `PipelineOwner`) is left to the caller by `markdown_export.dart`, so it lives here.
- [x] The page is a **slice of the one tall layout**, not a break the layout chose: a line or a picture crossing a slice's edge is cut in two. (The planned block-level page breaks were not built: the printed browser path owns real pagination, and this is the fallback for a machine without one.)
- [x] The note is recorded **once** and sliced per page; pages go into a `PdfWriter` one at a time, so a novel does not hold every page's pixels at once.
- [x] Every picture the note shows is decoded and drawn in place — the fallback hands the page its pictures, or the note would silently lose them.
- [x] The printed page points at its pictures with `file:` URLs, where the exported HTML must carry `data:` URIs: the engine fetches them itself, and embedding a library's photos built pages of hundreds of megabytes — the Android bridge read one into its own heap until it OOM'd.
- [x] The export says it is running — the engine printing, then the pages drawn — and can be cancelled from the dialog; the fallback checks between pages, and Android's bridge stops a print in flight.
- [x] Afterwards the app says what happened: the PDF is a picture of the pages, and a browser engine on the machine gives selectable text.
- [x] Tests: the page count over a known note; the paper is A4 in points; a picture handed in is drawn; the writer round-trips its image streams.

### 2.3 What gets exported as PDF
- [x] A note gives one `.pdf`.
- [x] A folder gives a zip with one `.pdf` per note, its pictures embedded. A combined PDF is an open question (below).

## 3. Hooking up the UI

Every entry exists on Android, Linux and Windows.

- [x] **The note's ⋮ menu.**
  - Add `NoteMenuAction.export` in `ui/note_menu.dart`, inside `if (textNote)`, next to Format and History; the key is `note-menu-export`.
  - It is handled in `shell.dart`'s `_noteMenu()`.
  - It opens an **Export** sheet (phone) or dialog (desktop) with the formats Markdown / HTML / PDF. *(PDF in #63.)*
- [x] **The tree row menu** (`ui/shell_row_menu.dart`, `rowMenuGroups`, the file group):
  - a note gets "Export…", the same chooser;
  - a folder gets "Export folder…", with Markdown zip / HTML zip. *(PDF in #63.)*

  Dispatch goes in `ui/shell_row_actions.dart` `run`.
- [x] **The tree's background menu** (`showTreeBackgroundMenuAt`): "Export library…", the folder chooser for the root.
- [x] **Command palette.** Add `AppCommand.exportNote` and `AppCommand.exportLibrary` in `ui/app_shortcuts.dart`, with labels.
  - `paletteGroup`: note / library. `paletteAsks`: true.
  - `commandNeeds`: `{CommandNeed.textNote}` for the note.
  - Handlers in `shell.dart` `_allCommandHandlers()`. Key maps and pins pick them up from `AppCommand.values`.
- [x] **Progress.** A single note is quick: a snackbar at the end. A folder gets a progress dialog with a cancel button.
- [x] **When it is done.** A snackbar with where the file went. On desktop it also offers **Show in folder** (`file_tree_context.dart`).
- [x] **Strings** in every locale (`ui/strings/*.dart`).
- [ ] **Docs:**
  - [x] `docs/user/`: a new `export.md`, linked from `organization.md`;
  - [x] `platforms.md`: the PDF engine per platform and the Linux fallback; *(with #63)*
  - [x] `settings.md`, if a setting appears; *(no setting)*
  - [ ] `CHANGELOG.md` at the release.
- [x] **Widget tests:** the menu entries, the chooser, the save call through the fake picker, and cancellation.

## 4. Order of work

1. `feat/24-export`:
   1. 1.1 sources;
   2. 1.2 single note;
   3. the UI entries for a single note (part of 3);
   4. 1.3 folders and the library, with their UI entries;
   5. docs;
   6. PR `Closes #24`.
2. `feat/63-pdf`:
   1. 2.1 engines, Windows and Linux first, then Android;
   2. 2.2 fallback;
   3. 2.3;
   4. the PDF format in the choosers;
   5. docs;
   6. PR `Closes #63`.

Commit each step as it lands. Run analyze and the targeted tests on each commit, and the integration tests before the PR.

## Open questions

- A folder as **one combined PDF** (notes in tree order, a page break between them) instead of a zip of PDFs.
- **Very large pictures** inline in a single-note page: embed them all, or link them above some size.
- A **library-wide HTML zip on a phone**: it streams, so memory is bounded, but the time for a million notes calls for a progress estimate before it starts.
