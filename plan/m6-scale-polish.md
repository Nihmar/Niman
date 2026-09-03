# M6 — Scale & polish

**Status:** Planned · **Depends on:** M5 · **Spec:** *Requirements* (export,
import, themes, security, layout), *Performance strategy*, *Milestones → M6*

## Purpose

Hit the scale gate (1M notes, novel-length files), add multi-tab, import/
export, the theme system (brightness × palette), optional per-file encryption
with the first-launch onboarding, and overall polish.

## Current state

M5 syncs a local-only, unencrypted library with a single open note and system
theming.

## Tasks

- [ ] **T-M6-01** 1M-note performance pass: startup with cached index (no
  blocking scan), incremental indexing verified, lazy tree, FTS5 search at
  scale. Fixture generator (synthetic 1M-note library) + timing assertions in the
  test suite. *AC: startup < target, search instant, memory bounded.*
- [ ] **T-M6-11** First-index experience at scale: opening a library for
  the first time still runs a blocking scan behind a spinner, which is
  fine for a thousand notes and minutes long for a million. Index in the
  background with visible progress and a browsable partial tree, and let
  the user work while it fills. *AC: a 1M-note library is usable before
  its first scan finishes.*
- [ ] **T-M6-02** Multi-tab: multiple notes open at once — tab bar, close,
  switch; per-tab editor state. *AC: edit two tabs independently; state
  survives tab switch.*
- [ ] **T-M6-03** Export: note → `.md` (plain) / `.html` (with KaTeX rendered
  math, standalone HTML + minimal CSS); library/folder → `.md` bundle (zip).
  *AC: exports open correctly in an external viewer; HTML shows math.*
- [ ] **T-M6-04** Import: Obsidian library = open the folder (wikilinks
  already supported); Notion export zip → import (map Notion markdown to
  `.md` notes, strip Notion-specific metadata). *AC: both sources produce a
  browsable, linked library.*
- [ ] **T-M6-05** Themes: brightness (day/night/system) × palette (system |
  Catppuccin — night → Mocha, day → Latte); token-based role map (design.md).
  *AC: all four combinations render; adding a palette = adding a mapping.*
- [ ] **T-M6-06** Encryption: first-launch choice of plain vs encrypted
  library; AES-256-GCM per file; key in `flutter_secure_storage`; transparent
  encrypt-on-write / decrypt-on-read in the note pipeline; export yields plain
  `.md`. The choice is fixed when the library is created: converting one in
  place rewrites every file, which for a synced library means a full
  re-upload and a conflict on every file on every other device. *AC:
  round-trip test; on-disk bytes are ciphertext; decrypting with the wrong
  key fails cleanly; an existing library cannot be flipped.*
- [ ] **T-M6-07** Onboarding: first-launch flow — pick/create library +
  encryption choice (per spec); skippable for plain libraries. *AC: fresh
  install lands in a usable library.*
- [ ] **T-M6-08** Polish: settings screens complete (library, sync, theme,
  layout override, trash), sync status UI, notification of queued/failed ops.
  *AC: no dead-end screens; every setting reachable and effective.*
- [ ] **T-M6-09** Platform path polish: image-insert paths on every
  platform. Library-root picking is done and verified on device — the
  native picker plus "All files access" on Android, see
  [android.md](android.md) — so only the image side is left. *AC: an
  inserted image resolves from the library-relative link on real devices.*
- [ ] **T-M6-10** Tests: perf assertions, unit (crypto round-trip,
  zip/HTML export, Notion import mapping), widget (tabs, onboarding, themes).
  *AC: green + on device.*

## Technical design

See [design.md](design.md). M6 slice:

- **Modules:** `ui/tabs.dart`, `ui/onboarding.dart`, `ui/theme/` (token maps),
  `core/crypto.dart`, `export/` (note, html, bundle), `import/` (obsidian,
  notion), `core/settings/` (theme settings).
- **Crypto:** AES-256-GCM via a pure-Dart implementation (`pointycastle` —
  new dep, the "zero-deps" constraint applies to the WebDAV client, not
  crypto). Per-file: 12-byte random nonce + ciphertext; magic-byte header
  marking encrypted files; key from `flutter_secure_storage`. Editor holds
  plaintext in memory only; `.md`/HTML exports always decrypt.
- **HTML export:** markdown → HTML (shared preview pipeline) + KaTeX output
  inlined; standalone file.
- **Notion import:** zip walk → `.md` files mapped into the library tree;
  frontmatter stripped/normalized; page links best-effort to wikilinks.
- **Perf gate:** fixture generator writes 1M small notes + novel-length files;
  the suite asserts startup, first-paint and search timings (soft
  thresholds, tracked over time).

## Exit criteria

- 1M-note fixture: startup (cached index), tree scroll, and search meet the
  timing gate; memory bounded.
- Multi-tab works; export/import round-trips verified for `.md`, HTML, zip,
  Obsidian, and Notion.
- Encryption round-trips; onboarding complete; all theme combinations render.
- Unit + widget + perf tests green.

## Risks / open questions

- `pointycastle` vs other pure-Dart AES options — pick during T-M6-06; keep
  the crypto behind `core/crypto.dart` so the choice is swappable.
- Encryption × sync interaction: encrypted files hash differently locally vs
  remotely is fine (both sides compute the same file hash); key is never
  synced (it lives in OS secure storage) — first-launch flow must happen
  before the first sync.
- AppImage/AppImage-free tar.gz builds for M6 testing on Linux desktop
  (Wayland required) — build tooling finalized in M7.
- 1M fixture generation time — generate it once and keep the artifact.
