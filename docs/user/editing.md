# Editing

## Editors

Each library writes in one editor (`editorKind`, kept per library on
each device): `source` (default) or `wysiwyg`. The settings
screen can offer source, WYSIWYG, or both (`enabledEditors`); the note's
status row switches only when both are enabled.

A library the device opens for the first time takes its two from the
welcome's Markdown question (#266): *Never* starts in `wysiwyg` with the
source not offered, *A little* starts in `wysiwyg` with both, *All the
time* (or a skipped question) is the `source` default above. Settings →
Editor changes either whenever, and the answer is never applied twice.

Both are one surface, Niman's own, in two modes: the note's text is the
same Markdown either way, and only how it is drawn differs. The read view
(the preview) is the same engine again, with nothing to edit.

- **Source editor**: the Markdown as written, with Niman's incremental
  tokenizer for highlighting. Line numbers and indent width (2–8, default
  2) are per-library settings.
- **Source editor font**: the source pane is set in a **monospace** face —
  `monospace`, with `Consolas` / `DejaVu Sans Mono` / `Roboto Mono` as
  fallbacks — because the source is read as text: its markers, its indents and
  its columns. **Settings → Editor → Source editor font** offers **Monospace**
  (the default), **Sans serif** and **Serif** (`sourceFont`); the read view and
  `live` keep the note's own face whatever is chosen, so switching panes never
  changes the note's face. The line numbers use the same face at the same size,
  dimmed, and the gutter measures a digit in it, so they line up with the
  characters they count whichever face is chosen.
- **Editing, in both modes**: Enter carries a list on, **Tab and Shift+Tab
  indent and outdent** (the note keeps the focus; on a list item they nest
  and un-nest it, see *Indenting a list item* below), PageUp/PageDown page, and
  on a phone a **long press selects a word**, with handles to adjust it and a
  toolbar to cut, copy, paste or select all. Both have the find and replace
  bar, the spelling underline and its panel, the context menu, Ctrl+click on
  links, folding, typewriter mode and Zen.
- **WYSIWYG editor**: the note drawn as it reads — the Markdown stays the
  note's text, and only where the caret is does it show as written. Headings
  are set at their size; bold, italic,
  strikethrough, `==highlight==`, underline (`<u>`) and superscript (`<sup>`) are drawn as
  such, and so is a format inside another (`<u>**x**</u>` is bold and
  underlined); a wikilink with an alias, `[[note|alias]]`, shows its alias,
  coloured and underlined, as the read view does; list items get their bullet, number or checkbox — a click or a
  tap on the checkbox ticks it, one undo step, without moving the caret (in
  the read view too, where the tick is saved like any edit). With **Tick
  nested checkboxes** on (Settings → Editor, per library, on by default),
  ticking an item also ticks the tasks nested under it, at any depth, as the
  same undo step; clearing the parent leaves the children as they are. A
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
  view, and a tap on one puts the caret in its definition. A footnote
  holds the lines that follow its own without a blank line, and the lines
  indented four spaces under it, blank lines between them included — more
  paragraphs, a list, code. The read view is
  the same page: a blank line is as tall in both, and flipping between
  them leaves the text where it was. Columns, bullets,
  checkboxes and numbers grow with the note text size. Display formulas (`$$…$$`) and inline ones
  (`$…$`) are typeset — a `$` touching a number from outside is a
  currency sign, not a formula's edge (`20$ + 0,10$/Kg`, `$5 and $10`),
  and `\$` is always a dollar — and
  images and `![[embeds]]` are drawn under their line. Put the caret in a word
  and its syntax appears; put it in a formula block and the block's source
  appears — so everything stays editable as text.
- **Any size**: every mode opens a note of any size, novel-length ones
  included; the note is scanned as it is drawn rather than converted up
  front, so there is no wait to open it and no cap on any surface.

### Open notes and tabs

On the desktop the notes you have open are tabs in the title bar,
starting where the file tree ends.

On a wide window the tree, the notes and the side panel are each a
rounded island on the color of the title bar and the rail, with a thin
margin of it around and between them; the margin between two islands is
what drags to make one wider. Split panes share one island, divided by
their own line. The other places of the rail (tasks, search) are an
island each too. A phone keeps its screens edge to edge, turned to
landscape as well: it is the same layout with more width for the note.

A name too long for its room — a tree row, a tab, the window title, or
the phone's note bar — does not stop at an ellipsis: it scrolls itself to
reveal the rest, rests a moment, and comes back. A system set to reduce
motion keeps the ellipsis instead.

- **A click** on a note in the tree shows it in the tab you are on. A
  note that is already open is shown in its tab rather than opened twice.
  A **double click** opens it alongside instead, and the note the first
  click replaced comes back in its tab. A note that leaves its tab is
  remembered where it was left: it opens again at the same place,
  whichever way it comes back (a click, back, the palette), and after a
  restart. The place is the line at the top of the view you were in, the
  editor or the preview, so another window width, text size or note
  column lands on the same line. Renaming or moving an open note keeps its tab, its place and
  its undo.
- **`Ctrl+click`** or the tree's right-click **Open in new tab** opens a
  note alongside.
- **The + after the tabs** opens a **new tab** with no note in it, and
  the launcher in its place: **New note**, **New from template**, **Go to
  note**, and the notes you looked at last. The note you open next —
  from the launcher, the tree, the search or a link — fills that tab. A
  pane holds one new tab: **+** again shows the one it has, and a new
  tab dragged to a pane that has one stays where it is. A pane with
  nothing open shows the same launcher.
- **Switching** is by the tab, by `Ctrl+Tab` / `Ctrl+Shift+Tab`, or by
  the **▾** list, which shows every tab with its folder when the row is
  too full. With Home or Todo pinned over the notes, `Ctrl+Tab` goes on
  to the first note tab (`Ctrl+Shift+Tab` to the last), and `Ctrl+W`
  closes the pinned page, not a note under it. A row too full to fit
  scrolls: with the mouse wheel over it, or by swiping along it with a
  finger; a thin bar under it shows where you are.
- **Back and forward** go through the notes you looked at, in the order
  you looked at them, as a browser goes through pages: the mouse's side
  buttons, `Alt+←` / `Alt+→` (remappable, and in the palette), or — on a
  tablet — the arrows at the start of the tab row. One
  history for the window, whichever pane showed the note. A note you
  closed since opens again in the place of the tab you are on, at the line
  where you left it, and adds no tab; one deleted since is skipped.
- **Dragging a tab** along its row reorders it; a line shows where it
  will land. A finger holds the tab a moment first, so a swipe along the
  row scrolls it instead. Dropped on the other pane's row or body it moves there,
  keeping everything, undo included. With the window not split, dropping
  it on a pane's right or bottom quarter splits the window with that tab
  — the shaded half shows what you are about to get.
- **Closing** is by the tab's **×**, a middle click, or `Ctrl+W`. The tab
  to the right takes its place. A tab's right-click menu also closes the
  **others**, those **to the right**, or **all** of the pane's.
- **The tab's note.** The same menu has **Reveal in tree**, **Copy path**
  (the library path), **Rename…**, **History** and **Export…** for the
  note in the tab (#712).
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

**The side panel.** On a wide window a panel on the right shows the note's **Outline**, its **Tags**, its **Links**, its
**Spelling** or its
**History**, one at a time, switched by the icons at its top. A panel too
narrow for all of its icons shows them from the end, the first ones cut
off at the left: the wheel over the row scrolls it, and the mouse drags
it as a finger does on a tablet.

- **Outline** lists the headings, and a click takes the caret to one.
- **Tags** lists the note's tags; a click lists the other notes with
  that tag, which open from there.
- **Links** lists the notes that link to this one, each with the line it
  says the link on, and opens one on a click (see
  [links](links.md#links-to-this-note)).
- **Spelling** lists the note's misspellings, each with its suggestions
  (see [Spellcheck](#spellcheck)).
- **History** lists the kept versions, newest first, and opens the
  history screen to compare or restore.

It follows the note in the focused pane, and changes as the note is
edited. The panel's button in the note's row, its **×**, or
`Ctrl+Shift+B` shows and hides it. Whether it is open, and which of the
panes it shows, is remembered with the tabs. The note's **⋮** menu has
Outline, Tags and Links to this note too: they open the panel where it
docks, and a sheet on a phone. Wherever the wide layout can show the
panel — beside the note, or over it on a narrower window — the note's
outline and its spelling review live there, and the row under the note
leaves both their buttons out; a phone keeps them, and there they open
the outline and the spelling review as sheets.

With 1000 px or more the panel docks beside the note. On a narrower wide
window — half of a 1080p screen, say — the button stays in its place in
the note's row and the panel opens **over the note** instead, on the
right edge, under the note's row of buttons, the note below it under a
scrim and not moving or resizing. The row, and so the panel's button,
stays where it was, filled while the panel is open; that button,
`Ctrl+Shift+B`, the **Side panel** command of the palette, the panel's
**×**, `Esc` or a click outside it shut it, and so does opening a note
from its Tags or Links pane. It is not
remembered: the window starts, and is resized, with the panel shut over
the note, while the docked state you left (open or shut) comes back as
soon as the window has room again.

Each tab keeps its own way of showing its note: the source editor or the
WYSIWYG one, the preview or not. The **Default editor** setting is the
editor a note opens in. The last few tabs you looked at keep everything
behind them, undo included. Older ones come back to where you left them
(caret, selection, scroll) but start a fresh undo history. A very long
note keeps its editor only while it is on screen.

**On a phone** (upright or turned: one note on one screen, never panes or
tabs) the notes you open stay open after you go back to the
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
(*Readable line length*) or sets how wide the text runs
(*Column width*, 100% unless changed, anything from 70% to 200% in steps
of 5%). 100% is 700 px, about 80 characters of prose at the default text
size.

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
row numbers all go, and the note fills the window edge to edge, its
island's margin and rounded corners with them. A thin bar at the top
keeps the note's name, the
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

### Find and replace

The find bar searches the note a line at a time, without making a copy of
it, so a very long note can have it open: the matches arrive in a moment
after you stop typing the query. **Replace** swaps the current match and
moves on, keeping the matches it already found; **Replace all** is one undo
step and leaves the caret where it was in the text (moved by the
replacements before it) instead of taking it to the first match. A query
that contains a line break is searched over the whole note.

### Copy and paste

The clipboard carries Markdown on both editors, so copying the same text
from either gives the same thing: a bulleted item copies as `- item`, a
heading keeps its `#`, bold keeps its `**`. Pasting Markdown into the
WYSIWYG editor brings the structure back rather than the characters.

Pasting a styled page from a browser still arrives as formatted text —
the HTML is used when the clipboard carries it. In the source editor,
**Paste as Markdown** (`Ctrl/⌘+Shift+V`, or the editor's menu) turns a
browser's copy into Markdown, linked to the page it came from (see
[web capture](web-capture.md#paste-as-markdown)).

### Undo and redo

Undo goes back one step at a time, and a step is what a writer would call
one thing done rather than one key pressed. Typing is a step, and so is a
run of Backspace or Delete in one direction: a held Backspace is undone with
one `Ctrl/⌘+Z`, not one character per press.

A step ends when you:

- stop for about a second;
- start a new word — the word you type after a space is a step of its own,
  so undo takes words back one at a time;
- press Enter, or move the caret;
- change from typing to deleting, or from Backspace to Delete.

A bracket or quote that closes itself belongs to the step of what you type
inside it: `(like this)` is undone whole, and typing the closing `)` over the
one the editor wrote does not end the step.

Each open note keeps its last 200 steps, as long as the text they hold fits
in about 32 MB; past that the oldest go first, and the latest step always
stays. A change over a long stretch of the note — Replace All, Tidy — keeps
only the lines it changed, so a big note does not weigh down its own undo.

### Opening and saving a note

**A note that does not open.** The pane says why in one line — the file is no
longer on the disk, Niman is not allowed to read it, or another program is
using it at the moment — and offers **Retry**. The note is also tried again by
itself the next time something asks the editor to look at the file again (the
app coming back to the front, a sync that touched it), so a read that failed
for a moment does not need a trip to another note and back. A file that is not
text at all is an attachment, and says so instead.

**When a note is saved.** About half a second after the last change (a couple
of seconds for a note over 2 MB, five over 16 MB), when the editor loses the
focus, and when the app goes to the background or the window is hidden. A
writer who never pauses that long is not left unsaved: the first change not
yet saved is written at most five seconds later (twenty over 2 MB, thirty over
16 MB), however the typing goes after it, so a crash or a flat battery costs a
few seconds of writing and not a session.

**A save that fails.** A full disk, a card that was pulled out, a program
holding the file: the status row reads **Could not save · retry** instead of
*Unsaved*, a message says so once, and Niman tries again after 2, 5 and 15
seconds — a tap on the status text tries at once, and so does the next change.
Nothing is thrown away meanwhile. If the note is switched away from or its tab
is closed while the write is still running or has failed, its text is kept by
the app: the note stays marked as unsaved, the write is retried, and quitting
waits for it (or asks, if it still cannot be written) instead of leaving with
the last edits lost. If you open that note again meanwhile, it opens with
those edits in it, as unsaved changes of its own — not with the older text the
disk still has — and the held write is dropped, so nothing old is ever written
over what you type next.

**A note changed by another program.** When a sync client, Niman's own sync or
another program rewrites a note that is open, every open note whose text you
have not changed — the tabs behind the one on screen too — shows the new file
at once. A note with edits of yours keeps them: your text wins and is saved
over the file — but before it is, the version the other program wrote is kept
in the note's [history](organization.md) (*changed outside Niman*), and a
message says so. The comparison is of the file with the one the editor last
read or wrote **and** with the one Niman's own writer last left, so nothing is
kept or announced when the other writer was the app itself (a second editor,
Replace all, an outgoing write) or when nobody touched it at all. When the
file's size and time match neither, its bytes are compared with what Niman
last wrote: a file that only shows another time (Android's storage does not
always report the one the write left) is still Niman's own and is not
announced.

**Line endings and the byte order mark.** The editor works with plain lines,
but the file keeps what it had: a note with Windows (`CRLF`) line endings is
saved with them, and a note that began with a UTF-8 byte order mark is saved
with it, so changing one character of a note changes one character of the
file — a version-control diff or a sync merge sees that character and not
every line. A note that mixes endings is saved with the one most of its lines
had (a tie goes to `LF`), so every line ends alike afterwards; a note of lone
`CR` lines, as the oldest Mac programs wrote, stays that way.

## Markdown support

Tables, task lists, footnotes, strikethrough, `==highlight==` (a marker's
yellow, the same in every theme), callouts, fenced code blocks with
syntax highlighting — and, in the read view and in live mode, a **copy**
button at a code block's top right that puts its code on the clipboard;
down a block taller than the screen it stays at the top of the part you
see. Math via `$…$` and `$$…$$` (KaTeX). Links: standard
Markdown links plus `[[wikilinks]]` (see [links](links.md)).

The read view reads a note as GitHub does — GitHub Flavored Markdown, as
`cmark-gfm` reads it — with Niman's own syntax added to it: what is inside
a quote or a list item is read as a note of its own, so a list in a quote
is a list and a quote, a heading or a code block on an item's line is one
in the item; a paragraph written under an item after a blank line stands
at the item's indent; `- [ ]` with nothing after it is an empty task; a
link's destination may sit on the line after its `[label]:`; `\*` and
`&amp;` read as `*` and `&`; a footnote is cited by its number, raised.
The WYSIWYG editor reads the note the same way: the backslash of an
escape is hidden as any mark is (`\$5` shows `$5`), a footnote citation
shows its label raised, and a callout's title is drawn with its own
formatting, in both.

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
look are stacked, and the cheatsheet is a page. On a desktop it is a
floating window that stays open, so several examples can be inserted one
after another without reopening it; the keyboard stays with the window,
so Esc still closes it after an insert. Opened from Settings, it is a page
in the Settings window's right column, with a back arrow.

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

- a list item wrapped over several lines is written back on one, its
  lines joined with a space (a line ending in a hard break keeps it, and
  an item's second paragraph stays a paragraph of its own); with that
  rule off, a line that continues an item is indented to the item's text
  instead, so a wrapped item stays one item;
- a paragraph wrapped over several lines — a note's own, a quote's, a
  footnote's — is written back on one, its lines joined with a single
  space; the editor wraps it on screen. Only a plain line break is
  joined: a line ending in a hard break (two spaces, or a backslash)
  keeps it, a blank line still ends the paragraph, and a line that
  starts something else — a heading, a list item, a quote, a rule, a
  fence, a table — stays on its own line. Headings (an underlined one
  included), code, tables, math, HTML, frontmatter and link definitions
  keep their lines. This is the **Join wrapped paragraphs** rule: turn it
  off in **Markdown rules** to keep your paragraphs wrapped as you wrote
  them;
- a heading gets one space after its hashes;
- runs of blank lines become one, and the trailing ones go;
- spaces left at the end of a line go, except the ones that mean a line
  break;
- a list comes back tight: no blank lines between its items, one space
  after each marker (five or more start an indented code block inside
  the item, and stay), and a task box written `[ ]` or `[x]` whatever
  case it was (a link such as `[x](…)` or `[](…)` is a link, not a box,
  and is left alone);
- a fenced code block gets its closing fence when the note forgot one.
  The fence goes at the end of the note: an unclosed block already runs
  to the end for every Markdown reader, so the note reads exactly as it
  did. If the code was meant to stop sooner, everything after it showing
  as code is the sign, and moving the fence up is yours to do.
  A language written the Pandoc way loses its braces and its dot
  (`{.dart}` becomes `dart`). Any other language is left as written,
  punctuation included: `c++`, `c#` and `objective-c` are names;
- the note ends with a single newline.

Beyond joining a paragraph's lines it never reflows your prose — no
rewrapping at a width, the words and the inline marks byte for byte —
and never touches what it cannot read:
tables, math, frontmatter and HTML come back byte for byte, and so does
the code inside a fence — only its two fence lines are read. Tidying
twice changes nothing the second time. The note is saved first, so what
is tidied is the note as it stands. A note written with Windows line
endings keeps them when it is tidied on close.

It also runs by itself: a note you edited is tidied when it is closed.
That is a setting of the library (**Settings → Editor → Tidy the
Markdown on close**, on by default), so every device writes the
library's notes the same way. **Markdown rules**, right below it, picks
which of the rules above run; notes over 4 MB are left as they are. A
voice note is never tidied: its body is the clip document, not prose. The
command is not offered on it — not in its ⋮, not in the command palette
or on a key bound to it — and the on-close tidy leaves it as it is.

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
next to the list or voice-note switch when the note has one. On a list
note the same menu carries the **Shopping list** entry, and on a
shopping list the **Checklist** one, which is how the two are turned
into each other (see [list notes](lists.md)). The row
keeps to the note's column, so its first button sits over the start of
the text. It stays when there is nothing to format, in the preview or on
a list note, so the ⋮ is always in the same place. The note's name is
in the window's title. A note that opens with frontmatter shows its
fields above the first line of the note as well, in both editors and in
the read view: closed to one row until you open it, and away while the
note is scrolled past its head (see [frontmatter](organization.md)).

On a phone the toolbar keeps its size and rides the keyboard, and the ⋮
in the note's bar offers the same actions. Opening the keyboard — a tap
or a selection — takes the pane's bottom with it, and the note comes up
just enough to keep what the keyboard was raised for above it: the whole
selection where it fits, the caret's end where it does not. A selection
already in view is left where it is, and so is a scroll you started
yourself.

The same formatting is also on the **context menu**: right-click in the
editor (long-press on a phone). It is grouped by what you are doing, as
Obsidian's is:

- **Open link** and **Copy link** when the click lands on a Markdown
  link whose target leaves the library (`https://…`, `mailto:…`): the
  same URL Ctrl+click opens, and the URL on the clipboard;
- the spelling's suggestions for a misspelled word, and a table's
  **Row ›**, **Column ›** and sorts on a table's cell, next;
- **Paste as Markdown**: what was copied from a web page, as Markdown
  linked to its page (see
  [web capture](web-capture.md#paste-as-markdown));
- **Add link** (`[[…]]`) and **Add external link** (`[…](https://)`);
- **Format ›** — bold, italic, strikethrough, highlight, underline, superscript,
  subscript, code — **Paragraph ›** — headings 1 to 6, **Body** (the
  heading taken off), bulleted, numbered and checkbox lists, quote — and
  **Insert ›** — footnote, table, columns, horizontal rule, code block,
  math block, image;
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
anything into ends the list instead — the usual second Enter. On an empty
item that is nested, Enter first takes it back one level, as Shift+Tab
does, and only at the margin removes the marker. Inside a fenced code
block, a math block or the frontmatter it does nothing: a dash there is a
dash.

Enter in a quote or a callout starts the next line with the same `>`
marks, and a list inside the quote goes on behind them: `> - milk` and
Enter gives `> - `, `> > x` gives `> > `, and the first line of a callout,
`> [!note]`, gives `> ` for its body. Enter on a line with nothing after
its marks, `> `, takes them off and leaves the quote; on an empty list
item in a quote it takes the marker, and the next Enter the quote. Enter
and Tab read the line the same way, behind the `>`.

Brackets come in pairs, in both editors and on every platform: `(`
writes `()`, `[` writes `[]` and `{` writes `{}`, with the caret between
them, so `[[` opens a whole wikilink. The closing bracket is added only
before a space, a closing bracket or the end of the line; before a word
and after a backslash (`\(` starts inline math) a bracket is just
itself. Typing the closing bracket where the pair put one steps over it,
Backspace between an empty pair removes both, and a bracket typed over
a selection wraps it.

The punctuation a Markdown note is written with pairs too, each by its
own rule (#718). `*` writes one star and closes it: the second star
typed where it stands steps over, so `**bold**` and `***bold italic***`
are typed straight through, three and three. A space after a star makes
it a literal one — `* ` at the start of a line opens a list item, and
`a * b` stays a multiplication. After a word a star is only itself:
`2*3` stays a product, and a star typed after `this` in `make *this
bold` closes the emphasis. `_` opens only when no word stands
before it, so `snake_case` and a closing `word_` are what they are. The
quotes `"`, `'`, `«»` and `“”` open when no word stands before them
either: after a word a quote closes one already spoken, like the
apostrophe in `don't`. A star or a quote already in the note does not
count as a closing character, so typing `*` in front of `"quote"` or
`(` in front of `*emph*` writes just that character. Backspace takes both
stars or both quotes only when the closing one was written by the pair:
between the two closing stars of an existing `**bold**`, or inside `''`,
it takes one. `<`, `>` and the backtick do not pair at all —
`a < b` is a comparison, an autolink has its own `>`, and a fence is
three backticks.

In code and maths — a fenced or indented code block, an inline code
span, a `$$` block or inline `$…$` — none of that punctuation pairs, nor
wraps a selection: `*` in `char *p` writes one star, `$a * b$` stays a
product and a quote is just a quote. The brackets `()`, `[]` and `{}`
still pair there, as everywhere else: code and formulas are written
with them. A code span counts once both of its backticks are written;
while only the opening one is, the text after it is not code yet.

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

A table wider than the pane is fitted to it, the same way in the read view
and in live mode: every column shows, its cells wrap inside it, and a column
keeps its longest word whole where the pane has room for it. A long cell in
one column does not squeeze the others; where the pane cannot hold all the
words, the columns share it evenly and only the longest words break. A table
that already fits keeps each column as wide as its widest cell.

### Columns

Two or more columns of blocks on one row — a picture and a table beside
prose, two columns of text — written as Pandoc's and Quarto's fenced
divs:

```markdown
:::: columns
::: {.column width="40%"}
![[map.png]]

| Height | 2,218 m |
|---|---|
:::

::: column
Prose, a list, a table, a callout…
:::
::::
```

- **Fences.** A fence stands at the margin of what it is in — the note,
  a list item, a quote — with no indent, as Pandoc reads it. An opener is
  three colons or more and a class, `columns` or `column`, as a word or
  in braces (`::: {.column}`); colons after it are optional. A line of
  colons alone closes the div opened last, whatever its length. Any
  other `::: name` stays the text it is; inside `columns` its closer is
  matched with it, so it does not close the column around it. An opener
  needs a blank line, a heading or another fence before it: a `:::` line
  inside a paragraph is the paragraph's. An opener with no closer runs
  to the end of what it is in, as an unclosed code fence does.
- **Widths.** `width="40%"` gives a column its share of the row; the
  columns without one share what is left equally. Each column is at
  least 16 em wide: columns that do not fit move to the next row, and on
  a phone's pane they stack one under the other, in the order they are
  written. What decides is the width the note has, not the device: a
  narrow window stacks them too, a wide tablet puts them side by side.
- **What a block holds.** Anything: text, lists, tables, code, formulas,
  diagrams, pictures, callouts. Text inside `columns` but outside any
  `column` is a column of its own. A footnote defined in a column is
  drawn with the note's footnotes, at its end.
- **Nesting.** Columns may stand in a callout, a quote, a list item or a
  column. Only the outermost level sits side by side: columns inside a
  column are drawn one under the other.

In **live mode** the columns sit side by side and are edited where they
stand. Out of the caret's reach each fence is a thin band with nothing
in it; with the caret in the block the bands show a hairline and a chip
naming each column (`column · 40%`); with the caret on a fence line it
shows its source, to edit the width. A fence is reached by a click on
its band, by **Home** at the start of a column's first line, by a find,
or in source mode. The arrows go through the note in the order it is
written: **Right** at a column's last character goes to the next
column's first, **Down** on a column's last row to the next column's
first row — and out of the block after the last — and **Up** and
**Left** the other way. The gutter numbers the block's first and last
lines, with a bracket between them; source mode shows every line,
numbered, the fences coloured as a code fence's. The block's opener has
a fold arrow, which folds the block to its first line.

**Insert columns** writes two columns at the caret, on lines of their
own, with the first column's text selected so typing replaces it: the
**Columns** toolbar button, **Insert › Columns** in the editor's menu
(the Insert sheet on a phone), and **Insert columns** in the command
palette.

An export lays the columns out as the app does: the HTML page, the PDF
and the EPUB by the same rule, in CSS. Elsewhere — GitHub, Obsidian —
the `:::` lines show as text and the blocks one after the other; Pandoc
and Quarto read them as columns. Nothing is lost or reordered.

A few places keep the columns stacked, one under the other, where the
rest of the app sets them side by side: in live mode, a quote or a
callout of more than 2 000 lines, a quote inside another or inside a
list item, and a block with a folded section in it; and the read view
of a book or a recognized text, whose text can be selected. A heading in
a side-by-side column has no fold arrow of its own — the gutter has one
row for several columns — and folds inside its column where the columns
stack.

### Diagrams (Mermaid)

A fenced block whose language is `mermaid` is drawn as a diagram, in the
read view and in live mode alike:

    ```mermaid
    flowchart TD
      A[Start] --> B{Ok?}
      B -->|Yes| C[End]
    ```

Twenty-two kinds are drawn:

- **Flowcharts** (`flowchart` or `graph`): all four directions, the node
  shapes (the double circle `(((…)))` too), subgraphs (nested too, and
  joined by their names — `A --> S` or `S1 --> S2` reaches the box), every
  edge spelling and its label, the invisible link `~~~`, which places
  its nodes and draws nothing, and the look of a node or a subgraph —
  its fill, outline, outline width and text colour — given by `style`
  (`style B fill:#fef3c7,stroke:#d97706,stroke-width:2px,color:#000`) or
  by a class: `classDef warn fill:#fef3c7`, then `class B,C warn` or
  `B:::warn`, and `classDef default` for every node. A `style` wins over
  a class, and a class given later over one given earlier. A colour is
  written as `#rgb`, `#rrggbb`, `rgb(…)` or a common name; a fill with no
  `color` gets black or white text, whichever reads on it.
- **Sequence diagrams** (`sequenceDiagram`): participants and their
  aliases, every message arrow, notes, and the frames of `loop`, `alt`,
  `opt`, `par`, `critical` and `break` with their sections.
- **Pie charts** (`pie`): the slices clockwise from the top with their
  shares, a legend (with each value under `showData`) and the title. Each
  slice has a colour of its own, told apart by colour-blind readers too;
  past eight slices the rest are gathered into "Other".
- **Class diagrams** (`classDiagram`): classes in three compartments —
  name and stereotype, attributes, methods — every UML relation with its
  ends, cardinalities and label, notes and namespaces.
- **State diagrams** (`stateDiagram`, `stateDiagram-v2`): states, the
  start and end `[*]`, forks, joins and choices, composite states (nested
  too) and notes.
- **Entity-relationship diagrams** (`erDiagram`): entities with their
  attributes and keys, and relationships ending in the crow's feet of
  their cardinalities, solid or dashed, with their labels.
- **C4 diagrams** (`C4Context`, `C4Container`, `C4Component`,
  `C4Dynamic`, `C4Deployment`): people, systems, containers and
  components — external ones, databases and queues too — as cards with
  their technology and description, inside nested boundaries, and the
  relationships between them; a relationship's direction (`Rel_U`,
  `Rel_L`…) is left to the layout.
- **Requirement diagrams** (`requirementDiagram`): requirements of every
  kind and elements, each with its attributes (a long text wrapped), and
  the relationships between them — `contains` with its circled cross, the
  others dashed with an arrow.
- **Gantt charts** (`gantt`): sections and their tasks on a time axis,
  every way of writing a start and an end (dates, durations, `after`,
  `until`), `done`, `active`, `crit` and milestones, the days `excludes`
  leaves out, the `dateFormat` and the `axisFormat`.
- **Timelines** (`timeline`): periods along a time line, their events
  under them, sections in a colour each.
- **User journeys** (`journey`): the tasks of each section with a face
  that shows how each went, and dots for the actors who took part.
- **Git graphs** (`gitGraph`): branches as lanes, commits with their ids,
  tags and types, merges and cherry-picks, left to right or top to bottom.
- **Kanban boards** (`kanban`): columns of cards, each with its ticket,
  assignee and priority.
- **Quadrant charts** (`quadrantChart`): four named quadrants, the axes'
  ends, and points placed from 0 to 1 on each axis.
- **XY charts** (`xychart-beta`): bars and lines over categories, the
  values in round steps, upright or `horizontal`.
- **Sankey diagrams** (`sankey-beta`): flows written as CSV, drawn as
  bands as wide as their values between bars as tall as what passes
  through them.
- **Block diagrams** (`block-beta`): blocks in a grid of `columns`, as
  wide as the columns they `span`, empty cells with `space`, groups
  nesting a grid of their own, block arrows pointing any way, and edges
  between blocks.
- **Packet diagrams** (`packet-beta`): fields by their bits (`0-15`, `106`
  or `+16`) in rows of 32, each with its first and last bit's numbers, a
  field longer than its row going on in the next.
- **Radar charts** (`radar-beta`): axes as spokes clockwise from the top,
  curves with a value for each axis (in order or by axis id), rings as
  circles or polygons, `min`, `max`, `ticks` and a legend.
- **Treemaps** (`treemap-beta`): a tree written by indentation, each leaf
  a rectangle as large as its value's share, each section holding its
  nodes under its name; a leaf too small for its name is drawn without it.
- **Architecture diagrams** (`architecture-beta`): services with their
  icons (`cloud`, `database`, `disk`, `internet`, `server`; any other a
  plain box), junctions and nested groups, set on a grid by the sides
  their edges name (`db:L -- R:server` puts the server left of the
  database), each edge at right angles from side to side with its
  arrows and label.
- **Mind maps** (`mindmap`), the tree drawn left to right.

In any of them a label may write a character as an entity, as in Mermaid:
`&amp;`, `&nbsp;`, `&#65;`, or Mermaid's own `#quot;` and `#58;`. They are
written out after the line is read, so `#58;` puts a colon in a label
where a plain `:` would end it.

What only colours or animates a diagram — `rect`, activations,
`autonumber`, C4's `UpdateElementStyle` and `UpdateLayoutConfig`, and
`style` or `classDef` anywhere but in a flowchart — is read and drawn
without, in the theme's own colours. ZenUML, a plugin Mermaid itself
loads from outside, is left as source with a note saying so. While the caret is in the fence, live mode
shows the source again; a tap in the read view leaves it a diagram, and the
read view where it is. A syntax error
leaves the block as source, the offending line underlined and the
message under it ("Line 4: expected \"-->\" after \"--\""), so the
diagram is one edit away.

    ```mermaid
    sequenceDiagram
      Alice->>Bob: Hello
      alt is busy
        Bob-->>Alice: Later
      else
        Bob-->>Alice: Hi!
      end
    ```

The icon at the top right of a diagram opens it alone, to pinch and drag.
It opens whole and centred: a diagram larger than the screen is shrunk to
fit it, a smaller one keeps its own size, and the view never opens
enlarged. Pinch or scroll to zoom in (up to eight times its own size) and
drag to reach every edge; zooming out stops at the whole diagram, however
wide or tall it is. A double tap shows it at its own size where you tapped,
and a second one shows it whole again. Turning the device fits it again.
An export carries the diagram as SVG: the HTML, the PDF and the EPUB show
it, and outside Niman the block stays standard Mermaid.

The engine is Niman's own, written in Dart and drawn on every platform;
there is no browser and no script inside the app.

### Mind map

**Convert list to mind map** replaces the list at the cursor with a
`mindmap` fence as one undo step, so Ctrl+Z brings the list back. It is
in the command palette, and in the editor's Tools sheet on a phone. One
outermost item becomes the root; several get a root to hang from. A
paragraph or a code block an item holds joins that item's words, and the
cursor may stand in one. The **Tools** section below lists the sheet.

## Tools

The toolbar's **Tools** button opens the editor's extra tools. They are
not formats: each one reads the note and writes something back. Both
editors offer the same tools, and a tool that has nothing to work on in
this note is listed greyed with the reason rather than hidden.

### Indenting a list item

Tab, Shift+Tab and the toolbar's indent and outdent (`Ctrl/⌘+M`,
`Ctrl/⌘+Shift+M`) move a list item to where its list says, not by a fixed
number of spaces: Markdown only nests a line under an item when it is indented
to that item's content, which is three columns for `6. `, four for `10. `, two
for `- ` or `- [ ] `.

- **Indent** nests the item under the item above it at its level. An
  ordered item starts the sublist at `1` (or goes on from the last number of a
  sublist already open under that item); a bulleted item keeps its bullet. The
  lines under the item that belong to it move with it. The items that were
  numbered one by one after it close up (`8.` becomes `7.`); a list numbered
  any other way is left as written. Enter on `6. foo` and then Tab on the empty
  `7. ` gives `1. ` under `6.`, with the caret ready to type.
- **Outdent** is the inverse: the item goes back to its parent's indent, takes
  the number after the parent's when both are ordered, and the parent's next
  siblings make room. An item with no parent loses up to the indent width of
  its own indent.
- The first item of a list has nothing to nest under, so it moves by the
  indent width (Settings, 2–8). So does every line that is not a list item.
- On several selected lines, each item is placed by the same rule; items
  selected together move together, and an item selected with its own children
  keeps its shape. Inside a quote or a callout the rule is the same, behind the
  `>`.

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

The rendered note shows Markdown, math, diagrams, and fenced code
coloured by the language its fence names.

Extras: word count, heading outline, heading folding.

The word count is of your words, not of the Markdown around them. The
marks at the head of a line — a heading's `#`, a list's `-` or `1.` and
its task box, a quote's `>` — are not counted, so `## Title` is one word
and `- [ ] buy milk` is two. A line that is only syntax counts for
nothing: a rule (`---`, `***`), a table's `|---|---|` row, the pipes
between a table row's cells and the lines that open and close a code
fence. The frontmatter at the top of the note, between its two `---`
lines, is not counted either. The words inside a code block are.

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

The spelling panel lists the note's misspellings, each with hunspell's
suggestions; tapping one replaces the word. The panel opens at once on
any note, however long: it checks the note a little at a time, with a
bar showing how far it has got, and the list fills as it goes. The suggestions arrive just after the words they
belong to. A fix updates the list on the spot, without checking the
whole note again. The panel lists at most 200 words; when a note has
more it says so, and **Check again** lists the next ones once some are
fixed.

Wherever the wide layout shows the panel, the review is its **Spelling**
pane — beside the note, or over it on a narrower window (#712): you keep
writing while it is open, and it checks the note again after each edit,
once you pause. A
click on a word selects it in the note; **Ignore** takes the word off the
list for as long as the note stays open, however much you edit it and even
if you close the pane and open it again (it is not remembered after that:
**Add to dictionary** adds it to the library's words for good). The list
stays on screen while the note is checked again, and if the note changed
under a word before you used it, nothing is replaced: the list is
refreshed instead. A phone, and a window too narrow for the wide layout,
opens it as a sheet over the note from the status row's button.
