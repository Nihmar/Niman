# Note history and WebDAV sync — design

Decisions for M5 (#9) and the history it rests on (#13, #55, #67),
settled before the code. History ships first; sync builds on it.

## Principles

- **Disk stays the source of truth.** History lives in the library
  folder (`.history/`), so it survives an index rebuild and a folder
  copy. Sync state is the one exception: it is per device, cannot be
  rebuilt from disk, and lives in `AppDatabase`.
- **The editor writes through `NoteOps`.** `NoteOps.saveNote`
  (`NoteWriter`) writes atomically, takes the history snapshot in the
  same isolate pass, updates the index and (later) marks the file dirty
  for sync. Replace runs its own isolate chunks and calls the same
  snapshot routine with reason `replace`. The Android widget writes from
  a background isolate and stays outside; the periodic rescan and the
  sync reconcile catch it. `NoteOps` makes things *fast*; correctness never depends on it,
  because anything can edit the folder.
- **No global write queue for saves.** `NoteOps` serializes structural
  ops (create, rename, move, delete, trash) on one chain; saves take a
  per-path lock instead, so emptying a large trash never delays typing.
- **Log everything.** Logger names `history`, `sync`, `webdav`. Every
  snapshot taken or skipped (with the reason), rotation, pin move,
  restore, reconcile decision, HTTP request (verb, path, status, ETag,
  bytes, ms), retry and conflict is a log line. Never passwords,
  `Authorization` headers or note text — paths, sizes, short hashes and
  counts only.

## History

### Layout

```
.history/
  Projects/
    Plan.md.v12        full snapshot, byte-for-byte
    Plan.md.v14
    Plan.md.json       manifest for Plan.md
```

- `.history/<library-relative path>.v<n>`: a full copy of the note. `n`
  grows forever and is never reused, so a version number is a stable id
  (the sync base points at one).
- `.history/<path>.json`: the note's manifest —
  `{"versions": [{"v": 14, "savedAt": <ms>, "reason": "session",
  "size": 5120, "sha256": "…"}], "pinned": {"syncBase": 12}}`.
  Read tolerantly like the trash manifest: a corrupt file is rebuilt
  from the `.v<n>` files present (mtime as `savedAt`, reason unknown);
  entries whose file is gone are dropped on the next write.
- `.history/` is a dot folder: the indexer, the templates and the tree
  already ignore it. Sync never uploads it.
- Text notes only (what the editor saves: `.md`, `.txt`); attachments
  get no history.

### What a version is

A version is **the content on disk before a save replaced it** — never
the text being written. The newest text is always the note itself
("Current version" in the list), so it never shows twice.

When a save arrives for a note, a snapshot of the old content is taken
when any of these holds:

| Reason (`reason`) | When |
|---|---|
| `session` | first save since the note was opened (the state it had when you started editing) |
| `interval` | the newest version is older than `historyIntervalMinutes` (default 5) |
| `restore` | right before a restore overwrites the note |
| `sync` | right before sync overwrites the note with a download or merge result |
| `replace` | right before a library-wide replace rewrites the note |
| `unknown` | a `.v<n>` file the manifest did not describe, read back on rebuild |

A snapshot is skipped — and logged as skipped — when the old content's
sha256 equals the newest version's (nothing to keep), when the note did
not exist yet, or when `historyVersions` is 0 and no pin needs it.

Autosave runs every ~500 ms while typing, so without this rule ten
versions would last five seconds.

### Rotation and the pinned base

- Keep the newest `historyVersions` versions (0–100, default 10).
- Pinned versions never count against the limit and are never rotated
  out. The only pin today is `syncBase`: the content both sides agreed on
  at the last successful sync of that note, the base of the 3-way merge.
  Moving the pin to a new version releases the old one to normal
  rotation.
- Rotation runs after each snapshot and deletes the oldest unpinned
  versions beyond the limit (file first, then manifest).

### Settings (`.niman/settings.json`, per library)

| Key | Range | Default |
|---|---|---|
| `historyVersions` (exists) | 0–100 | 10 |
| `historyIntervalMinutes` (new) | 1–60, offered as 1, 2, 5, 10, 15, 30, 60 | 5 |

Out-of-range values in a hand-edited file read back as the default,
like `historyVersions` does today.

### Following the note

| Operation | History |
|---|---|
| rename / move note | `.v*` files and manifest move with it |
| rename / move folder | the matching `.history/<folder>` subtree moves |
| delete into trash | history stays at the original path |
| restore from trash | back at the original path: nothing to do; restored elsewhere (collision, parent gone): history moves to the new path |
| delete permanently / empty trash | history of the original path is removed when no note lives there again |
| hard delete (trash off) | history removed with the note |

Snapshots, rotation and moves run off the UI isolate (`Isolate.run`,
top-level entry points).

### UI (mockups H1–H7)

- Tree context menu and the note's new ⋮ menu (History, Rename, Move,
  Delete) open **History**: versions grouped by day, with time, reason
  label, `+added −removed` lines against the previous version, the
  pinned sync base marked.
- A version opens in `DiffView` (`rollback` mode) against the current
  note, with a toggle to read the version's full text.
- Restore asks once, snapshots the current text (`restore`), writes the
  version through `NoteOps`, and offers Undo.
- Settings → Library gains the two rows above.

### DiffView (#67)

One widget, three modes: `readonly`, `rollback` (history), `merge`
(sync conflicts, later). Input is full texts — `left`, `right`,
optional `base`. The line diff is Myers O(ND) in pure Dart, computed in
an isolate; unchanged runs fold. Desktop renders side by side, mobile
inline.

## WebDAV sync (after history)

### Configuration

Per library, on the device: a `sync_destinations` table in
`AppDatabase` keyed by library path (URL, remote folder, user, trigger
options, detected capabilities). The password lives in
`flutter_secure_storage` under `sync.<library path>`. Not in
`.niman/settings.json`: the same server can have different URLs per
device, and a copied folder must not start syncing into the original's
remote with a separate state.

`http://` is allowed (VPN, LAN) with an informational warning.

### State: `sync_items`

One row per synced path, per library: local `sha256`, `size`, `mtime`;
remote `etag`, `size`, `mtime`, `fileid` (when the server has one); the
history version pinned as base; `syncedAt`. It records what both sides
agreed on at the last success, which is what tells "deleted here" from
"created there". It lives in `AppDatabase` (schema v22) because the
index database is dropped on every schema bump, and losing it would make
every file look new on both sides.

Reconcile compares disk now and remote now against the row:

| Local vs row | Remote vs row | Action |
|---|---|---|
| same | same | nothing |
| changed | same | upload |
| same | changed | download (`sync` snapshot first) |
| changed | changed | conflict: 3-way merge on the pinned base, else 2-way |
| deleted | same | delete remote |
| same | deleted | move the local file to `.trash/` |
| deleted | changed | download again (the edit wins) |
| new (no row) | absent | upload |
| absent | new (no row) | download |
| new | new | same sha: record only; different: 2-way conflict |

The first sync (empty table) compares by content only and **never
deletes** on either side; it shows a summary before it starts.

Moving a note to the trash deletes it remotely; other devices then move
their copy into their own trash. `.trash/` and `.history/` never sync.

### Server capabilities

Probed on "Test connection" and stored; every optimization has a
fallback, because the target includes plain servers (the OpenMediaVault
WebDAV plugin over a VPN).

| Capability | Used for | Fallback ("compatible mode") |
|---|---|---|
| collection ETags that change with the subtree | skip unchanged folders | PROPFIND `Depth: 1` per folder, compare size + mtime |
| file ETags | change detection, `If-Match` | size + mtime, then hash on doubt |
| `If-Match` / `If-None-Match: *` honored | lost-update protection | PROPFIND the item right before writing |
| `MOVE` | renames without re-upload | DELETE + PUT |
| `oc:fileid` | detect remote renames | treat as delete + create |
| `oc:checksums` | verify downloads without hashing twice | sha256 computed while streaming |
| `X-OC-Mtime` | keep mtime | record the server's mtime |

Also: explicit PROPFIND properties (no `allprop`), reused connections,
3–4 parallel transfers, `Retry-After` on 429/503, backoff on 423,
redirects that keep the method, download to a temp file then atomic
rename after the size/hash check. No `LOCK`.

### Queue and triggers

`sync_ops` in `AppDatabase` persists across restarts; ops on the same
path coalesce (ten saves = one upload). Exponential backoff 5 s → 10 m,
immediate retry when the network returns. Triggers: manual, app resume,
5 s after the last edit, periodic (default every minute, only while the
app is open), optionally not on mobile data.

### Conflicts

`PUT` answering 412 (or the pre-write check finding a newer remote)
re-fetches, merges non-overlapping hunks automatically and opens
`DiffView` in `merge` mode for the rest: per hunk mine / theirs / both,
or keep a whole side. The result is saved through `NoteOps` and queued.

## Order of work

1. History: `NoteOps.saveNote` + per-path lock, callers moved over.
2. History store: snapshot policy, manifest, rotation, pins, following
   renames/moves/trash; settings key.
3. Line diff + `DiffView` (readonly, rollback).
4. History UI (H1–H7), strings in every locale, user docs.
5. Sync: WebDAV client + mock server, then `sync_items` and reconcile,
   configuration UI, upload/download/delete, queue, triggers, conflicts,
   end-to-end tests.
