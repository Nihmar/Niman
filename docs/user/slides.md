# Slide notes

A **slides note** is a note whose frontmatter says `type: slides`. The app
shows it as a deck: one slide per part of the note, presented full screen
and exported as a PDF of slides. It is still an ordinary `.md` file — the
pencil beside the ⋮ opens the raw editor, where the slides are written.

```markdown
---
type: slides
---

# Piano Q4

Riunione di progetto

---

## Obiettivi del trimestre

1. Note-presentazione
2. Sync verso S3

Note: Partire dal primo punto.
Ricordare che il PDF esce in 16:9.
```

Create one with **New slides** in the Files FAB, the desktop's **New**
menu under the tree, or the command palette. It asks for a name and
starts with two slides, the second with a point and a speaker note. A new
presentation is made in the library's root, whatever folder or note is
selected; move it from the tree if it belongs elsewhere.

## The format

- **`---` separates slides.** Only in a slides note: everywhere else it
  stays a horizontal rule. `***` and `___` separate slides too. A `---`
  inside a code block stays code, a line of text right above `---` stays a
  heading (Markdown's own rule), and a `---` inside a list or a quote
  belongs to it. Two `---` in a row make an empty slide.
- **Speaker notes** start at a line beginning with `Note:` and run to the
  end of the slide. They are a reminder for whoever presents: shown under
  the slide in the slide view and in the presenter view, never on the
  presented screen and never in the PDF. A `Note:` inside a code block or
  a quote is text.
- Everything else is the note's own Markdown — headings, lists, tables,
  code, formulas, diagrams, pictures — drawn as the preview draws it, on a
  16:9 slide. A slide is laid out at one size and scaled to the screen,
  so it looks the same in the pane, on a projector and in the PDF. What
  does not fit is cut off at the slide's edge: make the slide shorter, or
  split it.

## The slide view

The note opens on its slides.

- **Desktop:** the slide on screen large, its speaker notes under it, and
  every slide as a thumbnail in a row below. ← → (and Page Up / Page Down,
  Home, End) move between slides; a click on a thumbnail goes there. The
  **Present** button beside the pencil is `F5`.
- **Phone:** the slide at the top — swipe for the next one — dots and the
  count under it, then the speaker notes. **Markdown** at the bottom shows
  the note's normal preview, and **Present** presents.

The ⋮ menu leads with **Present** (`F5`), **Presenter view** (`Alt+F5`,
desktop), **Markdown preview** and **Export slides as PDF**, then the
note's own entries. Markdown preview is the raw mode with the preview on:
the slideshow icon on the bar brings the slides back.

## Presenting

- **Desktop:** the window goes full screen with the slide alone. → ↓
  Space, Page Down, Enter or a click go forward; ← ↑ Backspace or Page Up
  go back; Home / End go to the first / last slide; `B` blacks the screen
  out and back; `O` opens the overview of every slide (arrows and Enter,
  or a click, pick one); `Esc` stops, on the slide where the talk stopped,
  and gives the window back as it was (full screen stays full screen).
  Moving the mouse shows a bar — ‹ 3 / 7 › · Overview · Notes · Exit —
  that fades after two seconds of stillness, with the cursor. A clicker
  works as it is: it sends Page Up / Page Down.
- **Presenter view** (`Alt+F5`, the ⋮, or **Notes** on the bar): the slide
  on screen, the next one, the speaker notes in large type, the time the
  talk has run and the clock. The timer starts on the first move, not on
  opening; `P` pauses it, `R` puts it back to zero. **Slide only** (or
  `F5`) goes back to the slide alone.
- **Phone:** turn the phone sideways while the slides are on screen and
  they are presented in landscape, or press **Present**. Tap the right
  third for the next slide and the left third for the one before, or
  swipe; swipe down to stop. A hint says where to tap each time
  presenting starts. The presenter view is not laid out for a phone:
  `Alt+F5` on a keyboard plugged into one presents the slide alone. Turning the phone upright again stops a talk that
  began by turning it.

While slides are presented the screen stays on — no dimming, no lock —
on every platform, until the talk ends.

## Export

**Export slides as PDF** in the ⋮ writes one 16:9 page per slide, through
the same PDF export every note has (see [export](export.md)): the text
stays selectable where a browser engine prints it, and the speaker notes
are left out. **Export…** still writes the note itself as Markdown, HTML,
PDF or EPUB.
