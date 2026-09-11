# Project Analysis - Pending Points

This document lists all pending tasks, unchecked checkboxes, and unmanaged observations identified across the project's plans and specifications.

Verified 2026-09-11 against `plan/` and the live GitHub issue tracker
(open: #6, #7, #8; closed: #2, #3, #4, #5).

## Milestones & Specific Plans

### M5 — Sync
- [ ] T-M5-01 WebDAV client on dart:io HttpClient (zero deps)
- [ ] T-M5-02 Destination settings UI (URL, user, password)
- [ ] T-M5-03 sync_items tracking (sha256, size, modified, etag)
- [ ] T-M5-04 .history/ versioning: keep the last N versions
- [ ] T-M5-05 Upload path: MKCOL parent propagation, then PUT
- [ ] T-M5-06 Download path: ETag-compare, GET -> .tmp -> atomic rename
- [ ] T-M5-07 Delete propagation: local delete or empty-trash -> remote delete
- [ ] T-M5-08 Conflict path: PUT 412 -> re-fetch remote -> 3-way merge
- [ ] T-M5-09 Triggers: manual button; automatic on app focus, on-change, and ~60 s poll
- [ ] T-M5-10 Offline: queue persists across restart; retry with exponential backoff
- [ ] T-M5-11 Tests: mock WebDAV suite + integration_test E2E

### M7 — Packaging & Release
- [ ] T-M7-01 Final branding: decide the real name + icon
- [ ] T-M7-02 Android packaging: release-signed APK + AAB
- [ ] T-M7-03 Linux packaging: release tar.gz; AppImage; Arch `.pkg.tar.zst` (PKGBUILD, no AUR)
- [ ] T-M7-04 Release build procedure: documented sequence
- [ ] T-M7-05 Open-source release: repo hygiene
- [ ] T-M7-06 Release: tag vX.Y.0, changelog, publish artifacts
- [ ] T-M7-07 Windows packaging: release runner directory, zipped (installer decision landed: Inno Setup, T-M7-08)
- [x] T-M7-08 Tag-triggered release CI (landed 2026-09-11): `.github/workflows/release.yml` runs on `v*` tags only — APK, Linux tar.gz + AppImage + Arch pkg, Windows Inno Setup installer + portable zip

### M2a — Line Editor
Milestone status is Done + device-verified 2026-09-06, but the custom widget
stack was replaced by `re_editor`, so these stay unchecked and superseded
rather than pending:
- [ ] E8a Input view: DeltaTextInputClient bridge (superseded by `re_editor`)
- [ ] E8b Selection + clipboard UI (superseded by `re_editor`)
- [ ] E8c Folding + outline view (superseded by `re_editor`)
- [ ] E9 On-device performance verification of the custom stack (done instead on the `re_editor` stack)

### M-Type Note Kinds
Done (T-TK-01..T-TK-09 all checked). No pending tasks. (A previous version
of this file listed "Latte / Pane / Integrale" here — those are example
grocery items from the `type: list` markdown example in
`plan/m-type-note-kinds.md`, not tasks.)

### Platform Parity
- [ ] T-PP-04 Device-and-desktop verification
- [ ] T-PP-07 Android: SEND/VIEW intent-filters
- [ ] T-PP-08 Desktop: MIME/file association
- [ ] T-PP-12 T-M6-09 close-out per platform
- [ ] T-PP-13 Secure-storage first-run

### Template Language
- [ ] T-TPL-05 {{counter:name}}
- [ ] T-TPL-07 {{cursor}}
(Held back deliberately; the slice is otherwise Done.)

### M6 — Scale & Polish
- [ ] T-M6-11 First-index experience at scale
- [ ] T-M6-02 Multi-tab: tab bar, close, switch
- [ ] T-M6-03 Export: note -> .md / .html; library/folder -> .md bundle
- [ ] T-M6-04 Import: Obsidian library, Notion export zip
- [ ] T-M6-06 Encryption: first-launch choice, per-file AES-256-GCM
- [ ] T-M6-07 Onboarding: first-launch flow
- [ ] T-M6-08 Polish: settings screens, sync status, notification
- [ ] T-M6-09 Platform path polish: image-insert paths
- [ ] T-M6-10 Tests: perf assertions, unit (crypto, export, import), widget

### Open GitHub issues (live, 2026-09-11)
Issues #2–#5 (fullscreen preview status-bar overlap, bottom gap, checklist
input, Quick Note black flash) are closed; `plan/Copist_issues_plan.md`
covers them as a 2026-09-08 snapshot. Currently open:
- #6 Add widgets to home screen (enhancement, opened Sep 9)
- #7 Daily Notes/Journal (enhancement, opened Sep 9) — note: "daily note"
  is explicitly outside the app's vocabulary (README, spec)
- #8 Smart table creation (enhancement, opened Sep 11)

## Stretch Goals & Backlogs
- Mermaid: Stretch goal (bundled offline webview renderer)
- PDF Export: Stretch goal
- LaTeX Autocomplete: Backlog
- E2E: Backlog
- Linux Spellcheck: `plan/README.md` still tables it as stretch goal 4 /
  backlog, but T-PP-09 is checked with a landed implementation (desktop
  binds the system libhunspell via `dart:ffi`) — the two are inconsistent,
  and so is the README Features line ("Linux/Windows: no engine service,
  backlog").

## Observations & Notes
- App Name: "Copist" is a placeholder; both app name and icon will be renamed later.
- Platform Portability: macOS/iOS support is planned for later; keep code portable.
- Terminology: "Library" instead of "Vault". No vault, canvas, publish, daily notes, graph view.
- Model: SQLite is only a rebuildable index, never the source of truth.
- Images: On insert, copy file into library and insert a link (no base64 by default).
- History: Last N versions in .history/ (not synced); doubles as merge base.
- Templates: Default folder Templates/; placeholders: {{title}}, {{date}}, {{time}}, {{now}}, {{uuid}}.
- Conflicts: Multi-device simultaneous editing out of scope for v1.
- Android: Target minSdk 35 (Android 15); APK for now (debug-signed until T-M7-02 keys exist; optional `key.properties` signing is wired).
- Linux: Wayland required; release AppImage + Arch .pkg.tar.zst.
- Security: Choice of plain or encrypted library at first launch; TLS transport (no standard WebDAV E2E).
- Search: Full-text (title + body + tags) via FTS5; instant at 1M notes.
- Themes: Brightness (day/night/system) x Palette (device Material You colors, Catppuccin, Solarized, Gruvbox).
- Export: PDF is a stretch goal.
- Import: Obsidian library = open folder; Notion export zip -> import.
- Licensing: MIT (confirmed).
