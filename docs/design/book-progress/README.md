# Book progress — the screens, and the decisions

The mockups #1275 was agreed against (2026-11-13), before any code: a
book's reading progress on a phone, a tablet and a desktop, in `html/`.
Each page works: a tap or a click on the progress control moves it to its
next view, and on the desktop a pointer over it shows the three measures
at once. They are drawn in a plain light palette, not one of
`lib/src/ui/theme/niman.dart`'s, with Literata for the book; where a
mockup and the app disagree, the app is what ships. How the reader works
is [docs/records/epub-reader.md](../../records/epub-reader.md).

| Screen | Mockup |
|---|---|
| Phone: a 44 dp line over the book's row, the views' dots at its end | [Phone](html/Phone.html) |
| Tablet: in the book's row, beside the book's name, a short track and the dots | [Tablet](html/Tablet.html) |
| Desktop: as on the tablet, at a pointer's size; a pointer over it shows the three measures together | [Desktop](html/Desktop.html) |

## Decided with them

- **One control, three views**, which a tap cycles and the dots name:
  - **Chapter** — the chapter's title and how far into it: `Chapter I · 62%`.
  - **Book** — how far into the whole book and which chapter of how many:
    `2% of the book · chapter 1 of 38`. Its track has a tick at every
    chapter's start, so the chapters' lengths show.
  - **Time left** — an estimate to the chapter's end and to the book's:
    `Chapter ≈ 11 min · Book ≈ 14 h 50 min`.
- **The view chosen is kept per library**, with the books' look: the next
  book opens on it.
- **Measured in characters**, from the line at the top of the view and the
  chapters' first lines, never in lines or in laid-out pixels: a book's
  paragraphs vary too much in length for lines to be fair, and the pixels
  are only known for the part built so far.
- **The time left comes from the words left**, at about 250 words a
  minute. Learning the reader's own pace is a possible follow-up, not part
  of #1275.
- **Counted once per book**, when it is read: a scroll looks the figures
  up, it does not count.
- **A jump moves it at once** — the contents, a link, a search.
- **On a phone it goes with the bars**: full screen hides it, as it hides
  the book's row.
- **It is one button**, labelled with what it shows and what a tap does
  next, so TalkBack and a keyboard reach it like any other.
