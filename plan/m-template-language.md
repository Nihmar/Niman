# Templates — a language worth writing in

**Status:** Planned; the four design choices below were made by the user
on 2026-09-09 · **Depends on:** M4
(`templates/engine.dart`, `templates/repo.dart`, the frontmatter parser) ·
**Spec:** user request: *"definiamo bene un meta linguaggio per i template
che sia espressivo e potente"*.

## Purpose

T-M4-06 built substitution, not a language: six placeholders, no
arguments beyond a date format, everything else copied through. It is
enough for a daily note and runs out immediately after. This slice
defines what a template can say, and stops at a line drawn on purpose.

## The line

A template is a note with holes in it. Someone must be able to read one
and know what it will produce, without running it. So this design has
**no conditionals, no loops, no expressions and no variables** — the
things that turn a template into a program you have to debug. What it
adds instead is *more kinds of hole*, and one place to put instructions
that are not text at all.

Everything below therefore falls into three layers, and each one has a
different syntax **because it does a different thing**:

| Layer | Written as | Produces |
|-------|-----------|----------|
| Values | `{{name}}`, `{{name:arg}}`, `{{name:arg\|filter}}` | text, in place |
| Directives | a `copist:` block in the template's frontmatter | nothing — they steer the creation |
| Prompts | `{{ask:Label}}`, `{{choice:Label:a,b,c}}` | text the user types once, at creation |

An unknown placeholder is still left standing. That rule is what makes a
typo visible in the note instead of silently eating a line, and nothing
here changes it.

## Current state

`applyTemplate(source, {title, now, uuid})` replaces `{{title}}`,
`{{date}}`, `{{date:FORMAT}}`, `{{time}}`, `{{now}}` and `{{uuid}}`.
`formatDateTime` knows `YYYY YY MM M DD D HH H mm m ss s` and
single-quoted literals. The shell asks for a template, then a name, then
creates the note in the FAB's target folder with the substituted text.

## The three answers asked for

1. **`{{folder:…}}`** — yes, but not as a placeholder. A placeholder
   produces text where it stands; "put this note in Journal/2026/09" is
   an instruction about the file, and writing it inline means the
   template carries a line that must then be deleted from every note it
   makes. It goes in the frontmatter block (T-TPL-02), where it can be
   read, edited and validated as data.
2. **`{{date}}` / `{{time}}`** — already there. What is missing is the
   tokens people actually want in them: month and weekday *names*, the
   ISO week, and dates other than today (T-TPL-01).
3. **`{{date|time}}`** — recommended **against** as "combine two
   placeholders": `{{date}} {{time}}` already does that, and
   `{{now:YYYY-MM-DD HH:mm}}` does it in one. The `|` is worth far more
   as a **filter pipe**, which is what every template language on earth
   uses it for: `{{title|slug}}`, `{{ask:Author|upper}}`,
   `{{date:YYYY-MM-DD|+7d}}`. One meaning for one symbol.

## The choices, as made

Four questions were put to the user on 2026-09-09; these are the
answers, and the tasks below follow them rather than restating the
alternatives.

1. **Instructions live in the template's frontmatter**, in a `copist:`
   block — not as inline `{{folder:…}}` placeholders, and not both.
2. **`|` means a filter pipe**, and only that.
3. **Variable fields are a form shown before the note is created** — not
   editor tab stops, and not both. So a field can name the file.
4. **First:** the date vocabulary, `{{parent}}` + `{{clipboard}}`, and
   `{{include:…}}`. The counter and the caret marker wait.

## Tasks

The first four are the slice as ordered; T-TPL-05 and T-TPL-07 are held
back by choice 4 and land after.

- [x] **T-TPL-01** The value layer: filters and a real date vocabulary.
  `{{name:argument|filter|filter}}`, filters applied left to right.
  Filters: `upper`, `lower`, `slug` (the link slug, so a template can
  build a wikilink to a note it names), `title` (title case), `trim`,
  `pad:N`, `default:text`. Date tokens gained: `MMM`/`MMMM` (month name),
  `ddd`/`dddd` (weekday name) — both in the app language — `W`/`WW` (ISO
  week), `Q` (quarter). Date offsets as filters: `+3d`, `-1w`, `+1m`,
  `+1y`, and `startof:week` / `endof:month`. *AC: `{{date:dddd|upper}}`
  on a fixed clock; an offset crossing a month and a year boundary; an
  unknown filter leaves the placeholder standing, whole.*
- [x] **T-TPL-02** The directive layer: a `copist:` mapping in the
  template's own frontmatter, consumed on creation and never written to
  the new note. Keys: `folder` (where the note goes, library-relative,
  created if missing), `filename` (what it is called, placeholders and
  all), `open` (`editor` | `preview` | `none`), `append` (add to the file
  if it already exists instead of uniquifying the name — this is what
  makes a daily note *a* daily note rather than `Daily 2.md`). Every
  value is substituted first, so `folder: Journal/{{date:YYYY}}/{{date:MM}}`
  works with no nesting problem: the placeholders are gone before the
  path is read. *AC: a template that files itself; a second use of an
  `append` template lands in the same file; the `copist:` key never
  appears in a created note, while the template's other frontmatter
  does.*
- [x] **T-TPL-03** The prompt layer: `{{ask:Label}}` and
  `{{choice:Label:one,two,three}}`. Every distinct label is asked once,
  in one form shown before the note is created, in the order the template
  mentions them; the answer fills every occurrence, directives included —
  so `filename: "{{ask:Character}}"` names the file from the form.
  `{{ask:Label:hint}}` seeds the field. *AC: a template with three fields
  asks three questions once each; cancelling creates nothing; an answer
  reaches both the body and the filename.*
- [x] **T-TPL-04** Context values: `{{parent}}` (the note the creation
  was started from — the backlink that makes a template worth using in
  worldbuilding), `{{folder}}` (the folder the note landed in),
  `{{clipboard}}`, `{{selection}}` (the editor selection, when the
  creation came from "new note from selection"; empty otherwise).
  *AC: creating from inside a note links back to it; an empty clipboard
  yields an empty string, not the literal placeholder.*
  **Built differently:** `{{parent}}` gives the note's *name*, not a
  ready-made wikilink. A placeholder that wrapped itself in `[[…]]` could
  not be used in a sentence, in a frontmatter value, or with a filter, and
  it would have to guess between the two link formats the settings offer.
  A template writes `[[{{parent}}]]`, which is also what it looks like in
  the note. The four resolve to the empty string when there is nothing to
  say and stand only when the caller supplied no context at all.
- [x] **T-TPL-06** `{{include:path}}` — another template's text, pasted
  before substitution, so a library can keep one header and one footer.
  Depth-limited to 5, cycles refused with the cycle named in the created
  note rather than a hang. *AC: a two-level include; a self-include
  produces a visible error, not a stack overflow.*
  A path is tried inside the template folder first and from the library
  root second, with the `.md` added when it was left off, so
  `{{include:_repro}}` is what a person writes. Because the paste happens
  before anything else runs, a partial's own `{{ask:…}}` fields join the
  same form as the template that included it.
- [ ] **T-TPL-08** A reference the user can reach: a "Template
  placeholders" help sheet in the settings, next to the template folder
  row, listing every placeholder and filter with an example — the same
  shape as the todo.txt help (T-TD-09).
- [ ] **T-TPL-09** Tests: unit for every placeholder, filter, token and
  directive; widget for the prompt form and the folder/filename
  directives. *AC: green.*

### Held back (choice 4)

- [ ] **T-TPL-05** `{{counter:name}}` — a per-library counter that
  increments on use, kept in `.copist/counters.json`, formattable with
  `|pad:3`. Chapter numbers, ticket numbers, session numbers.
  *AC: two notes from the same template get 1 and 2; the count survives
  a restart; a counter is per name and per library.*
- [ ] **T-TPL-07** `{{cursor}}` — where the caret lands when the note
  opens, removed from the text. Numbered stops `{{cursor:1}}`,
  `{{cursor:2}}` if the editor can be made to walk them; one stop
  otherwise. *AC: the caret is at the marker, and the marker is not in
  the file.*
- [ ] **T-TPL-08** A reference the user can reach: a "Template
  placeholders" help sheet in the settings, next to the template folder
  row, listing every placeholder and filter with an example — the same
  shape as the todo.txt help (T-TD-09).
- [ ] **T-TPL-09** Tests: unit for every placeholder, filter, token and
  directive; widget for the prompt form, the folder/filename directives
  and the caret. *AC: green.*

## What the layers buy, by the way the app is used

**Worldbuilding.** `{{ask:…}}` plus `{{choice:…}}` turns a template into
a character sheet that fills itself in; `{{parent}}` links the new
character back to the faction page it was created from; `folder:` files
every location under `World/Locations` no matter which folder the tree
happened to be showing; `{{counter:chapter|pad:2}}` numbers the
chapters.

```yaml
---
copist:
  folder: World/Characters
  filename: "{{ask:Name}}"
type: character
tags: [character, "{{choice:Allegiance:Crown,Rebels,Neutral}}"]
---
# {{ask:Name}}

**Faction:** {{choice:Allegiance:Crown,Rebels,Neutral}}
**First seen:** {{parent}}
**Created:** {{date:dddd D MMMM YYYY}}

## Appearance
{{cursor}}
```

**School.** A lecture note wants the week, the weekday and the course:
`filename: "{{date:YYYY-MM-DD}} {{choice:Course:Analysis,Physics,History}}"`,
`folder: University/{{choice:Course:…}}/Week {{date:WW}}`, and a
`{{date:YYYY-MM-DD|+7d}}` line for the next lecture.

**Programming.** `{{clipboard}}` drops the stack trace you copied into a
bug note; `{{uuid}}`; `{{include:Templates/_repro.md}}` keeps one
reproduction checklist shared across every bug template; `{{title|slug}}`
builds the branch name.

**Work.** A meeting note with `append: true` and
`filename: "{{date:YYYY-MM}} {{ask:Project}} log"` turns every meeting
into an entry in one monthly file instead of forty files.

## Technical design

- **Modules:** `templates/engine.dart` grows the filter pipeline and the
  token table; new `templates/directives.dart` (parse and strip the
  `copist:` block), `templates/prompts.dart` (collect the fields),
  `templates/counters.dart`; `ui/template_form.dart` for the prompt
  dialog; `ui/template_help.dart` for T-TPL-08.
- **Order of operations**, fixed and documented, because everything else
  follows from it: includes are pasted → prompts are collected (one pass
  over the whole text, directives included) → values are substituted →
  directives are read off the frontmatter and removed → the note is
  created → the caret marker is consumed. Prompts before values means an
  answer can be a placeholder's argument; directives after values means a
  path can be built from a date.
- **Parsing** stays a regex over `{{…}}` with the argument running to the
  closing braces, extended with a `|` split *outside* quotes so a format
  may contain one. No nesting: a placeholder inside a placeholder is not
  supported and does not need to be, since directives are substituted as
  plain strings.
- **The `copist:` block** is read with the existing YAML parser, so a
  malformed one gets the treatment malformed frontmatter already gets —
  named in the editor's warning bar, not a crash.
- **Counters** are a small JSON file next to `settings.json`, written
  atomically like everything else in `.copist/`.

## Exit criteria

- Every placeholder, filter and directive above works, is covered by a
  test, and is listed in the help sheet.
- A template with a bad placeholder, a bad filter or a bad `copist:`
  block still creates a note, with the mistake visible in it.
- The three worked examples above are shipped as sample templates a new
  library can be seeded with.

## Risks / open questions

- **`append` and the index.** Appending to an existing note is a write
  the watcher will see; make sure it goes through `NoteOps` so the
  rescan is the ordinary one.
- **Prompts and the quick-note path.** A template with `{{ask:…}}`
  cannot be used for anything non-interactive (a launcher shortcut, a
  future automation). Either those refuse such a template or they fall
  back to the hint text; decide when the first non-interactive caller
  exists.
- **Empty answers.** A skipped `{{ask:…}}` leaves an empty line the user
  must delete. Dropping the line automatically is a conditional in
  disguise, which this design rules out; the honest fix is `default:`.
  Revisit only if it actually annoys in use.
- **Localized names.** `MMMM` and `dddd` follow the app language, so the
  same template produces different text on a phone set to English.
  That is what a person would expect, but it means a template is not
  byte-reproducible across devices — worth saying out loud in the help.
- **`{{selection}}`** needs a "new note from selection" command that does
  not exist yet; T-TPL-04 ships it empty until that lands.
