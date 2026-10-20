# Flashcards

A **deck** is a note whose frontmatter says `type: flashcard`: questions
with their answers, studied with spaced repetition (SM-2), each card
coming back when it is about to be forgotten. It is still an ordinary
`.md` file — the cards are the note's own tables, lines and highlights,
and the pencil beside the ⋮ opens the raw editor where they are written.

Flashcards and Study are one of the [Features](features.md). Switched off, a deck opens as plain Markdown with its `type:` kept, and `.niman/review.json` is left as it is.

```markdown
---
type: flashcard
deck: Lingue/Inglese
tags: [esame-giugno]
---

| Verb | Past · participle |
|---|---|
| begin | began · begun |
| choose | chose · chosen |

- thrive :: throve · thriven

The past of *to tread* is ==trod==.
```

## Making a deck

- **New flashcards** — in the Files FAB, the desktop's **New** menu under
  the tree, or the command palette: a note with `type: flashcard`, an
  empty `deck:` and a two-column table ready for the first card. The
  **New flashcards here** entry of a folder's right-click menu makes it
  in that folder; otherwise it is made where the library's setting for
  new notes puts it (see
  [organization](organization.md#where-new-notes-and-folders-go)).
- **Make flashcards…** — in the ⋮ of any note of no `type`, and in the
  palette: the note becomes a deck without its text being touched. It
  counts the cards the note already holds, asks for the question and
  answer columns when a table has more than two, and for the `deck:` —
  the places your decks use are offered, a new one is typed — and shows
  the exact frontmatter it will write before **Make N cards** writes it
  as one edit, which Undo takes back. A note with nothing to make cards
  from says so and is left alone.

The first deck a library gets offers, once, to show
[Study](#study-the-decks) in the navigation.

## The note

- **`type: flashcard`** makes it a deck. Wherever it is opened from — the
  tree, search, a link, a tab — it opens as its cards.
- **`deck:`** is the deck's place in Study, categories separated by `/`:
  `deck: Lingue/Inglese` sits under *Lingue › Inglese*. Several notes can
  share one place. No `deck:`, or an empty one, is **No category**.
- **The deck's name** is its `title:`, else the file name.
- **`tags:`** filter Study: a tag chip leaves the decks that carry it.
- **`front:` and `back:`** name, by their header, the question and the
  answer columns of a table with more than two; without them the first two
  columns are read. **Question and answer columns…** in the deck's ⋮ sets
  them for you.

## The cards

Read from the note every time; there is no file per card. Nothing inside
a code block, a math block or the frontmatter is a card.

- **A table row** — every body row of every table is a card: the
  question column asks, the answer column answers. The header row is not
  a card.
- **A `::` line** — a paragraph or a list item of one line holding ` :: `:
  before it the question, after it the answer. The first ` :: ` splits.
- **A cloze** — in any other paragraph or list item, each `==highlight==`
  is a card that hides it, the rest of the sentence showing. In a deck, a
  highlight *is* a cloze.

Questions and answers are Markdown: emphasis, code, math and pictures look
as they do in the note.

**A card is known by its question**, as plain text. Its answer can change
and it keeps its progress; moving it, reordering the table, or turning a
row into a `::` line keeps it too. **A question changed is a new card**,
which starts over. The same question asked twice in one deck is two cards,
the second marked **Repeated** in the deck.

## The deck view

- **Desktop:** the deck's place and name, its counts — due, new, all the
  cards — and **Study N**, then the cards as rows: question, answer, and
  when each comes back (*Due*, *New*, *in 3 days*). A double click edits a
  row in place (`Enter` saves, `Esc` cancels); a right click offers
  **Edit card** and **Delete**;
  **+ Add card** at the end appends a row to the first table, making one
  when the note has none.
- **Phone:** the counts on top, the questions as a list with their
  answers, **Add card** and **Study** at the bottom. A long press on a
  question opens a sheet to change or delete it.

Every edit is an edit of the note — only that card's characters change —
and Undo takes it back. A card written as a `::` line needs an answer: the
editors do not save it without one (a table row may keep an empty cell).
The counts of an open deck follow the reviews you grade on another device
once they sync, and the turn of the study day, with no need to reopen the note.

The deck's ⋮: **Study this deck** (`F5`), **Edit as Markdown**,
**Question and answer columns…**, **Reset the review of this deck…** (the
cards become new again; the note does not change), then Rename, Move,
History, Export and Delete.

## Studying

**Study** — the deck's button, its ⋮ entry or `F5` — reviews the cards
due today, the oldest first, then new cards in note order, up to the
library's **New cards per day** for that deck. A new card counts against
the day it was first graded.

The question shows first; **Show answer** (`Space`) shows the answer — a
cloze shows its sentence with the gap filled in. Then grade how well you
remembered:

| Grade | Key | Comes back |
|---|---|---|
| **Again** | `1` | later in this session, until it is graded otherwise; tomorrow after that |
| **Hard** | `2` | a little later than last time |
| **Good** | `3` (or `Space`) | tomorrow, then in 6 days, then each interval times the card's ease |
| **Easy** | `4` | as Good, a third longer |

Each button says when its grade brings the card back. `Ctrl+Z` (or the
undo button) takes the last grade back, as many as the session has; `Esc`
or ✕ ends the session. On top: the cards left — due, new, again — and the
progress.

- **Desktop:** the review opens as a tab of its own, *Study · Irregular
  verbs*, in the pane beside the deck — splitting the window to the right
  when it is not split and has room — with the card under study marked in
  the deck and the deck's answers hidden until the review ends. A window
  too narrow for two panes shows the review over the deck. A note tab
  shown in its pane covers it; its chip brings it back.
- **Phone:** the review takes the screen, the grades in a row where the
  thumb is.

**The end** shows the cards reviewed, the Again grades, the minutes, how
the grades spread, and when the next cards are due, with **Back to the
deck** and **Next deck** — the next deck with cards today.

**Today** is the journal's day: with **A new day starts at** set to 4, a
review at 1 a.m. still counts for the day before (see
[journal](journal.md)).

## Study, the decks

**Study** is a destination of the rail and of the bottom bar, hidden until
asked for: show it from the offer the first deck makes, or in
**Settings → Navigation** (see [settings](settings.md#navigation)).
`Ctrl+7` and the palette's *Go to: Study* reach it either way.

It is the Study tree: the decks' tags as chips that filter, the categories
from `deck:` — folding at a click, *No category* last — and the decks,
each row with its **due** and **new** cards, summed up the categories.
Every row has its own Study: a category's studies every deck under it as
one session. A deck opens at a click — beside the tree on a desktop, which
keeps the tree in its left island as it keeps the search.

## Where the progress is kept

When each card comes back is not in the note — every grade would rewrite
it — but in the library's `.niman/review.json`, beside the reading
positions. It is the library's, so it [syncs](sync.md), card by card: two
devices studying different decks never conflict, and a card graded on
both keeps the later grade. A deck renamed or moved in Niman keeps its
progress; a deck deleted takes it along. Losing the file loses only the
dates: the cards are in the notes.

## Settings, Home and widget

- **Settings → Study:** **New cards per day** (per deck; 0 shows no new
  cards; 20 by default) and **Reset all reviews**, which asks first (see
  [settings](settings.md)).
- **Home:** the **Study** tile — today's cards and the decks that have
  some, Study on the first (see [home](home.md)).
- **Android:** the **Niman Study** home-screen widget — the decks with
  cards today, grouped by `deck:` (see [widgets](widgets.md)).
