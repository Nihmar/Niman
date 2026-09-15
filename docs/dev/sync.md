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

`sync_destinations` (schema v22), one row per library:

| Column | Type | Notes |
|---|---|---|
| `library_path` | text, PK | absolute, normalized, like `known_libraries.path` |
| `url` | text | the remote folder the library maps to, e.g. `http://nas:8080/webdav/Notes/` (always stored with a trailing `/`) |
| `username` | text | empty for no auth |
| `enabled` | bool | off stops every trigger; rows and state stay |
| `auto_sync` | bool, default true | on-change, resume and periodic triggers |
| `interval_seconds` | int, default 60 | periodic trigger while the app is open; 0 = off |
| `wifi_only` | bool, default false | automatic triggers skip mobile data |
| `capabilities` | text (JSON) | the probe result, see below; `{}` = never probed |
| `last_sync_at_ms` | int, nullable | last full reconcile that ended without errors |
| `last_error` | text, nullable | short, user-readable, never a secret |

One URL rather than server + folder: servers disagree on where the
WebDAV root lives, and the user copies the address the server shows.
The password lives only in `flutter_secure_storage`; forgetting a
library deletes the row, its `sync_items`, its `sync_ops` and the
secret.

### State: `sync_items`

One row per synced path, per library: local `sha256`, `size`, `mtime`;
remote `etag`, `size`, `mtime`, `fileid` (when the server has one); the
history version pinned as base; `syncedAt`. It records what both sides
agreed on at the last success, which is what tells "deleted here" from
"created there". It lives in `AppDatabase` (schema v22) because the
index database is dropped on every schema bump, and losing it would make
every file look new on both sides.

| Column | Type | Notes |
|---|---|---|
| `library_path` | text | PK part 1 |
| `path` | text | PK part 2; library-relative, `/`-separated, files only |
| `local_sha256` | text | content both sides agreed on |
| `local_size` | int | |
| `local_mtime_ms` | int | disk mtime right after the sync wrote or read it |
| `remote_etag` | text, nullable | null when the server has no ETags |
| `remote_size` | int | |
| `remote_mtime_ms` | int | `getlastmodified` (second resolution) |
| `remote_file_id` | text, nullable | `oc:fileid` when offered |
| `base_version` | int, nullable | the `.history` version pinned as `syncBase`; null for attachments and when history is off |
| `synced_at_ms` | int | |

Folders get no rows: a folder exists remotely when a file under it
does, and MKCOL is idempotent enough (405 = already there). Local
change detection is cheap: `size` + `mtime` against the row, sha256
only when either differs (a touch without an edit uploads nothing).

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

#### The probe

"Test connection" runs it, and a sync re-runs it when the stored result
is older than 30 days or a request contradicts it (an `If-Match` PUT
that should have failed and did not). It works in a scratch folder
`.niman-probe-<random>/` under the destination and deletes it at the
end, even on failure:

1. `OPTIONS` on the URL: `DAV:` header present (class 1 required),
   `Allow` lists `PROPFIND`, `PUT`, `MKCOL`, `DELETE` (`MOVE` noted).
   401 → wrong credentials; no `DAV:` → "not a WebDAV folder".
2. `MKCOL` the scratch folder, `PUT a.txt`, `PROPFIND Depth: 1` on the
   folder asking for `getetag`, `getcontentlength`, `getlastmodified`,
   `resourcetype`, `oc:fileid`, `oc:checksums`.
3. **file ETags**: `a.txt` carries a `getetag`, and a second `PUT` with
   different content changes it.
4. **collection ETags**: the folder's `getetag` changed after that
   second PUT.
5. **`If-Match`**: `PUT a.txt` with `If-Match: "niman-wrong"` → must
   answer 412 and leave the content alone (checked with a GET).
   **`If-None-Match: *`**: `PUT a.txt` with it → must answer 412.
6. **`MOVE`** `a.txt` → `b.txt` with `Overwrite: F`: 201/204 and the
   PROPFIND shows `b.txt` only.
7. **`X-OC-Mtime`**: a PUT with it returns `X-OC-MTime: accepted`.
8. `DELETE` the scratch folder.

The result is stored as JSON with a `probedAt` time, and each missing
capability is logged with the fallback it selects. A server that fails
step 1 or 2 cannot be used; everything after that only turns
optimizations off.

**Compatible mode without ETags.** `getlastmodified` has a one-second
resolution, so two writes of the same size within a second look equal.
The row keeps `remote_mtime_ms` and `synced_at_ms`; when the remote
mtime is within 2 s of `synced_at_ms` the item is "doubtful" and the
next reconcile GETs it and compares sha256 instead of trusting size +
mtime. A clean result clears the doubt (the row's `synced_at_ms` moves
on).

### The client (`lib/src/sync/webdav/`)

`dart:io` `HttpClient`, no WebDAV package. The `xml` package (already
in the lock file through other packages) becomes a direct dependency
for multistatus parsing: servers pick their own namespace prefixes
(`D:`, `d:`, `lp1:`), which a hand parser gets wrong. The client:

- takes a base URL, user and password; Basic auth sent preemptively
  (no challenge round trip per request), never logged;
- speaks `PROPFIND` (Depth 0/1), `GET`, `PUT`, `MKCOL`, `DELETE`,
  `MOVE`, `OPTIONS`; paths are library-relative and percent-encoded per
  segment; hrefs in responses are decoded and made relative to the
  base, whatever mix of absolute URL / absolute path the server uses;
- streams both ways: `PUT` from a file stream with `Content-Length`,
  `GET` into a sink with sha256 computed in flight, never a whole file
  in memory;
- follows 301/302/307/308 itself (at most 5), keeping method, body and
  auth only while the host stays the same;
- maps statuses to typed failures: `WebDavAuthFailure` (401/403),
  `WebDavNotFound` (404/409 on a missing parent), `WebDavPrecondition`
  (412), `WebDavRetryable` (429/502/503/504/423 and socket errors,
  carrying `Retry-After`), `WebDavProtocolFailure` (anything else);
- logs one line per request under `webdav`: verb, relative path, status,
  ETag (short), bytes, ms, attempt.

It knows nothing about libraries, the database or Flutter, so it runs in
any isolate and is tested against an in-process fake server
(`test/fakes/fake_webdav_server.dart`, `HttpServer` on loopback) whose
switches turn ETags, collection ETags, `If-Match`, `MOVE`, auth,
redirects and injected failures on and off.

### Queue and triggers

`sync_ops` in `AppDatabase` persists across restarts; ops on the same
path coalesce (ten saves = one upload). Exponential backoff 5 s → 10 m,
immediate retry when the network returns. Triggers: manual, app resume,
5 s after the last edit, periodic (default every minute, only while the
app is open), optionally not on mobile data.

The queue holds **hints, not commands**: what `NoteOps` saw happen to
a path. The reconcile decides the action from disk, remote and the row,
so a stale or lost op can make a sync slower but never wrong.

| Column | Type | Notes |
|---|---|---|
| `id` | int, autoincrement | |
| `library_path` | text | |
| `path` | text | unique with `library_path`: a new hint replaces the old |
| `kind` | text | `changed`, `deleted`, `moved` |
| `from_path` | text, nullable | `moved` only: lets the sync issue a `MOVE` instead of DELETE + PUT |
| `attempts` | int | failed runs so far |
| `next_attempt_at_ms` | int | backoff: 5 s · 2^attempts, capped at 10 min |
| `last_error` | text, nullable | |
| `created_at_ms` | int | |

- **Quick sync** (the 5 s after-edit trigger) handles only the queued
  paths: a PROPFIND `Depth: 0` per path, then the table above.
- **Full sync** (manual, resume, periodic) walks the remote tree
  (skipping folders whose collection ETag is unchanged when the server
  has them) and the local tree, reconciles every path, then drops the
  ops it covered.
- An op is removed when its path reconciles cleanly; a failure bumps
  `attempts` and `next_attempt_at_ms`. 401/403 stops the run and marks
  the destination (`last_error`) instead of backing off forever.

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
5. Sync, one PR per step:
   1. WebDAV client + fake server + probe (#10, part of #20).
   2. Schema v22: `sync_destinations`, `sync_items`, `sync_ops` +
      secure password store (#12, #19 storage).
   3. Reconcile as a pure function over (local, remote, row) → action,
      unit-tested on every row of the table (#12).
   4. Engine: upload with MKCOL propagation, download with `sync`
      snapshot + temp + rename + hash, delete / trash, pin move (#14,
      #15, #16).
   5. Configuration UI + Test connection + status (#11, part of #28),
      strings in every locale, user docs.
   6. Queue hints from `NoteOps`, triggers, backoff (#18, #19).
   7. Conflicts: automatic non-overlapping merge + `DiffView` merge mode
      (#17, #67).
   8. End-to-end tests (#20).
