# Text recognition — the screens, and the decisions

The mockups #532 was agreed against (2026-10-07), before any code: four
desktop screens and six phone screens, in `html/`. They are drawn to look
like Niman, in the Night palette of `lib/src/ui/theme/niman.dart`; where a
mockup and the app disagree, the app is what ships.

| Screen | Desktop | Phone |
|---|---|---|
| Settings › Text recognition: engine, quality, default language and "Also", the languages on the device and the others, with search | [Desktop-1-Settings](html/Desktop-1-Settings.html) | [Phone-1-Settings](html/Phone-1-Settings.html) |
| **Recognize text**: language and "Also", pages (All / This page / From…to), where the note goes, and on first use the download it needs | [Desktop-2-Recognize](html/Desktop-2-Recognize.html) | [Phone-2-Recognize](html/Phone-2-Recognize.html) |
| Recognizing in the background: "Recognizing p. 3 of 4 · Cancel" in the file's bar, the pages done marked on the scan, a ring on the file in the tree, a notification at the end; on a phone a strip under the top bar | [Desktop-3-Progress](html/Desktop-3-Progress.html) | [Phone-3-Progress](html/Phone-3-Progress.html) |
| The scan and its text: a Text pane beside the scan (a **Scan \| Text** switch on a phone), a line selected on the scan with Annotate · Copy · Copy link, highlighted on both sides, the notice of lines that lost their place, the sidecar under its file in the tree | [Desktop-4-ScanText](html/Desktop-4-ScanText.html) | [Phone-4-Text](html/Phone-4-Text.html), [Phone-5-ScanLine](html/Phone-5-ScanLine.html) |
| A picture in the attachments: "Text recognized · N words", Copy and Open text | — | [Phone-6-Image](html/Phone-6-Image.html) |

## Decided with them

- **The app grows by its code only.** The engine and every language are
  downloads, made from inside the app the first time they are needed and
  deletable from the settings page (record: [ocr.md](../../records/ocr.md)).
- **Both qualities**, tessdata_fast and tessdata_best, chosen in Settings.
- **On Linux the distribution's Tesseract first**; the download only
  where it is missing.
- **A store build stays possible**: the engine is looked for inside the
  package before anything is downloaded.
- **Four steps**, each shipped on every platform: the engine and the
  settings (#593), the command and the sidecar (#594), the Text pane and
  the tree (#595), the lines on the scan (#596).
- **The pages done are marked on the scan itself.** The issue asked for
  thumbnails that mark them; the app has no PDF thumbnails.
- **A position comment ends its line**, rather than sitting under it: one
  source line is one recognized line, and a paragraph still reads as one
  in any preview.
