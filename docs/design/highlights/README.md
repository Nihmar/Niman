# Highlights — the screens, and the decisions

The mockups #626 is to be agreed against (2026-10-08), before any code:
four desktop screens and three phone screens, in `html/`. They are drawn
to look like Niman, in the Night palette of `lib/src/ui/theme/niman.dart`;
where a mockup and the app disagree, the app is what ships. Highlights
build on annotations and their marks — the record
[annotations.md](../../records/annotations.md) (#284, #285).

| Screen | Desktop | Phone |
|---|---|---|
| Highlighting a selection: **Highlight** joins the selection's menu, in the colour last chosen, and is done — no sheet, no comment | [Desktop-1-PdfSelect](html/Desktop-1-PdfSelect.html) (a PDF) | [Phone-1-Select](html/Phone-1-Select.html) (a book) |
| A highlight clicked or tapped: its four colours, **Annotate**, **Copy**, **Copy link to this place**, **Remove highlight** | [Desktop-2-HighlightMenu](html/Desktop-2-HighlightMenu.html) (a book) | [Phone-2-Sheet](html/Phone-2-Sheet.html) |
| A highlight and an annotation on the same words: the annotation is drawn over it, and a click asks which | [Desktop-3-Overlap](html/Desktop-3-Overlap.html) | — |
| The companion note: highlights are quotes with their link and nothing else; the colour rides in the link | [Desktop-4-Companion](html/Desktop-4-Companion.html) | — |
| A PDF on a phone, its highlights each in its colour, an annotated passage and a page annotation | — | [Phone-3-Pdf](html/Phone-3-Pdf.html) |

## Decided with the owner

- **Kept in the companion note** annotations already use (#284), so the
  note is the only record: a highlight syncs, survives a rebuilt index,
  and is plain Markdown anyone can read. A highlight is an annotation
  without a comment: the passage quoted, its link back, no heading.
- **Four colours** — yellow, green, blue, pink — see-through, so the text
  keeps its own colour on them. Yellow is the `==mark==` yellow annotated
  passages are tinted with today.
- **Removed with a tap**: a highlight's menu (a sheet on a phone) has
  **Remove highlight**, which deletes its quote from the companion note.
  Deleting the quote in the note does the same.
- **Overlaps ask which**: where a highlight and an annotation cover the
  same words, a tap asks which, in the list #285 already shows for several
  annotations.

## Proposed in the mockups, to agree

- **The colour rides in the link**:
  `[[Dune.epub#chapter=ch03&line=4&chars=19-66&highlight=blue|Chapter 3]]`.
  A link without `highlight=` is an annotation, as every link is today, so
  nothing written so far changes meaning; the place still opens from the
  note as any place link does.
- **Highlight uses the colour last chosen**, one tap, no colour picker on
  the way: the selection's menu is the platform's own (pdfrx's on a PDF,
  Flutter's toolbar in a book), which takes labels, not swatches. The
  colour is changed afterwards, from the highlight's menu.
- **An annotation keeps today's tint and gains a dotted underline**, so a
  passage with a note behind it reads apart from a yellow highlight.
- **Annotate** on a highlight turns it into an annotation: the comment
  sheet opens with the passage, and the quote in the note gains its
  heading and comment.
- On a phone **Highlight comes first** in the selection's toolbar, before
  Annotate and Copy, where a thumb finds it.
