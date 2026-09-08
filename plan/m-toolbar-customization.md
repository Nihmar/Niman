# Editor toolbar — user-ordered, user-hidden buttons

**Status:** Planned (2026-09-08, user request) · **Depends on:** T-UI-08
(the toolbar itself, landed) · **Spec:** user request: reorder the editor
toolbar and hide buttons from the settings.

## Purpose

The formatting toolbar ships fourteen buttons in a fixed order. Which of
them matter is personal: someone writing prose wants bold/italic/link,
someone taking notes wants lists and headings, and the rest is noise to
scroll past. Let the user set the order and hide what they do not use,
from a settings screen that shows each button with its name and icon.

## Current state

`ui/note_view.dart` builds the fourteen `EditorToolbarButton`s inline in
`_toolbar()`, each with a hardcoded `Key`, icon, tooltip and callback, and
hands the list to `EditorToolbar` (`editor/toolbar.dart`), which is a dumb
scrolling row. Nothing names a button beyond its widget key, and nothing
persists.

## Agreed decisions

1. **The button set is an enum, not a list of widgets.** A
   `ToolbarItem` enum (id, icon, label, default rank) is the model; the
   note view maps an id to its callback. The id is the persisted name, so
   renaming one is a migration.
2. **One setting, app-scoped.** Order and visibility are one value in
   `app_settings` (not per library): the user's habits do not change with
   the library. Stored as a single text column — the visible ids in
   order, then the hidden ones, so both facts survive in one string.
3. **Unknown ids are dropped, missing ids are appended.** A stored value
   from an older or newer build still yields a usable toolbar: ids the
   build does not know are ignored, and buttons the value never mentions
   land at the end, visible. This is what makes adding a button later a
   non-event.
4. **The settings row is the button.** Each row shows the real icon, the
   button's name, a drag handle and an eye toggle — the same handle and
   eye vocabulary the list kind already uses (`ui/kinds/`), so the two
   reorderable surfaces of the app behave alike.
5. **Hiding every button is allowed.** The toolbar then does not render
   at all; the editor keeps its keyboard shortcuts.

## Tasks

- [ ] **T-TB-01** `ToolbarItem` enum + defaults. `editor/toolbar_item.dart`:
  the fourteen items with a stable id, an `IconData`, a `strings.dart`
  label, and the current order as the default. *AC: unit test — the
  default order matches what ships today, every id is unique.*
- [ ] **T-TB-02** The stored layout. A `ToolbarLayout` value object
  (visible ids in order + hidden ids) with `parse`/`encode` over the
  single stored string, applying decision 3 for unknown/missing ids.
  *AC: unit tests — round trip, unknown id dropped, new id appended
  visible, empty/absent value gives the default.*
- [ ] **T-TB-03** Persistence. `editor_toolbar` text column in
  `app_settings` (schema 12 + migration), repo getter/setter, exposed on
  the session like `indentWidth`. *AC: set, reopen, still there;
  migration test from the previous schema.*
- [ ] **T-TB-04** The note view honours it. `_toolbar()` builds from the
  layout: an id→callback map replaces the inline list, hidden ids are
  skipped, and no visible button means no toolbar. *AC: widget tests —
  a reordered layout renders in that order, a hidden button is absent,
  an all-hidden layout renders no toolbar.*
- [ ] **T-TB-05** The settings editor. A screen (pushed from the settings
  list) with a `ReorderableListView` of the items: icon + name + drag
  handle + eye toggle; hidden rows are dimmed. Changes save immediately
  and the open editor picks them up through the existing settings
  refresh. *AC: widget tests — a drag reorders and persists, the eye
  toggles and persists, an open editor reflects both without reopening.*
- [ ] **T-TB-06** Strings + a reset. Every name in `strings.dart`; a
  "Restore default order" action on the screen. *AC: analyze clean;
  reset writes the default and the toolbar follows.*

## Technical design

- **Where the callbacks stay.** The note view keeps owning the markdown
  commands; only the *ordering* moves out. The enum carries no behaviour,
  so `editor/` gains no dependency on the note view.
- **Encoding.** `id,id,id|hiddenId,hiddenId` — visible before the pipe,
  hidden after. Readable in the database, trivially parseable, and it
  keeps the hidden buttons' relative order for when they come back.
- **No per-library variant.** `app_settings` already holds the editor
  toggles that are about the person rather than the library (line
  numbers, autofocus, indent width); this joins them.

## Exit criteria

- The toolbar renders in the user's order, without the buttons they hid.
- The settings screen reorders by drag and toggles visibility by eye,
  persisting both immediately.
- A stored layout from an older build still produces a full toolbar.
- Unit + widget tests green.

## Risks / open questions

- **Discoverability of a hidden button.** Nothing tells the user a
  command still exists once hidden. The reset action is the answer for
  v1.
- **Wide layout.** The toolbar is shared with the wide layout; the
  setting applies to both. No per-layout override in v1.
