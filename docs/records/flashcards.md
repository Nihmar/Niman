# Flashcards (#533)

A note with `type: flashcard` is a **deck**: questions with their answers,
reviewed with spaced repetition (SM-2). Written before the code
(2026-10-14), as the plan the work follows; the screens are in
[docs/design/flashcards](../design/flashcards/README.md).

The constraint that shapes all of it is the app's first rule: **the disk is
the source of truth.** The cards are the note's own Markdown — a table, a
`::` line, a highlight — and nothing about a card lives anywhere but the
note, except *when to show it again*, which changes at every grade and so
has a file of its own.

## The note

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

- **`type: flashcard`** makes it a deck. Like `type: audio` and
  `type: slides`, it opens in its own view wherever it is opened from —
  the tree, search, a link, a tab — and **Edit as Markdown** (the pencil
  beside the ⋮, as on a slides or list note) shows the text.
- **`deck:`** is where the deck sits in the Study tree, its categories
  separated by `/`: `deck: Lingue/Inglese` sits under `Lingue › Inglese`,
  beside `Lingue/Tedesco`. Several notes can share a `deck:` — the note is
  the deck, `deck:` its place. No `deck:` (or an empty one) is
  **No category**.
- **The deck's name is the note's**: its `title:` when it has one, else
  its file name.
- **`tags:`** (and inline tags) filter the Study view, as they filter
  everywhere: a tag leaves the decks that carry it, across categories.
- **New → Flashcards** creates a deck: the type, an empty `deck:` and a
  two-column table with its header and no row.

## The cards

A card is read from the note; there is no file per card. Three sources,
read with the block tree (so nothing inside a code block, a math block or
the frontmatter is a card):

1. **A table row.** Each body row of a table is a card; the header row is
   not. Two columns: the first is the question, the second the answer.
   More than two: the columns named by `front:` and `back:` in the
   frontmatter (by header text), else the first two. Every table of the
   note contributes, each read by the same rule.
2. **A `::` line.** A paragraph or a list item of one line holding
   ` :: ` is a card: before it the question, after it the answer
   (`- thrive :: throve · thriven`). The first ` :: ` splits.
3. **A cloze.** In any other paragraph or list item, each `==…==` is a
   card that hides it and leaves the other highlights readable. In a
   deck, a highlight *is* a cloze: that is what the type says.

Table cells and lines are rendered as Markdown — emphasis, code, math,
pictures — with the read view's inline renderer.

### A card's identity

The review state is kept by a **key**: the question as plain text (its
Markdown marks stripped, whitespace collapsed). A cloze's key is its line
with that one highlight replaced by `[…]`, so each gap of a line is its own
card.

- **The answer can change** and the card keeps its history: the key does
  not see it.
- **The question changing makes a new card**, which starts over — the
  issue's rule, and the only one that needs no guess.
- **The same question twice in one deck**: the second is keyed
  `question (2)`, the third `(3)`, by order in the note. The deck view
  marks the repeat, so it can be told apart from an accident.
- Moving a row, reordering the table, turning a table row into a `::`
  line: none of these changes the key.

## Scheduling: SM-2, four grades

Each card carries SM-2's four numbers: `ef` (ease, starting at 2.5, never
under 1.3), `interval` (days), `reps` (correct reviews in a row), `due` (a
date). The four grades map onto SM-2's quality:

| Grade | Quality | Effect |
|---|---|---|
| Again | 1 | `reps` back to 0, the card comes back **in this session** (after the cards left), then tomorrow |
| Hard | 3 | interval × 1.2 (at least +1 day) |
| Good | 4 | 1 day, then 6, then interval × `ef` |
| Easy | 5 | as Good, × 1.3 |

`ef` moves by SM-2's formula, `ef + (0.1 − (5−q)(0.08 + (5−q)·0.02))`.
Each grade button shows when the card would come back.

- **Today** is the journal's day: **A new day starts at**
  (`journalDayStart`) applies, so a review at 1 a.m. still counts for the
  day before, as an entry does.
- **A session** of a deck is its due cards (oldest due first), then its
  new cards (in note order), up to **New cards per day** (a library
  setting, default 20 per deck; 0 = no new cards). An Again card goes back
  in the queue until it is not graded Again. The session ends when the
  queue is empty.
- **Undo** takes the last grade back (the button, `Ctrl+Z`), as many times
  as the session has grades.
- **A category** can be studied whole: its row's Study reviews the due and
  new cards of every deck under it, one queue.

## Review state · `.niman/review.json`

```json
{
  "Studio/Irregular verbs.md": {
    "choose": {"ef": 2.5, "interval": 6, "reps": 2, "due": "2026-10-20", "at": "2026-10-14T09:12:03Z", "first": "2026-10-12"}
  }
}
```

`first` is the study day the card was first graded. A card has a state from
its first grade on, so it is what tells how many **new** cards a deck has
already shown today (the states whose `first` is today): the daily limit
needs no other counter. It is written once and kept by every later grade;
when both devices graded the card the sync keeps the earlier of their `first`,
and a card only one device changed (a deck reset and studied again) is that
device's whole, `first` included. A state without it (none
written before it existed) is never counted as a new card of today.

- **Out of the note**, because every grade changes it: inside the note it
  would rewrite the file at every card, flooding the history and the sync
  with edits nobody made.
- **In `.niman/`, like `reading.json`** (`lib/src/reading/reading_positions.dart`
  is the model): the library's, not the device's; it syncs; a rename or a
  move in Niman carries the note's entry (`note_relocation.dart`), a
  deletion the library sees drops it. Writes are queued per library and
  run off the UI isolate.
- **The sync merges it card by card**: the entry with the later `at` wins,
  so two devices studying different decks — or the same deck on different
  days — never conflict (`lib/src/sync/state_merge.dart`, beside
  `mergeReadingJson`). It joins the sync's library state files.
- **Losing the file loses the dates only**: the cards are in the notes.
- **Orphans** (a key no card has any more) are dropped only by **Reset the
  review of this deck**. A card edit does not prune: the text change is an
  undoable edit of the note, and Undo brings the old key back with its
  state; and a key the sync brought for a card whose note has not arrived
  yet is not mistaken for an orphan. An orphan costs a few bytes.

## Where the decks come from

The Study tree is the notes whose frontmatter says `type: flashcard` — one
query on the index's `frontmatter_fields` (`key = 'type'`), with their
`deck:` and tags. The counts need the cards and the review state: the
deck notes are read off the UI isolate together with `review.json`, and
the result is kept per note by its modification time, so a library of a
million notes and forty decks reads forty notes. Nothing new is indexed.

## Desktop

- **Study is a place of the rail** (`ShellTab.study`, the destination
  #536 reserved). The left island shows the **deck tree** — categories
  from `deck:`, decks as leaves, each with its **due** and **new** counts,
  summed up the categories — and the deck tags as chips over it.
- **A click opens the deck in a tab**, like a note; several decks open
  together.
- **The deck view**: the deck's place (`Lingue › Inglese`), its name, its
  counts, **Study N**, and the cards as rows — question, answer, when it
  comes back (`Due`, `New`, `in 3 days`). A double click edits a row in
  place (`Enter` saves, `Esc` cancels); **Add card** appends a row to the
  first table (making one if the note has none).
- **The review opens in the other pane**, as a tab of its own
  (`Study · Irregular verbs`), splitting the window right when it is not
  split; the deck stays in its pane with the card under study marked.
  Where the window is too narrow to split, the review takes the deck's
  pane, as the compare tab does (#712). Keys: `Space` shows the answer,
  `1`–`4` grade (`Space` = Good once shown), `Ctrl+Z` undoes, `Esc` ends.
- **End of review**: the summary in the review's pane — reviewed, again,
  time, the grades' spread, when the next cards are due — with **Back to
  the deck** and **Next deck**.
- **The deck's ⋮**: Study this deck (`F5`, the slides' Present key), Edit
  as Markdown, Question and answer columns…, Reset the review of this
  deck…, then the note's own Rename · Move · History · Export · Delete.

## Android

- **Study is a destination of the bottom bar**: the same tree as an
  expandable list with the counts as pills and the tags as chips.
- **The deck**: its counts on top, the questions as a list, **Study** at
  the bottom where the thumb is, beside **Add card**. Several decks open
  are the open-notes switcher, as notes are.
- **Long press on a question**: a bottom sheet with question and answer,
  **Delete** and **Save**; Niman rewrites that row of the note. "Review
  progress is kept while the question stays the same."
- **Review, full screen**: the question, **Show answer** at the bottom,
  then the four grades in a row. End: **Done for today · N reviewed ·
  Next: tomorrow, N cards**, **Next deck** / **Back to the deck**.
- **The Home's Study tile**: today's cards, the decks with cards due, a
  Study button on the first.
- **The Niman Study widget**: the decks with cards due today, grouped by
  `deck:`; a row opens its deck, the header opens Study. Like the other
  widgets, Android only (`docs/user/widgets.md` already says so for Linux
  and Windows); refreshed on a grade, on a deck's change and at the day's
  turn.

## Make flashcards

**Make flashcards** — the ⋮ of a plain note and the palette — turns a note
into a deck without touching its text: it finds the tables, the `::` lines
and the highlights, asks for the question and answer columns when a table
has more than two, asks for the `deck:` (the existing ones offered, a new
one typed), shows the exact frontmatter it will write, and writes it as one
undoable edit (**Make 15 cards**). On a deck the same dialog is **Question
and answer columns…**.

## Decided (2026-10-14)

1. **Study is hidden by default** in the navigation (`defaultHidden`,
   #536's mechanism): a library with no deck does not grow a seventh
   destination. The first deck made (New → Flashcards, Make flashcards)
   offers, once, **Show Study in the navigation**. Study is also always
   reachable from the palette (*Go to: Study*), the Home tile and the
   deck's ⋮.
2. **New cards per day: 20 per deck**, a library setting in a new
   **Settings › Study** (with **Reset all reviews…**).
3. **Today follows the journal's day start.**
4. **Again repeats in the session** until the card is not Again.
5. **A repeated question is keyed `(2)`, `(3)`** and marked in the deck.
6. **A whole category can be studied** from its row.
7. **Undo** of the last grades, as many as the session has.
8. **Keys**: `Space`, `1`–`4`, `Ctrl+Z`, `Esc`; `F5` studies the deck on
   screen.
9. **Desktop review in the other pane**, splitting right when needed; in
   the same pane when the window is too narrow.

## Phases

One branch, `feat/flashcards`, one PR into `main`; a commit per step.

1. **The model**: card reader (tables, `::`, clozes; keys), SM-2
   scheduler, `review.json` store with its sync merge, rename and delete;
   unit tests, the sync merge's included.
2. **The deck catalog**: the query, the off-isolate read, the tree with
   its counts and the tag filter; unit tests.
3. **The deck kind**: `type: flashcard` registered in `NoteKinds`, the deck
   view (desktop and phone), the card edits (inline, the sheet, add,
   delete) as byte-stable rewrites of the note, Edit as Markdown,
   New → Flashcards.
4. **The review**: the session, the grades, undo, the summary; the
   desktop pane beside the deck, the phone's full screen.
5. **Study**: the destination, the tree view, the navigation default,
   the palette commands, the shortcuts, Settings › Study.
6. **Make flashcards**: detection, the columns and deck dialog, the
   frontmatter write.
7. **Home tile and Android widget** (Kotlin provider and service, as the
   todo widget's).
8. **Docs**: `docs/user/flashcards.md`, the settings, shortcuts, home,
   widgets and platforms pages; this record's *As built*.

Main risk: a card's identity when the note changes — kept to the one rule
above, and tested on every edit the deck view makes.

## As built (2026-10-14)

All eight phases landed on `feat/flashcards`, in that order. Where the
build parted from the plan above, or said what the plan left open:

- **Make flashcards and the columns dialog are two dialogs** sharing the
  column pickers (`DeckColumnFields`): a deck's **Question and answer
  columns…** asks only that. Make flashcards writes `front:` and `back:`
  only for a table of more than two columns, and leaves out an empty
  `deck:`. A note with nothing to make cards from is told so and left
  alone. Fixing it turned up that `applyKindEdit` kept the kind a note
  was opened with: an edit that writes a `type:` now turns the view.
- **"Offers once" needs no setting.** The offer writes Study into the
  navigation layout, still hidden; a layout that already places Study —
  shown, hidden by hand, offered before — is not asked again.
- **The deck beside its review hides its answers** (decided 2026-10-14,
  after the first build): the card under study is marked in the list,
  and its answer would be one glance away.
- **The review is a pane tab like the compare tab** (#712): its own
  state (`ReviewTab`), placed by the shell — the other pane of a split, a
  split to the right where the panes have room for two
  (`2 × RightDock.minPanesWidth`), the deck's pane otherwise. A note shown
  in its pane covers it; Home, Todo and the compare tab do too.
- **Next deck** is the first other deck, in path order, with cards today;
  on a phone its review takes the place of the last, and **Back to the
  deck** returns to where the first study began.
- **Study opens a deck the way the tree does**, in place of the pane's
  note. The search's way (`_showNote`) left the new deck *Loading…* in a
  widget test when another deck was open beside the Study tree; not
  followed further.
- **The Home tile is added from the Home's panel**, as Tags and the
  calendar are; it is not one of a new Home's tiles.
- **The day's turn reaches the widget when the app comes back**: the
  decks are counted for the study day it is now on resume. With the app
  closed across midnight the widget shows the day before until Niman is
  opened (`docs/user/widgets.md` says so). Its text is English and
  Italian, as the other widgets'.
- **Settings › Study** offers 0, 5, 10, 20, 30, 50 and 100 new cards a day;
  a number typed into `settings.json` keeps its place among them.
