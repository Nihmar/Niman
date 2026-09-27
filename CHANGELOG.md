# Changelog

All notable changes to Niman, newest version first.

This file ships inside the build and feeds the in-app changelog (the
launch dialog after an update and the screen under Settings → About).
Update it in the release commit, before the tag.

## [0.1.3] - 2026-09-27

Say what a frame costs.

A slow frame on a large note now says where its time went — the edit
path, the build, the layout and the paint, per view and per pane — so
the next round is spent on the part the log blames instead of on the
one it guesses. And three reports became fixes: the crash on the first
launch after an update, a to-do token suggestion that ignored the
click, and saves that stopped when the folder the app was started from
was gone.

### Changed
- **Opening a library warms the index connection while the rest of the open runs.** The tree's first frame used to spend its whole ~50 ms on the index's first query — the one that opens the sqlite file, its schema and its FTS table. The connection is now asked for at the very start of the open, so the warm-up's ~160 ms of device log overlaps the open itself instead of its tail, on the connection's own isolate, and reports itself as `index warm-up: N ms`
- **A slow frame is followed by the parts of it.** The debug log (*Settings → Diagnostics*) puts a line beside `[frames] slow frame` for each view that spent the frame — the editor's `[edit] keystroke frame: edit …, build …, layout …, paint …` and the read pane's `[read] read pane frame: …` — the frame's own number and the view's line adding up to the split, and what is left over being the shell's. Only the frames that miss their budget are written, and a view whose line has no edit in it is a frame nobody typed into

### Fixed
- **The first launch after an update no longer crashes.** The welcome gate, the update notice and the session each opened their own connection to `niman.db` and migrated it at once on the first run after an update: one added a column, another's `ALTER` came out as `duplicate column name` (the phone's crash reports). One connection is handed out now, the upgrade runs under the file's write lock in a single transaction with the version stamped inside it, and a step that throws rolls the whole migration back instead of leaving the file half stepped through
- **A `+project`, `@context` or `#tag` suggestion inserts when it is clicked**, on the desktop: the platform unfocused the field on the pointer *down*, and the rebuild that followed took the suggestion away before the pointer *up* could fire
- **A save no longer needs the folder the app was started from.** With the app started from the folder the release bundle lives in — and that folder replaced by a build while it ran — every write failed with `PathNotFoundException: Getting current working directory failed`, a crash report written into the open library per failure. The temporary name is cut from the path it is given now, and the platform style is asked for once, explicitly

## [0.1.2] - 2026-09-27

Let's go to the mall!

The list note learned to be a shopping list — a quantity per item, the
same file, and a switch in the note's ⋮ that goes both ways — and its
rows delete themselves now, with an Undo, while the list follows what
you add.

### Added
- **A shopping list is a list note turned.** *⋮ → Shopping list* on an open list note, *⋮ → Checklist* to come back: only the frontmatter's `type` changes, so the file, its name and its lines stay what they were and a round trip loses nothing. Every row carries a `×N` pill — a tap edits just the quantity, and the in-place edit shows the name and the number side by side — the add row has its own quantity chip with a stepper and quick counts, and a typed `latte x2` is read as quantity 2. The quantity is part of the item's text (`- [ ] Latte ×2`, whole numbers, and one is never written: `- [ ] Pane`), so the note stays plain Markdown. The home-screen widget shows a shopping list with its quantities
- **A row can be deleted.** The trash at the end of every row removes the item and its sub-items at once, and the snackbar's Undo puts the whole block back. The trash keeps its place while the row is being edited, so nothing moves under the thumb already on the row
- **An item's text scrolls when it is longer than its row**, as a note's name already does in the tree and the title bar

### Changed
- **Adding an item scrolls the list to it.** The add field sits under the viewport's foot, so a new row used to land out of sight until you scrolled by hand

## [0.1.1] - 2026-09-26

Show me around.

A fresh install opens on the app itself: what Niman is, one question
about Markdown that decides how the first library writes, and a guided
tour that points at the real controls, one step at a time.

### Added
- **A welcome on the first run.** Nine pages on what Niman is — notes as files, the three ways to write one, links and templates, search, export and import, tasks and sync, and what this device adds — and then one question: *Have you written Markdown before?* The answer only decides how your first library starts, and Settings → Editor has the switches whenever you change your mind. The deck is shown once, and opens read-only again from Settings → About (*What Niman can do*) or the palette
- **A guided tour, pointing at the real controls.** The tree, the create menu, the note and its tabs, the three editor modes, the toolbar, the navigation and the dock: each step dims the app, spotlights the control it talks about and says what it is for. A step whose control is not on this screen — no dock on a phone, no source switch in a live-only library — is skipped rather than pointing at nothing, and the last step hands over to the Markdown cheatsheet. Offered once by the welcome, resumable where it stopped, and always there from Settings → About (*Take the tour*) or the palette
- **A library this device opens for the first time takes its two editors from the answer.** *Never* starts in the live editor with the Markdown source not offered, *A little* starts live with both, *All the time* (or a skipped question) is today's source default — never overwriting a library's own choice, and only until you change it in Settings → Editor

## [0.1.0] - 2026-09-26

Notes in, notes out.

Your notes leave as files anyone can open — Markdown, a page of their
own, a print-ready PDF, a whole book as EPUB — and arrive from wherever
they were: a Notion export, an Obsidian vault, another app's share menu.
And underneath, the library learned to walk a million notes without
holding them all at once.

### Added
- **A note as a PDF.** *Export → PDF* prints the note through the machine's own browser — Edge on Windows, a Chromium-family browser on Linux, the system WebView on Android — so its text stays selectable and searchable: A4, pictures and formulas in place. Where no browser is, Niman says so before it starts and draws the pages itself instead, a picture of them that still holds the note's pictures, and the drawing can be stopped
- **A note, a folder, the library as EPUB.** A book out of Markdown: a cover and metadata from the frontmatter, a chapter per note anchored to `index.md`, the math typeset, a working dialog with a stop button
- **A Notion export, imported.** Notion's *Markdown & CSV* zip lands as a new folder of the library — the page ids off every file name, the links between pages rewritten to the names they now have, pictures and attachments kept, the database `.csv`s and the hidden files dropped. From *Settings → Maintenance → Import Notion export*, from sharing the zip to Niman on Android, or from dropping it on the desktop window
- **An Obsidian vault, opened.** Pick the vault folder when opening a library and Obsidian's own syntax reads as it stands: `[[wikilinks]]` and their `|aliases`, `[[folder/note]]` paths, `![[image.png]]` embeds resolving their attachment by name, frontmatter and `#tags`
- **Sharing into Niman on Android.** Another app's share menu offers it now: text lands at the end of the quick note — or waits for the choose/create screen when none is set — a `.md` is imported into the library and opened, and a Notion export is imported
- **The Markdown tidy's rules are yours to choose.** *Settings → Editor* lists what the tidy fixes, each on or off
- **The right dock resizes** by dragging its edge, and **desktop tree rows** are drawn compactly with a menu made for the pointer

### Changed
- **A full scan reconciles one directory at a time.** First open, re-index and the periodic rescan no longer hold every index row, the whole disk walk and every changed note in memory at once: the peak is the largest folder, not the library. At a million notes the old scan took about a gigabyte to itself; the rescan of an untouched library now takes none of it

### Fixed
- **The in-app update installs the official app again.** 0.0.10's release page carried the testing build beside the official APK, and the updater took the testing one — a different application ID, which installs *beside* the app that asked — so Android auto-update is fixed by not publishing it (and by refusing a `-testing` name in the updater itself)
- A heading typed at the end of a note no longer hangs the editor on a phone
- An inline formula with spaces in its source reveals its `$…$` instead of staying stuck
- The touch handles and their menu no longer flash at a stale place; a revealed mark starts on the note's margin
- A re-index closes the tabs of the notes it really pruned, and leaves a renamed note's tab open
- Ctrl+F and Ctrl+H work in the single-file editor
- A live table's row no longer wraps off its columns

## [0.0.9] - 2026-09-25

A homegrown editor, and a lot more to play with.

The source editor, the live (WYSIWYG) editor and the read view are one widget of Niman's own now — and around it, the round that reads books and PDFs, annotates them, keeps a journal, and lets you wear colors of your own.

### Added
- **Books, read in the app.** An EPUB opens in the note pane on every platform and reads like a note — its headings, emphasis, lists, quotes, tables and pictures in Niman's typography — with an **Outline** of its table of contents. A PDF and a picture open there too, paged and zoomed, and the row under a PDF or a book copies a link to the place being read
- **A book or a PDF opens where you left it.** Its page, or its chapter and the line in it, is kept for the library and syncs with it, so a book put down on the phone opens on the desktop where the phone stopped
- **Annotate a passage.** Selecting one in a book or a PDF opens a sheet; saving writes a section into a companion note that quotes it and links back to the place. The file shows where it was annotated — tap a mark to open its annotation
- **Links into a book or a PDF**: a link opens the file at the page or the chapter it names, instead of where you left it
- **A journal:** one note a day, made the first time you open that day, from a folder, a name and a template you set, with a month calendar, a strip over an entry for the day before and after, the tasks due on the day, and quick actions for today's entry
- **Themes of your own:** a Themes page where you make one from any shipped palette or a random hue, edit its colors with the whole app wearing them as they move, duplicate, rename and delete it, and export or import it as a `.json` file. Niman, Catppuccin, Solarized and Gruvbox ship beside the system's own colors
- **One Markdown surface.** The source editor, the live (WYSIWYG) editor and the read view are one widget, written for the app: the note on disk is the same text whichever you write in, and switching modes no longer moves the page. The size cap the old WYSIWYG had is gone
- **Callouts (`> [!note]`) and `==highlight==`** are read in every mode
- **Tables, edited as tables** in live mode: rows and columns added, moved, aligned, sorted and deleted from a cell's own menu, and Tab from cell to cell
- **Insert a table and a checkbox list** from the toolbar and the context menu; the context menu is grouped by what you are doing — links, Format, Paragraph, Insert, the clipboard
- **An in-app Markdown cheatsheet**: every construct Niman reads, each written beside how a note shows it, to copy or insert
- **Titles that scroll** when they are too long for their room — a tree row, a tab, the window title, the phone's note bar
- **Forget a library**, the one open included, from its row's menu — the folder, its notes and its settings stay where they are

### Changed
- **The template commands** (`{{date}}`, `{{ask}}`, …) are coloured in the template folder, in a color of their own in the theme
- **`todo.txt` and `done.txt`** open in the editor coloured as task lists: priority, dates, projects, contexts and `key:value` tags, with a completed task struck through. The colors are the theme's, under *Task lists (todo.txt)*
- **The changelog's bullets** are drawn as the Markdown they are written in, in the update dialog and under Settings → About
- **Settings → Commands** says it is the palette's reference, and the keys it shows follow Keyboard shortcuts
- **The task dialog** on a window with the room picks the due date and the reminder in place, under their rows, and its description wraps and grows downward
- **A note edited and closed has its Markdown tidied** (a library setting, on by default)
- **A task's reminder warns where it is set**, not only in the Todo tab's banner, and the warning follows the switches the system shows — background usage, and the notification permission even before the first reminder
- **The search index keeps the words of a note**, not a copy of its text, so it no longer grows with the notes
- **Library settings sync** by merging key by key, template counters keep the highest number, and the personal dictionary merges word by word; how a library looks on screen stays on each device

### Fixed
- **Huge notes open and stay editable:** the load runs off the UI isolate, a keystroke costs what it changed rather than the note, the read pane shows the top while the rest is scanned, and a pinned note is edited at its head instead of loading whole
- A note's word count is built again after a reload from disk
- A first library open waits for the tree, not for every note
- The watcher leaves a note to the indexer its writer scheduled
- The read view keeps no room for the editor's line numbers when the numbers are off
- Brackets are typed in pairs, in both editors
- The Windows tray menu wears the app's theme, and opens again after one is dismissed

## [0.0.8] - 2026-09-20

**Updates over 0.0.7 normally.** The signing key from 0.0.7 carries on, so this installs over it, and the app database migrates itself: the open notes, the shortcuts, the pins and the tray choice land where they belong.

### Added
- **Tabs, panes, and a workspace that remembers.** The desktop keeps every open note in tabs — one pane, then two, split from a tab or opened beside with a middle or double click — and tabs drag to reorder, move between panes, or drop to split. Phones get the same model as an open-notes switcher. Which notes were open, and where each one was left, is kept per device and restored on return
- **The command palette.** One search for commands and notes: find a note by name, run a command, pin the commands used most so they wait at the top. The phone's palette stands apart from the library search, and a Commands page in Settings lists what the palette can run and when
- **Keyboard shortcuts of your own.** Change, clear and restore shortcuts; the map lives on the device, both editors hear it, and a remapped key runs once. The palette's search finds a command by its keys too
- **Zen mode and typewriter mode.** Zen clears the desktop down to the note, preview included; typewriter mode keeps the line being written in the middle of the screen, set per library from the note's menu
- **A right dock** with the note's outline, tags and history, keeping its state as it moves beside the note
- **Close to tray, and a tray menu worth having.** The window's × hides Niman to the tray on the desktops, where the reminders keep firing
- **One Niman per desktop session.** A second launch reaches the running one instead of opening another
- **Drop files on the window.** Markdown files and folders dropped on Niman land in the library; `.md` files open in Niman from the file manager, and a file passed on launch opens, even outside any library
- **Tidy the Markdown**: the editor rewrites the note's Markdown clean — spacing, list marks, heading style — the same in both editors
- The palette answers with settings too: its search reaches the app's own settings
- Settings opens as a floating window on a wide window, and the library switcher floats too, with **Close library**

### Changed
- The rail is 48 px and icons only, with its way out at the foot
- A note is a centred column, on by default; list notes, voice notes and the Todo list keep to it, and a window showing one thing wears a slim title bar
- Settings is two columns on a wide window, every row stacking label, description and control
- A note wears one row above it, with the note menu at its end; the formatting actions live on right-click in both editors
- No keys named where there is no keyboard to press them: the phone's labels say what they do instead

### Fixed
- **Starts on a clean Windows**: the bundle carries the Visual C++ runtime it needs
- A note whose list items wrap opens as a note again, instead of choking on its own wrapping
- A section break reads as a line in the WYSIWYG, not a box of hyphens
- `Ctrl+Z` on a note just opened no longer empties it
- The buffer is never saved over a file that did not load, and a file that is not text says so instead of opening as one
- In the palette the pointer selects, and a chosen key beats the formatting; on Linux the tray menu appears
- A drop that brings nothing says so, and leaves a trace
- Tapping a todo on the home-screen widget completes it again, and the testing build finds its placed widgets
- The spellcheck panel opens at once on any note, and the overdue reminder line reads true on a desktop
- A full sync waits out a backoff and names a stuck file, and a 207 that says "not there" is not taken for a file
- The "+" dialog reads on a dark theme

## [0.0.7] - 2026-09-18

- **Reinstall once, on Android.** Every release until now was signed with a throwaway key that changed from build to build, so Android refused to update over it. There is a real signing key now and every release from here on updates normally — but this one has to be uninstalled and installed again by hand. Your notes live in your library folder and are not touched by it; copy anything you keep elsewhere first

### Added
- **Windows draws the app's own title bar**, the way Linux already did: the sidebar toggle and the window buttons sit in one row with the note's name, and the space in the middle is where the note tabs will go
- **Count a list**: the editor toolbar's new **Tools** button turns a list into a checklist of totals — a page of `Alessandro - cappuccino, brioche` becomes `- [ ] cappuccino: 2`, ready to tick off at the counter. It shows which list it is about to count and exactly what it would write before writing it, reads each row the way you tell it to, and run again after the list changes it replaces what it wrote rather than adding a second block — keeping the totals you had already ticked. Both editors, same result
- Enter carries a list on in the source editor: the next line starts with the same marker, a numbered list counts on, a task item gives you a fresh empty box, and Enter on an item you have not typed anything into ends the list. The WYSIWYG always did this
- The trash can empty itself: a library can be told how many days a deletion may sit before it goes for good, checked when the library opens. Off in a fresh library, and off whenever the setting cannot be read — it is permission to delete notes permanently
- Settings search: type a word and the matching rows come back with the area they live in
- A note's row menu on desktop can show the file in the file manager, or hand the `.md` to whatever your system opens Markdown with
- An Android testing build that installs beside the normal app — its own application ID, "Niman (Testing)" on the launcher — release-equivalent, with update management switched off

### Changed
- **A note opens as a page, not a tab.** On a phone the tab bar no longer sits under the note: back is the app bar's arrow and it lands on the tab the note was opened from, and the bar carries the note's folder under its title
- **Settings is a home of areas** — Appearance, Editor, Updates, Folders and paths, Sync, Trash and history, Diagnostics and info — each opening its own screen, with the app's own settings separated from the library's and the library named
- The tree's long-press menu opens with the row it acts on — icon, name, and the folder it sits in — instead of being a list of verbs with no subject, and its entries are grouped
- Moving a note asks with the same folder picker the settings use: a real list, a **New folder** button, and a mark on what is selected, instead of a dropdown opening over a dialog
- The new-item button's actions name what they do and where they land, and the trash is a plain list like every other screen, with **Empty** in the app bar — disabled, not missing, when there is nothing to empty
- Todo token chips wear their kind's colour, so projects, contexts and tags are apart at a glance, instead of a colour per name
- Deleting a note into the trash offers **Undo**
- Icons are outline throughout; a filled one now means a state is on
- The switch between the source editor and the WYSIWYG says which one it would take you to, and is not offered in preview, where there is no editor on screen

### Fixed
- **Pasting in the WYSIWYG editor closed the app on Windows.** `Ctrl+V` took it down outright; it now pastes, and falls back to plain text when the clipboard's formatted version cannot be read
- **The right-click menu in the source editor did nothing.** Cut, copy, paste and select all were all silently dropped — and, because every attempt left the editor without the cursor, `Ctrl+A` afterwards selected nothing and `Ctrl+C` copied a single line
- `Ctrl+←` and `Ctrl+→` jump a word and `Ctrl+Shift+←`/`→` select one, the way they do everywhere else on Windows and Linux. Before, selecting a word from the keyboard was not possible at all
- Copying from the WYSIWYG editor keeps the Markdown: a bulleted item copies as `- item`, a heading keeps its `#`, and the last item of a list no longer loses its bullet. Pasting Markdown back in brings the structure with it, and pasting a page from a browser still arrives formatted
- The WYSIWYG editor's right-click menu opens where you clicked instead of halfway across the window
- **Editing a note in the WYSIWYG no longer rewrites its lists.** A task list with blank lines between its items kept its boxes — they were being written back as plain bullets, and the tick went with them — a spaced-out list kept its spacing, a numbered list kept its numbers and the number it starts at, and a nested list kept its nesting
- A task list with blank lines between its items shows its boxes in the preview too
- Closing the app on Linux ended in a crash on NVIDIA, where a C exit handler unwound into the EGL driver
- Sync on Windows stalled on the third attachment of every run; the attachment is copied in rather than renamed, which is a workaround and marked as one
- The folder settings could create the folder you asked for inside a folder that was not there — `assets/attachments` instead of `attachments`
- Setting the quick note anywhere but the settings screen left every other surface unaware of it
- A library's settings changed somewhere else are re-read instead of going stale
- The find button keeps the keyboard up instead of closing it and reopening it a frame later
- Text that stayed in English whatever language the app was in: the editor's status row, the trash, the tree's row menu, the new-item button's tooltip
- The search mode row fits a phone's width; the new-item button's label cannot run past the screen edge; two settings search results no longer share one identity; the desktop editor header keeps its actions at the right edge

### Other
- `shell.dart` and `note_view.dart` split into focused files, and the settings screen with them
- Background file jobs are counted while in flight, so one that hangs says so in the log instead of leaving a silent gap

## [0.0.6] - 2026-09-16

### Added
- WebDAV sync: point a library at a folder on your server and it keeps in step, by hand or on its own — automatic triggers with backoff, a queue that survives going offline and restarting, per-library credentials in the keychain, and a status panel listing whatever a run could not settle. Servers without ETags or preconditions work in a compatible mode, and one reached through a reverse proxy that mounts it under a path prefix works too. A run that would delete many files asks first, and deletions land in the trash rather than disappearing
- Note history: every note keeps its recent versions in `.history/` inside the library, grouped by day with the lines added and removed against the note as it is now. A version opens as a diff — side by side on a wide screen, stacked on a phone — and restores whole, or in part by picking single changes, with what it replaces kept as a version so a restore is itself undoable
- Conflicts merge instead of asking: when both sides changed a note, edits in different places land together, and only real overlaps open a screen where each one is settled by choosing this device's lines, the server's, or both
- On-device transcription of voice notes: **Transcribe** in a clip's menu runs a Whisper model locally and writes the text into the clip's description, asking first whether it replaces what is written there or goes below it. Models are downloaded and kept per device, never in the library, and nothing leaves the device. Available on Android and on Windows and Linux desktops
- A personal dictionary per library: right-click a word the spell-checker flagged and add it, and it stops being flagged in that library
- Clicking a link to a note that does not exist offers to create it, at the folder you choose in Settings → Editor

### Changed
- **The Android build is 64-bit only.** Devices with a 32-bit-only processor cannot install this version or update to it
- A todo reminder's notification now wears the app's mark instead of a generic alarm clock
- Voice recording can be paused and resumed, and saving a clip no longer stutters the interface
- Opening a library upgrades its database (schema 22). A `.history/` folder appears inside libraries from this version on; it holds the note versions and is never synced

### Fixed
- Inserting a large image no longer freezes the app while the file is read
- Wrong words in several older translations (Icelandic, Belarusian, Bulgarian, Greek, Basque, Lithuanian, Slovak, Albanian, Serbian), and strings that had stayed in English in every language
- The launcher's long-press menu was missing **New voice note**, which the in-app button and `Ctrl+Shift+A` both offered
- Playing a voice note's clip on Windows, where the file's path was put together with mixed separators and the player could not open it

## [0.0.5] - 2026-09-15

### Added
- Android auto-update opens the system package installer for the downloaded APK (FileProvider share, `REQUEST_INSTALL_PACKAGES` declared); the download alone was all 0.0.4 did

## [0.0.4] - 2026-09-15

### Added
- Auto-update from GitHub Releases (off by default): a quiet check shortly after launch and then every 6 hours, a shell banner offering the download, and a manual "Check for updates" row in Settings → Updates that downloads immediately; Windows launches the installer, Linux fetches the installed variant into Downloads, Android saves the APK (the system-installer step is next)

### Fixed
- Release APK without network: the INTERNET permission lived only in the debug manifest, so the update check (and WebDAV sync) failed on release builds

## [0.0.3] - 2026-09-14

### Added
- Home-screen widgets on Android: a todos widget (the open tasks, up to 100 rows, tap a row to toggle it, "+" opens the app with the add field focused) and a notes widget for your pinned notes, both wearing the app's palette
- Voice notes as a chat (`type: audio` notes): vocals on the left, written notes on the right; record or import audio as content-addressed files under the attachments folder, with a description per vocal and rename support
- 34 new UI languages (Dutch, Swedish, Norwegian, Danish, Basque, Catalan, Galician, Polish, Czech, Finnish, Romanian, Hungarian, Croatian, Slovak, Slovenian, Estonian, Latvian, Lithuanian, Bulgarian, Ukrainian, Belarusian, Serbian, Bosnian, Macedonian, Albanian, Greek, Icelandic, Turkish, French, German, Spanish, Portuguese, Chinese, Japanese, Hindi)
- `{{counter:name}}` template counters, kept per library, and `{{cursor}}` to land the caret in a created note

### Changed
- The preview shows a skeleton placeholder while its first parse is in flight, and the editor subtree survives preview switches
- Note rows scroll to the delete action on short screens; notes are picked with the system file picker

### Fixed
- App freeze on empty wikilink forms in the preview

### Other
- New `docs/` tree with user and contributor documentation
- The debug log export includes the device logcat; widget decisions are logged to a durable native file

## [0.0.2] - 2026-09-12

### Added
- The Niman theme, built from the logo palette, as the default on fresh installs
- Frame logging now attributes the frames after a tab switch to that switch (#48)

### Changed
- The preview parses each block inline when it builds, instead of the whole note at once
- The outline finds headings without tokenizing the document
- A big note opens without waiting for its stats, and a tab switch no longer rebuilds the tab bodies

### Fixed
- Preview parse parity, inline math wrapping, and keeping panes alive; the math glue reads its one-character text safely and glues punctuation to the formula
- The pre-search hint is centred and padded

## [0.0.1] - 2026-09-11

### Added
- The first release of Niman: plain `.md` files on disk as the source of truth, with the database as a rebuildable index
- Markdown with tables, task lists, footnotes, strikethrough and code highlighting; math (`$…$` / `$$…$$`, KaTeX); wikilinks and standard links
- Source editor and WYSIWYG editor, switchable; images copied into the library on insert
- Spellcheck on every platform
- Libraries as plain folders with self-contained settings; trash, history, templates, frontmatter, tags
- Full-text search (SQLite FTS5); themes (day/night/system × palettes) and adaptive layout
- Task reminders on Android
