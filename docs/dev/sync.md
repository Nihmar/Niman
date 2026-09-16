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
The password lives only in `flutter_secure_storage`
(`SecureSyncSecretStore`, key `sync.<library path>`); forgetting a
library deletes the row, its `sync_items`, its `sync_ops` and the
secret (a keychain failure is logged and does not block forgetting).

Saving the destination with another URL or user clears the library's
`sync_items` and capabilities: they describe a different remote, so the
next sync is a first sync, which never deletes. The queue stays, since
it describes the local side.

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
| `remote_unverified` | bool | the listing could not rule out a same-second rewrite (no ETags, mtime = the server's current second): the next reconcile hashes the remote |
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
| changed | deleted | upload again (the edit wins) |
| deleted | deleted | drop the row |
| new (no row) | absent | upload |
| absent | new (no row) | download |
| new | new | same sha: record only; different: 2-way conflict |

The first sync (empty table) compares by content only and **never
deletes** on either side; it shows a summary before it starts.

#### Reconcile (`lib/src/sync/reconcile.dart`)

Pure functions, no I/O and no clock, one unit test per row above:

- **Local verdict:** size + mtime equal to the row → unchanged without
  reading the file; otherwise the sha256 decides. A new file needs its
  hash too (the upload records it, move pairing uses it).
- **Remote verdict:** with file ETags (probed) on both the row and the
  listing, the ETag decides. Otherwise size + `getlastmodified`, except
  when they cannot rule out a same-second rewrite (`remote_unverified`,
  or a server that sends no mtime or size): then the downloaded
  content's sha256 decides.
- A side that needs a hash comes back as `hashLocal` / `hashRemote`; the
  engine hashes and plans again until nothing waits for one.
- Two more outcomes: `record` (content agrees but the row is stale —
  a touched file, a cleared doubt) and the table's actions carry their
  write guards: `If-Match` with the remote ETag, `If-None-Match: *` for
  a path that should not exist, or `checkRemoteFirst` when the server
  honors neither.
- **Renames:** a `deleteRemote` of A and an `upload` of a new B with A's
  agreed content (unique on both sides) become one `moveRemote` when the
  server has `MOVE`; a `trashLocal` of A and a `download` of a new B with
  A's `oc:fileid` become one `moveLocal`.
- **Mass-deletion guard:** a plan that would delete or trash more than
  10 files and more than half of the synced rows is more likely a wrong
  URL, an unmounted share or an emptied folder. The engine stops and asks
  before carrying it out.

**What syncs:** every file except dot entries (`.trash/`, `.history/`,
temp files, a user's `.git/`) and `Thumbs.db` / `desktop.ini` — with two
exceptions inside `.niman/`: `settings.json` and `counters.json`, which
belong on every device. Folders get no rows (see above).

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

1. `OPTIONS` on the URL: records the `DAV:` classes. 401 → wrong
   credentials. When `OPTIONS` is refused or advertises no class 1
   (some proxies eat it), a `PROPFIND Depth: 0` on the folder decides:
   207 → usable, anything else → "not a WebDAV folder".
2. `MKCOL` the scratch folder and `sub/` in it (refused → unusable),
   `PUT sub/a.txt`, `PROPFIND Depth: 0` on the scratch folder and on
   the file, asking for `getetag`, `getcontentlength`,
   `getlastmodified`, `resourcetype`, `oc:fileid`, `oc:checksums`.
3. **file ETags**: the file carries a `getetag`, and a second `PUT`
   with different content changes it.
4. **collection ETags**: the scratch folder's `getetag` changed after
   that second PUT — two levels up, with no entry added, so a server
   whose folder ETag is only the directory mtime does not pass.
5. **`If-Match`**: `PUT` with `If-Match: "niman-wrong"` must answer
   412. **`If-None-Match: *`**: `PUT` onto the existing file with it
   must answer 412.
6. **`X-OC-Mtime`**: a PUT with it returns `X-OC-MTime: accepted`, or
   the next PROPFIND shows that mtime.
7. **`MOVE`** `a.txt` → `b.txt` with `Overwrite: F`: 201/204 and a
   PROPFIND finds `b.txt` and no `a.txt`.
8. `DELETE` the scratch folder (in a `finally`).

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
  (412), `WebDavRetryable` (408/423/425/429/500/502/503/504 and socket
  errors, carrying `Retry-After`), `WebDavUnsupported` (no `DAV:`
  header, a needed verb refused), `WebDavProtocolFailure` (anything
  else);
- logs one line per request under `webdav`: verb, relative path, status,
  ETag (short), bytes, ms. It makes one attempt per call (plus
  redirects); retries and backoff belong to the queue, which logs them.

It knows nothing about libraries, the database or Flutter, so it runs in
any isolate and is tested against an in-process fake server
(`test/fakes/fake_webdav_server.dart`, `HttpServer` on loopback) whose
switches turn ETags, collection ETags, `If-Match`, `MOVE`, auth,
redirects and injected failures on and off.

### The engine (`lib/src/sync/sync_engine.dart`)

`SyncEngine.run` does one full sync of a library; a second call while
one runs joins it.

1. **Destination:** row, password (a user without a stored password
   stops the run), client. Capabilities come from the store; missing or
   older than 30 days, the probe runs and stores them.
2. **Scan:** the local tree off the UI isolate (size + mtime, dot
   folders skipped except `.niman`), the remote tree with `Depth: 1` per
   folder. A missing remote folder stops the run — it never reads as an
   empty one.
3. **Plan:** `planSync`, then up to three hashing passes (local files
   hashed streamed in an isolate; remote ones downloaded to a discarding
   sink) until nothing waits for a hash.
4. **Confirm:** a first sync (no rows, never synced) and a plan that
   looks like a mass deletion go through the caller's `confirm`. Without
   one, a first sync goes ahead — it cannot delete — and a mass deletion
   is refused.
5. **Apply**, one decision at a time. Before touching a side, the engine
   checks it still is what the scan saw (local size + mtime; the remote
   with a PROPFIND when the decision has no precondition): a path that
   moved meanwhile is skipped and decided again next run.
   - *upload*: missing remote folders are created (once per run), `PUT`
     streamed from disk with `If-Match` / `If-None-Match` and
     `X-OC-Mtime`, then a `PROPFIND Depth: 0` for the metadata to record.
   - *download*: `GET` into `.<name>.niman-tmp-sync-<µs>` next to the
     target, size checked against the listing (unless the ETag says the
     file was rewritten since), then `NoteOps.syncReplace`: in the note's
     save order, the replaced text becomes a `sync` version, the temp
     file is renamed over, the index follows. Replacing
     `.niman/settings.json` reloads the settings.
   - *deleteRemote*: `DELETE` with `If-Match`. *trashLocal*:
     `NoteOps.syncTrash`, which uses `.trash/` whatever the trash toggle.
   - *moveRemote*: `MOVE`, then the row moves; a server that turns out
     not to support it gets `move: false` stored. *moveLocal*:
     `NoteOps.syncMove`, history included.
   - *conflict*: the remote is downloaded and hashed. Equal content is
     recorded. For `.niman/*.json` the newer side (local mtime vs remote
     `getlastmodified`) wins whole, since a line merge could break JSON.
     Anything else is left untouched on both sides and reported, with the
     pinned base, for the merge (step 7).
6. **Rows:** every success records local sha/size/mtime, remote ETag/
   size/mtime/file id, `remote_unverified` (no file ETags and the mtime
   within 2 s of the server's `Date`, never this device's clock), and —
   for notes — the pinned base: the newest history version with the
   agreed content, kept as a new `sync` version when none has it
   (`NoteHistory.pinSyncBase`).
7. **Errors:** 401/403 and a lost connection stop the run; any other
   failure fails that path only and the run goes on. The outcome goes to
   `sync_destinations.last_error` (cleared by a clean run) and comes back
   as a `SyncReport`: counts per action, conflicts, failures, skipped
   paths, or why it stopped.

A **quick** run (`run(quick: true)`, step 6) works on the due hints of
the queue only; see "Queue and triggers". Either kind settles the hints
it read and keeps the server's longest `Retry-After` on the report.

Not yet: parallel transfers, skipping unchanged folders by collection
ETag, pruning remote folders left empty.

### UI (`lib/src/ui/sync/`, mockups S1–S11)

`LibrarySyncService` (`lib/src/sync/sync_service.dart`) is what the UI
drives, exposed as `LibrarySession.sync` for every open library. It
holds a `SyncStatus` (destination, capabilities, running stage and
count, the session's last `SyncReport`), notifies on every change, and
streams the local paths a run or a resolution changed, so the shell
re-reads the open note.

- **Settings → Sync → WebDAV** (`SyncSettingsScreen`): unconfigured or
  editing, a form (one URL field, user, password) whose **Save** is
  enabled only for the exact fields a successful **Test connection**
  measured; a password left empty while editing keeps the stored one.
  Saving a destination that never synced starts the first sync.
  Configured, an overview: status, **Sync now**, edit, **Test the server
  again**, **Disconnect** (removes the rows and the password, touches no
  file).
- **Status icon** (`SyncStatusButton`) in the Files app bar (phone) and
  the tree footer (desktop), only with a destination: a tap syncs, or
  opens the panel when the last run left conflicts, failures or an
  abort; a long press always opens it. A progress strip sits under the
  tree while a run goes.
- **Panel** (`showSyncPanel`): the last result, conflicts with
  **Resolve**, failed paths, **Sync now** / **Try again**, and
  **Settings** (**Update password** after an authentication failure).
- **Conflicts** (`SyncConflictScreen`), whole-file for now:
  `SyncEngine.conflictTexts` feeds a read-only `DiffView` (server −,
  device +); **Keep this device's** uploads with `If-Match`, **Keep the
  server's** downloads with a `sync` snapshot. Both record the row and
  pin the base. Non-text files get the two buttons only. The hunk merge
  (step 7) replaces the diff in the same screen.
- `runSyncFromUi` saves open editors, answers the engine's `confirm`
  with the first-sync summary or the mass-deletion question, and shows a
  snackbar only when there is something to say (files trashed here,
  conflicts, an abort).

- **When to sync** (mockups T1, T2), in the overview above Server:
  **Automatically** (`auto_sync`), **Check the server every** 1 / 5 /
  15 / 30 min or Never (`interval_seconds` 60 / 300 / 900 / 1800 / 0),
  **Wi-Fi only** (`wifi_only`, phones only). `SyncService.setTriggers`
  stores them and re-arms the scheduler.
- **Queue** (mockups T4–T6): `SyncStatus` carries `pendingHints`,
  `nextRetryAt`, `autoPaused`, `waitingForNetwork`, `network` and
  `background`. The overview card and the panel show "N changes waiting
  · retrying in 40 s" (the panel counts down), and a hint: how a pause
  ends, that the queue survives an outage, or that Sync now uses mobile
  data. An automatic run shows no progress strip; the icon turns, and
  reads `cloud_queue` while changes wait.

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
| `next_attempt_at_ms` | int | after the n-th failure: 5 s · 2^(n−1), capped at 10 min |
| `last_error` | text, nullable | |
| `created_at_ms` | int | strictly increases on every rewrite of the hint |

Coalescing (`SyncStore.enqueue`), one hint per path:

| Queued | New | Result |
|---|---|---|
| `changed` / `deleted` | `changed` / `deleted` | the new kind |
| `moved` from A | `changed` | `moved` from A (content is checked at the target anyway) |
| `moved` from A | `deleted` | `deleted`, plus `deleted` at A unless A has its own hint |
| anything at B | `moved` B → C | the hint at B goes; `moved` from B, or from A when B's hint was `moved` from A (and `changed` when that brings it back to A) |
| hints under folder B | `moved` B → C | they move to C with it |

A rewrite keeps the backoff: edits during an outage do not bypass it,
the network coming back (`retryNow`) does. A sync removes a hint only
if `created_at_ms` is still the one it read, so a save that lands while
its path is syncing is never lost.

**Where hints come from.** `NoteOps` calls its `syncHints` sink after
every user operation's disk change: create, save (after the write, so a
sync that reads the hint sees the new text), append, pin, rename and
move (`moved`), delete (`deleted`), restore from history or trash, and
every write of `.niman/settings.json` (through
`LibraryConfigRepo.onWritten`). The sync's own `syncReplace`,
`syncTrash` and `syncMove` report nothing and remember their paths for
10 s. The file watcher adds what changed behind the ops (another app, a
widget isolate, a hand edit): `LibrarySyncService.watched` queues
`changed` for a path that exists and `deleted` for one that does not,
dropping dot folders and the echoes of sync writes. Hints are hints:
a duplicate costs a PROPFIND, a missed one waits for the next full sync.

- **Quick sync** (`SyncEngine.run(quick: true)`) reads the due hints and
  reconciles only their paths and move sources: the destination folder
  is checked first (`PROPFIND Depth: 0` on it: a missing one stops the
  run instead of reading as "every file is gone"), then one `PROPFIND
  Depth: 0` per path; a path that is a folder on either side (or has
  rows under it) is walked, locally and remotely. The mass-deletion
  guard still measures against every row. A quick sync is never a first
  sync, and leaves `trashLocal` and `moveLocal` to a full sync
  (`SyncReport.deferred`): a single 404 is not enough to trash a file.
- **Full sync** (manual, library opened, resume, periodic, after a quick
  sync that deferred something) walks both trees and reads every hint,
  due or backing off.
- **Settling** (both kinds): a hint is removed (`completeOp`, only if
  not rewritten meanwhile) when no path it covers — its path, its move
  source, anything under either — failed or changed during the run; a
  conflict settles it too (the report carries it). Otherwise `failOp`
  backs it off. A run that stopped backs every hint off; one that was
  not confirmed, had no destination or no password leaves them alone.

#### Triggers (`lib/src/sync/sync_scheduler.dart`)

`SyncScheduler`, one per open library, owned by `LibrarySyncService`
and started by `LibraryController` after `load()`:

| Trigger | Run | When |
|---|---|---|
| hint | quick | 5 s after the last one, at most 60 s after the first of a burst |
| app backgrounded (`paused`) | quick | right away, when something is due |
| library opened, app resumed | full | right away |
| periodic | full | every `interval_seconds` (0 = never); on phones only in the foreground |
| network back (offline → online, mobile → Wi-Fi) | full after a stopped run, else quick | after `retryNow` |
| quick sync deferred something | full | after it |
| manual (icon, panel, Sync now) | full | always; clears pause and backoff, `retryNow` |

Automatic runs are skipped (and logged) without a destination, with
`enabled` or `auto_sync` off, before the first sync, while paused, while
backing off, on a phone that is offline or on mobile data with
`wifi_only`, and — for a quick one — with nothing due. One run at a
time: a trigger during a run is remembered and served after it; hints
still due after a run arm the debounce again.

After a run: `offline` / `failed` back automatic runs off for
`syncBackoff(n)` or the server's `Retry-After` if longer, with a retry
timer; `authentication` / `missingPassword` pause them
(`SyncPause.authentication`), `remoteMissing` / `unsupported` too
(`server`), and a refused mass deletion (`confirmation`). A pause ends
with a manual run or a saved destination. Paths that failed back off
their hints and arm a quick retry.

The network comes from `NetworkMonitor` (`ConnectivityNetworkMonitor`
over `connectivity_plus`: Wi-Fi or Ethernet = unmetered, mobile, none =
offline, a VPN alone or no answer = unknown, which never blocks). Off
phones the network never blocks a run, since a desktop without a network
manager can read as offline; it only speeds up the retry.

Closing the library stops the triggers and waits up to 10 s for a run
going (`LibrarySyncService.close`), since it writes through the index
about to close.

### Conflicts

A path both sides changed differently goes through the three-way merge
(`lib/src/diff/three_way.dart`, issues #17 and #67) before it is called a
conflict:

- **The base** is the history version pinned as `syncBase` (the content
  of the last agreement). Without one — a file created on both devices,
  an attachment, a base that rotated away — nothing merges and the whole
  copies are the only choice.
- **`mergeThreeWay(base, local, remote)`** aligns each side with the base
  through `diffLines` and walks the base once, cutting it into regions:
  untouched, changed by one side, changed the same way by both (taken
  once), or **conflict**, which keeps all three sides. `MergeResult.text`
  builds the merged text with one `MergeChoice` per conflict (mine,
  theirs, both; mine by default) and keeps the local line endings and
  trailing break. It merges lines, not words: two edits on one line
  overlap.
- **The engine** merges during a run (`_tryMerge`, inside the `conflict`
  action): a clean merge is written with `NoteOps.syncMerge` (the
  replaced text becomes a `sync` version), uploaded with `If-Match`, and
  recorded — `SyncReport.merged` lists those paths and the editor
  re-reads them. A merge with overlaps changes nothing and reports the
  conflict, base included.
- **The screen** (`SyncConflictScreen` + `MergeView`) shows the merge
  region by region: what each side contributed is already in, and every
  overlap has a three-way segmented choice. **Save the merge** calls
  `SyncService.resolveMerged`, which writes the text here (again a `sync`
  version) and uploads it with `If-Match`. Keeping one whole copy stays
  one tap away, and is the only option without a base, where the screen
  falls back to the read-only `DiffView`.

### Tests (#20)

- **Units** over the fake server (`test/fakes/fake_webdav_server.dart`,
  an `HttpServer` on loopback with a switch per capability, per failure
  and per refusal): the client, the probe, the store and its queue, the
  pure reconcile, the pure merge, the engine (full and quick), the
  scheduler on fake time, and the service.
- **Scenarios** (`test/unit/sync_e2e_test.dart`): two devices with their
  own libraries and databases over one server, driven the way the app
  drives them — `NoteOps` writes, hints, triggers, engine, service. A
  day of edits (create, edit, rename, delete, trash on the other side),
  a merge and a conflict resolved by hand, a queue written offline that
  survives a restart, a server without ETags or preconditions, and a
  write the server refuses with 412.
- **On a device** (`integration_test/sync_e2e_test.dart`): the real app
  against a server in its own process — set the destination up from the
  settings screen, first sync, an edit that leaves by itself, then a
  conflict resolved in the merge screen. It needs a device: opening a
  real library uses isolates the headless runner does not give.

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
