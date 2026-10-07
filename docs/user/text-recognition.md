# Text recognition

Niman can read the text of a scanned PDF or a picture — a contract, a
whiteboard, a receipt, a book page — and write it into a note next to the
file, so search finds it. It runs on the device: nothing is sent anywhere.

The work is tracked in [#532](https://github.com/Nihmar/Niman/issues/532)
and lands in steps. **What is here now** is the engine and its languages,
in **Settings › Text recognition**. The **Recognize text** command, which
writes the text of a file into a `.ocr.md` note beside it, comes next
([#594](https://github.com/Nihmar/Niman/issues/594)).

## Nothing extra in the app until you use it

The app does not ship the recognition engine or any language: installing
or updating Niman costs nothing for a feature you may never use. Each piece
is downloaded once, from inside the app, the first time it is needed, and
can be deleted again from the same page.

- **The engine** — Tesseract 5, about 2.3 MB on a phone, 2.9 MB on Linux,
  3.9 MB on Windows. On **Linux**, when the distribution's Tesseract is
  installed (`tesseract` on Arch, `libtesseract5` on Debian and Ubuntu),
  Niman uses it and downloads no engine at all: the page says **System
  library**.
- **The languages** — 123 of them, each a separate download.

Every file is checked against the checksum the app carries before it is
used: a damaged or tampered download is thrown away, never loaded.

## Settings › Text recognition

The same page on the desktop and on the phone:

- **Engine** — where the engine comes from (downloaded, or the system
  library), its size, and **Download** or **Delete**.
- **Quality** — **Fast** (1–4 MB per language, quick on any device) or
  **Best** (10–15 MB per language, better on hard scans, two or three
  times slower). Each quality keeps its own languages: switching shows the
  ones of the other.
- **Default language** — the language a page is read in; until you pick
  one it follows the app's language.
- **Also** — a second language read with it, for pages that mix two
  (`Italiano` and `English`, say).
- **On this device** — the languages downloaded for the current quality,
  with the space they take; a download in progress shows its bytes and can
  be cancelled, one cut off by a lost connection resumes where it stopped.
- **Other languages** — the rest, with a search over their names (in the
  language itself and in English).

Languages are listed by their own name — *Deutsch*, *Español*, *日本語* —
which needs no translation.

## Where the files go

In the app's own folder, under `ocr/`, never in the library:

| | |
|---|---|
| Engine | `ocr/engine/<release>/niman-ocr-<platform>.so` (`.dll` on Windows) |
| Languages | `ocr/fast/<code>.traineddata`, `ocr/best/<code>.traineddata` |
| Settings | `ocr/ocr.json` (quality, default language, "Also") |

The app folder is `~/.local/share/dev.niman.niman` on Linux,
`%APPDATA%\dev.niman\niman` on Windows, and the app's private storage on
Android; the testing build keeps its own.
