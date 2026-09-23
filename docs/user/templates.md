# Templates

Templates live in the library's `templateFolder` (default `Templates`).
Creating a note from a template substitutes `{{placeholders}}` and merges
the template's frontmatter into the new note.

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
| `{{counter:name}}` | Per-library counter, hands out 1, 2, 3… |
| `{{clipboard}}` | Paste contents (title-cased by filters below) |
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
(`+7d`, `+1y`, … — applied left to right, before case filters).

## File directives

A template's frontmatter may carry creation directives:

```markdown
---
folder: Journal/{{date:YYYY}}/{{date:MM}}
filename: "{{date:YYYY-MM-DD}} {{title}}"
---
```

`folder` / `filename` accept placeholders (resolved before the path is
used). The remaining frontmatter merges into the new note. A malformed
directives block aborts creation with the reason shown — the note is not
half-created.
