# Text recognition

Niman can read the text of a scanned PDF or a picture — a contract, a
whiteboard, a receipt, a book page — and write it into a note next to the
file, so search finds it. It runs on the device: nothing is sent anywhere.

The work is tracked in [#532](https://github.com/Nihmar/Niman/issues/532)
and lands in steps: the engine and its languages, and **Recognize text**,
are here; the Text pane beside the scan ([#595](https://github.com/Nihmar/Niman/issues/595))
and selecting the recognized lines on the scan ([#596](https://github.com/Nihmar/Niman/issues/596))
come next.

## Recognize text

Never automatic: you ask for it, on a PDF or a picture —

- with the **Recognize text** button in the row under the file;
- in the file's **⋮** menu;
- in the tree's context menu (right click on the desktop, a long press on
  a phone);
- with **Recognize text** in the command palette.

It asks:

- **Default language** and **Also** — the language the page is read in
  (the one set in Settings to start with) and a second one for pages that
  mix two.
- **Pages**, for a PDF of more than one — all of them, the page on
  screen, or a range from one page to another.
- It says where the text goes, and, the first time, what it has to
  download first (the engine, a language) and how much: **Download and
  recognize** does both.

The file can be closed while it is read, page after page. On the
desktop the row under the file says **Recognizing p. 3 of 4** with
**Cancel**; on a phone a strip under the top bar says it on any other
note you open meanwhile. When it is done a message says **Text
recognized · N words** with **Open text**; if you had left Niman, a
notification says it instead, and a tap opens the text. A cancel takes
effect at the end of the page being read, and writes nothing.

## The text note

The text goes into a note next to the file, named after it:
`Contratto 2019 (scan).ocr.md` beside `Contratto 2019 (scan).pdf`. It is a
real note — search finds the scan by its words, and you correct it by hand
like any other.

```markdown
---
ocr: "[[Contratto 2019 (scan).pdf]]"
language: ita+eng
recognized: 2026-10-07
---

## p. 1

CONTRATTO DI LOCAZIONE <!-- ocr 0.093 0.110 0.641 0.129 -->
Il contratto scade il 28 febbraio. <!-- ocr 0.093 0.193 0.660 0.215 -->
```

- One `## p. N` section per page of a PDF; a picture is one page, with no
  heading.
- Each line ends in a comment holding where it is on the page. Comments
  are invisible in every preview, in Niman or anywhere else; they are how
  a line will be found again on the scan.
- What the scan reads as Markdown stays words: a `#` on a receipt is
  written `\#`, never a tag.
- Recognizing pages again replaces only their sections: your corrections
  on the other pages stay. A picture's note is replaced under its
  frontmatter.
- The link names the file only, so the note keeps pointing at it when the
  two move together.

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
