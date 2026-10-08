# Slide notes — the screens, and the plan

The mockups #534 is to be agreed against (2026-10-08), before any code: three
desktop pages and two phone pages, in `html/`. They are drawn to look like
Niman, in the Night palette of `lib/src/ui/theme/niman.dart`; where a mockup
and the app disagree, the app is what ships.

| Screen | Desktop | Phone |
|---|---|---|
| The slide view: the current slide large, its speaker notes under it, the others as thumbnails (desktop) or dots (phone); the ⋮ menu of a slides note | [Desktop-1-SlideView](html/Desktop-1-SlideView.html) | [Phone-1-SlideView](html/Phone-1-SlideView.html) |
| Presenting: only the slide; the discreet bar on a mouse move; the overview grid. Phone: landscape, the tap zones, New → Slides | [Desktop-2-Present](html/Desktop-2-Present.html) | [Phone-2-Present](html/Phone-2-Present.html) |
| The presenter view: now, next, notes, elapsed timer, clock | [Desktop-3-Presenter](html/Desktop-3-Presenter.html) | — (the upright slide view is the phone's) |

## The note

```markdown
---
type: slides
---

# Piano Q4

---

## Obiettivi del trimestre

1. Note-presentazione (#534)
2. Sync verso S3

Note: Partire dal #534.
Ricordare che il PDF esce in 16:9.
```

- **A slide break is a thematic break, as CommonMark reads one.** The split
  comes from the block scan the read view already makes
  (`DocumentScan`, `BlockKind.thematicBreak`), not from a line regex: a `---`
  inside a code fence stays code, and `Text` followed by `---` stays a setext
  heading. `***` and `___` break slides too — they are the same block.
- **Speaker notes** are the top-level paragraph that starts with `Note:` and
  everything after it up to the next break (reveal.js's convention, so a deck
  written for it reads the same). A `Note:` inside a fence or a quote is text.
- Only top-level breaks count; one inside a list item or a quote does not.
- Frontmatter is not a slide. An empty slide (two breaks in a row) is a blank
  slide — useful as a pause, and what the file says.

## Decided with them

- **A slide is laid out at 960×540 and scaled.** One `MarkdownReadView` per
  slide, over that slide's lines, inside a fixed 960×540 box and a
  `FittedBox`: the pane, the projector, the thumbnails and the PDF show the
  same slide. Text that overflows the box is clipped, not shrunk — the editor
  is where a slide is made shorter.
- **The slide view is the kind GUI.** `type: slides` registers a `NoteKindGUI`
  like `list` and `audio`; the pencil is the raw editor, the kind toggle there
  brings the slides back (a slideshow icon). **Markdown preview** in ⋮ is the
  raw mode with the eye on — no third mode.
- **A Present button on the desktop note bar**, beside the pencil (an
  addition to the issue, which had Present in ⋮ only): F5 is not known by
  everyone, and a deck is opened to be presented.
- **The presenter view is one window.** Flutter's multi-window API is behind
  an experimental flag in 3.47 and does not exist on Android, so "F5 with two
  screens opens the presenter view on one and the slides on the other" is not
  in this round. F5 always presents in the window's screen; the presenter view
  is its own full-screen mode (Alt+F5, ⋮, or Notes on the bar). The second
  window comes back as its own issue when windowing is stable; `docs/user/platforms.md`
  says so.
- **No presenter view on the phone**: the upright slide view already shows
  the slide and its notes, and swipes. The capability is there, the shape is
  the phone's.
- **Turning the phone presents.** Upright → slide view; sideways while the
  slide view is on → presenting (immersive, `FLAG_KEEP_SCREEN_ON`). A swipe
  down leaves presenting and stays in the slide view until the phone goes
  upright again — no fight with the sensor.
- **The screen stays on while presenting on every platform**: Android
  through `FLAG_KEEP_SCREEN_ON` on a `niman/screen` channel, Windows through
  `SetThreadExecutionState` (`ffi` is already a dependency), Linux through
  GTK's `gtk_application_inhibit` on the same channel — a `gdbus` call was
  the first idea, but the session drops an inhibit when the process that
  asked for it exits. No new package.
- **The tap-zone hint shows each time presenting starts** on the phone and
  fades after 2 s; nothing is remembered, so no setting.
- **Keys**: → ↓ Space Page Down and a click forward; ← ↑ Backspace Page Up
  back; Home / End; O overview; B black screen; Esc out. A Bluetooth clicker
  sends Page Up / Page Down, so it works on every platform as is.
- **Export slides as PDF** is the existing export (#63) with a slides page:
  one `<section>` per slide, `@page { size: 254mm 142.875mm; margin: 0 }`
  (16:9, 10 × 5.625 in), notes left out. Android's `PdfBridge` takes the
  page size from the call instead of its fixed ISO A4; the raster fallback
  already takes `pageWidth` / `pageHeight` and draws one slide per page.

## The plan

Each step is one commit, shipped on Android, Linux and Windows together.
The slide code lives in `lib/src/ui/kinds/slides/`; `shell.dart` only wires
it (it is past every size rule already).

1. **The split.** `slides/slide_split.dart`: note text → `List<Slide>`
   (`start`, `end`, `notesStart?`) from the `DocumentScan`. Unit tests: fence
   with `---`, setext heading, `***` / `___`, break inside a list or quote,
   frontmatter, `Note:` in a fence, empty slide, CRLF, a note with no break
   (one slide).
2. **The kind.** `SlidesKindGui` registered in `NoteKinds`;
   `slidesNoteContent()` (two slides, one note line); **New slides** in the
   FAB, the desktop create menu and the command palette
   (`AppCommand.newSlides`); the slideshow icon in the shell's kind toggle.
   Strings in every locale file.
3. **The slide view.** `slide_frame.dart` (960×540 + `FittedBox` over a
   `MarkdownReadView`), `slides_view.dart`: desktop = slide, notes, thumbnail
   strip, arrow keys; phone = `PageView`, dots, notes card, Markdown and
   Present buttons. Widget tests for the split's slides on screen and the
   notes box coming and going.
4. **The ⋮ entries.** `NoteMenuAction.present`, `presenterView`,
   `markdownPreview`, `exportSlides`, shown only for `type: slides`; the
   Present button on the desktop note bar; F5 / Alt+F5 in the shortcuts and
   in `docs/user/shortcuts.md`.
5. **Presenting.** `slides_present_screen.dart`: full screen through the
   path the EPUB reader's full screen already takes (`window.setFullScreen`
   / `immersiveSticky`), the bar that fades, the overview grid, the keys,
   tap zones and swipe-down on the phone, the rotation trigger, keep-awake
   (`core/keep_awake.dart`, three small platform branches).
6. **The presenter view.** `slides_presenter_screen.dart`: now, next, notes,
   timer (starts on the first move), clock, overview.
7. **Export slides as PDF.** `export/slides_html.dart` (the sections, notes
   stripped), the page size through `PdfPrinter` and `PdfBridge.kt`, the
   raster path one slide per page. Tests: page count = slide count, notes
   absent from the HTML.
8. **Docs.** `docs/user/organization.md` (the kinds), `export.md`,
   `shortcuts.md`, `platforms.md` (the second window, as a decision).

Integration (`./scripts/niman.sh integration`) runs once, after step 8.

## Not in this round

- The second window on a second screen (see above).
- Slide themes, layouts, transitions, `<!-- .slide: -->` attributes:
  a slide is the note's Markdown in the reading theme.
- Fragments / step-by-step reveal.
