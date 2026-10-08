# Web capture (#531)

Saving a web page — or a selection of it — as a clean Markdown note, its
pictures in the attachments folder. Written before the code (2026-10-07), as
the plan the work follows; the screens are in
[docs/design/web-capture](../design/web-capture/README.md).

## Why the plan changed from the issue

The issue chose Readability.js running in "the same headless JS engine the
diagrams bring" (#530). #530 shipped a Mermaid engine written in Dart instead,
so there is no JS engine to share, and adding one — QuickJS or flutter_js,
Readability.js and a light DOM such as linkedom — would put a native runtime
in every build for this one feature.

The constraint that shapes the rest: **no new pub dependency.**

- **The article** is found by a Dart port of Readability.js (Mozilla,
  Apache-2.0) over `package:html`, already a dependency through the EPUB
  reader. The port keeps upstream's algorithm and names, so a diff against a
  new upstream release stays readable.
- **The conversion** to Markdown is `XhtmlMarkdown`
  (`lib/src/epub/xhtml_markdown.dart`), moved to
  `lib/src/markdown/from_html/` (`markdown/html/` is the writer the other way)
  and grown for the web.
- **HTTP** is `dart:io`'s `HttpClient`, as the sync and the updates use it.
- **The clipboard's HTML** is read by Niman's own native code on each
  platform, not by `super_clipboard`, which would bring a Rust toolchain.
- **Notifications with buttons** are already in flutter_local_notifications
  22 on all three platforms (`AndroidNotificationAction`,
  `LinuxNotificationAction`, `WindowsAction`).

## The port

`lib/src/capture/readability/`, one concern per file and each under 300
lines, every file headed "Ported from mozilla/readability, Apache-2.0":
patterns and options, the DOM walk, text metrics, candidate scores,
preparing the document, grabbing the article, the top candidate and its
siblings, cleaning (plain and conditional), post-processing (absolute
URLs), metadata (meta tags, OpenGraph, JSON-LD), `isProbablyReaderable`, and
the entry point with upstream's retry loop over the flags.

What `package:html` 0.15.7 lacks, and how it is filled:

| Missing | Filled by |
|---|---|
| `nextSibling` / `previousSibling` on plain nodes | helpers over `parentNode.nodes` |
| renaming a tag (`localName` is final) | a new `Element.tag`, attributes copied, children reparented, score moved |
| data on a node (`node.readability`) | an `Expando` |
| `style` | a small parser of the inline `display` and `visibility` |
| `baseURI` | the page's `Uri` passed in, then the first `base[href]` |
| `innerHTML` cached between retries | `document.clone(true)` per attempt |

`package:html` decodes only ASCII and UTF-8 bytes itself, and throws on
Windows-1252, so the page is always decoded to a String before it is parsed.

The licence ships with the app: `assets/licenses/readability.txt`, added to
Flutter's `LicenseRegistry`, shown from an "Open-source licences" row in
Settings › About.

## The oracle

Mozilla's own test pages — `source.html`, `expected.html`,
`expected-metadata.json` — for a subset kept in
`test/fixtures/readability/`, pinned to an upstream commit, with its README
and licence. Synthetic pages come first; real pages only from permissive or
institutional sites (Wikipedia, Mozilla, IETF).

The article is compared as a tree, not as bytes: a pre-order walk that skips
whitespace-only text and comments and compares the tag, the attribute set
and the collapsed text, reporting the path of the first difference.
Metadata is compared field by field. html5lib and upstream's JSDOMParser do
not always build the same tree; each such page is listed in
`known-diffs.txt` with its reason, and the list only shrinks.

Niman's own fixtures (`test/fixtures/capture/`) end in a golden `.md`: a
figure with `srcset` and lazy pictures under a `<base href>`, a page that
builds its text with a script, a page with nothing but OpenGraph, a
Windows-1252 page, a Shift_JIS page, a byline from JSON-LD.

A perf test runs the Wikipedia page and holds its absolute bar behind
`NIMAN_PERF`, as every perf test does.

## The pipeline

1. **Download** (`lib/src/capture/fetch/`), in `Isolate.run`: http and https
   only, up to 5 redirects, 15 s to connect and 30 s in all, at most 10 MB,
   HTML or XHTML only. The user agent says it is Niman.
2. **Charset**: BOM, then the `Content-Type` header, then a `<meta>` in the
   first 1024 bytes, else UTF-8. UTF-8, ASCII, Latin-1 and Windows-1252 are
   decoded with `decodeNoteText`, UTF-16 by hand; any other charset counts
   as too little text, so the browser — which decodes everything — reads it.
3. **Extract** with the port. Too little text means no article, fewer than
   500 characters, or a charset step 2 could not decode.
4. **Only then, the browser**, and step 3 again:
   - desktop: the engine the PDF export already finds (`findPdfEngine`: Edge
     on Windows, a Chromium on `PATH` on Linux) with `--headless=new
     --dump-dom`, a throwaway profile deleted afterwards, a time budget for
     the page's scripts, 45 s and 20 MB at most;
   - Android: a WebView of its own (`PageReaderBridge.kt`, separate from the
     PDF one), JavaScript on, network pictures off, no file access and no JS
     interface, its `outerHTML` read once the page has settled.
5. **Convert** to Markdown and **download the pictures** into the
   attachments folder, named by their SHA-256 as pasted pictures already
   are: 15 MB each, 60 at most, 4 at a time.
6. **Save** the note: frontmatter `source`, `captured`, `author`, `tags`.
   When nothing was found even after the browser — or there is no browser,
   on a Linux without Chromium — the note keeps the title, the description
   and the picture, under a quoted notice to open the link.

What was removed (scripts, the menu, a cookie banner, the footer) is
counted outside the port, so the port stays what the oracle checks.

## The platforms

- **Desktop**: **Capture web page…** in the command palette, a link pasted
  outside the editor, or a link dropped on the window. Dropping a link needs
  the runners: on Linux, http(s) entries of `text/uri-list` are forwarded; on
  Windows, an OLE `IDropTarget` replaces `DragAcceptFiles`, for files and
  URLs alike.
- **Android**: Share → Niman. The share bridge also sends `EXTRA_SUBJECT`; a
  lone URL or "title, URL" is a page, text with a URL carrying `#:~:text=` (or
  quoted text before a URL) is a quote, anything else goes to the quick note
  as today. On Save the sheet closes and the task goes back to the browser;
  the capture runs in the app's own engine under the notification plugin's
  foreground service (`shortService`, so it must end within its three
  minutes: Niman stops at 150 s). No second Flutter engine, no WorkManager.
- **Paste as Markdown** (Ctrl+Shift+V, the editor's menu on a phone):
  Windows reads `HTML Format` through `dart:ffi` (its offsets are bytes, and
  it carries `SourceURL`); Linux asks GTK for `text/html` and the browsers'
  source-URL targets; Android reads `ClipData.getHtmlText()`, which has no
  source URL. Undo puts the plain text in its place.

  Settled while building it (PR 4): CF_HTML is converted from `StartHTML`
  to `EndHTML` — the context, so list items keep their list — and the
  fragment alone only when there is none. The page is linked by a last
  paragraph `— [label](<url>)`, as a captured quote is, the label being a
  `<title>` the copy carries, else the host. Pictures stay remote links:
  a paste downloads nothing, and one with no web address (`data:`,
  `blob:`, a relative address with no page) is left out. On Linux the page
  is Chromium's `chromium/x-source-url` or Firefox's
  `text/x-moz-url-priv`, and the bytes are decoded in Dart, UTF-16 when
  Firefox wrote them so.

## Delivery

One PR at a time, each branched from main once the one before is merged:

1. **The engine**, no UI: the moves (`HtmlMarkdown`, the process runner, the
   attachment store), the port and its oracle, the download, the charsets,
   the pictures, the notes.
2. **The browser fallback**, desktop and Android.
3. **The capture UI**, on all three platforms at once: the dialog, the
   share sheet, the notifications, the drops, and the user guide.
4. **Paste as Markdown**, on all three platforms at once.

## Risks

- The two parsers' trees differ in places: the known-diffs list absorbs it,
  and says why.
- `text` is recomputed on every call; on a huge page on a phone that may
  cost. The perf test watches it; caching text per pass is the fix.
- Edge headless: whether `--dump-dom` reaches a pipe on Windows, and whether
  a managed policy forbids headless runs, is the first thing PR 2 checks.
- Android: the foreground service's limit, vendors that kill background
  work, a WebView throttled off-screen. A bot wall ends in the unreadable
  note, by design.
- The clipboard: X11 and Wayland offer different targets.
- The fixtures add a few megabytes to the repository.
