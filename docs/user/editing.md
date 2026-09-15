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
