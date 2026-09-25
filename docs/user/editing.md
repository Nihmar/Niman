# Editing

## Editors

Each library writes in one editor (`editorKind`, kept per library on
each device): `source` (default) or `wysiwyg`. The settings
screen can offer source, WYSIWYG, or both (`enabledEditors`); the note's
status row switches only when both are enabled.

Both are one surface, Niman's own, in two modes: the note's text is the
same Markdown either way, and only how it is drawn differs. The read view
(the preview) is the same engine again, with nothing to edit.

- **Source editor**: the Markdown as written, with Niman's incremental
  tokenizer for highlighting. Line numbers and indent width (2–8, default
  2) are per-library settings.
- **Source editor font**: the source pane is set in a **monospace** face —
  `monospace`, with `Consolas` / `DejaVu Sans Mono` / `Roboto Mono` as
  fallbacks — because the source is read as text: its markers, its indents and
  its columns. The line numbers use the same face at the same size, dimmed, so
  they line up with the characters they count. Making the face and size a
  setting is issue #259.
- **Editing, in both modes**: Enter carries a list on, **Tab and Shift+Tab
  indent and outdent** (the note keeps the focus), PageUp/PageDown page, and
  on a phone a **long press selects a word**, with handles to adjust it and a
  toolbar to cut, copy, paste or select all. Both have the find and replace
  bar, the spelling underline and its panel, the context menu, Ctrl+click on
  links, folding, typewriter mode and Zen.
- **WYSIWYG editor**: the note drawn as it reads — the Markdown stays the
  note's text, and only where the caret is does it show as written. Headings
  are set at their size; bold, italic,
  strikethrough, `==highlight==`, underline (`<u>`) and superscript (`<sup>`) are drawn as
  such, and so is a format inside another (`<u>**x**</u>` is bold and
  underlined); list items get their bullet, number or checkbox — a click or a
  tap on the checkbox ticks it, one undo step, without moving the caret (in
  the read view too, where the tick is saved like any edit). A
  sublist is one column in per level, as the read view draws it, and a
  line that goes on an item — its wrapped rows, and the lines written
  under it — starts under the item's text. On the caret's line the marks
  are written out and the text stays where it was: marks wider than their
  column, like a task's `- [ ] ` or a `10. `, hang into the margin
  instead. A quote gets its bar — a callout its box, icon and title — and what is inside it — a heading, a
  list, a code block — is drawn as it is outside; `---` a rule; a code
  block (and an HTML block) its box, in monospace, the code coloured by the
  language its fence names; a table its grid, which stays a grid while
  you write in it, as Obsidian's does: only the word the caret is in
  shows its marks, the delimiter row never shows, the caret goes from
  cell to cell rather than onto the pipes, and Backspace or Delete stop at
  the cell's edge. Footnote and link definitions take no room
  where they are written: the note ends with its footnotes, as in the read
  view, and a tap on one puts the caret in its definition. The read view is
  the same page: a blank line is as tall in both, and flipping between
  them leaves the text where it was. Columns, bullets,
  checkboxes and numbers grow with the note text size. Display formulas (`$$…$$`) and inline ones
  (`$…$`) are typeset, and
  images and `![[embeds]]` are drawn under their line. Put the caret in a word
  and its syntax appears; put it in a formula block and the block's source
  appears — so everything stays editable as text.
- **Any size**: every mode opens a note of any size, novel-length ones
  included; the note is scanned as it is drawn rather than converted up
  front, so there is no wait to open it and no cap on any surface.

### Open notes and tabs

On the desktop the notes you have open are tabs in the title bar,
starting where the file tree ends.

A name too long for its room — a tree row, a tab, the window title, or
the phone's note bar — does not stop at an ellipsis: it scrolls itself to
reveal the rest, rests a moment, and comes back. A system set to reduce
motion keeps the ellipsis instead.

- **A click** on a note in the tree shows it in the tab you are on. A
  note that is already open is shown in its tab rather than opened twice.
- **`Ctrl+click`**, the tree's right-click **Open in new tab**, or the
  **+** after the tabs (a new note) opens one alongside.
- **Switching** is by the tab, by `Ctrl+Tab` / `Ctrl+Shift+Tab`, or by
  the **▾** list, which shows every tab with its folder when the row is
  too full.
- **Dragging a tab** along its row reorders it; a line shows where it
  will land. Dropped on the other pane's row or body it moves there,
  keeping everything, undo included. With the window not split, dropping
  it on a pane's right or bottom quarter splits the window with that tab
  — the shaded half shows what you are about to get.
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
  everything, undo included; so does dragging it onto the other pane.
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
  read in Zen in its preview. The note shows its editor or its preview,
  as its tab says, and the eye in Zen's bar (or *Show preview* / *Show
  editor* in the palette) flips between them.
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

Tables, task lists, footnotes, strikethrough, `==highlight==` (a marker's
yellow, the same in every theme), callouts, fenced code blocks with
syntax highlighting. Math via `$…$` and `$$…$$` (KaTeX). Links: standard
Markdown links plus `[[wikilinks]]` (see [links](links.md)).

**Callouts**, as Obsidian writes them: a quote whose first line is
`[!type]`, with a title of its own after it or the type's as its title.

```markdown
> [!tip] A title of its own
> What it says.

> [!warning]- Folded until opened
> Hidden at first.
```

The read view and the WYSIWYG editor draw a box in the type's colour,
with its icon and title on top. The types Obsidian ships have their own
colour and icon — note, abstract (summary, tldr), info, todo, tip (hint,
important), success (check, done), question (help, faq), warning
(caution, attention), failure (fail, missing), danger (error), bug,
example, quote (cite) — and any other word is drawn as a note. A `-`
after the type folds the callout in the read view until its title is
tapped, a `+` makes it foldable and open; the editor always shows what
it says, to be written in. With the caret on the title line its
`[!type]` shows as written.

The **Markdown cheatsheet** shows every construct Niman reads, each as it
is written beside how a note shows it — headings, emphasis, highlight,
underline and super/subscript, lists and checkbox lists, quotes and
callouts, links and links to notes, images and embeds, tags, code, math,
tables, footnotes, rules, frontmatter and template placeholders. Open it
from the note's ⋮ menu, *Editor: Markdown cheatsheet* in the palette, or
Settings, next to the changelog. Every example can be copied; opened from
a note, it can also be inserted at the caret — one line where the caret
is, several on lines of their own. On a phone an example's source and its
look are stacked.

One thing to know when a note came from somewhere else: **a list marker has
to start a line.** `- c)` written inside a sentence — after a formula, or
wherever the text happened to wrap — is a hyphen and a letter, not an item,
and no renderer can turn it into one. Put it on a line of its own and it
becomes an item; a blank line is not needed, because a list can interrupt a
paragraph. Indentation is what makes a sublist: a marker under an item's own
text is that item's child, one at the same column is its sibling.

**Tidy the Markdown** — the note's ⋮ menu, or *Editor: Tidy the
Markdown* in the palette — puts a note's own text in order without
changing what it says:

- a line that continues a list item is indented to that item's text, so
  a wrapped item stays one item (this is what makes such a note read
  right in the WYSIWYG, where it used to break the numbering);
- a heading gets one space after its hashes;
- runs of blank lines become one, and the trailing ones go;
- spaces left at the end of a line go, except the ones that mean a line
  break;
- a list comes back tight: no blank lines between its items, one space
  after each marker, and a task box written `[ ]` or `[x]` whatever case
  it was;
- a fenced code block gets its closing fence when the note forgot one,
  and its language — the first word of the info string — loses the
  punctuation around it (`{.dart}` becomes `dart`);
- the note ends with a single newline.

It never reflows your prose, and never touches what it cannot read:
tables, math, frontmatter and HTML come back byte for byte, and so does
the code inside a fence — only its two fence lines are read. Tidying
twice changes nothing the second time. The note is saved first, so what
is tidied is the note as it stands.

It also runs by itself: a note you edited is tidied when it is closed.
That is a setting of the library (**Settings → Editor → Tidy the
Markdown on close**, on by default), so every device writes the
library's notes the same way. **Markdown rules**, right below it, picks
which of the rules above run; notes over 4 MB are left as they are.

The **checkbox list** button (beside the bulleted and numbered lists)
makes the selected lines — or the caret's — tasks: a bulleted item gains
its box, a numbered one keeps its number, a plain line becomes `- [ ] `.
Pressed on lines that are all tasks already, it takes the boxes off and
leaves their text. Blank lines in a selection are left alone, and the
whole change is one undo step. On a task line the button reads as on.

The **table** button writes an empty table — two columns, a header and
one row — on lines of its own, with the caret in its first header cell:
it takes the place of a blank line the caret is on, goes above a line
the caret is at the start of, and below one the caret is anywhere else
in, with a blank line kept from the text around it. One undo step takes
it away. Rows and columns are added from the table itself in live mode.

Formatting toolbar buttons apply to whichever editor is active, and so
do the formatting keys — `Ctrl+B`, `Ctrl+I`, `Ctrl+K` and the rest, all
changeable in Settings → Keyboard shortcuts → Formatting (see
[shortcuts](shortcuts.md)).

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

The same formatting is also on the **context menu**: right-click in the
editor (long-press on a phone). It is grouped by what you are doing, as
Obsidian's is:

- the spelling's suggestions for a misspelled word, and a table's
  **Row ›**, **Column ›** and sorts on a table's cell, first;
- **Add link** (`[[…]]`) and **Add external link** (`[…](https://)`);
- **Format ›** — bold, italic, strikethrough, highlight, underline, superscript,
  subscript, code — **Paragraph ›** — headings 1 to 6, **Body** (the
  heading taken off), bulleted, numbered and checkbox lists, quote — and
  **Insert ›** — footnote, table, horizontal rule, code block, math
  block, image;
- the clipboard last: Cut, Copy, Paste, Select all. What cannot run now
  (Cut with nothing selected) stays in its place, greyed out, so nothing
  moves under the pointer.

On the desktop a submenu opens beside its row as the mouse comes onto
it, and closes as it moves to another; on a phone the groups sit in the selection bar's overflow and
open as a sheet. What is on at the caret reads as on, as on the toolbar
— the heading level the line has, the format the word is in.
**Insert › Footnote** cites the next free number at the caret and
writes its definition under the paragraph, the caret on it to write the
note.

Enter inside a list carries the list on, in both editors: the next line
starts with the same marker, a numbered list counts on, and a task item
gives you a fresh empty box. Enter on an item you have not typed
anything into ends the list instead — the usual second Enter. Inside a
fenced code block, a math block or the frontmatter it does nothing: a
dash there is a dash.

Brackets come in pairs, in both editors and on every platform: `(`
writes `()`, `[` writes `[]` and `{` writes `{}`, with the caret between
them, so `[[` opens a whole wikilink. The closing bracket is added only
before a space, a closing bracket or the end of the line; before a word
and after a backslash (`\(` starts inline math) a bracket is just
itself. Typing the closing bracket where the pair put one steps over it,
Backspace between an empty pair removes both, and a bracket typed over
a selection wraps it.

### Tables in live mode

A table in live mode is drawn as the read view draws it, and edited as a
table (as Obsidian does):

- **The two `+`** add a column at the table's right edge and a row at its
  foot. On the desktop they show while the mouse is on the table; on a
  phone, while the caret is in it.
- **Right-click a cell** (long-press on a phone) for **Row ›** — add a row
  above or below, move it up or down, duplicate or delete it — **Column
  ›** — add a column to the left or right, move it, align it left, centre
  or right, duplicate or delete it — and **Sort by column**, A → Z or
  Z → A. On the desktop Row and Column open beside the menu as the mouse
  comes onto them; on a phone they open a sheet. What does not apply
  to the cell is greyed out: a row above the header, moving the last
  column right, deleting the only column.
- **Tab** goes to the next cell and Shift+Tab to the one before, the
  cell's text selected so what you type replaces it; Tab past the last
  cell adds a row. Outside a table Tab indents, as ever.
- **Enter** goes to the end of the cell below, in the same column; on the
  last row it leaves the table, to the line after it. **Shift+Enter** or
  **Ctrl+Enter** leave it from any row, and **Down** on the last row does
  too. A table the note ends with gets an empty line under it to leave
  to, so the keyboard alone always gets out. On a phone the keyboard's
  Enter does the same as Enter.
- The header stays the header: it is not moved, sorted or deleted. The
  sort compares numbers as numbers and the rest ignoring case, and rows
  that tie keep their order.

Every action is one change to the note's Markdown and one undo step, and
the caret lands in the cell the action leaves it in. A table written with
its columns padded to one width is written back padded, the pipes under
one another; one written with a single space round each cell stays that
way. A column's alignment (`:--`, `:-:`, `--:`) is drawn in both the read
view and live mode.

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

The note is one pane, and it holds one of the two: the editor you write
in, or the rendered note you read. The eye flips between them — in the
note's status row on a wide window, in the app bar on a phone, or *Show
preview* / *Show editor* in the palette anywhere. What you leave behind
keeps its place: the caret, the undo history, the typeset math and the
images are all there when you come back. The note stays where you were
reading it, too: flipping to the preview, back to
the editor, or between source and live keeps the line at the top of the
pane at its top, however differently the two draw what is above it.

The rendered note shows Markdown, math, and fenced code coloured by the
language its fence names.

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
survives app restarts, and the WebDAV sync merges it word by word, so
a word added on one device is known on the others.

The status row's spelling button opens a panel listing the note's
misspellings, each with hunspell's suggestions; tapping one replaces the
word. The panel opens at once on any note, however long: it checks the
note a little at a time, with a bar showing how far it has got, and the
list fills as it goes. The suggestions arrive just after the words they
belong to. A fix updates the list on the spot, without checking the
whole note again. The panel lists at most 200 words; when a note has
more it says so, and **Check again** lists the next ones once some are
fixed.
