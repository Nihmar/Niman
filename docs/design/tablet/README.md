# Tablet — the screens, and the decisions

The mockups the tablet's wide shell was redrawn against (2026-11-11),
before any code: a tablet had the desktop's shell with thumb-sized
targets (#849, #1134), and it read as a squeezed desktop. They are drawn
on an 11″ tablet (1194 × 834 dp in landscape) to look like Niman, in the
Day palette of `lib/src/ui/theme/niman.dart` (one in the Night palette);
where a mockup and the app disagree, the app is what ships.

Three directions were drawn; **A** was chosen.

| Direction | Screen |
|---|---|
| **A** — the shell as it is, made for a thumb: a rail with labels, the tree, the note | [A-1-Main](html/A-1-Main.html) |
| B — three columns: sidebar, a list of the folder's notes with a preview, the note | [B-Columns](html/B-Columns.html) |
| C — the note full screen, the chrome floating over it | [C-Focus](html/C-Focus.html) |

## Direction A

| Screen | Mockup |
|---|---|
| Landscape: the rail with labels, the library at its top and **New** under it, Settings at its foot; the tree with the library's name over it; the open notes as chips heading the pane, **Edit \| Read** and ⋮ at the row's end | [A-1-Main](html/A-1-Main.html) |
| Portrait, the tree closed: the rail and the note | [A-2-Portrait](html/A-2-Portrait.html) |
| Portrait, the tree open: it lies over the note beside the rail, a scrim over the rest; a tap outside closes it, the pin keeps it | [A-3-PortraitTree](html/A-3-PortraitTree.html) |
| Writing: the keyboard up, the tree out of the way, the rail without its labels, the formatting toolbar on the keyboard | [A-4-Writing](html/A-4-Writing.html) |
| Home: the tile grid takes the room the tree had | [A-5-Home](html/A-5-Home.html) |
| Todo: the list and, beside it, the task tapped | [A-6-Todo](html/A-6-Todo.html) |
| Search: the results in the tree's place, the note beside, the find bar on the match | [A-7-Search](html/A-7-Search.html) |
| Split: two panes, the focused one marked under its chips, a thumb-wide grab between them | [A-8-Split](html/A-8-Split.html) |
| The Night palette | [A-9-Dark](html/A-9-Dark.html) |

## Decided with them

- **A tablet keeps the wide shell**, the tree and the panes, and changes
  how it is drawn, not what it holds. A phone is untouched, and so is a
  desktop: every change below follows `thumbDense`, the touch density a
  tablet has and a mouse does not.
- **The rail says what its buttons are.** Icons alone were a desktop's
  answer, where a tooltip is a hover away; a thumb has no hover. Each
  destination is its icon on the active pill with its label under it, as
  a navigation rail is on Android and iPadOS.
- **New is at the top of the rail**, under the library: the phone's `+`
  button, where a thumb on the left edge finds it.
- **The tree gets out of the way when there is no room for it.** In
  portrait, or wherever the panes would be left too narrow, it lies over
  the note rather than beside it, and closes on a tap outside or on a note
  opened from it.
- **Writing is the note and the keyboard.** With the keyboard up in a
  note, the tree steps aside, the rail drops its labels, and the formatting
  toolbar rides on the keyboard as it does on a phone.
- **Home and Todo take the width.** They are pages, not notes: the tree
  steps aside while they show and comes back with Files.
- **Todo shows the task beside the list** where the pane has the room
  for both: the fields the edit dialog holds, in a panel that stays while
  another task is tapped. Where it has not, the dialog stays.
- **Search stays the sidebar view it is** (#712); only its touch sizes
  change.

## Where the app parts from the mockups

- **Edit | Read and ⋮ head the note**, in the note's own top row, not in
  the open notes' row: each pane of a split has its own note, and the
  pair has to say what that pane's note shows.
- **The tree lies over the note when the tablet is held upright**, or in
  landscape when beside it the note would have under 360 dp — not by
  width alone: a 7″ tablet in landscape and a 1024 dp one keep it beside.
- **The library's button shows its initial** on the accent, rather than
  the app's mark: it is the library, not the app, that it switches.
