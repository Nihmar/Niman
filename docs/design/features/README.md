# Features — the screens, and the decisions

The mockups #1109 was agreed against (2026-10-19), before any code: five
desktop screens and four phone screens, in `html/`. They are drawn to look
like Niman, in the Night palette of `lib/src/ui/theme/niman.dart`; where a
mockup and the app disagree, the app is what ships. The plan the work
follows — the model, the gating seam, the phases and the tests — is
[docs/records/library-features.md](../../records/library-features.md).

**Features** is a per-library switchboard: what this library uses. A group
turned off is gone from every surface — destinations, palette, keys, menus,
toolbar, Insert sheet, dock, Home, Settings — and its background work
stops. Nothing in the library's files is changed or deleted by a switch.

| Screen | Desktop | Phone |
|---|---|---|
| The area: the presets strip pinned on top (**Custom** selected, since the switches match no preset), the groups in cards, each row its icon, its name, what *off* means and its switch; **Audio notes** off, so **Transcription** greyed with *Needs Audio* and its own value kept; **Todo and reminders** just turned off, and the snackbar saying three reminders were cancelled, with **Undo** | [Desktop-1-Features](html/Desktop-1-Features.html) | [Phone-1-Features](html/Phone-1-Features.html) |
| The first normal open of an existing library after the update: the area opened by itself, the introduction card above the presets, **Everything** on, **Done** | [Desktop-2-Introduction](html/Desktop-2-Introduction.html) | [Phone-2-Introduction](html/Phone-2-Introduction.html) |
| A library just created: *What is this library for?*, the four presets as large radio cards in place of the chip row, **Notes only** picked and the switches below already following it | [Desktop-3-NewLibrary](html/Desktop-3-NewLibrary.html) | [Phone-3-NewLibrary](html/Phone-3-NewLibrary.html) |
| Settings → Navigation with Todo's feature off: the row in its place, greyed, *Off in this library*, the link **Off in Features ›** where the switch was; the rail preview without Todo | [Desktop-4-Navigation](html/Desktop-4-Navigation.html) | — (the same rows) |
| The command palette asked for `todo`: only notes come back, and a quiet line under the key hints says *Todo is off in this library · Features ›* | [Desktop-5-Palette](html/Desktop-5-Palette.html) | — (the same palette) |
| The Android home screen: the Todos widget in its off state (*Todo is off in this library*, **Open Features**), the Study widget beside it working as ever | — | [Phone-4-Widget](html/Phone-4-Widget.html) |

## The groups

Core, never switchable: Files, the editor (source, live, read), notes and
folders, links and backlinks, properties, tags, attachments, export,
settings, themes and language, the palette and the keys, updates, the
debug log, **trash** and **version history**.

| Section | Row | Off means | Needs |
|---|---|---|---|
| Finding and writing | Search | no search screen or commands; the index is still written | — |
| | Quick note | no quick note; shared text goes to Import | — |
| | Templates | new notes and journal entries start with their default | — |
| | Web capture | no page capture; links stay plain links | — |
| Planning | Todo and reminders | `todo.txt` stays a plain file; no reminders | — |
| | Journal | entries stay ordinary notes | — |
| | Calendar | `calendar.txt` stays a plain file; no event reminders | — |
| Note kinds | Lists | these notes open as plain Markdown; `type:` is kept | — |
| | Shopping lists | the same | Lists |
| | Audio notes | the same | — |
| | Transcription | no transcribe action; audio notes still record and play | Audio notes |
| | Slides | the same as the other kinds | — |
| | Flashcards and Study | the same; `.niman/review.json` is kept | — |
| Reading | PDF and EPUB readers | they open in the system app | — |
| | Annotations | no annotate or highlight; the companion notes stay | Readers |
| | Text recognition | no OCR; the scans already made stay | — |
| Around the app | Home | no Home | — |
| | Home-screen widgets (*Android*) | the widgets say this is off; no data written for them | — |

## Decided with them

- **The name is Features, the place the Library group of Settings**, its
  first row. Per library, like the rest of that group; not a fourth group.
- **Off is inert, never destructive.** No switch deletes, moves or
  rewrites a file or a setting. A note of a kind that is off opens in the
  plain editor, keeps its `type:`, and wears the generic note icon in the
  tree; turning the kind back on brings its view back. No migration.
- **No per-note override.** The switch belongs to the library; a note that
  wants to be plain Markdown drops its own `type:`.
- **Reminders are cancelled, not left firing.** Turning off Todo or
  Calendar cancels the alarms already scheduled — the snackbar says how
  many, and **Undo** turns the feature back on — and turning it on
  schedules them again from the files. A widget whose feature is off shows
  that it is off and opens Settings → Features.
- **A PDF or an EPUB with the readers off opens in the system app**, like
  any attachment the app does not show.
- **Dependencies grey, they do not cascade.** A child whose parent is off
  stays where it is, disabled, with *Needs …* for its line, and keeps its
  own value: turning Audio back on brings Transcription back as it was.
  What counts is the parent and the child both on. Shopping lists need
  Lists (the two views swap from the same ⋮); Text recognition does not
  need the readers (images are recognised without them).
- **Sync is not a feature.** It is already per library *and* per device,
  and off until a server is connected; a switch in `settings.json` would
  travel with the very sync it stops. Connect and Disconnect stay in
  Settings → Sync, and no preset touches it.
- **The presets.** Everything (the default), Writing (notes, search,
  templates, readers), Notes only (notes and search: everything else off,
  templates and readers too), Tasks and journal (todo, journal, calendar,
  Home). A preset only writes the switches. The strip is pinned over the
  area so it stays in reach while the list scrolls; **Custom** is always
  its last chip, dimmed while the switches match a preset and selected
  when they match none, so the row never moves under the pointer.
- **Navigation is two layers.** A destination shows when its feature is on
  *and* Navigation does not hide it; turning a feature off writes nothing
  to `navigation`, so turning it on restores the order and the visibility
  the user had. In Navigation the row keeps its place, greyed, with
  **Off in Features ›** where its switch was.
- **The areas follow the switches.** Settings drops the area of a feature
  that is off — Transcription with Audio off, Study with flashcards off,
  Reminders only when Todo and Calendar are both off — and so does the
  settings search. The rail behind the window follows Navigation's rule.
- **The palette says why it found nothing.** A query that matches only
  commands of a feature that is off lists no command, and a quiet line
  under the key hints names the feature and links to Features.
- **The introduction is once per library, in the library's settings.**
  `featuresReviewed` in `.niman/settings.json`: set when the screen is
  left (Done, back, `Esc`), not when it opens, so a crash or a kill shows
  it again; it syncs, so a second device does not ask again. Only a normal
  library open triggers it — a share, a widget, a notification, a
  reminder or a deep link opens its target and leaves the flag as it was.
  A library created by the new build sees it at creation, as *What is this
  library for?*, the presets as large cards in place of the chip row. A
  boolean, no re-prompt when a later build adds a group: the new group is
  born on and simply appears. **Show this introduction again** at the foot
  of the area shows the card and changes no switch.
- **The Android widgets row shows on every platform**, tagged *Android*:
  the setting travels with the library and acts where widgets exist.
- **Every string in all 37 languages, in the same change** as the screen.
- **All the groups ship together**, gated on every surface before the
  screen is released — not a first round of the cheap ones.
- **Phone frames are 360 × 800** here; the earlier mockups are 390 × 844.
