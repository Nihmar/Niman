# M5 — Sync

**Status:** Planned · **Depends on:** M4 · **Spec:** *Requirements* (sync,
conflicts, history), *Sync state machine*, *Milestones → M5*

## Purpose

WebDAV sync of the whole library to one destination: manual + automatic
triggers, upload/download/delete propagation, conflict handling with a
hunk-level 3-way merge UI, `.history/` versioning (the merge base), and
offline resilience with a persisted queue.

## Current state

M4 is local-only; `.trash/` and `.history/` exist on disk but have no version
history yet.

## Tasks

- [ ] **T-M5-01** WebDAV client on `dart:io` HttpClient (zero deps):
  PROPFIND (depth 1), GET, PUT, MKCOL; ETag + If-Match; Basic auth;
  `http://` and `https://`; streaming transfers (chunked, no full-file in
  memory) with hash computed in flight. *AC: protocol tests against the mock
  server cover each verb + auth + redirect behavior.*
- [ ] **T-M5-02** Destination settings UI (URL, user, password); credentials
  in `flutter_secure_storage`; connection test action. *AC: no secret ever
  written to drift or logs.*
- [ ] **T-M5-03** `sync_items` tracking (design.md): per-path
  (sha256, size, modified, etag); reconcile per the state machine on every
  trigger. *AC: reconcile unit tests cover every branch (upload/download/
  conflict/delete/skip).*
- [ ] **T-M5-04** `.history/` versioning: on every note save keep the last N
  versions (library setting, default 10) as `.history/<path>.v<n>`; excluded
  from index, watcher, and sync. *AC: N+1 saves → exactly N versions; merge
  base retrievable.*
- [ ] **T-M5-05** Upload path: MKCOL parent propagation, then PUT with
  `If-Match` when the remote item exists; success updates `sync_items`.
  *AC: new folders + notes + modified notes all land remotely (mock server
  assertions).*
- [ ] **T-M5-06** Download path: ETag-compare, GET → `.tmp` → atomic rename;
  size/hash verified after transfer. *AC: corrupt-transfer test rejects and
  retries.*
- [ ] **T-M5-07** Delete propagation: local delete (hard) or empty-trash →
  remote delete (tombstone ops in the queue). *AC: remote tree matches local
  after sync.*
- [ ] **T-M5-08** Conflict path: PUT 412 → re-fetch remote → 3-way merge
  (base = `.history` version at last sync) → conflict UI: hunk-level
  mine/theirs per hunk, or keep whole file; result written locally and
  re-queued. *AC: mock-server scenario drives the dialog end-to-end; both
  hunk and whole-file resolutions tested.*
- [ ] **T-M5-09** Triggers: manual button; automatic on app focus, on-change
  (debounced), and ~60 s poll (reusing the M1 rescan cadence). *AC: each
  trigger demonstrably starts a reconcile.*
- [ ] **T-M5-10** Offline: queue persists across restart; retry with
  exponential backoff; UI shows queued-op status. *AC: kill server mid-sync →
  resume cleanly on reconnect.*
- [ ] **T-M5-11** Tests: mock WebDAV suite (round trip, ETag, 412, offline) +
  integration_test E2E (open → edit → sync → conflict). *AC: green in CI;
  E2E on a device.*

## Technical design

See [design.md](design.md) → *Sync architecture (WebDAV)* and *Data model
(drift)* (`sync_items`, `sync_ops`). M5 slice:

- **Modules:** `sync/` (webdav, machine, merge, config),
  `ui/settings/sync.dart`, `ui/conflict_dialog.dart`.
- **State machine:** triggers → RECONCILE → persisted QUEUE (upload /
  download / delete / conflict), drained sequentially; `.trash`/`.history`
  excluded from all sync ops.
- **Merge algorithm:** line-based 3-way diff (base vs mine vs theirs);
  conflicts grouped into hunks; user resolves per hunk or whole file; result
  re-hashes and re-queues.
- **Streaming:** 64 KB chunks; sha256 accumulated during transfer; temp file
  renamed atomically on success.
- **Security:** Basic auth + TLS as specified; Nextcloud E2EE is explicitly
  out of scope (separate protocol).

## Exit criteria

- A real WebDAV server (or the mock in CI) round-trips the whole library:
  notes, folders, renames, deletes.
- A real 412 conflict produces the merge UI; both resolution styles work.
- Offline disconnect/reconnect resumes without data loss.
- `.history/` keeps N versions and serves as merge base.
- Unit + mock-server + integration tests green.

## Risks / open questions

- WebDAV server quirks: ETag stability, PROPFIND depth handling, MKCOL-on
  conflict — mock server mirrors Nextcloud/ownCloud behavior for these paths.
- Clock skew / mtime vs hash: hash-first comparison, mtime only as shortcut.
- Large-file transfer interruptions: resumability is M6 polish; M5 retries
  whole files (atomic temp writes prevent partial-state).
- `.history` retention of *other devices'* versions: history is local-only per
  spec — cross-device merge bases rely on the oldest local version; acceptable
  per v1 scope (multi-device simultaneous editing out of scope).
