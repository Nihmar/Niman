# Look up — the screens

The mockups the dictionary was agreed against (2026-11-27), before any
code: a word looked up in a book on a phone, in a PDF on the desktop and
on a scan's recognized line, and the Dictionaries settings, in `html/`.
They are drawn in a plain light palette, not one of
`lib/src/ui/theme/niman.dart`'s, with Literata for the book; the UI text is
Italian, as the owner reads it. Where a mockup and the app disagree, the
app is what ships. The plan they belong to is the record
[dictionary.md](../../records/dictionary.md); the numbers below are its
decisions.

| Screen | Mockup |
|---|---|
| **A** — a word selected in a book on a phone: *Significato* (Look up) first on the bar, *Read aloud from here* second (6, 7) | [1-Phone](html/1-Phone.html) |
| **B** — the meaning in a half-height sheet: the lemma and the form read, the language chip, senses, nearby entries, the pack's licence, Copy and Annotate with the definition (8, 9, 12) | [1-Phone](html/1-Phone.html) |
| **C** — a PDF on the desktop: the pointer's menu, and the panel under the word; the language chip remembered for the file (7, 10, 11) | [2-Desktop](html/2-Desktop.html) |
| **D** — Settings → Dictionaries: the installed packs, a download running, the catalog of the app's languages with a search (3, 4, 14) | [3-Settings](html/3-Settings.html) |
| **E** — no definition: the nearby entries, nothing sent anywhere (9) | [3-Settings](html/3-Settings.html) |
| **F** — no pack for the language: the pack offered with its size, downloaded in the panel (4) | [3-Settings](html/3-Settings.html) |
| **G** — a scan's recognized line: *Significato* first in the line's menu (13) | [4-Scan](html/4-Scan.html) |
| **H** — the line's words as chips over the meaning, the tapped one chosen (13) | [4-Scan](html/4-Scan.html) |

## Drawn with them, not yet confirmed

- The desktop shortcut is Ctrl+D (Cmd+D on a Mac); it is free in the
  reader today, and the editor's binding is checked when the entry lands
  there.
- The sizes on the settings screen are estimates; the pipeline measures
  the real ones (phase 2).
- On a phone the annotation that *Annotate with the definition* opens is
  the usual annotation sheet, its text the definition, the passage its
  quote.
