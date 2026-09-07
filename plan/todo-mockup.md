# Todo tab — mockup parity (filter row, rows, app bar overflow)

**Status:** In progress (implementation) · **Depends on:** `todo-tab.md`
(T-TD-01…T-TD-08 done) · **Spec:** the mockup below is the source of
truth for everything this file is silent on.

## Mockup

`screenshots/Main@2x.png` — the approved Todo screen (dark theme, phone).

## Current state

- **App bar** (shell): title + `+` (add) + `ⓘ` (format help).
- **View switch**: `SegmentedButton` Open/Done below the app bar.
- **Filter UI**: one horizontal chip bar — sort popup, five due-range
  `ChoiceChip`s, one `FilterChip` per token with count (scrollable).
- **Rows**: `ListTile` — checkbox, title, `Wrap` subtitle (priority
  badge, due badge, `+p`/`@c`/`#t` chips, alarm icon for reminders).

## Mockup vs current — diff

| Area | Current | Mockup |
|------|---------|--------|
| App bar | `+` + `ⓘ` help | `+` + **⋮ overflow** (Open/Done, format help) |
| View switch | `SegmentedButton` in the body | **⋮ overflow items** (checked) |
| Filter UI | horizontal chip bar | **compact row**: due-range **dropdown pill** ("All dates"), **`Filter` pill** → bottom sheet (token chips + sort), **"N open"/"N done"** count, right-aligned |
| Sort | popup in the chip bar | inside the **Filter sheet** (choice chips) |
| Rows | checkbox + title + chip/badge wrap | checkbox + title + **one-line subtitle**: due state + short date (+ reminder time with clock icon); **left accent bar** = first tag's color |
| Priority badge | shown in the row | **dropped from the row** (still sortable) — the mockup's rows carry no badge |
| Reminder icon | separate alarm icon | the **clock + time** in the subtitle is the reminder marker (no extra icon) |

## Tasks

- [ ] **T-TDM-01** Strings: `todoAllDates` ("All dates"), `todoFilter`
  ("Filter"), count suffixes (`open` / `done`), `todoNoTokens`; drop the
  chip-bar-only `todoDueAll` ("All"). *AC: analyze clean, no dead strings.*
- [ ] **T-TDM-02** Row per mockup: one-line subtitle — overdue:
  `Overdue · d MMM` (error color); today: `Today` (tertiary) + clock +
  `HH:MM` when the task has a reminder; upcoming: `d MMM`
  (onSurfaceVariant) + clock + time; no due date and no reminder: no
  subtitle. Short date `d MMM`, year appended when it differs from
  today's year. Left accent bar (3 dp, full row height) in the color of
  the **first** `#tag` (`ui/tag_color.dart`, deterministic per name);
  no tag → no bar. Checkbox, tap-to-edit, long-press menu, completion
  strikethrough unchanged. *AC: widget test per due state + accent bar +
  no-subtitle case.*
- [ ] **T-TDM-03** Filter row + sheet: `TodoFilterBar` rebuilt —
  due-range dropdown pill (outlined button, `expand_more`, popup menu
  with the five ranges, checked state), `Filter` outlined pill
  (`filter_alt` + "Filter") opening a **bottom sheet** (the app's menu
  pattern) with the token `FilterChip`s (counts, AND semantics, keys
  `todo-token-<token>`) and a **Sort** section (three `ChoiceChip`s:
  due date / priority / creation date); right-aligned count
  `N open` / `N done` (entries of the visible file, unfiltered). *AC:
  widget tests — dropdown narrows the list, sheet chips toggle tokens,
  sort chips re-sort.*
- [ ] **T-TDM-04** App bar ⋮: phone tab shell **and** the wide pushed
  screen get `+` + `PopupMenuButton` (⋮) with Open/Done (checked item)
  and Format help; the shell owns `_todoShowDone` (mirrors
  `_showTags`); `TodoTab` receives `showDone` + `onShowDoneChanged` and
  keeps pruning tokens when the view flips. The old `ⓘ` action and the
  `SegmentedButton` are gone. *AC: widget test — overflow flips the
  list, help still opens (shell test).*
- [ ] **T-TDM-05** Test sweep: `todo_tab_test.dart` rewritten for the
  new shapes (dropdown, sheet, overflow-driven view switch);
  `shell_reminders_test.dart` (`todo-help` key) and
  `tab_bar_test.dart` updated. *AC: `flutter test` green.*

## Technical design

- **State split.** The shell already owns app-bar state (`_showTags`,
  `_treeSort`); the view switch becomes shell state
  (`_todoShowDone`) because the ⋮ action lives in the app bar. Due
  range, tokens and sort stay tab-local inside the existing
  `TodoFilter` (only the sheet edits them).
- **Dropdown.** `showMenu` anchored to the pill's render box
  (`RelativeRect.fromRect`); `PopupMenuItem`s keep the old
  `todo-due-<range>` keys.
- **Sheet.** `showModalBottomSheet` with `SafeArea`; chips keep the
  `todo-token-<token>` keys; sort chips get `todo-sort-<key>` keys.
- **Accent bar.** `IntrinsicHeight` not needed:
  `Row(crossAxisAlignment: CrossAxisAlignment.stretch, [Container(width:
  3, color), Expanded(ListTile)])` — the bar stretches to the row
  height. `tagColorFor(name)`: lowercase hash → hue, fixed
  s/l (`Color.fromHSL`).
- **Subtitle.** One `Row` of `Text`/`Icon` (14 dp clock) in a single
  state color; short-date + `HH:MM` helpers are file-local in
  `todo_row.dart` (display formatting is a UI concern; the parser's
  `formatTodoDate` stays the machine form).

## Decisions

- **"N open" semantics** = the entries in the visible file, *unfiltered*
  (the mockup shows "12 open" with six rows on screen).
- **Accent bar: dropped (user feedback, 2026-09-07).** The mockup's
  left accent bar (first `#tag`'s color) was unrecognizable — the user
  could not tell what it meant — and is gone. The row now shows a chip
  per `+project` / `@context` / `#tag` token instead, each dotted with
  `tagColorFor` (the bar's color, repurposed), so the tokens are visible
  in the row and the color still marks the token.
- **Priority leaves the row** (mockup rows carry no badge); sorting by
  priority remains in the sheet.
- **FAB: yes (user override, 2026-09-07).** The Todo tab's add action
  moved from the app-bar `+` to a bottom-right `FloatingActionButton`
  (phone tab shell and the wide pushed screen alike): the bar `+` did
  not read as "add a task". The Files tab's expandable `+` FAB is
  untouched; at most one FAB per tab, never two on screen.
- **Reminder marker** = the clock + time in the subtitle (a `rem:`
  without a due date still shows its date + time).
