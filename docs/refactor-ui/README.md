# The Android UI pass: what is left

A review of the Android screens on 2026-09-17 turned up a set of
inconsistencies — the same question asked two ways, controls that move
under the thumb, labels left in English, icons of two weights in one
list. Part of it has landed. This folder holds the mockups for the rest,
so the work can be picked up without re-deriving it.

The pictures are phone-sized (390×844) and wear the app's own Night
palette, so they can be compared with a device screenshot directly.

## What has landed

| | |
|---|---|
| #122 | The preview toggle keeps its place when the fullscreen button appears |
| #124 | The find button keeps its slot in preview-only mode; one icon weight per list |
| #125 | One dialog for "which folder?" — `MovePicker` gone, the move can create a folder |
| #126 | The row menu says what it acts on, and groups what it offers |
| #127 | The FAB menu names its actions |
| #129 | The labels that were still English: the status row, the trash, the menu's "here" |

Two rules came out of it and are written down in
[`conventions.md`](../dev/conventions.md):

- Icons are outline; a filled icon says a state is on.
- A control that shows in only some states keeps its place — disable it,
  or put it on the side the row grows from, so nothing already on screen
  moves under a thumb that is already on it.

## 1. A note opens as a page, not as a tab

Issue #73.

![The editor, full page](01-editor-full-page.png)
![The editor with the keyboard open](02-editor-keyboard-open.png)
![The quick note, in preview](03-quick-note-preview.png)

Today the bottom of an open note carries three bars: the status row, the
formatting toolbar and the tab bar — around 150 px of permanent chrome on
a phone, with *Quick note* lit as though the editor were a tab.

- Opening a note hides the tab bar; back returns to the tab it was opened
  from. **This has to hold for the quick note too**: its tab opens the
  note, the bars go, and back lands where you came from.
- The formatting toolbar appears only while the keyboard is up, and only
  in an editor — in preview there is nothing to format, and today it
  stays.
- The freed height pays for the status row's touch targets, which are
  `minWidth: 34, minHeight: 26` in
  [`note_view_chrome.dart`](../../lib/src/ui/note_view_chrome.dart)
  against the 48 dp guideline. Left alone so far on purpose: a tight
  phone row was asked for on 2026-09-11, and the space to loosen it
  honestly only exists once the tab bar is gone.
- The app bar keeps the title and gains the note's folder under it.

## 2. Settings: a home, sub-screens and a search field

Issue #104.

![Settings home](04-settings-home.png)
![Searching the settings](05-settings-search.png)
![Folders and paths](06-settings-folders.png)

Ten sections in one column, and finding *Versions to keep* is blind
scrolling.

- A home of areas, each opening its own screen, with a search field on
  top. A result carries the area it came from, so nothing is changed by
  accident in the wrong place.
- App-wide settings separated from the library's own, with the library
  named — the current screen mixes them with nothing to tell them apart.
- *Reindex*, *Switch library* and *Close library* are actions, not
  settings: they move to a **Maintenance** group.
- A row that is disabled says why (the keyboard shortcuts need a physical
  keyboard).
- A value the library does not actually hold says so: `assets · to
  create` rather than a confident `assets`. The picker behind it already
  refuses to select a folder that is not there (#94); the row still
  claims it exists.
- Switch subtitles are uneven — *Preview* and *Line numbers* carry one,
  *Markdown source* and *WYSIWYG* do not, and those two are precisely the
  pair whose combination is not obvious.

## 3. The trash rejoins the family

![The trash](07-trash.png)

It is the only list in the app built out of `Card`s, while File, Settings
and the toolbar screen are flat rows.

- Flat rows, and dates written out rather than the first ten characters
  of an ISO timestamp (#129 did the date and the "was at" line; the
  layout is still `Card` + `ListTile` in
  [`trash.dart`](../../lib/src/ui/trash.dart)).
- **Empty** moves to the app bar. Today it is a FAB in the bottom-right
  corner — exactly where every other screen puts *create*.
- The auto-empty setting is reachable from the screen it is about.

## 4. Tasks: a project is not a context

![Tasks](08-tasks.png)

`+Niman` and `@Android` are drawn in the same purple, so the two things
`todo.txt` deliberately separates look alike at a glance. Give them two
colours from the palette (the accent and the syntax teal), and a third
for tags.

The filter row also mixes two chip shapes — one with a trailing chevron,
one with a leading icon — and the "6 to do" count sits on a different
baseline from the chips beside it.

## 5. Smaller things, without a picture

- **No undo after a delete.** `SnackBarAction` exists only in history,
  sync and transcription. Deleting a note says what happened but offers
  no way back, even though the file is in the trash.
- **The WebDAV screen** opens with both of its buttons greyed, which
  reads as broken, and its **Save** is a full-width button at the bottom
  — a shape that exists nowhere else in the app.
- **Where a new item lands.** The FAB menu could say which folder it
  creates in, but four of its five actions use the FAB's target folder
  while *New list note* always goes to the configured list folder. One
  label over all five would be wrong about one of them; saying it per
  action needs that setting in hand at build time.

## Regenerating the pictures

They were rendered from the mockup canvas at 390×844 with headless
Chrome. Nothing in the app builds them, and nothing reads them: they are
here to be looked at, and this page is the record of what they mean.
