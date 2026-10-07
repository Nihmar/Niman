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
