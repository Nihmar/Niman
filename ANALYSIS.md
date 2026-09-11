# Copist — pending points

Everything still open, with full descriptions. Done items are not listed:
for history, read the git log. Requirements live in
[`Copist - spec & plan.md`](<Copist - spec & plan.md>) — the spec wins on
disagreement. (Replaces the former `plan/` folder, removed 2026-09-11.)

Chain position: everything through M4 is done and device-verified; M6 and
platform parity are in progress; M5 and the rest of M7 are planned. M5 is
not a prerequisite for M6. Verified 2026-09-11 against the live GitHub
issue tracker (open: #6, #7, #8; closed: #2, #3, #4, #5).

## M5 — Sync — Planned

Purpose: whole-library WebDAV sync to one destination — manual +
automatic triggers, upload/download/delete propagation, hunk-level 3-way
merge UI, `.history/` versioning as merge base, offline persisted queue.
Local-only today; `.trash/` + `.history/` exist without versions.

- [ ] **T-M5-01** WebDAV client on `dart:io` HttpClient (zero deps):
  PROPFIND (depth 1), GET, PUT, MKCOL; ETag + If-Match; Basic auth;
  `http://` and `https://`; streaming transfers (chunked, no full-file in
  memory) with hash computed in flight. *AC: protocol tests against the mock
  server cover each verb + auth + redirect behavior.*
- [ ] **T-M5-02** Destination settings UI (URL, user, password); credentials
  in `flutter_secure_storage`; connection test action. *AC: no secret ever
  written to drift or logs.*
- [ ] **T-M5-03** `sync_items` tracking: per-path (sha256, size, modified,
  etag) plus a pointer to the merge base — the `.history` version, or its
  digest, current at the last successful sync (without it T-M5-08 cannot
  find its base). Reconcile per the state machine on every trigger.
  *AC: reconcile unit tests cover every branch; the base pointer survives
  a restart.*
- [ ] **T-M5-04** `.history/` versioning: on every note save keep the last N
  versions (library setting, default 10) as `.history/<path>.v<n>`; excluded
  from index, watcher, and sync. *AC: N+1 saves → exactly N versions; merge
  base retrievable.*
- [ ] **T-M5-05** Upload path: MKCOL parent propagation, then PUT with
  `If-Match` when the remote item exists; success updates `sync_items`.
  *AC: new folders + notes + modified notes all land remotely.*
- [ ] **T-M5-06** Download path: ETag-compare, GET → `.tmp` → atomic rename;
  size/hash verified after transfer. *AC: corrupt-transfer test rejects and
  retries.*
- [ ] **T-M5-07** Delete propagation: local delete (hard) or empty-trash →
  remote delete (tombstone ops in the queue). *AC: remote tree matches local
  after sync.*
- [ ] **T-M5-08** Conflict path: PUT 412 → re-fetch remote → 3-way merge
  (base = the `.history` version the T-M5-03 pointer names; if retention
  rolled past it, fall back to two-way and say so in the UI) → conflict UI:
  hunk-level mine/theirs per hunk, or keep whole file; result written
  locally and re-queued. *AC: mock-server scenario drives the dialog
  end-to-end; both resolutions tested.* Multi-device simultaneous editing
  stays out of scope for v1.
- [ ] **T-M5-09** Triggers: manual button; automatic on app focus,
  on-change (debounced), ~60 s poll (reusing the M1 rescan cadence).
  *AC: each trigger demonstrably starts a reconcile.*
- [ ] **T-M5-10** Offline: queue persists across restart; exponential
  backoff; UI shows queued-op status. *AC: kill server mid-sync →
  resume cleanly on reconnect.*
- [ ] **T-M5-11** Tests: mock WebDAV suite (round trip, ETag, 412, offline)
  + integration_test E2E (open → edit → sync → conflict). *AC: green; E2E
  on a device.*
- Design: modules `sync/` (webdav, machine, merge, config) +
  `ui/settings/sync.dart` + `ui/conflict_dialog.dart`; triggers →
  RECONCILE → persisted QUEUE drained sequentially, `.trash`/`.history`
  excluded; line-based 3-way diff in hunks, result re-hashed + re-queued;
  64 KB streaming chunks, sha256 in flight, atomic rename; Basic + TLS
  (Nextcloud E2E out of scope).
- Exit: whole-library round-trip (notes, folders, renames, deletes); real
  412 → merge UI, both styles; offline resume lossless; N-version history
  as merge base; unit + mock + integration green.
- Risks: server quirks (ETag stability, PROPFIND depth, MKCOL conflicts —
  mock mirrors Nextcloud/ownCloud); hash-first compare (mtime shortcut
  only); whole-file retries (resumability = later polish; atomic temps
  prevent partial state); cross-device bases rely on oldest local version
  (history is local-only per spec); retention can roll past the base —
  pointer detects, T-M5-08 falls back; consider pinning the base until
  next successful sync. Encryption (T-M6-06) rewrites every file's bytes
  (full re-upload; merge works on text → decrypt first): cheapest =
  encryption fixed at library creation — decide in M6 onboarding.

## M6 — Scale & polish — In progress (themes + text size done, rest open)

Purpose: 1M-note gate, multi-tab, import/export, per-file encryption +
onboarding, polish. Not gated on M5 (only constraint: an encrypted
library needs its key before its first upload — an M5 constraint).

- [ ] **T-M6-11** First-index experience at scale: first open still
  blocks behind a spinner (minutes at 1M). Index in background with
  progress + browsable partial tree; user works while it fills. *AC: 1M
  library usable before first scan finishes.* Also owns memory: `fullScan`
  loads every row into a map + walk into a list (9 s, ~1 GB at 1M — an
  OOM kill on a phone, and it runs on the periodic rescan too). Fix =
  reconcile a directory at a time. `index_scale_test.dart` keeps the
  number on record.
- [ ] **T-M6-02** Multi-tab: tab bar, close, switch; per-tab editor state.
  *AC: two tabs edited independently; state survives switch.*
- [ ] **T-M6-03** Export: note → `.md` / standalone `.html` (KaTeX
  rendered + minimal CSS); library/folder → `.md` bundle zip. *AC:
  externals open it; HTML shows math.*
- [ ] **T-M6-04** Import: Obsidian = open folder (wikilinks supported);
  Notion zip → import (markdown mapped, metadata stripped). *AC: both
  yield a browsable, linked library.*
- [ ] **T-M6-06** Encryption: first-launch plain-vs-encrypted choice
  (fixed at creation — converting rewrites every file = full re-upload
  + per-file conflicts elsewhere); AES-256-GCM per file (`pointycastle`
  behind swappable `core/crypto.dart`); key in secure storage;
  transparent encrypt/decrypt in the note pipeline; exports plain.
  *AC: round-trip; disk bytes are ciphertext; wrong key fails cleanly;
  no flip of an existing library.*
- [ ] **T-M6-07** Onboarding: first-launch pick/create library +
  encryption choice (skippable for plain). *AC: fresh install lands
  usable.*
- [ ] **T-M6-08** Polish: complete settings screens (library, sync,
  theme, layout override, trash), sync status UI, queued/failed-op
  notices. *AC: no dead ends; every setting reachable + effective.*
- [ ] **T-M6-09** Platform path polish: image-insert paths per platform.
  Root picking done + device-verified; image side left. *AC: inserted
  image resolves from the library-relative link on real devices.*
- [ ] **T-M6-10** Tests: perf assertions, unit (crypto, zip/HTML export,
  Notion mapping), widget (tabs, onboarding, themes). *AC: green + on
  device.*
- Design (pending slice): `ui/tabs.dart`, `ui/onboarding.dart`,
  `core/crypto.dart` (12-byte nonce + ciphertext, magic header; editor
  holds plaintext in memory only), `export/` (HTML via shared preview
  pipeline, KaTeX inlined), `import/ notion` (zip walk → tree,
  frontmatter normalized, page links → wikilinks best-effort).
- Exit: 1M gate timings + bounded memory (reads done, reconciliation
  waits T-M6-11); tabs; export/import round-trips; encryption round-trip
  + onboarding; unit + widget + perf green.
- Risks: AES package pick at T-M6-06; encryption × sync (same file hash
  both sides; key never synced; first-launch before first sync).

## M7 — Packaging & release — Planned (tag CI landed 2026-09-11)

Purpose: final branding, signed APK/AAB, Linux tar.gz + AppImage + Arch
pkg, repeatable procedure, open-source release, tagged changelog
release. Cut a release: bump `pubspec.yaml`, `git tag vX.Y.Z` (strict,
no suffixes), `git push origin vX.Y.Z` — CI publishes everything to the
tag's GitHub Release page (see README "Release").

- [ ] **T-M7-01** Final branding: real name + icon (placeholder
  "Copist"/feather; "Inkwell" rejected — existing product); labels,
  launcher icons, window titles, docs. *AC: one name source of truth
  across android/, linux/, windows/, docs.*
- [ ] **T-M7-02** Android: release-signed APK + AAB; versionName/Code
  policy; keys on the signing machine, never in repo. *AC: installs on
  minSdk-35; store-ready AAB.* (Interim: CI APKs are debug-signed;
  optional `key.properties` signing wired for `ANDROID_*` secrets.)
- [ ] **T-M7-03** Linux: release tar.gz; AppImage (bundled offline,
  Wayland-compatible; manual AppDir + `appimagetool`); Arch
  `.pkg.tar.zst` from in-repo `packaging/linux/PKGBUILD` (no AUR).
  *AC: each runs on target; PKGBUILD in repo.*
- [ ] **T-M7-04** Release procedure: one documented clean-checkout →
  artifact sequence per platform (README "Release" + workflow +
  `packaging/` scripts). *AC: the document reproduces every artifact.*
- [ ] **T-M7-05** Open-source release: README final, LICENSE = MIT,
  contributing doc, issue/PR templates. *AC: fork-and-build ready.*
- [ ] **T-M7-06** Release: tag `vX.Y.0`, changelog, publish APK/AAB,
  tar.gz, AppImage, pkg, Windows installer + zip. *AC: clean install
  from each passes integration E2E.*
- [ ] **T-M7-07** Windows: release runner dir zipped + Inno Setup 6
  installer (English + Italian; no MSIX, no cert); produced on a Windows
  host, never cross-built. *AC: clean install runs where Flutter never
  existed.*
- Exit: signed APK/AAB passes on-device E2E; Linux trio runs on
  targets; procedure reproduces all artifacts; repo MIT-releasable.
- Risks: Android keys = critical path (set up early in T-M7-02;
  AppImage signing optional); Arch bundle size/perf; rename (T-M7-01)
  coordinated with README/strings before freeze.

## Platform parity — In progress (share-in + verifications open)

Everything else is aligned or documented-limited. Open:

- [ ] **T-PP-07** Android `SEND`/`VIEW` for `text/plain` + `.md`
  (`onCreate`/`onNewIntent` → Dart, shortcuts-channel pattern): text →
  quick-note insert, file → library import. *AC: share lands in Copist.*
- [ ] **T-PP-08** Desktop: `.md` MIME association + single-instance
  handoff (second launch forwards `<file>`; needs the guard first, else
  two processes on one library) + optional tree drag-drop.
  *AC: double-click opens; no second library window.*
- [ ] **T-PP-04** Device-and-desktop verification: the overdue-reminder
  log line must read sensibly on desktop backends too. *AC: one log each
  from Linux and Windows next to the Android one.*
- [ ] **T-PP-12** T-M6-09 close-out per platform (one image from its
  link on Android shared storage, Linux Wayland, Windows). *AC: three
  checkmarks or the failing row says what broke.*
- [ ] **T-PP-13** Secure-storage first-run on all three (fresh profile,
  no keychain/dbus): save/load + clean degradation, by hand.
- Owed hand checks (landed, unverified): frameless-window drag /
  maximize / buttons / dirty-Close on Linux; accelerators in a real
  window; desktop reminder popup; hunspell underline click; tray-menu
  four-action click-through; Windows-host pass for `window_manager` +
  `nativeapi`.

## Template language — counter + caret held back

Done except, by choice:

- [ ] **T-TPL-05** `{{counter:name}}` — per-library, in
  `.copist/counters.json`, `|pad:3`-formattable. *AC: 1 then 2; survives
  restart; per name + library.*
- [ ] **T-TPL-07** `{{cursor}}` — caret landing, removed from text
  (numbered stops if the editor can walk them). *AC: caret at marker,
  marker not in file.*
- Both want a line on the settings reference page + their own tests
  when they land.

## WYSIWYG editor — device pass open (`feat/wysiwyg-editor`)

Implementation landed (codec, widget, settings, wiring, find, spell,
toolbar states, 200 KB guard); open: the **device pass** on Linux +
Android (frontmatter/table/footnote/math/wikilink note; edit one line;
confirm diff + surface switch). Standing rules the pass must hold:
open + save untouched = byte-identical; unrepresentable blocks stay
opaque embeds (verbatim write-back); WYSIWYG never beside preview;
>200 KB refuses, offers source. Known limits (measured 2026-09-11):
nesting indent lost, ordered lists renumbered from 1, autolinks/setext
normalized; tables/math/frontmatter/HTML/wikilinks/images/nested
quotes/hard breaks/ref-links/footnotes = read-only verbatim boxes;
toolbar super/subscript silently dropped on save (fix: map to
`<sup>`/`<sub>` in `_renderInline`). Open questions: exact large-note
threshold; per-construct editable embeds later.

## Reminder latency — fix in, confirmation open

Cause (2026-09-08 log): Copist cancelled its own deferred alarms —
`wantedReminders` dropped past-due reminders and full-replace
reconciliation killed the pending alarm. Fix: `reminderGrace` (1 h) —
due stays wanted (unarmed), the sweep spares it. Owed: the confirming
device run (2-min reminder, screen off, repeated).

## Tab-switch jank — shipped, device logs awaited

- [ ] **T-TS-05/06** Correlate fresh switch logs; fix the bottleneck
  found (suspect: switch-frame relayout of the unhidden SearchScreen,
  borderline over budget).
- [ ] **T-TS-08** Keep the shell alive under fullscreen notes (open
  disposes all five tab bodies; close remounts: 30.7 ms worst). Sketch:
  `Stack` overlay, shell always mounted + `Offstage` under notes.
  *AC: no `tree.ui`/`search.ui` mounts on open/close; no `build` >
  12 ms on return.* Shipped, awaiting log.
- [ ] **T-TS-10** Keep hidden bodies laid out (`Visibility(maintainSize)`
  on the search slot = paint-only switches). Shipped (`retainLayout`),
  awaiting log. *AC: repeated todo→search shows no `build` > 12 ms.*

## Cleanups — T-CL-03/04 open

- [ ] **T-CL-03** List parser re-tokenizes the whole note per edit.
  Measure on a large note first; line-scan fast path only if the
  benchmark says so. *AC: benchmark before any change.*
- [ ] **T-CL-04** Size-rule debt (`db/indexer.dart`, `ui/shell.dart`,
  `ui/note_view.dart` ~1400 lines each vs the ~300-line /
  one-class-per-file rule; shell worst by kind). Main structural debt;
  wants its own slice (split by responsibility, tests move along).
  *AC: no behaviour change.*

## Open GitHub issues (live, 2026-09-11)

All enhancements:
- #6 Add widgets to home screen (opened Sep 9).
- #7 Daily Notes/Journal (opened Sep 9) — note: "daily note" is
  explicitly outside the app's vocabulary (README, spec).
- #8 Smart table creation (opened Sep 11).

## Stretch goals (ordered)

1. Mermaid diagrams (bundled offline webview renderer) — Backlog.
2. PDF export — Backlog.
3. LaTeX autocomplete — Backlog.
4. Linux spellcheck — Backlog in the plan table, but the desktop
   system-hunspell implementation already landed (T-PP-09 was checked);
   the table is stale.
5. E2E next-level coverage — Backlog.
