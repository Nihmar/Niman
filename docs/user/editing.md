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
