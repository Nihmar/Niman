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

## Markdown support

Tables, task lists, footnotes, strikethrough, fenced code blocks with
syntax highlighting. Math via `$…$` and `$$…$$` (KaTeX). Links: standard
Markdown links plus `[[wikilinks]]` (see [links](links.md)).

Formatting toolbar buttons apply to whichever editor is active.

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
