# M6 — Scale & polish

**Status:** In progress · **Depends on:** M4 · **Spec:** *Requirements*
(export, import, themes, security, layout), *Performance strategy*,
*Milestones → M6*

M5 (sync) is **not** a prerequisite, whatever the M0→M7 chain says: nothing
here reads or writes the sync queue, and scale, tabs, export, themes and
onboarding all sit on the M4 library. The one place the two meet is
encryption × sync, and it meets in one direction only — an encrypted
library must have its key before its first upload — which is a constraint
on M5, not a dependency of M6 (user, 2026-09-09).

## Purpose

Hit the scale gate (1M notes, novel-length files), add multi-tab, import/
export, the theme system (brightness × palette), optional per-file encryption
with the first-launch onboarding, and overall polish.

## Current state

M4 leaves a local-only, unencrypted library with a single open note, one
seeded Material theme that follows the system brightness, and every text
size fixed in code. Sync (M5) has not been built.

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
- [ ] **T-M6-12** Text size: two sliders in the settings, one for the
  interface and one for the note text, each stored app-wide and applied
  live. The interface slider multiplies the OS text scale for every
  screen — tree, tabs, todo rows, dialogs, settings. The note slider sets
  the source editor's font size in points and scales the preview of the
  same note by the same factor, so switching between the two panes does
  not change how big the note reads. Neither slider moves the other.
  *AC: both sliders survive a restart; the editor ignores the interface
  slider and the tree ignores the note slider; the preview and the editor
  agree; the smallest and largest steps still lay out on a phone.*
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
  notion), `core/settings/` (theme and text-size settings).
- **Crypto:** AES-256-GCM via a pure-Dart implementation (`pointycastle` —
  new dep, the "zero-deps" constraint applies to the WebDAV client, not
  crypto). Per-file: 12-byte random nonce + ciphertext; magic-byte header
  marking encrypted files; key from `flutter_secure_storage`. Editor holds
  plaintext in memory only; `.md`/HTML exports always decrypt.
- **Text size:** two doubles on the single `app_settings` row, both
  defaulting to 1.0 and clamped to a usable band. The interface one is
  applied once, at the app root, by composing it with the OS scaler
  (`MediaQuery.textScalerOf`) so the accessibility setting still counts;
  everything under it inherits. The note one never travels as a scaler:
  the source editor takes an explicit `CodeEditorStyle.fontSize` (re_editor
  paints its own text and ignores `textScaler` entirely), and the preview
  subtree gets its own `MediaQuery` carrying the note scaler instead of
  the interface one. That split is what keeps the two sliders independent
  — without it the preview would follow the interface slider and disagree
  with the editor beside it.
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
- Both text-size sliders persist, apply live, and stay out of each other's
  way.
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
