# The index scan: a directory at a time, with bounded memory (2026-09-26)

Issue #302, split out of #22. `fullScan` — first open, explicit re-index and
the periodic rescan fallback — used to load the whole library into memory
before it wrote anything: every index row into one `Map<String, Note>`, the
disk walk into one `List<DiskEntry>`, and the parsed text of every changed
note into one map. `d30ae0b4` measured that at a million notes on
2026-09-10: about nine seconds and a gigabyte, which on a phone is an OOM
kill that recurs on every rescan.

## What it does now

- **One streamed walk.** `DirWalker` drives one long-lived background
  isolate that answers one `DirListing` — a directory's direct children —
  per request, depth-first, parents first. The caller mirrors a directory,
  then asks for the next: one request per directory is the backpressure, so
  neither side holds more than one listing. A short-lived `Isolate.run` per
  directory would have been an isolate spawn per folder, and the FUSE
  `listSync`/`statSync` behind a listing cannot run on the UI isolate.
- **The diff is per directory.** A listing is compared with the rows whose
  parent it is, written in one transaction, and forgotten; content is read
  and written for that directory only, in the batches the content pass
  already used.
- **Renames pair across directories through two scan-scoped temp tables.**
  A note gone from a folder the walk has passed stays in `notes` (deleting
  it would take its FTS, tag and link rows, and pairing repoints the row
  rather than resurrecting it) and joins `scan_orphans`; the folder paths
  no pairing claims go to `scan_gone` for the prune at the end. A new note
  in a later folder pairs against the orphan table, immediately. A note
  whose new home the walk reached *before* its old one leaves a fresh row
  behind; a second pass after the walk pairs what is left, deletes the
  fresh row and repoints the orphan. Both tables are SQLite's, not Dart's:
  a mass delete costs disk, not heap.
- **Link edges are resolved after the walk.** Directory-at-a-time writing
  made the old inline resolution wrong twice over: a link to a note a later
  directory introduces found no row, and a link to a note moving into an
  earlier directory found two. Each directory's edges go to the durable
  `pending_links` table; at the end, after the pairing and the prune, they
  resolve against the final tree in pages of 500. Durable rather than
  scan-scoped: a scan that never reaches its end would leave a note whose
  FTS row is written but whose edges are not — and the content-row check
  cannot see the difference. The event paths (`applyEvents`, `rescanFiles`)
  still resolve inline, as before.
- **The one-time repairs are paged.** Missing file stems and frontmatter
  recorded against a non-note are written a page at a time
  (`repairDerivedRows`), and the "notes without a content row" check is
  scoped to the directory being mirrored instead of returning every
  missing path as a list.
- **The first index is streamed too.** `indexTreeFirst` writes the tree
  directory by directory instead of materializing the whole walk.

## Measured

`test/perf/index_scale_test.dart`, "a full scan holds a directory, not the
library": a real library on disk, a fresh index, RSS delta and wall clock.
`NIMAN_FIXTURE_DIR=<dir>` points it at the library
`dart run tool/make_fixture.dart <dir> 1000000` writes, which is the gate;
without it the test writes a small fixture (2 000 notes, 7 MB).

| Notes | First scan | RSS delta | Unchanged rescan | Rescan RSS |
|---|---|---|---|---|
| 2 000 | 3.9 s | 7 MB | 91 ms | 0 MB |
| 50 000 | 47 s | 38 MB | 786 ms | 0 MB |
| 200 000 | 189 s | 45 MB | 3.3 s | -4 MB |

The delta is what the old reconciliation scaled linearly — a gigabyte at a
million. What is left is SQLite's page cache and a directory's worth of
Dart objects, not the library. The first scan's wall clock is the content
pass (one read per note, one short-lived read isolate per 200), not the
tree diff; an unchanged rescan pays the walk and no reads.

## Decisions worth keeping

- **Sequential ids of a scan's new rows.** `maxId()` before the walk is the
  baseline: every row above it was inserted by this scan, which is how the
  second pairing pass finds the fresh rows a rename left behind without a
  third temp table.
- **Ambiguity pairs nothing.** Two orphans with identical size, mtime and
  digest make a move ambiguous, and guessing would repoint the wrong id;
  the same rule the in-listing pairing already had.
- **A failed listing is not an error.** A folder that vanishes between its
  parent's listing and its own comes back marked `failed`; the scan skips
  it and the next one repairs the row. The old walk threw and failed the
  whole scan.
- **The link queue is a schema table, not a temp one.** `pending_links`
  is written and deleted in the same pages, so it is empty whenever a scan
  finishes; a kill between pages leaves rows the next scan flushes. The
  index is a cache, so a schema bump wipes and rescans it anyway
  (`schemaVersion` 5).
