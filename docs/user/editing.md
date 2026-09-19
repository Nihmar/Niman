# Editing

## Editors

Each library writes in one editor (`editorKind` in
`.niman/settings.json`): `source` (default) or `wysiwyg`. The settings
screen can offer source, WYSIWYG, or both (`enabledEditors`); the note's
status row switches only when both are enabled.

- **Source editor** (`re_editor`): Markdown text with Niman's incremental
  tokenizer for highlighting. Line numbers and indent width (2–8, default
  2) are per-library settings.
- **WYSIWYG editor** (`flutter_quill`): formatted surface with a Markdown
  round-trip codec. What you see is the same `.md` file on disk.

### Open notes and tabs

On the desktop the notes you have open are tabs in the title bar,
starting where the file tree ends.

- **A click** on a note in the tree shows it in the tab you are on. A
  note that is already open is shown in its tab rather than opened twice.
- **`Ctrl+click`**, the tree's right-click **Open in new tab**, or the
  **+** after the tabs (a new note) opens one alongside.
- **Switching** is by the tab, by `Ctrl+Tab` / `Ctrl+Shift+Tab`, or by
  the **▾** list, which shows every tab with its folder when the row is
  too full.
- **Closing** is by the tab's **×**, a middle click, or `Ctrl+W`. The tab
  to the right takes its place.
- **An orange dot** in place of the **×** means the note has edits not
  written yet. They are written a moment later, as always.

**Two panes.** The window splits in two, and each half holds its own
tabs.

- **To split,** use `Ctrl+\` (right, with the note on screen), a tab's
  right-click **Split right** / **Split down**, or the tree's
  right-click **Open to the side**.
- **Splitting with a tab** moves that tab into the new pane. A pane with
  only that tab keeps it, and the new pane opens empty for the next note.
- **Split right,** the title bar's row of tabs divides exactly where the
  panes do. **Split down,** the lower pane carries its tabs at its top.
- **Focus.** A click inside a pane gives it the focus: the tree opens
  there, and the tree shows that pane's note.
- **Moving.** A tab's **Move to the other pane** moves it, keeping
  everything, undo included.
- **Unsplitting.** Closing a pane's last tab puts the window back
  together, and the divider drags.
- **One place per note.** A note is open in one place only: opening it
  again takes you to the pane and tab it is in.

**The side panel.** On a window wide enough (1000 px and up) a panel on
the right shows the note's **Outline**, its **Tags** or its **History**,
one at a time, switched by the icons at its top.

- **Outline** lists the headings, and a click takes the caret to one.
- **Tags** lists the note's tags; a click lists the other notes with
  that tag, which open from there.
- **History** lists the kept versions, newest first, and opens the
  history screen to compare or restore.

It follows the note in the focused pane, and changes as the note is
edited. The panel's button in the note's row, its **×**, or
`Ctrl+Shift+B` shows and hides it. Whether it is open, and which of the
three it shows, is remembered with the tabs. The note's **⋮** menu has
Outline and Tags too: they open the panel where it fits, and a sheet on
a phone.

Each tab keeps its own way of showing its note: the source editor or the
WYSIWYG one, the preview or not. The **Default editor** setting is the
editor a note opens in. The last few tabs you looked at keep everything
behind them, undo included. Older ones come back to where you left them
(caret, selection, scroll) but start a fresh undo history. A very long
note keeps its editor only while it is on screen.

**On a phone** the notes you open stay open after you go back to the
tree. The note bar and the Files bar show how many there are. Tapping
that count opens the list of open notes: the one on screen is marked,
and each note has its folder, the orange dot while it has unsaved
edits, and a close. From the list you can switch to a note, close one
(the next open note takes its place, or the tree once none are left),
close them all, or start a new note. Each note comes back where you
left it, and the notes left open are still in the list after the app
restarts.

Selecting a folder in the tree leaves the note on screen, and the tree
follows the tab you pick. Renaming or moving a note, or a folder with
open notes in it, carries their tabs along, and deleting closes them.
The tabs are remembered per library on this device: opening the library
again brings them back, and a phone never inherits a desktop's tabs.

### Readable line length

A note's text keeps to a centred column instead of running the full
width of the window: on a wide screen a line of prose stays a line you
can read. It is on by default, and **Settings → Editor** turns it off
(*Readable line length*) or sets how wide the text runs (*Column width*,
700 px unless changed, anything from 480 to 1400).

The same column holds in both editors and in the preview, so switching
editors does not move the text sideways. The source editor's row
numbers sit in the margin, just left of the text. The toolbar, the find
bar and the status row keep to the column too; their backgrounds still
span the pane, and so does the scrollbar, and the mouse wheel scrolls
from the margins as well.

A window narrower than the column simply is the column. That is why a
phone never shows a margin, and the reason the setting exists on
Android as well: on a tablet, or a phone in landscape, it starts to
count.

### Zen mode

On Linux and Windows, `F11` (or *View: Enter Zen mode* in the command
palette) leaves the note and nothing else: the rail, the tree, the
tabs, the side panel, the note's toolbar row, its status row and the
row numbers all go. A thin bar at the top keeps the note's name, the
button that leaves Zen, and the window's own buttons, so the window can
still be moved and found in the taskbar. The caret is a little thicker,
now that nothing frames it.

The window is maximized on the way in, and put back on the way out —
unless it was maximized already, in which case it stays so. The taskbar
stays visible: this is a writing mode, not a fullscreen.

- **Leaving.** `Esc`, `F11` again, or the bar's button. `Esc` goes to
  the nearest thing first: a find bar closes, a selection collapses, a
  dialog or the palette shuts, and the next `Esc` leaves Zen.
- **The preview** stays yours: a note read rather than written can be
  read in Zen in its preview. A split comes apart; the note shows its
  editor or its preview, as its tab says, and the eye in Zen's bar (or
  *Show preview* / *Show editor* in the palette) flips between them.
- **Split panes.** Zen shows the pane you were in; the other waits
  behind it, notes, undo and all, and comes back on the way out.
- **Moving between notes.** `Ctrl+Tab`, `Ctrl+O` and the palette work
  as usual, and the bar follows the note on screen. Closing the last
  note, or going to another place of the rail, leaves Zen.
- **What stays out.** The toggles for what Zen hides (the sidebar, the
  side panel, the splits) are left out of the palette
  while Zen is on, rather than changing something you cannot see.

Zen is not remembered: a restart, or another library, opens without
it. It is the desktop's alone — a phone is one note on one screen
already. `F11` can be changed under Settings → Keyboard shortcuts, like
every other.

### Typewriter mode

With typewriter mode on, the line you are writing stays in the middle
of the editor, and the note moves under it instead of the caret
wandering down the screen. It works in both editors, on every platform,
and changes nothing in the text: it is only a way of scrolling.

- **What moves the note.** Anything that moves the caret: typing onto a
  new row, the arrow keys, a click or a tap, a find landing on its
  match. A long paragraph is followed row by row, not line by line.
- **What doesn't.** The mouse wheel, the scrollbar and a swipe scroll
  freely, to read around; the next move of the caret brings its row
  back to the middle.
- **The ends.** The editor keeps half a screen of room below the last
  line, so the end of a note reaches the middle too. At the start there
  is nothing above, so the first lines are written where they stand
  until the note is long enough to move.

It is a setting of the library (**Settings → Editor → Typewriter
mode**), off unless you turn it on. `Ctrl+Shift+T` or *Editor: Turn
typewriter mode on* in the command palette switch it from anywhere, and
on the desktop a button in the note's status row shows it and switches
it. The phone's status row has no room for one more button: there the
note's ⋮ menu has *Turn typewriter mode on/off*, as do the setting and
the commands under the Search tab.

It is independent of [Zen mode](#zen-mode): either can be on without
the other, and entering or leaving Zen leaves typewriter mode as it
was. In Zen the status row is hidden, so the key and the palette are
the way to it.

### Copy and paste

The clipboard carries Markdown on both editors, so copying the same text
from either gives the same thing: a bulleted item copies as `- item`, a
heading keeps its `#`, bold keeps its `**`. Pasting Markdown into the
WYSIWYG editor brings the structure back rather than the characters.

Pasting a styled page from a browser still arrives as formatted text —
the HTML is used when the clipboard carries it.

## Markdown support

Tables, task lists, footnotes, strikethrough, fenced code blocks with
syntax highlighting. Math via `$…$` and `$$…$$` (KaTeX). Links: standard
Markdown links plus `[[wikilinks]]` (see [links](links.md)).

Formatting toolbar buttons apply to whichever editor is active.

On the desktop the toolbar and the note's own controls share **one row**
above the note, in both editors. The formatting is on the left, grouped
(text, lines, insertions) with a thin divider between groups, and the
note's **⋮** menu (history, rename, move, delete) is at the right end,
next to the list or voice-note switch when the note has one. The row
keeps to the note's column, so its first button sits over the start of
the text. It stays when there is nothing to format, in the preview or on
a list note, so the ⋮ is always in the same place. The note's name is
in the window's title.

On a phone the toolbar keeps its size and rides the keyboard, and the ⋮
in the note's bar offers the same actions.

The same formatting is also on the **context menu**: right-click in either
editor (long-press on a phone). Under cut, copy and paste come the toolbar's
buttons, with the same icons, names and grouping, and a format that is
on at the caret reads as on, just as it does on the toolbar. They apply
to the selection, so a word picked with the mouse can be made bold where
it is. The toolbar stays; the menu is a second way in. It lists the
buttons you keep on the toolbar, in the same order.

Enter inside a list carries the list on, in both editors: the next line
starts with the same marker, a numbered list counts on, and a task item
gives you a fresh empty box. Enter on an item you have not typed
anything into ends the list instead — the usual second Enter. Inside a
fenced code block, a math block or the frontmatter it does nothing: a
dash there is a dash.

## Tools

The toolbar's **Tools** button opens the editor's extra tools. They are
not formats: each one reads the note and writes something back. Both
editors offer the same tools, and a tool that has nothing to work on in
this note is listed greyed with the reason rather than hidden.

### Count a list

Turns a list into a checklist of totals — *who ordered what* into *what
to buy*.

Each row is cut at its first separator and the rest split on commas, so
`Alessandro - acqua naturale, brioche` counts as two values. The sheet
shows which list it is about to count (a picker, when the note has
several), how it will read each row, the order the totals come out in,
and a preview of exactly what it would write. The four readings are:

| Reading | `Chiara - succo, brioche` gives |
| --- | --- |
| Name - values | `succo`, `brioche` |
| Name: values | the whole row (no colon in it) |
| Values, comma separated | `Chiara - succo`, `brioche` |
| The whole row | `Chiara - succo, brioche` |

The dash may be a hyphen, an en dash or an em dash, and needs a space
only before it. A row with no separator counts as one value, so a plain
shopping list with repeats works too. Two spellings of one value count
together under the first one seen: `acqua naturale` and `Acqua naturale`
are one line.

The result is written under the list as ordinary Markdown:

```markdown
- [ ] brioche: 7
- [ ] succo pesca: 5
- [ ] macchiato: 3
```

Nothing marks the block as generated — its shape is what identifies it.
Run the tool again after the list changes and that block is replaced
rather than a second one written, and **a total you had already ticked
stays ticked**; a total that no longer appears takes its tick with it.
Move the block away from its list and the next run will not find it, and
will write a new one under the list.

It counts strings, not ideas: `tramezzino`, `tramezzino cip` and
`tramezzino olive` are three totals, not three of one. Grouping them is
yours to do.

## Preview

Side by side with the editor at 600 dp and up (`auto` mode), one pane on
narrow screens. Per-library toggles: `previewEnabled`, split ratio
(0.2–0.8, default 0.55). The preview renders Markdown + math + code
highlighting.

Extras: word count, heading outline, heading folding.

## Images

Pasting or inserting an image copies the file into the library — notes
never carry base64 blobs. The note references the copied file.

## Spellcheck

Every platform spellchecks: system/IME on Android, hunspell on desktop.
Desktop dictionaries are chosen per library (`spellDictionaries`, a list
of hunspell names in selection order; empty = locale default). A word
passes when any selected dictionary knows it.

Desktop additionally has a per-library personal dictionary: right-clicking
a flagged word in either editor offers *Add to dictionary*, which writes
the word to `<library>/.niman/dictionary.txt` (one word per line, next
to `settings.json`). A personal word always passes, whatever the hunspell
engines say, and its underline clears on the next scan. Words are read
case-insensitively but stored as first typed. The file travels with the
library, so different libraries can carry different vocabularies; it
survives app restarts.

The status row's spelling button opens a panel listing the note's
misspellings, each with hunspell's suggestions; tapping one replaces the
word. The panel opens at once on any note, however long: it checks the
note a little at a time, with a bar showing how far it has got, and the
list fills as it goes. The suggestions arrive just after the words they
belong to. A fix updates the list on the spot, without checking the
whole note again. The panel lists at most 200 words; when a note has
more it says so, and **Check again** lists the next ones once some are
fixed.
