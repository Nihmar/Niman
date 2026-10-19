# Library features (#1109)

A per-library switchboard for the macro features, gated on every surface.
Written before the code (2026-10-19), as the plan the work follows; the
screens and the decisions taken with them are in
[docs/design/features](../design/features/README.md), and the groups —
what each owns, what *off* means, what it needs — are tabled there.

The constraint that shapes all of it: **off is inert.** A switch hides a
feature everywhere and stops its background work; it never deletes,
moves or rewrites a note, a state file or a setting. Turning it back on is
the whole undo.

## The model (phase 1)

- **`LibraryFeature`**, an enum in its own file
  (`lib/src/core/settings/library_features.dart`): each value carries a
  stable id (`search`, `quickNote`, `templates`, `capture`, `todo`,
  `journal`, `calendar`, `kinds.list`, `kinds.shopping`, `kinds.audio`,
  `transcription`, `kinds.slides`, `kinds.flashcards`, `readers`,
  `annotations`, `ocr`, `home`, `widgets`), its parent (`kinds.shopping` →
  `kinds.list`, `transcription` → `kinds.audio`, `annotations` →
  `readers`) and its string keys. It is the only place a feature is named.
- **`Features`**, an immutable value over the raw `Map<String, bool>`:
  - an id missing from the map reads as on, so a feature a later build
    adds is born on;
  - an id this build does not know is kept and written back, the rule
    `NavigationLayout` already follows;
  - `own(f)` is the row's own switch, `isOn(f)` the effective value —
    its own and its parent's — which is what every surface asks;
  - the four presets are constant maps, and `presetOf(features)` answers
    the one the switches match, or none (*Custom*).
- **Storage.** `LibraryConfig` reads and writes two keys and holds no
  logic of its own (it is past 1 400 lines):
  - `features`: only the switches that differ from on, so a library that
    never touches the screen keeps a `settings.json` byte for byte as
    today;
  - `featuresReviewed`: the introduction's flag, false when absent.
  Both live in `.niman/settings.json`, travel and sync with it, and go
  through the settings merge as every other key does.
- **The session** exposes the library's `Features` as a listenable; every
  surface rebuilds from it, none keeps a boolean of its own.

Tests: the presets and `presetOf`, dependencies (a child keeps its own
value under an off parent), unknown ids preserved, absent keys reading as
defaults, the round trip through `settings.json`, and a library with no
`features` key writing none.

## The seam (phase 2)

A feature gate in each catalogue, written as an **exhaustive `switch`**
that answers the `LibraryFeature` an entry belongs to, or null for core:

- `featureOf(AppCommand)`, beside `commandNeeds`
  (`lib/src/ui/palette/command_needs.dart`);
- `featureOfTab(ShellTab)`, `featureOfArea(SettingsAreaId)`, the Home
  tile kinds', and `featureOfKind(type)` for the note kinds.

An exhaustive switch does not compile while a case is missing, so a new
command, destination, tile or area cannot ship unclassified — stronger
than the test the issue asked for, which remains only for the
dependencies.

Every surface that offers a command asks one question,
`available = needs met && feature on`: the palette, the keys, the row and
context menus, the toolbar, the phone Insert sheet, the dock. A command
whose feature is off is not offered and does not fire from its key. The
Commands page lists it greyed, with *Off in Features*. The palette, when
a query matched only such commands, adds the quiet line under its key
hints (Desktop-5).

Destinations are two layers: shown when the feature is on and Navigation
does not hide them. Nothing is written to `navigation`; Navigation's row
keeps its place, greyed, with the link to Features (Desktop-4). *Opens on*
follows the shown destinations as it already does for a hidden one.

## The screen and the introduction (phase 3)

- **Settings → Library → Features**, the group's first row: the presets
  strip pinned on top, the cards, the dependency rule, the snackbar after
  a switch that cancelled reminders (with Undo), and **Show this
  introduction again** at the foot.
- **The areas follow the switches**: the area list and the settings
  search drop what belongs to a feature that is off
  (`featureOfArea`).
- **The introduction.**
  - A library whose `settings.json` has no `featuresReviewed`, opened by a
    *normal* open (the picker, the switcher, the last library at launch),
    opens Settings → Features once — the floating window on a desktop,
    the screen on a phone — with the card of Desktop-2.
  - A share, a widget tap, a notification, a reminder and a deep link
    open their target and leave the flag as it was.
  - A folder with no `.niman/settings.json` is a library being created:
    the card is *What is this library for?* with the presets as large
    cards (Desktop-3), Everything preselected.
  - The flag is written when the screen is **left** (Done, back, `Esc`),
    never when it opens.
- **Strings**: every label, line, preset, card and snackbar in all 37
  languages, in this phase.

## The surfaces (phase 4)

- **Home**: a tile or an action whose feature is off is not built; Home
  itself follows `home`.
- **Note kinds**: `NoteKinds.forType(type, features)` answers null for a
  kind that is off, so the note opens in the plain editor; the tree's
  kind icon follows the same answer. The note's bytes are not touched.
- **Readers**: a PDF or an EPUB with `readers` off opens in the system
  app, through the path an unsupported attachment already takes.
- **Intents**: shared text with Quick note off goes to Import; a deep link
  or a notification for a feature that is off opens one sentence, not a
  broken screen.

## The background (phase 5)

- **Reminders**: turning `todo` (or `calendar`) off cancels the alarms
  already scheduled for it and answers how many, for the snackbar; turning
  it on schedules them again from the file. Nothing is scheduled while it
  is off.
- **Downloads**: no Tesseract or whisper model is fetched while `ocr` or
  `transcription` is off.
- **Widgets**: a widget whose feature (or `widgets`) is off is sent the
  off payload — the sentence and **Open Features** — and nothing else is
  written for it (Phone-4).
- **The index**: the FTS index keeps being written whatever `search` says
  — links, properties and the tree read it, and turning search back on is
  instant. Measure before ever revisiting this.
- **Sync** is untouched: it is not a feature (see the design's
  decisions).

## Docs (phase 6)

`docs/user/features.md` (the groups, what each owns, what off means),
Settings → Features in `docs/user/settings.md`, and
`docs/user/platforms.md`. The changelog when it ships.

## How it lands

AGENTS.md: work in several steps stays on one branch, each step committed
and pushed there, and goes into `main` with **one** pull request. The
branch is `feat/library-features-1109`; the phases above are its commits,
in order. Every phase leaves every feature on by default, so the branch is
releasable at each step. The owner chose **all the groups at once**: the
screen is not released until every group is gated on every surface.

## Tests, beyond each phase's own

- For each feature, off: a built shell offers none of its commands —
  palette, keys, row and context menus, Insert sheet, dock, Home, settings
  search, navigation — and on again brings them back.
- A note of a kind that is off opens as Markdown, its bytes unchanged;
  on again restores the kind's view.
- A toggle leaves every file under `.niman/` byte for byte as it was, and
  `settings.json` keeps the ids it does not know.
- The introduction: shown once per library on a normal open; not on a
  share, a widget, a notification or a deep link, which leave the flag
  false; a kill while it is open leaves it false; Done sets it; it round
  trips and merges in `settings.json`; *Show this introduction again*
  shows the card and changes nothing.
- An integration smoke run on Linux of *Notes only*: open, edit, search,
  export; no todo, journal or kind UI; no reminder scheduled. One manual
  pass on Android.
