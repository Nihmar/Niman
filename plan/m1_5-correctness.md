# M1.5 — Correctness pass

**Status:** Planned · **Depends on:** M1 · **Blocks:** M2 · **Spec:**
*Requirements* (model), *Performance strategy*

## Purpose

Close the defects found in M1 after the Android device round and a
review of the note operations. Most are visible in the app; one is the
reason M3 cannot start on top of the current index. None is a new
feature: this milestone changes how existing behaviour works, not what
the app does.

M2 is blocked on this because the tree is the surface every later
milestone builds on, and because the fix to the rewrite strategy touches
the same code paths M3 would otherwise extend.

## Current state

M1 is done and verified on device: the library opens, the watcher and
the periodic rescan run off the UI isolate, and the tree renders from
materialized rows. Underneath, the index is maintained by deleting and
re-inserting rows, mutations never notify the UI, and the trash restores
items under a name it derives from the wrong source.

## Tasks — index

- [ ] **T-M1.5-01** Fire `Indexer.onChanged` after every successful index
  mutation (`fullScan` write, `applyEvents`, `resync`), which is what its
  own doc comment already promises and what `LibraryController` wires to
  `_bump`. Today it is never called, so the session revision never moves
  for an index change. It used to be masked: the tree re-queried the index
  on every rebuild, so anything that repainted the UI also refreshed it.
  Caching the flattened rows (commit `9a3eb48`) removed that accident, so
  the missing notification is now visible for app-originated changes too.
  *AC: a note created outside the app appears in the tree without any
  other interaction; a unit test on the real controller asserts the
  revision moves.*
- [ ] **T-M1.5-02** Fix the parent link lost by a subtree resync.
  `_insertEntries` resolves parents only from the directory rows of the
  batch it is inserting, and `_parentId` falls back to `0` when the
  parent is outside it. A subtree resync therefore re-parents its own
  root to the library root: rename or move inside a nested folder and
  that folder jumps to the top of the tree. *AC: a move inside
  `a/b/c` leaves `a/b/c` under `a/b`; test covers the resync path
  directly.*
- [ ] **T-M1.5-03** Replace the wholesale rewrite with a diff.
  `fullScan` runs `DELETE FROM notes` and re-inserts everything whenever
  anything changed, and `_syncDirSubtree` does the same per subtree, so
  every `notes.id` is reassigned. The device logs show it: the same
  folder is `parent=207` in one open and `parent=5` in the next. Compute
  the difference against the stored rows and apply only inserts, updates
  and deletes, keeping the id of every row whose path survives. *AC: ids
  are stable across a rescan that adds, removes and renames entries; a
  rescan with no changes still writes nothing.*
- [ ] **T-M1.5-04** Align the widget-test fake with the real contract.
  `FakeLibrarySession` bumps its revision on every mutation while
  `LibraryController` does not, which is why T-M1.5-01 went
  unnoticed by the test suite. Cover the notification contract where the real
  implementation lives. *AC: the fake and the controller agree on when
  the revision moves, asserted in both suites.*
- [ ] **T-M1.5-05** Tests: id stability across scans, parent correctness
  after subtree resyncs, revision on disk-originated change, and the
  existing rebuildability check kept green. *AC: green.*

## Tasks — note operations and trash

- [ ] **T-M1.5-06** Restore under the original name. `restoreTrash`
  derives the restored name from the name inside `.trash/` via
  `splitFileName`, but that name is not the original one: a collision is
  stored as `<base>.<unixSeconds><ext>`, so a restored note keeps the
  timestamp, and a folder whose name contains a dot is truncated at it —
  `v1.2 notes` comes back as `v1`. The manifest already records
  `originalPath`; take the name from there. *AC: restoring a timestamped
  item and a dotted folder name both yield the original name (uniquified
  only on a real collision).*
- [ ] **T-M1.5-07** Fix the delete-permanently dialog text. It reads
  `'$item.name will be deleted permanently'`, which interpolates the
  object and then prints a literal `.name`, so the user is asked to
  confirm deleting `Instance of 'TrashItem'.name`. *AC: the dialog names
  the item; a widget test covers the confirm path, which today only the
  restore path exercises.*
- [ ] **T-M1.5-08** Reject moving a folder into itself or its own
  subtree. The move picker lists every indexed folder, descendants of the
  moved one included, and the rename then fails with a raw OS error in a
  snackbar. Filter the candidates and validate in `NoteOps.move`.
  *AC: the picker cannot offer an invalid target; `move` throws a
  meaningful error if called with one anyway.*
- [ ] **T-M1.5-09** Make the trash manifest tolerant. `_readManifest`
  already survives a missing, empty or non-object file, but a single
  malformed entry throws while decoding and takes the whole trash screen
  with it, permanently. Skip bad entries instead, and drop entries whose
  item is no longer on disk while writing. *AC: a manifest with one
  corrupt entry still lists the others.*
- [ ] **T-M1.5-10** Hide the atomic-write temp files from the index.
  `writeFileAtomically` names them `<file>.copist-tmp-<micros>`, which
  does not start with a dot, so the indexer's hidden-entry rule does not
  skip them and a scan that lands mid-write indexes one as a note. Give
  them a leading dot. *AC: a scan concurrent with a write never produces
  a temp-file row.*

## Technical design

See [design.md](design.md) → *Data model (drift)*. M1.5 slice:

- **Diff, not rewrite.** Load the current rows keyed by path (already
  done for the change check), compare against the walk, then: insert
  paths that are new, update rows whose size, mtime or name changed,
  delete rows whose path is gone. Directories keep their id, so parent
  ids stay valid and only genuinely moved rows are re-parented.
- **Parent resolution** must look up ids already in the index, not only
  in the current batch: with stable ids the parent of a subtree root is
  simply the existing row for its parent path. The `?? 0` fallback goes
  away; a missing parent is an error worth surfacing, not a silent
  re-parent to the root.
- **Notification.** One `onChanged` per completed mutation, fired after
  the transaction commits and only when something was written — the same
  rule `fullScan` already documents for its no-write case.
- **Why now, not in M3.** `frontmatter_fields.note_id`, `note_tags` and
  the FTS rowid all key off `notes.id`. On a churning id space each of
  them is orphaned or has to be rebuilt on every scan, and rebuilding the
  FTS content means re-reading every note body from disk. Stable ids are
  the precondition for the incremental indexing M3 and M6 both assume.

## Exit criteria

- A change made outside the app shows up in the tree by itself.
- Renames and moves inside nested folders leave the tree shape intact.
- Note ids survive rescans; a no-change rescan still writes nothing.
- The index stays verifiably rebuildable: delete the db, rescan, get the
  same tree.
- A restored item comes back under its own name, wherever it came from.
- No dialog shows an object where a name belongs, and no move offers a
  destination that cannot work.
- Unit + widget tests green.

## Risks / open questions

- The diff must stay off the UI isolate on the walk side (M1 already
  moved it) while the write side stays on the main isolate with the drift
  connection — the split measured 0.02 s for the write, so it holds.
- Deletions must still cascade to descendants; the subtree delete used
  today is the behaviour to preserve, not the row rewrite around it.
- Case-sensitivity of path keys across platforms (an M1 open question)
  becomes visible here, since the diff matches rows by path. Decide the
  comparison rule while writing it.
- The trash manifest lives inside `.trash/`, which the index never sees,
  so nothing cross-checks the two. Entries whose item vanished are
  filtered out on read but never pruned (T-M1.5-09 does the pruning).
- `emptyTrash` removes only managed items, leaving anything a user put in
  `.trash/` by hand. That is deliberate, but the button says "Empty
  trash" — decide whether the wording or the behaviour should change.
