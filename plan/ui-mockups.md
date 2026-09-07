# UI — mockup parity (bottom nav, toolbars, chrome)

**Status:** Planned · **Depends on:** M2a done (re_editor-based editor) · **Spec:**
*Requirements* (layout, editor) · **Visual source of truth:** the mockups below.
Everything in this file that the spec is silent on (bottom nav, new tabs, toolbar)
is defined by the mockups; T-UI-11 folds those back into the spec.

## Mockups

Approved designs in `mockup/`:

- **Library:** `mockup/Screenshot_2026-09-06-23-57-10-06_….jpg`
- **Editor:** `mockup/Screenshot_2026-09-07-00-05-22-47_….jpg`
- **Icon:** `mockup/logo.png` → vectorized as `mockup/logo.svg` (T-UI-01).

Current on-device reference: `screenshots/Screenshot_2026-09-07-00-17-…jpg`
(library) and `screenshots/Screenshot_2026-09-07-00-18-…jpg` (editor).

## Current state

- `shell.dart`: `LibraryHome` → AppBar (title, trash, settings) + `_ActionBar`
  (5 IconButtons: new note, new folder, rename, move, delete) + tree/detail.
  No bottom navigation; no sort control.
- `tree.dart`: `_RowTile` = chevron (folders) + `Icons.folder`/`Icons.article`
  + name.
- `note_view.dart`: 34px `_paneSwitchBar` (single centered eye/edit button)
  below the app bar; status row = insert-image, outline toggle, word count,
  `saved`/`unsaved`.
- `highlight_style.dart`: per-token text styles; wikilinks are purple, no
  underline. No heading rules, no frontmatter block styling.
- Icon: PNG only (`mockup/logo.png`), no vector source.

## Mockup vs current — diff

| Area | Current | Mockup |
|------|---------|--------|
| Library app bar | title + trash + settings gear | title + trash + **sort toggle** (chevrons) |
| Library note actions | `_ActionBar` row (5 icons) | none visible → context menu + **round “+” FAB** (T-UI-05) |
| Folder rows | chevron + filled folder icon + name | chevron + name only |
| File rows | `Icons.article` + name | outline doc icon + name |
| Bottom navigation | none | 5 tabs: **Files, Todo, Search, Quick note, Settings** |
| Editor app bar | back + name; switch row below title | back + name + **eye action in app bar** |
| Editor bottom | image, outline, word count, saved | status row (**word count** left, **saved** right) + **formatting toolbar row** |
| Toolbar | none | `B I S T^ T̲ link <> image list quote`, **evenly spaced** (mockup’s trailing gear and uneven spacing dropped) |
| Editor text | plain headings; purple wikilinks | headings w/ bottom rule; frontmatter w/ left rule; wikilinks **accent blue, underlined** |
| Icon | PNG | vector (`logo.svg`) |

## Tasks

- [x] **T-UI-01** Vector logo: `mockup/logo.svg` — hand-drawn 512×512 (squircle
  tile, clipboard + ring clip, three text lines, notched feather with rachis,
  gold nib with vent, ink swash). *AC: renders alongside `logo.png` (verify
  with `rsvg-convert`); colors: bg `#f2ead9`, tile `#f9f3e6`, navy
  `#1f2b3e`, gold `#d9b36a`.*
- [x] **T-UI-02** Bottom navigation (phone/narrow width only): 5
  `NavigationBar` destinations — Files, Todo, Search, Quick note, Settings.
  Files tab hosts the current tree + note-open stack; Settings tab hosts the
  existing `SettingsScreen` (as a body, `SettingsBody`); Search/Todo/Quick
  note per T-UI-10. *AC: tab switch keeps library state (expanded folders,
  selection) — `tab_bar_test.dart` covers it; wide layout (≥
  `_phoneBreakpoint`) unchanged — mockups are phone-only.*
  *Deviation: the phone Files app bar keeps the trash icon and drops the
  settings gear (the Settings tab replaces it); on wide, the gear stays the
  way to reach settings until T-UI-03.*
- [x] **T-UI-03** Library app bar: sort toggle (`Icons.unfold_more`, in
  both app bars) flipping name-asc ⇄ name-desc, persisted in
  `app_settings.tree_sort` (v7 migration). The phone Files bar is trash +
  sort per mockup; settings stays in the Settings tab. The wide bar keeps
  the settings gear as the only settings route (no tab bar there) and
  gains the same toggle. *AC: toggle survives restart (`library_state_test`
  restarts the controller); tree re-orders (widget test flips the row
  order).*
- [x] **T-UI-04** Tree rows per mockup: folder rows = chevron + name (drop
  `Icons.folder`); file rows = outline doc icon + name. Row height/font per
  mockup. *AC: `tree.dart` diff is style-only; no behavior change.*
- [x] **T-UI-05** Home the note actions: `_ActionBar` deleted; the classic
  Android round “+” FAB (bottom-right, above the bottom nav; also on the
  wide split) → new note in the currently selected folder (root if none);
  long-press a row → modal context menu (New note here / New folder here
  [dir rows only] / **Set as quick note** [file rows; is the quick note,
  shows "Current quick note"] / Rename / Move / Delete→trash) reusing the
  `_createNote`, `_createFolder`, `_rename`, `_move`, `_delete` handlers.
  *AC: all five actions + the quick-note item reachable — widget tested
  (`tab_bar_test` FAB/menu test, `library_flow_test` reworked to
  FAB/menu).*
- [ ] **T-UI-06** Editor app bar: eye/`edit` toggle becomes an app-bar action
  (mockup: single icon, top right); delete `_paneSwitchBar` (works for the
  wide-screen switch override too, since the app bar is shared).
- [ ] **T-UI-07** Editor status row: `N words` left, `saved`/`unsaved` right.
  Insert-image moves to the toolbar (T-UI-08); the outline toggle stays in
  this row (confirmed).
- [ ] **T-UI-08** `EditorToolbar` (`lib/src/editor/toolbar.dart`) over the
  status row: bold, italic, strikethrough, superscript, underline, link,
  code, image, list, quote, **evenly spaced** (the mockup’s trailing gear
  and its uneven spacing are dropped). Each button applies a pure command
  from new `lib/src/editor/md_editing.dart`
  (text + selection → new text + selection) through the re_editor
  `CodeLineEditingController`. *AC: unit tests for wrap-selection,
  empty-selection (insert markers at caret), and list/quote prefixing per
  line.*
- [ ] **T-UI-09** Editor text styling: wikilinks → theme accent + underline in
  `highlight_style.dart` (both palettes); heading bottom rule + frontmatter
  left rule if re_editor supports per-line decorations (else R5 fallback).
- [x] **T-UI-10** New tabs (spec-silent — confirmed): **Quick note** =
  scratch note `Quick note.md` at library root (created missing), opened in
  the note view (intro body with an "Open quick note" button;
  `NoteOperations.find` added for the existence check). **Todo** = tab
  created now with an **empty body** (the section exists; implementation is
  deferred, still being thought through). *Follow-up (user, 2026-09-07):
  the quick note is user-chosen, and **nothing is opened/created by
  default** — the tab offers "Choose a note…" (tree dialog) and "Create a
  new note…" (name dialog at the library root); both set the quick note
  and open it. The choice is persisted per library (`quick_note_path`,
  v6 migration) and also pickable from the Settings tile; the tree
  context menu gets a "Set as quick note" item when T-UI-05 lands. A
  stale choice (moved/renamed/deleted) is cleared on open.*
- [ ] **T-UI-11** Update spec (*Layout*, *Editor*) and `design.md` module
  layout (`ui/nav` / `editor/toolbar` / `editor/md_editing`); prepare
  `logo.svg` for launcher-icon generation in M7.

## Technical design

- **Shell tabs.** `shell.dart` gains a `ShellTab` enum + selected-tab state.
  Narrow layout: `Scaffold(appBar: …, bottomNavigationBar: NavigationBar(…))`.
  The Files tab body is today's `_treePane` + the existing note-open flow
  (`_treeVisible` push/pop unchanged). Each other tab is its own
  `Scaffold`-free body widget (one class per file, e.g. `ui/quick_note.dart`,
  `ui/todo_tab.dart`). Search tab stays disabled until M3 lands `SearchScreen`.
- **Sort.** New settings row (drift settings table, M0-style key/value):
  `treeSort ∈ {nameAsc, nameDesc}`; the DAO/scan order param already has a
  name sort — add direction. App-bar icon reflects current direction.
- **Toolbar commands.** `md_editing.dart` is pure and unit-tested:
  `wrap` (bold `**`, italic `*`, strike `~~`, sup `<sup>…</sup>`,
  underline `<u>…</u>`), `insert` (link `[[…]]`, code ``` ``` ```, image
  `![[…]]`, list `- ` per line, quote `> ` per line). The toolbar widget is
  dumb: it takes `List<_Button(icon, tooltip, onTap)>` from `NoteView`, which
  reads the selection off the controller and writes the result back.
- **Styling.** Wikilink color/underline: existing per-token `TextStyle`
  override mechanism (no new surface). Heading rule / frontmatter bar: check
  re_editor `CodeEditor` line-decoration API first; fallback is
  style-only (headings keep weight/color, frontmatter keeps the dim token
  style) — see R5.
- **Icon.** `mockup/logo.svg` is the vector source of truth; M7 generates
  Android adaptive + legacy, Linux, and Windows launcher icons from it
  (squircle tile as background layer, clipboard+quill as foreground).

## Exit criteria

- On-device screenshot pair (library, editor) matches the two mockups plus
  the confirmed deviations (round “+” FAB; no gear FAB; no trailing toolbar
  gear; evenly spaced toolbar icons): same chrome, same icon set, dark
  theme.
- `flutter test` green, including the new `md_editing` unit tests; widget
  tests updated for moved/removed chrome (`library_flow_test` — `_ActionBar`
  keys, `layout_modes_test` — `preview-switch` key, `image_insert_test` —
  insert-image moved, `outline_jump_test` — outline key).
- `flutter analyze --fatal-infos` clean.
- `logo.svg` visually verified against `logo.png`.

## Risks / open questions

1. **R3 — Search tab before M3.** Default: disabled destination with tooltip
   "search lands in M3".
2. **R5 — re_editor decorations.** Heading bottom rules and the frontmatter
   left bar may not be expressible with re_editor's line styling. Fallback:
   style-only (no rules). Verify the API during T-UI-09 and record the
   decision here.

## Decisions (user, 2026-09-07)

- **R1 (resolved):** note actions = long-press context menu **plus** the
  classic Android round “+” FAB (new note in the selected folder, root if
  none) — the mockup predates the FAB, which is added on top of it.
- **R2 (resolved):** the gear FAB in the library mockup is an unidentified
  leftover — drop it.
- **R4 (resolved):** Quick note = `Quick note.md` scratch note at root,
  exactly as defined. Todo = tab/section created now, body left empty;
  implementation deferred.
- **R6 (resolved):** the outline toggle stays in the editor status row.
- **R7 (partially resolved):** the trailing gear in the editor toolbar is an
  extra — remove it. Superscript/underline keep the HTML mapping
  (`<sup>`, `<u>`); the spec's Markdown extras don't cover them.
- **Toolbar spacing (resolved):** buttons evenly spaced
  (`MainAxisAlignment.spaceEvenly`); the mockup’s uneven spacing is a design
  artifact.
