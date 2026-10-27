# The tree, by what is on screen (#1200)

The design for bounding the note tree's memory by the rows on screen, not by
the rows ever scrolled past. It was written before any code; phases 1 to 4
are built (the index reads, `VisibleTree`, `TreePages`, and `NoteTree` on
them), and the measurement of phase 5 is not. It answers finding 7 of
[memory-usage.md](memory-usage.md); #1200 was deferred because the fix is a
redesign of how the tree reads and indexes its rows, not a local change.

## What the tree does now

`lib/src/ui/tree.dart` (~1 500 lines) and `lib/src/ui/tree_child_cache.dart`.

- **Reading.** `TreeChildCache` keeps, per folder id, the `List<Note>` read so
  far (`LoadedChildren`). A folder is read a page of 2 000 at a time
  (`NoteTree.defaultPageSize`) with `NoteDao.childrenPage`. That is a keyset
  read forwards only (`after:` the page's last row). Drawing a folder's last
  loaded row asks for the next page (`moreOf`, `_loadMore`), and the page is
  **appended**: the list only grows. A folder that is closed keeps its list
  (#1064: reopening reads nothing).
- **Flattening.** `_flatten` reads the missing folders level by level, then
  `_walkSync` builds `_Rows.tree`, a `List<_Row>` with one object per loaded
  child of every expanded folder. `ListView.builder` draws `_Rows` by index.
  Every row is the same height (`TreeRowMetrics`).
- **Invalidation.** A revision forgets the folders it moved rows in
  (`foldersMovedSince`, #1132), or all of them. A new order clears
  everything.

**What it costs.** The heap after a collection reads **697 B a row**: the
path, the name and its key, the digest's 64 characters, two `DateTime`s and
the other fields (`test/perf/memory_retention_test.dart`, #1193). Each loaded
row also gets a `_Row` of ~40 B. Scrolling a folder of a million notes to its
end keeps **~700 MB**, until the library closes or the order changes. The
library's open does not grow: 2 MB at a million notes
(`performance-audit.md`).

## The flows that read the whole flattened list

Each of these has to be answered differently once only some of the rows
are loaded:

| Flow | Today | Where |
|---|---|---|
| The list's length and row at an index | `rows.tree.length`, `rows.tree[i]` | `_tree`, `_walkAt` |
| A path's index: the cursor, the renamed row brought into view, a Shift+click range | `rows.tree.indexWhere(path)` | `_cursorAt`, `_revealRenamed`, `_rowActivated` |
| Left arrow to the parent | walks back through the rows for a smaller depth | `_onKey` |
| Jump to a typed name | walks every row from the cursor, wrapping | `_jumpTo` |
| Mark a range | `_walkRow(i)` for every index in the range | `_markRange` |
| Drop the marks that left the tree | a set of every row's path | `_dropMarksOutside` |
| A text recognition sidecar under its file | reorders a folder's loaded rows | `nestOcrSidecars` in `_walkSync` |
| The row being made under its folder | a `Column` taller than a row | `_tree`, `_CreateRow` |

## The design

### 1. A model of what is visible, without the rows

`VisibleTree` is a new pure-Dart class, testable without widgets. It knows
three things:

- **The expanded folders**, as the widget gets them today (`widget.expanded`).
- **Each expanded folder's child count** (`NoteDao.childCount(parent)`, one
  `COUNT(*)` through `notes_tree`).
- **The rank of each expanded folder among its siblings**: how many siblings
  sort before it (`NoteDao.rankOf(note, sort)`, a `COUNT(*)` over the same
  keyset predicate `childrenPage` builds).

From these:

```
visible(f) = childCount(f) + Σ visible(c), over the expanded children c of f
```

The root's `visible` is the list's length. An index maps to a
`(folder, position)` by walking down from the root: in folder `f`, the
expanded children are taken in rank order, and each one's block of
`visible(c)` rows is stepped over or entered. A `(folder, position)` maps
back to an index the same way.

The cost is O(expanded folders × depth) per lookup, and the expanded
folders are the ones a user opened. No row is needed for either direction.

A path's index is the reverse walk: the row's parent chain, from its `path`,
each with its rank. Each rank is one count. This is what the cursor, the
rename reveal, the left arrow (the parent is `note.parent`) and a Shift+click
range need.

### 2. Pages around the viewport

`TreePages` replaces `TreeChildCache`. It keeps pages keyed by
`(folder, page number)`, a page being `pageSize` consecutive positions in
the folder's order.

- **A page is read from a neighbour when it can be.** It uses `after:` the
  last row of the page before it, or the new `before:` from the first row of
  the page after it (the same keyset with the comparisons and the order
  turned, then reversed). Only a page with no loaded neighbour is read by
  position, with `LIMIT ? OFFSET ?`: an O(offset) walk of `notes_tree`, paid
  once for a jump.
- **The pages kept are the ones the list can draw:** those overlapping the
  viewport and the list's own cache extent, plus the one page either side
  that a keyset read starts from. A page that leaves that range is dropped
  when the next one lands. This is not an LRU of a chosen size: the window is
  the viewport's, so what is held follows the screen and the row height.
- **Closing a folder drops its pages.** This reverses #1064's "reopening
  reads nothing" for the pages, though not for the count. Reopening reads
  one page, which is what #1064 measured as cheap. What it was guarding
  against was reading every open folder again on each toggle, and that
  stays fixed.
- **A revision forgets** the counts, ranks and pages of the folders it moved
  rows in, as now, through `foldersMovedSince`.

### 3. The widget

- `ListView.builder` gets `itemCount` from the model and `itemExtent` from
  `TreeRowMetrics`. A jump to an offset (the scrollbar, `End`) then builds
  only what it lands on.
- **A row whose page is not loaded** is drawn as an empty row of the same
  height, and its page is asked for after the frame (as `_loadMore` is now).
  The row is filled in when the page lands. On a scroll this is one frame of
  blank rows at most for a page under a millisecond (`tree_queries_perf_test`
  measures a page).
- **The pinned block** stays as it is: a few rows read on their own, above
  the tree.
- **The row being made** becomes a virtual row of the model, one position
  under its folder. It no longer makes a taller `Column`, so `itemExtent`
  holds.

### 4. The flows

- **Cursor, rename reveal, Shift+click range, left arrow:** a path's index
  through the model (§1).
- **Keyboard moves:** `_walkRow(i)` reads the loaded page. A move that lands
  on an unloaded page (`End`, `PgDn` far, a jump) asks for the page and
  finishes the move when it lands. The key handler answers `handled` at
  once, so the keys stay synchronous as Flutter wants.
- **Jump to a typed name:** asked of the index, not walked through the rows.
  The search goes folder segment by segment in visible order from the
  cursor: the first child of the folder that sorts after the cursor and
  whose `name_key` starts with the folded prefix. In name order that is one
  seek on `notes_tree`, and in the field orders a filtered `LIMIT 1`. It
  wraps as now.
- **Mark a range:** the range's rows are read a page at a time into the
  marked paths. Marking a million rows is the user's choice, and so is
  deleting them, which reads them anyway.
- **Drop the marks that left:** one query for which marked paths still exist
  under expanded folders. The marks are few.
- **Text recognition sidecars:** nested within a page, as they are within a
  2 000-row load today. A sidecar whose file falls in another page stays
  where it sorts, as a plain note, which is today's behaviour at a page
  boundary. Nesting moves rows only within a page, so positions and counts
  are unchanged.

### 5. Optional: slimmer rows

The tree draws a row from `id`, `path`, `name`, `isDir`, `title`, `date`,
`pinned`, and keys its pages on `name_key` and the sort's field. The digest
(64 characters), `created` and `size` (when not sorting by them) are read
for nothing. A `TreeRow` read with only those columns would bring a row from
697 B to about a third. Callbacks that need the whole `Note` (menus, drag,
open) would read it by id when they act. This is a separate phase, because
the window already bounds the count of rows held; it is worth doing if the
window's rows are still the tree's largest holder after phase 4.

## What it costs, and what it does not do

- **Memory:** O(viewport + expanded folders), whatever has been scrolled
  past.
- **Reads:**
  - A revision costs one count per affected expanded folder, where today it
    costs a page. A count of a million-child folder walks its `notes_tree`
    entries: tens of milliseconds, off the UI isolate (drift). If
    measurement shows that is too slow, the counts can be materialized the
    way `tag_counts` is, rebuildable from the rows.
  - Jumping into the middle of a huge folder costs one `OFFSET` read.
- **The field orders (modified, created, size)** have no index today: each
  page read sorts the folder's rows (a top-N sort, O(n log k)), and so will a
  count's rank. That is today's cost per page too. An index per field order
  would make them seeks at ~50 B a row of index each, six of them. Left out
  until a measurement asks for it.
- **The UI does not change.** No row moves, and the scroll position behaves
  as a list of fixed rows. A long jump shows blank rows for a frame.

## Phases

One branch and one PR, a commit per phase, following the issue's test for
each.

1. **The index:** `childCount`, `rankOf`, `childrenPage(before:)` and the
   positional read, with unit tests against `IndexDatabase` in memory,
   including the keyset reversed in every `TreeSort`.
2. **`VisibleTree`:** the model and its index ↔ position ↔ path mapping,
   with a property test against a flattened list built the old way, over
   random expanded sets and orders.
3. **`TreePages`:** the window, the neighbour reads and the invalidation,
   with tests that pages leave when the window moves and that a revision
   forgets only the moved folders.
4. **The widget:** `NoteTree` on the model and the pages. The existing tree
   widget tests are kept passing unchanged, as the proof that nothing a user
   sees moved: keyboard, marks, rename, create, drag, sidecars, pinned.
5. **The measurement:** `tree_queries_perf_test` and the retention test
   page through a folder of a million notes and print the heap retained,
   held to a bar of a few pages under `NIMAN_PERF`.
6. **Optional:** slimmer rows (§5), only if phase 5 says so.

Manual checks before the PR, on Windows and on the Android tablet:

- scroll a folder of 100 000 notes to its end and back;
- drag the scrollbar to its middle;
- `End` and `Home`;
- type a name;
- Shift+click across pages;
- rename a row far down;
- create a note in a long folder;
- open and close folders while scrolled.

## As built (phase 4)

What the widget does that the sections above leave open:

- **The list** is a `CustomScrollView` with a `SliverList` for the pinned
  block and a `SliverFixedExtentList` for the tree rows: a varied-extent list
  walks every item to lay out, which a million rows cannot pay. The system's
  insets are put around the slivers the way a `ListView` does.
- **The window** the pages are matched to is what the list laid out
  (`TreeRowsDelegate.didFinishLayout`), so the pages held and the rows drawn
  cannot disagree. The first read of a revision works the window out from the
  scroll position and the screen's height, and reads those pages before the
  rows land, so a change blanks nothing; the rows on screen meanwhile are
  drawn from the pages they held (`TreeListing.freeze`).
- **Keys** answer from the rows in memory, as they always did; only a cursor
  or a target in a page that is not loaded waits for the page, and a typed
  name that the rows in memory cannot answer waits for the index.
- **The row being made** is a virtual row of the list under its folder's row
  (a folder's row found in a loaded page, else by rank). At the root it stays
  above the list, as it was.
- **A name that a sidecar answers** is found in the order of the names, where
  the row is drawn under its file: when the index answers, a sidecar can be
  found before the file it is drawn under.

## Open questions

- **The OFFSET read on a phone.** Walking a million index entries is fast on
  the desktop. The tablet's flash may make a scrollbar jump visible: to be
  measured in phase 5, and answered by an index on position only if needed.
- **The count after each revision of a huge folder.** If the count is the
  slow part of a save in a million-child folder, materialize it (§"What it
  costs").
