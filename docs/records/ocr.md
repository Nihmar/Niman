# Text recognition (#532)

Recognizing the text of a scanned PDF or a picture, on the device, into a
`.ocr.md` note next to the file. The work is split in four, each shipped
on every platform: the engine, the languages and their settings (#593);
the **Recognize text** command and the sidecar (#594); the Text pane and
the tree (#595); the recognized lines on the scan (#596). The screens are
in [docs/design/ocr](../design/ocr/README.md).

The constraint that shapes all of it: **the app must grow as little as
possible.** Nothing the recognition needs ships in the package; the engine
and every language are downloaded from inside the app, the first time they
are needed.

## The engine — phase 1 (#593)

Tesseract 5 through `dart:ffi`, the hunspell way: hand-written bindings for
the ~20 functions of the C API the app calls
(`lib/src/ocr/tesseract_bindings.dart`), no ffigen. `Tesseract`
(`tesseract.dart`) loads the languages once and reads an 8-bit gray page
into lines, each with its box in fractions of the page's width and height
and whether a paragraph starts with it.

### One library, built for the download

`scripts/ocr-engine.sh` builds a single shared library per target:
Tesseract 5.5.3 over a **static Leptonica 1.87.0**, and nothing else.

| Cut | Why it is safe | What it saves |
|---|---|---|
| Leptonica without image codecs (zlib, png, jpeg, tiff, webp, gif, openjpeg) | The app hands the pixels over raw: pdfrx renders a page, `dart:ui` decodes a picture | Every codec library, and their dependencies |
| `DISABLED_LEGACY_ENGINE` | tessdata_fast and tessdata_best are LSTM models only | About half the code |
| Only `Tess*` exported (version script), `--gc-sections`, LTO | The app calls the C API only | 2540 → 137 exported symbols; with the line above, 8.2 MB → 3.4 MB on Linux |
| No OpenMP, no libarchive, no libcurl, no training tools | One page at a time on a worker isolate; files come from the app | Runtime dependencies |
| Leptonica built with `NO_CONSOLE_IO` | Its warnings went to the app's stderr ("png library missing") | Noise |

Per target, beyond that:

- **Android** (arm64-v8a, x86_64 — the app is 64-bit only): NDK, the static
  C++ runtime, 16 KB page alignment (`max-page-size=16384`, required on
  Android 15 devices with 16 KB pages). Tesseract's NEON detection links
  google/cpu_features v0.11.0. A cross build cannot run Tesseract's TIFF
  probe: `LEPT_TIFF_RESULT=1` answers it.
- **Linux**: built on Ubuntu 22.04 with the C++ runtime static, so it
  needs only glibc 2.34+, libm and libc.
- **Windows**: MSVC with the static CRT. Leptonica's
  `cmake_minimum_required(3.10)` ignores `CMAKE_MSVC_RUNTIME_LIBRARY`
  unless `CMAKE_POLICY_DEFAULT_CMP0091=NEW` forces it; without it the two
  libraries mixed /MD and /MT and the link failed on `__imp_*` symbols.
  `SW_BUILD=OFF` keeps Leptonica from looking for the SW package manager.

| Target | Size |
|---|---|
| android-arm64-v8a | 2,347,896 B |
| android-x86_64 | 2,683,776 B |
| linux-x64 | 2,889,080 B |
| windows-x64 | 3,950,592 B |

### Published on a prerelease, pinned in the app

`.github/workflows/ocr-engine.yml` runs the script on a tag
`ocr-engine-N` and publishes the four libraries, their `SHA256SUMS` and the
two licences on that tag's release, **as a prerelease**: the updater asks
`/releases/latest`, which never answers with one, and `release.yml` runs
on `v*` tags only. `ocr-engine-1` failed on Windows (above) and published
nothing; `ocr-engine-2` is the first engine.

`lib/src/ocr/ocr_engine_build.dart` pins each file's URL, size and SHA-256:
the trust is in the app's own binary, not in whatever the URL serves. A new
engine is a new tag and an app release pointing at it; it lands under its
own `ocr/engine/<release>/` folder, so it never overwrites a library a
running process holds.

### Where the engine comes from

`findInstalledOcrEngine` (`ocr_engine_locator.dart`), on a worker isolate:

1. **Bundled** — `libniman_ocr.so` / `niman_ocr.dll` inside the package.
   No build ships one today: it is the way a Play or F-Droid build would,
   since both forbid downloading native code.
2. **System**, Linux only — `libtesseract.so.5`, then `.so.4`. Tested
   against the distribution's 5.5.3 here.
3. **Downloaded** — by its absolute path, once the file is on disk.

Each must be Tesseract **4.1 or later** (`TessVersion`): the LSTM models
need it. The downloaded engine is not probed at launch — once loaded,
Windows locks the file until the process exits, and the settings page
must be able to delete it — but it is opened **once, right after its
download**, on a worker isolate: a library the device refuses is deleted
and shown as a failed download there and then, not found by the first
recognition. On Windows that load is what locks it; a delete in the same
session fails, leaves the engine listed and logs why, and the next
launch can delete it.

Android loads a **shared library** from the app's private storage with
`dlopen` (`DynamicLibrary.open` of an absolute path), which every version
allows; executing a downloaded **binary** is forbidden since targetSdk 29
(W^X), so a `tesseract` command was never an option there.

## The languages

123 languages, each in **tessdata_fast** (1–4 MB, quick on a phone) and
**tessdata_best** (10–15 MB, better on hard scans, two or three times
slower), at pinned commits (`87416418…` and `e12c65a9…`), straight from
`raw.githubusercontent.com`. `tool/ocr_catalog.dart` lists both trees,
downloads every file once (about 1.4 GB) to hash it, and writes
`lib/src/ocr/ocr_language_catalog.dart`: code, the name in the language
itself (needs no translation) and in English (for search), size and
SHA-256 of each model.

- `osd` (orientation) and `equ` (equations, legacy-only) are not languages
  and are left out.
- tessdata_fast's `frk.traineddata` is a **symlink** in the repository: the
  raw URL serves its target's name, 20 bytes. Anything under 1 KB is
  dropped, which took Fraktur out; German Fraktur is `deu_latf`.

The default language follows the app's (`ocrCodeOfAppLanguage`, every app
language has one) until one is chosen.

## Downloads

The transcription's downloader, moved to `lib/src/core/download/` and made
generic over a `Downloadable` (id, URL, size, file name, SHA-256): an
isolate per download, `.part` + rename, `Range` resume, retries, cancel,
and a resume when the app returns to the foreground. New for OCR: **a
pinned SHA-256 is checked in the download isolate before the rename**; a
mismatch deletes the bytes and fails for good, not as a transient error to
retry. Files go under `<app support>/ocr/` — the engine, `fast/`, `best/`
(each Tesseract's `datapath`) and `ocr.json` for the settings — never in
the library.

`OcrInstallation` (`ocr_installation.dart`, `ocrInstallationProvider`) is
the app-wide state: what is on disk (scanned, not stored), the engine, the
settings, and `missingFor(languages)` — what a recognition still has to
download, which phase 2's dialog shows before it starts.

## Recognize text — phase 2 (#594)

### The pipeline

`OcrQueue` (`ocr_queue.dart`, `ocrQueueProvider`) is app-wide and runs
one job at a time; closing the file does not stop it.

1. **What is missing** (`OcrInstallation.missingFor`) is downloaded
   first — the engine, a language — through the same downloader.
2. **Pages**: a PDF is opened with pdfrx and each page rendered at
   300 DPI (`ocr_page_source.dart`), its longest side capped at 4200 px
   (a poster would otherwise be hundreds of MB of pixels); white under
   it, BGRA. A picture is decoded by the engine's codecs
   (`ImageDescriptor`), RGBA, as one page. Both travel as
   `TransferableTypedData`.
3. **Recognition**: an `OcrWorker` isolate per job opens the engine,
   loads the languages once (`ita+eng`) and reads page after page; it
   turns the pixels into 8-bit luminance itself, a quarter of what
   Tesseract would copy. Every Tesseract call blocks, so nothing of it
   runs on the UI isolate.
4. **The sidecar** (`ocr_sidecar.dart`) is written through the library's
   own operations: `createNote` for a new one (atomic write, FTS5 index,
   sync hint), `readNote` + `saveNote` to merge into an existing one (its
   history keeps the hand corrections). The open notes are saved first,
   so an editor holding the sidecar does not write its copy back over it.

Measured here on a 2-page image-only PDF (A4 at 200 DPI) with the
distribution's 5.5.3 and the English model: **423 ms** for the job, worker
start and model load included; a picture **109 ms**.

### Decisions

- **The position comment ends its line** (`text <!-- ocr l t r b -->`),
  where #532 drew it under: one source line is one recognized line — so a
  line joined or split by hand is seen at once (#596) — and a paragraph's
  lines still read as one paragraph in any preview. Fractions with three
  decimals: a thousandth of an A4 page is a fifth of a millimetre.
- **Escaped like a PDF's quoted text** (`markdown/text_escape.dart`): a
  `#`, a `[[`, a `<!--` on a scan stay words.
- **Merged by page**: recognizing pages again replaces only their
  `## p. N` sections, in page order. The frontmatter is kept as it is
  (the `recognized:` date stays the first one).
- **Name**: `<stem>.ocr.md` beside the file; when that note belongs to
  another file of the same stem (`scan.pdf`, `scan.jpg`), `<name>.ocr.md`.
  The `ocr:` link names the file only: the move rewrite skips frontmatter
  (as it does for `annotates:`), and a name-only link still resolves after
  the two move together.
- **Cancel** kills the worker isolate; a kill lands between two Dart
  instructions, so the page being read finishes first, and nothing is
  written. A job pauses with the app when Android freezes it, and goes on
  in the foreground; no foreground service.
- **Done**: a snackbar with Open text; when the app is not in front, also
  a notification, through the plugin the reminders initialize (initializing
  it again would take their taps) on its own Android channel, its payload
  `ocr:<sidecar>` routed by the shell's tap listener.
- **Not done here**: the pages done are not marked on the scan while a
  job runs, and a PDF that already has a text layer is not detected. The
  tree's ring came with #595, the line overlay with #596.

## The text beside its scan — phase 3 (#595)

- **`OcrScanText`** wraps a PDF's or a picture's view when the file has a
  sidecar (`findOcrSidecar`: the note under one of the two sidecar names
  whose frontmatter links to the file). From 720 px of pane up, the
  **Text** pane (`OcrTextPane`, a `MarkdownReadView` over the sidecar,
  selectable) sits beside the scan at 40% of the width (280–460 px), shown
  and hidden by the file bar's button through `OcrTextToggle`; below, a
  **Scan | Text** `SegmentedButton` over an `IndexedStack`, so the PDF
  keeps its page while the text is read. The pane reads the sidecar again
  when a job of its file reaches done.
- **The read view hid nothing**: it drew inline raw HTML as text, the
  position comments included. An inline `<!-- … -->` now renders nothing
  and leaves the plain text too (`fix(read)`, a commit of its own): what
  every Markdown renderer does, and what a writer's note-to-self wanted
  anyway. Other inline tags still show, and HTML blocks still show as code.
- **The tree** (`nestOcrSidecars`): while a folder's rows are flattened,
  each `<stem>.ocr.md` moves right under the PDF or picture of that stem
  (`<name>.ocr.md` under the file of that full name), one level in,
  dimmed, with the scan's icon. Told by the name alone, so the tree reads
  nothing more; O(n) per folder, over rows it already holds. A sidecar
  with no such file beside it stays where it sorts.
- **The ring**: `OcrTreeRing`, on a recognizable file's row, listens to
  the queue and shows the job's fraction while it runs.
- **On a phone a picture's text** comes in a sheet when its job ends with
  the app in front (`showOcrResultSheet`): the words, the plain text
  (`ocrSidecarPlainText` drops the frontmatter, the headings, the comments
  and the escapes), Copy, Open text. A PDF keeps the snackbar.

## The lines on the scan — phase 4 (#596)

- **`readOcrPlacedLines`** reads a sidecar back: each content line with
  exactly one `<!-- ocr l t r b -->` is a placed line (page from the last
  `## p. N`, box, its index in the text, and its characters in its
  paragraph's drawn text — escapes resolved, comment gone, a soft break
  one character); a line with none or two counts as lost on its page. The
  frontmatter's `language:` gives the languages to read a page again in.
- **`OcrLinesScope`** (an `InheritedNotifier` over the selected line) is
  put above the scan and the Text pane by `OcrScanText`, so the two share
  the lines and the selection without a callback between them.
- **On the scan**: `ocrLineOverlays` adds a target per line to pdfrx's
  `pageOverlaysBuilder`, next to the annotation marks; invisible until
  picked, then tinted and bordered. A pick opens Annotate · Copy · Copy
  link (`showMenu` at the tap). Annotate and the link name the **page**
  (`PdfLocation(page:)`): a scan has no text layer for `chars=`, and a new
  location kind for a box was not worth a link format of its own; the
  quote carries the line.
- **In the Text pane**: the line is a `BlockMark` of its source line and
  character range, so the read view tints the line alone inside its
  paragraph, and `jumpToLine` brings it into view once per selection.
- **Lost places**: a notice per page at the top of the pane, and
  **Recognize p. N again** queues that page alone in the sidecar's
  languages without the dialog (`ShellOcrFlow.recognizeAgain`); the merge
  replaces only its section.
- **Not done**: a picture's lines are not targets on the picture (its
  fitted rectangle inside the zoomable viewer would need its decoded size,
  and a picture has no annotation place); the pages already read are not
  tinted on the scan while a job runs.

## Build impact

Measured on the beta builds of this host, before (`cfc7d0a0`) and after
phase 1 (`93ec9091`):

| Target | Before | After | Delta |
|---|---|---|---|
| Android APK (beta, universal 64-bit) | 133,746,865 B | 133,943,685 B | +196,820 B (+0.15%) |
| Linux bundle | 60,938,478 B | 61,152,177 B | +213,699 B (+0.35%) |

Against the 2.3–3.9 MB engine and the 1–15 MB per language it no longer
carries, the package grows by about 200 KB.

No native library is added to any package: the delta is Dart code, the
language catalog (44 KB of source) and the strings.
