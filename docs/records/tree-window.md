# The tree, by what is on screen (#1200)

The design for bounding the note tree's memory by the rows on screen, not by
the rows ever scrolled past. It was written before any code; phases 1 to 4
are built (the index reads, `VisibleTree`, `TreePages`, and `NoteTree` on
them), and phase 5 measured them (see "Measured (phase 5)"). It
answers finding 7 of [memory-usage.md](memory-usage.md); #1200 was deferred because the fix is a
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

## Measured (phase 5)

`test/perf/tree_window_memory_test.dart` writes one folder of N files into an
in-memory `IndexDatabase` and drives a `TreePages` the way `NoteTree` does: a
window of 60 rows (a screen and the list's cache extent at a 24-px row)
stepped down 40 rows at a time, from the top to the end; each step loads the
pages the window is drawn from and keeps `pagesFor`. Then it jumps to the
middle and to the end of the folder (the OFFSET path), and times `visible()`.
N is 100 000 in a normal run and a million under `NIMAN_PERF=1` (or
`NIMAN_SCALE=<n>`). What is held, in pages and rows, is not a timing and gates
on every host; the heap and the timings assert a backstop, and the design's
bar (the window's four pages at 697 B a row plus 256 KB for the model) only
under `NIMAN_PERF=1` with an exact heap reading. Run:

```
flutter test test/perf/tree_window_memory_test.dart
NIMAN_PERF=1 flutter test --enable-vmservice test/perf/tree_window_memory_test.dart
```

Windows 11, 2026-10-27, both runs passing:

| | 100 000 files, default run | 1 000 000 files, `NIMAN_PERF=1`, exact heap |
|---|---|---|
| Seeding the index | 0.3 s | 2.5 s |
| Scroll, top to end | 2 501 steps, 1.4 s | 25 001 steps, 32 s |
| Pages / rows held at the peak | 3 / 6 000 | 3 / 6 000 |
| Pages / rows held at the end | 2 / 4 000 | 2 / 4 000 |
| Heap retained by the `TreePages` after the scroll | not readable (the resident set read -62 MB) | **3.59 MB** (bar 5.57 MB) |
| What the old design held (computed: rows x 697 B) | 66.5 MB | **664.7 MB** |
| A keyset page of 2 000 rows (median / max) | 28 / 39 ms | 63 / 118 ms |
| Same, first tenth of the folder / last tenth (median) | 25 / 31 ms | 28 / 98 ms |
| OFFSET page at the middle | 28 ms | 43 ms |
| OFFSET page at the end | 25 ms | 53 ms |
| `visible()`, first call (find, rank, both counts) | 2.9 ms | 23 ms |
| `visible()` after a revision of the folder (its count again, median) | 2.1 ms | 21 ms |
| `visible()` with the facts held | 0.1 ms | 0.2 ms |

- **The window holds.** Scrolling a million rows ends with two pages
  (4 000 rows) and peaks at three: 3.59 MB where the old design held about
  665 MB, 0.5% of it. That is about 900 B a held row, above the 613 to 618 B
  a row a page costs once read (the exact reading of a bare `childrenAt` of
  2 000 rows), because the reading also takes the model, the facts and the
  heap's fragmentation after a long scroll. A first read on a connection
  adds about 1.2 MB of statements and code to the heap for good, which the
  test warms up before it reads the baseline; a figure from a cold connection
  would blame the scroll for it.
- **The resident set cannot hold the bar.** Without `--enable-vmservice` the
  heap line is the process's resident set, and it read -62 MB and -10 MB on
  two runs of the same scroll. Only its backstop (half of what the old design
  would hold) gates there.
- **The keyset read is not flat in depth at a million rows.** A page read
  after a row costs 28 ms in the first tenth of the folder and 98 ms in the
  last, and the same shape reads straight off the DAO (27 ms at row 10 000,
  96 ms at row 950 000, in either order of asking). `EXPLAIN QUERY PLAN` of
  the query `TreePager._cursor` builds says `SEARCH notes USING INDEX
  notes_tree (parent=?)`: the cursor is an `OR` of the order's terms, which
  SQLite cannot seek on, so it walks the folder's index entries from the
  first and discards those before the cursor. Adding the seek bound a files
  cursor allows (`is_dir = ? AND name_key >= ?`, and `name_key <=` for a
  descending order) makes the plan `(parent=? AND is_dir=? AND name_key>?)`
  and took the same page from 69 ms to 4.6 ms at row 750 000 (raw rows,
  without building the `Note`s). The read was like this since #1064's
  `childrenPage(after:)`, which a 200 000-row test passed because its bar is
  a backstop; it is now the cost of every page of a long scroll, and the
  reason a keyset read is slower than an OFFSET read from the middle of a
  million rows on.
  - **Fixed, measured again.** In a name order `TreePager` now reads
    the cursor's own `is_dir` group as one row value, `(name_key, name) >
    (?, ?)` (`<` in a descending order, and turned round before the cursor),
    which is a range of `notes_tree`. When that group runs out before the
    page is full, the read goes on into the next group from its own end. A
    name order's rank is counted the same way. At a million rows a page now
    costs 24 ms at the top and 24 ms in the last tenth (median 24, max 40,
    against 63 and 118 before), and the scroll from top to end takes 12.8 s
    instead of 32. The 24 ms left is building the 2 000 `Note`s. The field
    orders keep the `OR` cursor: they have no index to seek, and every page
    of theirs is a sort of the folder whatever the predicate.
- **A model costs one count.** `visible()` over the million-file folder is
  23 ms the first time, and 21 ms when a revision made it count again, on the
  test's own isolate (in the app the read is off the UI isolate). With the
  facts held it answers in 0.2 ms.

## Open questions

- **The OFFSET read.** Answered for the desktop in phase 5: a read by
  position costs 43 ms at the middle of a million-file folder and 53 ms at its
  end, three frames of blank rows at most for a scrollbar jump, and it is no
  slower than a keyset read from there. No index on position is needed on the
  desktop. **Still open on a phone:** the tablet's flash may make the walk of
  a million index entries slower, and it was not measured there. What the
  measurement found instead is the keyset read's cost growing with depth (see
  "Measured (phase 5)"). That is fixed now for the name orders, flat at
  24 ms a page.
- **The count after each revision of a huge folder.** If the count is the
  slow part of a save in a million-child folder, materialize it (§"What it
  costs"). Answered for the desktop: 21 ms at a million children, so it is
  not materialized. Open on a phone, with the OFFSET read.
