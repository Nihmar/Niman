# Features

**Settings → Library → Features** is a switchboard for the open library:
what it uses. A feature turned off is gone from every place it showed —
the rail and the bottom bar, the command palette, the keys, the menus, the
toolbar, the Insert sheet, the Home, Settings — and its background work
stops. A library that only holds notes can be just that.

The switches belong to the library. They are kept in its
`.niman/settings.json` (the `features` key), so they travel with the
folder and with [sync](sync.md); a phone and a desktop opening the same
library see the same ones.

## Off is inert

Turning a feature off never deletes, moves or rewrites a note, a state
file or a setting. Turning it on again is the whole undo.

- A note of a kind that is off opens as plain Markdown in the editor and
  keeps its `type:` line. The tree shows it with the generic note icon.
  Turn the kind back on and its view is back.
- `todo.txt` and `calendar.txt` stay plain files, `.niman/review.json`
  stays where it is, and the scans and annotations already made stay.
- Navigation's order and visibility are not touched: see
  [what each surface does](#what-each-surface-does).
- There is no switch per note. A note that wants to be plain Markdown
  drops its own `type:`.

## The switches

Core never switches off: Files, the editor, notes and folders, links,
properties, tags, attachments, export, settings, themes and language, the
palette and the keys, updates, the debug log, the trash and the version
history. [Sync](sync.md) is not a feature either: it is already per
library and per device, and off until a server is connected.

| Section | Switch | Off means |
|---|---|---|
| Finding and writing | Search | No search screen or commands. The index is still kept up to date, so turning Search on again is instant |
| | Quick note | No quick note. Text shared from another app becomes a new note instead |
| | Templates | No *new from template* in the menus; new notes, journal entries and Home actions start with their default, whatever template is set |
| | Web capture | No page capture; links stay plain links |
| Planning | Todo and reminders | `todo.txt` stays a plain file; no task reminders |
| | Journal | Entries stay ordinary notes |
| | Calendar | `calendar.txt` stays a plain file; no event reminders |
| Note kinds | Lists | List notes open as plain Markdown |
| | Shopping lists | The same. Needs Lists |
| | Audio notes | The same |
| | Transcription | No *Transcribe*; audio notes still record and play. Needs Audio notes |
| | Slides | The same as the other kinds |
| | Flashcards and Study | The same; there is no Study |
| | Kanban boards | The same as the other kinds |
| Reading | PDF and EPUB readers | A PDF or a book opens in the system's app |
| | Annotations | No annotating or highlighting; the companion notes stay. Needs the readers |
| | Text recognition | No scanning; the text already read stays. Does not need the readers |
| Around the app | Home | No Home |
| | Home-screen widgets (*Android*) | The widgets say this is off |

A switch that needs another one is greyed while that one is off, with
*Needs …* under its name. It keeps its own value: turn Audio notes back on
and Transcription is back as it was. The row's line under the name says
what off means, as the table does.

## The presets

A strip of presets sits pinned above the list. A preset only sets the
switches — afterwards the library is just a set of them, and you can flip
any.

- **Everything** — the default: every switch on.
- **Writing** — notes, Search, Templates and the readers.
- **Notes only** — notes and Search.
- **Tasks & journal** — Todo, Journal, Calendar and Home.

**Custom** is always the last chip. It is dimmed while the switches match
a preset and selected when they match none.

## What each surface does

- **Palette, keys and menus.** A command of a feature that is off is not
  offered and does not fire from its key. When a palette query matches only
  such commands, a quiet line under the key hints says *Todo is off in this
  library*, with a link to Features. **Settings → Commands** lists them
  greyed, with *Off in Features*.
- **Navigation and settings.** A
  destination is shown when its feature is on *and*
  [Navigation](settings.md#navigation) does not hide it. Turning a feature
  off writes nothing to the navigation setting, so turning it on restores
  the order and visibility you had. In **Settings → Navigation** the
  row stays in its place, greyed, *Off in this library*, with
  **Off in Features ›** where its switch was. The settings areas of a
  feature that is off are not listed, and the settings search does not find
  their rows: Journal, Study, Transcription and Text recognition each
  follow their own switch, and Reminders goes only when Todo and Calendar
  are both off.
- **Home.** A tile or button of a feature that is off is not drawn, and the
  Home's file is not touched. With Home off there is no Home.
- **Reminders.** Turning Todo or Calendar off cancels the alarms already
  scheduled for it. A snackbar says how many (*3 reminders cancelled*) and
  offers **Undo**, which turns the feature back on. Turning it on
  schedules them again from the file. Nothing is scheduled while it is off.
- **Downloads.** The text-recognition engine and the transcription models
  are not downloaded while their switch is off.
- **PDF and EPUB.** With the readers off, a PDF or a book opens as a pane
  that names the file and offers **Open in default app**, on Linux,
  Windows and Android alike. On Android the file is handed over through a
  read-only grant for that one start. Pictures are shown whatever the
  readers say.
- **Shortcuts, notifications and widgets.** A launcher shortcut, a
  reminder notification or a widget tap that leads to a feature that is off
  opens one sentence, *Todo and reminders is off in this library*, with
  **Open Features**. An Android widget of a feature that is off says the
  same on the home screen and opens Features when tapped.
- **Shared text.** With Quick note off, text shared from another app
  becomes a new note rather than going to the end of the quick note. With
  Web capture off, a shared link is plain text.

## The first time

A library that existed before the switches did opens Settings → Features
by itself once, on the first *normal* open — the library picker, the
switcher, or the last library at launch. A card above the presets
explains the screen; everything is on, and **Done** closes it. Opening
from a share, a widget, a notification, a reminder, a launcher shortcut
or a file does not trigger it: it waits for the next normal open.

It is shown once per library. That is remembered in the library's
settings (`featuresReviewed`) when the screen is *left* — **Done**, back
or `Esc` — never when it opens, so a library closed with the card up shows
it again. Because it syncs, a second device does not ask again. A feature
a later version adds is born on and simply appears: there is no new
prompt.

A library just created asks *What is this library for?* instead, with the
four presets as large cards and **Everything** picked. Pick one, flip any
switch below it, and go on.

**Show this introduction again**, at the foot of the screen, shows the card
again. It changes no switch.
