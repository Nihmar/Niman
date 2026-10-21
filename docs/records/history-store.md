# The history store: objects, deltas and a log (#1148)

How `.history/` keeps a note's versions since #1148, why it changed, and
what was measured. What a version *is* — when one is kept, rotation, the
pinned sync base, how history follows a note — is unchanged and stays in
[sync.md](sync.md), "History".

## Why

Before #1148 every version was a whole copy, `.history/<path>.v<n>`, beside
a JSON manifest that every snapshot rewrote whole. Both were written to a
temp file, flushed and renamed before the save that asked for them could
go on.

- **On the tablet** (log of 2026-10-20), a session's first save waited
  **85 ms at the median and 219 ms at worst** for its snapshot. A 10 KB
  note waited as long as a 1.5 MB one: the time was the two flushes, not
  the copy.
- **On disk**, twenty sessions of small edits to a 1.5 MB note kept
  **30 MB**: 100 % of twenty copies.

## The layout

```text
.history/
  .objects/
    3f/a1c4…            one version's content, named by its sha256
  .locks/
    9c2e….lock          one writer at a time on a note's log
  Projects/
    Plan.md.log         Plan.md's history: one line an event
```

- **Objects.** `.history/.objects/<first two hex>/<other 62>`. Each holds
  the content of one version, kept once whichever note or version names it:
  a restore, a sync base, the same text in two notes. The format is
  `"NHO1" | kind | [base sha256] | zlib(payload)`.
  - Kind 2 is whole and compressed fast: what a snapshot writes, since a
    save waits for it.
  - Kind 0 is whole and compressed hard.
  - Kind 1 is a delta against the base object named in the header.
- **The log.** `.history/<path>.log` has one JSON object a line, appended
  and never rewritten on a save's path:
  - `{"v":14,"t":<ms>,"r":"session","n":5120,"h":"<sha256>"}` keeps a
    version;
  - `{"pin":"syncBase","v":12}` moves a pin (`"v":null` releases it);
  - `{"drop":[3,4]}` rotates versions out.

  Folding the lines in order gives the `HistoryManifest` the rest of the
  app has always read. The log is rewritten whole, atomically and flushed,
  in two cases only: to compact it (once its lines pass twice what they
  describe, plus 16), and when a move merges two histories.
- **Deltas.** Packing stores an older version as a delta against the
  version after it: the newest stays whole, as git packs (reverse deltas).
  A delta is found a line at a time and each match extended a byte at a
  time (`text_delta.dart`). A whole object comes every 15 deltas, so a read
  of the oldest version applies at most 15. A delta is kept only when it
  is under half the object it replaces, and never against a base whose own
  chain leads back to it.

## One writer at a time

A save's snapshot, a sync's pin, the upkeep's compaction and a move read a
log, decide, and write it, from isolates that share nothing. Each runs
holding the note's lock (`history_lock.dart`, `history_lock_file.dart`):

- **Flat, apart from the notes.** `.history/.locks/<sha256 of the path in
  lower case>.lock`. A release has no folder of the note's to tidy (a
  listing of a folder of 30k logs on every save is a round trip each on
  Android), and a case-only rename, whose two names are one file on
  Windows and Android, asks for one lock and not two. Folding the case
  makes two notes that differ by case alone take turns on Linux, which is
  harmless.
- **Owned.** The file holds its holder's token and a release deletes it
  only while it still does: a holder whose lock was broken as stale must
  not delete the next holder's.
- **Broken once.** A lock older than 30 s is a crash's leftover. Breaking
  it holds a `.break` guard created exclusively and looks at the lock
  again once held, so two waiters that saw it stale do not take turns
  deleting each other's fresh lock.
- **Waiting is for a lock that is there.** Only "already exists" waits (up
  to 10 s, then `HistoryLockTimeout`). A store that cannot hold a lock
  (read-only, full, a path in the way) raises at once, so a save does not
  pay 10 s a snapshot for it. Windows alone is given half a second for
  the refusal that follows a delete still pending.
- **Reads take none.** A note with no log and no old history reads as
  empty without a lock.

## What is flushed, and why that is safe

On a save's path, nothing is flushed. The note itself still is, before its
rename: that part of the save is unchanged. Its history is not.

- An object is trusted only when what it rebuilds hashes to its name. One
  a crash cut short — truncated, empty, a rename that landed before its
  data — reads as a missing version. A version whose file drifted always
  read that way (#378): it is not listed as content, never returned as
  content, and never pinned as a sync base, so sync treats the path as a
  conflict rather than merging on a wrong base.
- A log line a crash cut short does not decode and is skipped. Every
  append starts on a new line, so a torn line never takes the next one
  with it.
- When a save finds the note unchanged since its newest version, it writes
  that version's object again if the object no longer reads. The note
  holds exactly that content, so a damaged newest version repairs itself.

The cost of all this: a crash can lose the newest entry of a note's
history. It cannot lose the note.

## The upkeep

`history_upkeep.dart`, off every save's path, does what `git gc` does:

- **Pack** each note's history: older versions become deltas, and the
  newest is compressed hard. `NoteHistory` packs a note 30 s after its
  last kept version, so an editing session's versions pack once.
- **Collect** the objects no log names, directly or as a delta's base, and
  older than an hour. Rotation and deletes write only the log. The hour is
  there because a snapshot writes its object before its log line, and the
  collection could otherwise list the logs between the two. An object
  named again — a snapshot of content kept before, a delta's new base —
  has its modification time refreshed for the same reason.
- **Move in** the history kept the old way.
- **Compact** the logs that grew.

The whole pass runs once each time a library opens, after the ready state
and beside the stale-temp sweep.

## The history kept before

`history_legacy.dart` reads `<path>.v<n>` and `<path>.json` as the old
store did, and moves a note's history in the first time it is touched; the
upkeep moves in what is left.

- **Order.** The objects go first, then the log (written whole and
  flushed), and the old files only once the log is there. A log on disk
  therefore means the move finished, and old files beside it are leftovers
  to delete.
- **Drift.** A version whose file no longer hashes to its manifest's
  sha256 stays out, as it always read as missing.
- **No manifest.** A file the manifest did not describe comes in as an
  `unknown` version, as it always read.
- **Delete.** Deleting an old history deletes it as it lies, without
  moving it in first.

One behavior is gone: a lost manifest used to be rebuilt from the version
files. A lost log is not rebuilt, because an object does not know which
note it belongs to. The log is append-only and rewritten only atomically,
so it is far harder to lose than a manifest that every snapshot rewrote.

## Measured

`test/perf/history_snapshot_test.dart` runs twenty editing sessions, each
inserting one paragraph into a note of prose-like text. Reference host,
JIT:

| | 10 KB note | 1.5 MB note |
|---|---:|---:|
| snapshot median, before | 4.0 ms | 19.4 ms |
| snapshot median, after | 1.0 ms | 26 ms |
| twenty versions on disk, before | 100 % of the copies | 100 % (30 MB) |
| after, unpacked | 28.6 % | 24.2 % |
| after, packed | 4.4 % | 2.1 % (650 KB) |
| the oldest version read back, packed | 1 ms | 19 ms |

- **The 1.5 MB snapshot on this host.** It reads, hashes and compresses
  the note, and its object takes 11 ms of the 26: zlib's fast level (7 ms
  for 1.5 MB of prose, against 62 ms at the default level). The old store
  copied it with no compression, and this host's NVMe flushes in well
  under a millisecond, which is why its 19.4 ms looks cheap here.
- **On the tablet.** The old store's time there was the flushes, which
  this host cannot reproduce: #1145's device run measures both stores
  from the `snapshot` line, which now reads `(object N, log M)`.
- **The bars.** Under `NIMAN_PERF` the test holds a snapshot's median
  (5 ms / 50 ms) and the packed share (10 % / 5 %).
