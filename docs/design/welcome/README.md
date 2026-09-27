# Welcome & first-run tour — plan

Issue #266 (a guided tour of the app's features), split into two acts.
This file is the plan the round is built against; the mockups and the
decisions that survive review move beside it as they are drawn.

## 1. What this is

A **welcome deck** on a fresh install, before anything of the app is
asked of the user, that

1. says what Niman is and what it can do — the features, in the app's own
   words, not a manual;
2. asks one question: **how much Markdown does this person know?**;
3. turns the answer into the first library's editor defaults — a user who
   has never written Markdown starts in the live editor with the source
   editor not offered at all, and a user who writes it daily starts in
   source, as today.

And then, as the second act (the issue itself), a **guided tour**: the
same ground again, but pointing at the real controls in a real library,
one step at a time, with the [cheatsheet](../user/editing.md#markdown-support) (#265) as
its playground — no sample notes are made in anyone's library.

The two acts ship together: one round, one release.

Not in this: an account, telemetry, a forced tour, video, or a second
onboarding for someone who already has a library.

## 2. Shape, decided up front

| Question | Decision | Why |
|---|---|---|
| Where the deck shows | **Before the library picker**, full screen, over the open-library screen | Nothing about the app needs a library to be explained, and the answer must be known *before* the first library's settings are written |
| How long | 9 pages, one per theme; ~40 seconds read | A page per feature is a manual; a page per theme is an invitation |
| Skippable | **Always**, top right, and the last page's primary action is "Start writing" | Never forced (the issue's own requirement) |
| Markdown question | Last page, **three answers** | Two forces a guess; three matches how people actually answer ("never" / "a little" / "all the time") |
| What "never" does | Source editor **off** (`enabledEditors = {wysiwyg}`), live editor default | "Show the source editor or not" (the request): off, not merely not-default. Settings → Editor re-enables it in two taps, and the question's own subtext says so |
| What "a little" does | Both editors on, **live** default | They can write, but the markers should not be the first thing they meet |
| What "all the time" does | Both editors on, **source** default | Today's behavior; nothing changes for an experienced user |
| Where the answer lives | `app_settings` (device), applied to a library **the first time this device opens it** | The editors are device settings; the answer must not follow the library to another machine |
| Where the tour lives | After the first library is open, opt-in from the welcome's last page, and later from Help and the palette | The tour points at real controls: there must be a shell to point at |
| Tour playground | The **cheatsheet** (#265): it is opened, talked through, and can insert the example a step is about into a note the user picks | Nothing of the app's own is left in the library; the user keeps only what they chose to insert |
| Delivery | One round: the deck **and** the tour, in the same release | The tour's promise ("show me around") is the deck's last line; shipping the pause between them costs a release for no user |

## 3. The first run, step by step

```
app starts (no library to resume)
        │
        ├─ welcome_seen? ── yes ──▶ open-library screen (today's flow)
        │
        no
        ▼
WelcomeScreen (deck, 7 pages)
   page 1 … page 6: features, Back / Next / Skip
   page 7: the Markdown question + "Show me around" + "Start writing"
        │
        ├─ welcome_seen = true                  (written on leave, not on entry)
        ├─ markdown_experience = answer         (written as soon as it is tapped)
        └─ tour_offer = checkbox                (read after the first library opens)
        ▼
open-library screen   (unchanged: Open existing / Create new)
        │
        ▼
first library opens
        ├─ no device settings for this library yet?
        │     └─ seed editorKind + enabledEditors from markdown_experience
        └─ tour_offer?
              └─ the shell asks: "Show me around?" → TourOverlay runs (act two)
```

Existing installs: the migration that adds the column writes
`welcome_seen = 1` for every database that upgrades into it, so only a
fresh install (or the beta build's own application ID, which has its own
database) sees the deck.

## 4. The welcome deck

### 4.1 Frames

- Phone: full-bleed page, safe-area padded, body scrollable when the
  window is short; the controls pinned to the bottom.
- Desktop: the same page in a centred card, max width 720, so a 1440-px
  window does not turn six lines of prose into one line of 1440 px.
- Controls: `Skip` (top right) · dots (bottom left, with a semantics
  label: they are progress, not buttons — with nine pages a 48 dp target
  each does not fit a phone) · `Back` / `Next` (bottom right). On the
  last page `Next` becomes `Start writing`.
- Keys: ←/→ or PageUp/PageDown page, Esc skips. On Android, system back
  goes to the previous page; on page 1 it leaves the app (with the deck
  unfinished, so it comes back next launch).
- Motion: a slide + fade between pages, off under
  `MediaQuery.disableAnimations`.

### 4.2 The pages (copy is the shipped English; 37 locales follow)

**1 — Your notes are files.**
> Niman keeps your notes as plain Markdown files in folders you choose.
> One note is one `.md` file; everything the app shows is built from
> them. No account, no format of ours to get back in.

**2 — Three ways to write the same note.**
> Write the Markdown source, write it as it reads (the live editor), or
> read it. It is one note whichever you use, and you can switch per note
> or for the whole library.

**3 — Everything connects.**
> Wikilinks like `[[this one]]` find their note as you type. Tags,
> frontmatter and templates keep the parts you write over and over out of
> the way.

**4 — Find it again.**
> Full-text search across the library, a command palette for everything
> the app can do, and the quick note a keystroke away.

**5 — It goes with you.**
> Export a note or a whole folder as Markdown, HTML, a PDF or an EPUB
> book. Bring in a Notion export, or open an Obsidian vault where it
> already is.

**6 — Tasks and reminders.**
> A `todo.txt` you keep as a file — priorities, projects, due dates — and
> `rem:` alarms that warn you when something is due, on the phone and on
> the desktop.

**7 — Across your machines.**
> Point a library at a WebDAV folder — Nextcloud, ownCloud, a NAS — and
> edits sync both ways, merged line by line when two devices touched the
> same note.

**8 — Niman on this device.** (platform page, one of:)
> *Android:* Share text or a file into Niman from any app, keep a note on
> the home screen, and record a voice note instead of typing.
> *Desktop:* Tabs and split panes, the system tray, drag and drop onto
> the window, and `.md` files that open Niman.

**9 — One question.**
> **Have you written Markdown before?**
> `Never` · `A little` · `All the time`
> *This only sets how the app starts. You can turn any editor on or off
> in Settings → Editor at any time.*
> ☐ Show me around the app
> [ Start writing ]

### 4.3 The strings

New labels, in the order they ship (name → English):
`welcomeSkip`, `welcomeNext`, `welcomeBack`, `welcomeStart`,
`welcomePageOf(n, of)`, `welcomePage1Title/Body` … `welcomePage7Title/Body`,
`welcomeAndroidTitle/Body`, `welcomeDesktopTitle/Body`,
`welcomeQuestionTitle`, `welcomeAnswerNone`, `welcomeAnswerNoneHint`,
`welcomeAnswerSome`, `welcomeAnswerSomeHint`, `welcomeAnswerFluent`,
`welcomeAnswerFluentHint`, `welcomeQuestionNote`, `welcomeTourOffer`,
`welcomeTourOfferNote`. About **34** labels × 37 locales — the same
mechanical pass `notionImportTitle` took, done in the phase that
introduces them, never as an English fallback (the strings contract is
compile-time).

## 5. The Markdown question

| Answer | Stored | `editorKind` | `enabledEditors` | The user sees |
|---|---|---|---|---|
| Never | `none` | `wysiwyg` | `{wysiwyg}` | Notes open as they read; Settings → Editor shows the Source switch off, and turning it on is the whole step |
| A little | `some` | `wysiwyg` | `{source, wysiwyg}` | Live first, source one switch away in the note |
| All the time | `fluent` | `source` | `{source, wysiwyg}` | Today's default, unchanged |

**When it is applied.** `LibraryConfigStore.read()` already has the
moment: a library the device has never stored settings for takes the
file's device keys once. That branch gains the first-run defaults — the
stored answer's `editorKind`/`enabledEditors` — so the seeding is part of
the same write, is never re-applied (the row exists afterwards), and
never touches a library this device has opened before. A library opened
by an older build keeps what it has.

**Where the user changes it later.** Settings → Editor's two switches
(already there, `SettingsKeys.editorSource` / `editorWysiwyg`), plus the
in-note mode switch. The question's subtext names the settings path on
purpose.

## 6. Act two — the guided tour

### 6.1 How it runs

- A `TourController` (Riverpod) owns the step list for the current
  platform and the answers to (a) the source editor being offered and
  (b) the shell layout (wide/narrow), and walks them.
- `TourOverlay` sits in the shell's `Overlay`: it dims everything, cuts a
  rounded hole over the step's target, and puts a card beside it with
  `Back` / `Next` / `Skip`, a step counter and `Don't show again`.
- Targets are looked up through a `TourTargets` registry: a widget that
  can be pointed at wraps itself in `TourTarget(id)` (a
  `GlobalKey`-carrying wrapper, the way `HighlightRow` already owns the
  settings rows' keys). A missing target — a hidden rail, a dock that is
  not there, a source toggle the user turned off — **skips the step**
  instead of pointing at nothing.
- Dropping out mid-tour is fine: `tour_step` is remembered, and the
  palette's *Help: Take the tour* offers "continue" or "start over".
- The overlay never blocks input outside the hole when the step says
  "try it" (a step may end with the user's own click, e.g. opening the
  palette, and advance when that control is used).

### 6.2 The steps

Desktop (wide):

| # | Points at | Says |
|---|---|---|
| 1 | the tree | the library is this folder; this is the tree |
| 2 | the + menu / FAB | new note, list, voice, template, folder |
| 3 | the mode switch | source / live / read, and that it is one note (skipped or shortened when the source editor is off) |
| 4 | the toolbar | formatting, the context menu, the cheatsheet |
| 5 | the cheatsheet's own rows (opened in a pane) | wikilinks and backlinks, tags and frontmatter — each with its example, insertable into a note the user picks |
| 6 | search | full-text, tags, `key = value` |
| 7 | the palette | commands and notes in one place; pinned commands |
| 8 | the dock | outline, tags, history |
| 9 | the journal / templates | one note a day; what a template fills in |
| 10 | the trash | soft delete, restore, history |
| 11 | the Todo tab | `todo.txt`, priorities and `rem:` reminders |
| 12 | Settings → Editor/Commands | where editors are chosen; commands vs keyboard shortcuts |
| 13 | Settings → Sync | WebDAV, per library |
| 14 | the tray / quick note | the quick note; the tray on the desktop |
| 15 | done | where the cheatsheet lives (the palette, the note's ⋮ menu), and the end |

Android (narrow): the same ground with the phone's controls — the bottom
bar, the notebook FAB and its sheet, the keyboard toolbar, the note's ⋮
sheet, the open-notes switcher, share-in, the home-screen widget, voice
notes and reminders, Settings → Maintenance.

The exact per-platform list is written down in `tour_steps.dart` as
data (target id, title, body, advance-on-use), so the set is reviewable
and testable without a device.

### 6.3 The playground: the cheatsheet

The tour writes nothing of its own. Its content steps open the
**cheatsheet** (#265) — every construct, written beside how a note shows
it — in a pane, point at the row being talked about, and offer its
**Insert** action: the example lands in the note the user has open (or
in one they pick), which is what makes the next steps (the wikilink's
backlink, the tag in the tag list, the table as a table) real.

A step whose content is not there — an empty library, a cheatsheet row
out of view — still explains itself; what it must never do is create a
note nobody asked for. Nothing is written, and nothing has to be cleaned
up afterwards.

## 7. Coming back to it

- **Help:** Settings → About gains a `Welcome tour` row (the changelog's
  neighbour) that reopens the deck? No — the deck is once; the row runs
  the **tour**. The deck stays reachable in Settings → About as *What
  Niman can do* for anyone who wants the pages again.
- **Palette:** two commands — `Help: Take the tour` (or *Continue the
  tour*) and `Help: What Niman can do` (the deck, read-only: the question
  is not asked twice and never rewrites an existing library).
- **Never re-prompted:** `welcome_seen`/`tour_seen` are the only gates;
  no timed second offers, no "are you sure".

## 8. Data & storage

`AppDatabase` v31 (`app_settings`, one row):

| Column | Type | Default | Meaning |
|---|---|---|---|
| `welcome_seen` | bool | `0` | The deck has been finished or skipped; the migration sets `1` for every upgrading install |
| `markdown_experience` | text nullable | null | `none` / `some` / `fluent`; null = never asked |
| `tour_seen` | bool | `0` | The tour was finished or dismissed with "don't show again" |
| `tour_step` | int | `0` | Where the tour stopped, for *Take the tour* |
| `tour_offer` | bool | `0` | The welcome's "show me around" checkbox, read when the first library opens |

`AppSettingsRepo` gains the getters/setters (one row, `_ensureRow`, the
existing pattern), and `test/unit/database_migration_test.dart` gains the
v30 → v31 case (columns added, `welcome_seen = 1` for an upgrade, `0` for
a fresh database).

The editor seeding is *not* a new store: `LibraryConfigStore.read()`'s
"device has never stored settings for this library" branch merges the
answer's two keys into what it writes. Its input, a
`Map<String, Object?>`-producing callback, is handed to
`LibraryConfigRepo` where the controller builds it (it has the app DB),
and is `null` in tests/tools — the file's own values then rule, exactly
as today.

## 9. Where the code goes

New:

- `lib/src/core/welcome.dart` — `MarkdownExperience` enum, `WelcomeStatus`
  (seen/answer/offer), `WelcomeStore` over `AppSettingsRepo`, and the
  pure mapping answer → `editorKind`/`enabledEditors` (unit-testable).
- `lib/src/ui/welcome/welcome_gate.dart` — watches the store, shows the
  deck until seen, then the open-library screen/shell unchanged.
- `lib/src/ui/welcome/welcome_screen.dart` — the deck: pages, controls,
  keyboard, back handling.
- `lib/src/ui/welcome/welcome_pages.dart` — the page data (title, body,
  platform condition), so copy and order are one table.
- `lib/src/ui/welcome/welcome_question.dart` — the last page's question
  and the "show me around" offer.

Touched:

- `lib/src/db/app_database.dart` (+ `.g.dart`) — v31, the five columns.
- `lib/src/core/settings/library_settings.dart` — the repo's accessors.
- `lib/src/core/settings/library_config.dart` — the first-open seeding
  branch.
- `lib/src/library/library_state.dart` — build the seeding callback in
  `open()` from the app DB; hand `tour_offer` to the shell.
- `lib/src/ui/shell.dart` — the gate in the wrapper that switches between
  `OpenLibraryScreen` and `_LibraryShell`; the tour offer after a library
  is ready; the two palette commands; the About row.
- `lib/src/ui/app_shortcuts.dart` + `settings_search.dart` — the new
  commands and their rows.
- strings ×38, `test/fakes/…` where a new provider needs a fake.

Phase two only: `lib/src/ui/tour/{tour_controller,tour_overlay,tour_steps,tour_targets}.dart`,
`lib/src/library/tour_notes.dart` (the sample notes), the `TourTarget`
wrappers in the tree/footer/FAB/dock/toolbar/palette.

## 10. Tests

The deck:

- `test/unit/welcome_test.dart` — the answer → editors mapping; the store
  round-trip; the migration's `welcome_seen` for an upgrade; the seeding
  applies once and never overwrites a stored choice.
- `test/widget/welcome_screen_test.dart` — page navigation (tap, keys,
  back), Skip, dots, `welcome_seen` written on leave, the answer saved on
  tap, "Start writing" → the open-library screen; and the whole path into
  a library: answer *Never* → the note opens in live mode and Settings →
  Editor shows Source off.
- `test/widget/settings_layout_test.dart` — the new About row is findable
  and the palette command is listed (the "every entry points at a row
  that is really there" test).
- `integration_test/app_boot_test.dart` — pre-seeds `welcome_seen` (the
  deck would otherwise stand in front of the screen it asserts), and one
  new headless case asserts the deck appears on a fresh database and
  leaves.

The tour:

- `test/unit/tour_steps_test.dart` — the step list per platform and per
  `enabledEditors`; no step names a target the shell does not register.
- `test/widget/tour_overlay_test.dart` — the spotlight's rect follows the
  target, a missing target skips the step, Next/Back/Skip, "don't show
  again", resume from `tour_step`.
- `test/widget/tour_cheatsheet_test.dart` — a content step opens the
  cheatsheet, points at its row, and inserts only when the user asks;
  no note is created by the tour alone.

## 11. Docs

- `docs/user/getting-started.md` — the first-run flow (deck, question,
  where the editors land), and a line that the tour is under Help.
- `docs/user/editing.md` — the mode section gains a note that a fresh
  install's default comes from the welcome's answer, and how to change it.
- `docs/user/settings.md` — `welcome`/`tour` are app settings, not library
  ones; the Editor rows already document the two switches.
- `docs/user/platforms.md` — the platform page of the deck and the
  platform tour differ, and what each shows.
- `docs/dev/architecture.md` — `ui/welcome/`, `ui/tour/`, `core/welcome.dart`.
- `README.md` — a line in the feature list (the tour, and that the first
  run offers it).
- `CHANGELOG.md` at the release that ships the round.

## 12. Edge cases

- **A library already open when the deck is due** (a resume on the very
  first launch after installing over an old build): the migration's
  `welcome_seen = 1` already answers it — the deck never stands in front
  of a resumed library.
- **Killed mid-deck:** the deck returns next launch; the answer already
  given is kept.
- **Answered but no library yet:** the answer waits; if another library is
  created first, that one takes it (its first open on this device).
- **Two devices, one library:** each seeds its own editors, or none if it
  has opened it before — the settings file is not touched by the seeding
  (`deviceKeys` are not written back to it).
- **Beta/testing build:** its own application ID and database, so the deck
  and the question are testable there without disturbing the release.
- **Narrow landscape / keyboard:** body scrolls, controls stay reachable;
  the deck is never taller than the window's safe area.
- **The tour meets a user's layout:** hidden rail, closed dock, source
  editor off — steps with no target are skipped, and the step list is
  built after the layout is known.
- **The tour meets an empty library:** the cheatsheet still opens, and
  its Insert action makes the note the following steps point at. Nothing
  is created until the user taps Insert.

## 13. Delivery and what each part closes

**One round: the welcome deck and the guided tour together** (the
agreed shape). Internally the work is ordered deck → cheatsheet wiring
→ tour, and no
release is cut between them.

**The deck** (this document's §3–§5, §8–§9).
AC: a fresh install shows the deck once, before the library picker;
every page is skippable; the last page's answer sets the first library's
editors as the table says; an upgrading install never sees it; the deck
is reachable again from Settings → About and the palette.

**The guided tour** (the issue's own body, §6–§7).
AC: offered from the welcome's last page and re-runnable from Help and
the palette; each step points at a real control (a missing one skips the
step); the phone and the desktop each get their own list; the cheatsheet
is the playground and nothing is written without the user's Insert;
`tour_seen` and `tour_step` survive a restart.

**Together:** `flutter analyze` clean, the tests of §10 green, one
headless integration case for the fresh-install path, and a device pass
on Android and Linux for the deck's pages and the spotlight geometry.
Mockups land in this folder as they are drawn.

## 14. Decisions (agreed 2026-09-26)

1. **The deck runs before the library picker.** Nothing in it needs a
   library, and the answer must exist before the first library's settings
   are seeded.
2. **Three answers** for the Markdown question: `Never` / `A little` /
   `All the time`.
3. **`Never` hides the source editor** (`enabledEditors = {wysiwyg}`),
   with the settings path named on the question itself.
4. **The cheatsheet is the tour's playground**; no sample notes.
5. **Sync and tasks get pages of their own** (5 pages became 7); the
   platform page keeps share-in, widgets and voice notes on Android and
   the tray, tabs and drag and drop on the desktop.
6. **Everything ships with the tour** — one round, one release.

## As built (2026-09-26)

The round shipped as one delivery — deck, question, seeding and tour —
and the pieces stand where the plan put them. What differs, and why:

- **The dots are progress, not taps** (§4.1): nine of them at a 48 dp
  target each do not fit a phone; `Back`/`Next` (and the arrow keys) are
  the way through.
- **No "Don't show again" on the card.** `Skip` leaves the tour where it
  is (the palette's *Take the tour* resumes), the last step's `Done`
  marks it seen, and the offer is spent the moment it is shown — the
  tour stays in Help and the palette, and is never raised on its own
  again.
- **A finished tour starts over.** `tour_step` goes back to 0 with
  `tour_seen`, so *Take the tour* resumes a tour left halfway and runs a
  finished one from its first step.
- **The last step opens the cheatsheet and ends the tour.** The card's
  button closes the overlay, opens the cheatsheet and marks the tour
  done, which is the hand-over the plan asked for without a second
  overlay over a screen it no longer belongs to.
- **The overlay is watched, not tried in.** Every tap goes to the scrim,
  the hole included: the steps that hand the user a control (§6.1) are
  not in this round, and nothing behind the tour can be edited by
  accident.
- **The copy started in `ui/welcome/welcome_copy.dart`, in English.**
  The deck and the tour are ~56 labels, and `ui/strings/` is
  compile-time complete across thirty-seven locales: the first round
  left onboarding prose in English rather than ship machine
  translations. [#308](https://github.com/Nihmar/Niman/issues/308)
  folded them into `AppStrings` (`welcome*`/`tour*`), so the deck and
  the tour now resolve in every locale the app speaks; the call sites
  read `AppStrings` directly and `ui/welcome/welcome_copy.dart` is gone.
- **Steps:** eight on a wide window (tree, create, note, modes, toolbar,
  tabs, dock, cheatsheet), seven on a phone (no dock step — the note's
  menu has the same three panes), and the modes step only when the
  library offers both editors.
- **Entries:** the deck reopens read-only from Settings → About (*What
  Niman can do*) and the palette; the tour from Settings → About
  (*Take the tour*), the palette, and the welcome's own offer once a
  library is open.
