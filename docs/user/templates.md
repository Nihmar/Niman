# Templates

Templates live in the library's `templateFolder` (default `Templates`).
Creating a note from a template substitutes `{{placeholders}}` and merges
the template's frontmatter into the new note.

## Commands in the editor

In a note under the template folder, the editor gives every `{{…}}` the
engine answers a color of its own (`template` in the theme), arguments and
filters included, so the placeholders stand apart from the Markdown around
them. A `{{…}}` that names no command stays plain, so a typo reads as one
before the template is used. A note outside the template folder colors
nothing.

## Placeholders

Substitution, not a language — unknown `{{…}}` is copied verbatim:

| Placeholder | Meaning |
|-------------|---------|
| `{{title}}` | The new note's name |
| `{{date}}` / `{{date:FORMAT}}` | Date, optional format (default `YYYY-MM-DD`) |
| `{{time}}` / `{{time:FORMAT}}` | Time (default `HH:mm`) |
| `{{now}}` / `{{now:FORMAT}}` | Date + time (default `YYYY-MM-DD HH:mm`) |
| `{{uuid}}` | A fresh UUID v4, one per occurrence |
| `{{cursor}}` | Caret stop after insertion (writes nothing; `{{cursor:2}}` numbers stops) |
| `{{counter:name}}` | Per-library counter, hands out 1, 2, 3… (two creations at once never share a number) |
| `{{clipboard}}` | Paste contents (title-cased by filters below) |
| `{{selection}}` | The text selected in the editor when the note was created (empty when nothing is) |
| `{{ask:Label}}` / `{{ask:Label:default}}` | Prompt for a value when creating |
| `{{choice:Label:a,b,c}}` | Pick from a list when creating |
| `{{parent}}` | Reserved: answered by the creation flow (e.g. `[[{{parent}}]]`); never `{{ask:parent}}` |
| `{{include:name}}` | Paste another template's content (its own placeholders resolve too) |

Date formats use the tokens you already know: `YYYY MM DD HH mm ss`,
plus `D` / `M` / `H` / `m` / `s` without the leading zero, `dddd` / `ddd`
for the weekday's name, `MMMM` / `MMM` for the month's (in the app's
language), `WW` for the ISO week and `Q` for the quarter — and date
arithmetic, see filters. `{{folder}}` and `{{title}}`-style
self-references inside directives resolve against the creation context.

## Filters

Append with `|`: `{{title|slug}}`, `{{date:YYYY-MM-DD|+7d}}`,
`{{counter:quest|pad:3}}`. Known filters: case (`upper`, `lower`,
`title`), `slug`, `trim`, numeric padding (`pad:3`), and date moves
(`+7d`, `+1y`, `startof:month`, … — applied left to right, before case
filters). Moves apply only to `{{date}}`, `{{time}}` and `{{now}}`, and
only as the first filters: `{{date|+1d|upper}}` works, while
`{{date|upper|+1d}}` and `{{title|+1d}}` are left standing. A move
in days or weeks counts calendar days, not 24 hours, so `+1d` is always
the next date — a clock change does not make it repeat a day.
`{{cursor}}` takes no filters.

## Checking a template

A template can be read before it is used, and what the tables above
accept is exactly what the checker accepts: it reads the engine's own
vocabulary — the placeholder names, the filter names and the date tokens
— and asks the engine's own rules whether a filter applies where it
stands, so a name added to the engine is a name the checker already
knows. It reports three kinds of mistake:

- braces that do not pair up: `{{title`, `title}}`, `{{ {{title}} }}`,
  `{{}}`, and a `|` with no filter after it: `{{title|}}`;
- a placeholder, filter or date token the engine does not answer:
  `{{titlex}}`, `{{title|upperr}}`, `{{date:YYYYY}}`;
- an argument the engine cannot read, or a filter where it does not
  apply: `{{title|pad:wide}}`, `{{date|+xd}}`, `{{time:HH'|mm}}`,
  `{{ask:}}`, `{{counter}}`, `{{date|upper|+1d}}`, `{{cursor|upper}}`.

Each mistake says where it is, what is wrong, and — where the correction
is deterministic and safe — the text that fixes it. A name within two
edits of exactly one known one is suggested: `{{titlex}}` → `{{title}}`,
`{{title|upperr}}` → `{{title|upper}}`, `{{date:YYYYY}}` → `{{date:YYYY}}`.
A stray `|` and the filters on a caret are dropped: `{{title|}}` →
`{{title}}`, `{{cursor|upper}}` → `{{cursor}}`.
A suggestion is only ever text to apply over the mistake it is on; the
checker rewrites nothing.

Where the fix would be a guess, there is no suggestion and the mistake is
reported alone: two known names equally close (`{{titel}}` is two edits
from both `title` and `time`), a `pad:` width that is not a number (only
the author knows the width), a date move whose count is not one
(`{{date|+xd}}`), a move out of its place (`{{date|upper|+1d}}` — before
or after the case is the author's call), a field with no label
(`{{ask:}}`), a counter with no name (`{{counter}}`), and an unclosed
`{{` with text after it — closing that one would swallow a sentence the
author wrote, so the checker points at it and stays quiet.

It reads the placeholders only: nothing is said about the Markdown around
them, about the frontmatter, or about the `niman:` directives block,
each of which has its own parser.

The checker runs in the editor, on the templates folder alone: a `{{…}}`
in a note anywhere else is ordinary text. A template is read again a
quarter of a second after typing stops — never on the keystroke itself —
and each mistake is drawn as a wavy underline under the span it is on, in
the colour the spelling's own underline uses. Putting the caret in a
marked span opens the hint: what is wrong, and, where a fix was computed,
**Did you mean …?** with that fix as a single button. The tap applies it
as one undoable edit and nothing is ever rewritten without it; where no
fix is safe the hint says so and offers only **Dismiss**. A template with
problems also carries a quiet count in the status row, and a clean one
carries nothing at all.

A note being made from a template is not the template: the **Fill in the
template** dialog edits no source, so the checker is not there.

## File directives

A template's frontmatter may carry creation directives — under a `niman`
map of their own, so they never become properties of the note:

```markdown
---
niman:
  folder: Journal/{{date:YYYY}}/{{date:MM}}
  filename: "{{date:YYYY-MM-DD}} {{title}}"
---
```

`folder` / `filename` accept placeholders (resolved before the path is
used). The remaining frontmatter merges into the new note. A `niman`
block that does not parse declares nothing: the note is still created —
in the folder the creation came from, under the name the template gives
it — and a message says what the block's problem is.
