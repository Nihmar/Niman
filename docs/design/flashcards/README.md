# Flashcards — the screens

The mockups #533 is planned against (2026-10-14), before any code: six
desktop screens and eight phone screens, drawn on a design canvas in the
Night palette of `lib/src/ui/theme/niman.dart`. Where a mockup and the app
disagree, the app is what ships. The plan they belong to is the record
[flashcards.md](../../records/flashcards.md).

| Screen | Desktop | Phone |
|---|---|---|
| **The Study tree**: categories from `deck:`, decks as leaves, due and new counts summed up the tree, tag chips that filter | D1 | P1 |
| **A deck**: its place, name, counts, **Study N**, the cards with when each comes back, **Add card** | D1 | P2 |
| **Review, the question**: in the pane beside the deck (the card under study marked in the list) on the desktop, full screen on a phone; progress, the remaining due / new / again, undo | D2 | P4 (a cloze) |
| **Review, the answer**: the four grades, each with when the card comes back; keys on the desktop | D3 | P5 |
| **End of review**: reviewed, again, time, the grades' spread, the next cards due, **Next deck**, **Back to the deck** | D4 | P6 |
| **Editing a card**: in place on the desktop (`Enter` / `Esc`), a bottom sheet from a long press on a phone; the deck's ⋮ | D5 | P3 |
| **Make flashcards** from a note: columns, deck, the exact frontmatter written | D6 | — |
| **The Home's Study tile** | — | P7 |
| **The Niman Study widget** (Android) | — | P8 |
