# Template checker — mockups

`#71` asks for a checker of the template placeholder language — the
double-brace forms \{\{…\}\} that `lib/src/templates/engine.dart` already
reads. The engine half, the pure function `checkTemplateSyntax` and the
`TemplateSyntaxError` it returns, is a **separate pull request**; these are the
**drawings** for the rest of the issue, its three open questions:

1. **When it runs** — on every keystroke (debounced like the spell checker),
   on save, or only when a template is opened for editing?
2. **How the feedback looks** — a squiggly underline like the spell checker's,
   or a lightweight banner?
3. **Auto-apply** — is any suggestion ever applied without the user asking?

so the shape can be settled by looking at it rather than by building it.

Every placeholder form below is written with its braces escaped in the source,
like \{\{title\}\} here, on purpose: the documentation site renders this README
as a page, and its renderer would read a literal brace pair as one of its own
tags and drop it. Escaped, the forms read as a brace pair everywhere.

## The two shapes, on the same template

[html/Shapes.html](html/Shapes.html) draws one template note twice, with the
same three problems in both.

**Shape (i) — squiggle + hint.** A wavy underline under the offending span, in
the colour the spelling's own squiggle is drawn in — the palette's `error`,
`#E0687A` — and a hint on the span: the message, then "Did you mean
\{\{title\}\}?" with the fix as a single action. Where no fix is safe the hint
says so and offers only **Dismiss**.

**Shape (ii) — banner / status line.** A quiet line at the top of the note that
reads "3 problems in this template" and expands to the list: the span, the
message and one fix per row.

The trade-offs, as drawn:

| | points at the text | lists everything at once | survives scrolling |
|---|---|---|---|
| **squiggle + hint** | yes — the mark sits under the span and moves with the line as it is edited | no — only the problems on screen | no |
| **banner / status line** | no — the span is read in the list and then found in the note | yes | yes |

The two are not exclusive: a squiggle under the span and a count in the status
row is the reading the app already uses for the spelling. The drawing shows
them apart so the choice is visible.

## The error cases

[html/Cases.html](html/Cases.html) draws the forms from the issue's tables and
what the checker says about each — the span with the wavy mark, the message,
and the fix or a plain "no fix offered":

| drawn | message | fix |
|---|---|---|
| \{\{titlex\}\} | Unknown placeholder | \{\{title\}\} |
| \{\{title | Unclosed \{\{ | none — no clear end to close |
| title\}\} | \}\} with nothing to close | none — leave as written |
| \{\{title\|pad:wide\}\} | `pad` needs a whole number | \{\{title\|pad:3\}\} |
| \{\{time:HH'\|'mm | Unclosed quote in the date format | \{\{time:HH'\|'mm\}\} |
| \{\{title\|+xd\}\} | `+xd` is not a filter | none — no safe default |
| \{\{\}\} | Empty placeholder | none — nothing to name |
| a clean template | — | the quiet state |

The messages are illustrative: the wording lives in the engine PR; this fixes
the shape of a row and of a hint. The boundary the issue draws — a suggestion
only where the fix is computable and safe — is the "no fix offered" lines.

## The quiet state

When a template has no problems the checker adds nothing at all: no banner, no
squiggle, no hint. A status line that always reads "Template syntax OK" would
be noise on every template that is fine, which is most of them; the drawing
puts the two side by side so the empty line wins by looking.

## While a template is being created

The \{\{ask:…\}\} and \{\{choice:…\}\} answers are filled in the **Fill in the
template** dialog, and that dialog does not edit the template's source: it
collects answers, and the source is not editable behind it. There is nothing
there to underline and nothing to point at, so the checker's feedback does not
change while a note is made from a template — it belongs to the editor, where
the source is. [html/Cases.html](html/Cases.html) draws the dialog anyway, to
show that the two screens do not meet: if the checker runs on save, a template
saved with a problem shows its banner the next time the template is opened for
editing, not here. This is the third state, and it adds nothing beyond saying
so.

## What the drawings ask

1. **When?** Every keystroke (debounced), on save, or only while a template is
   open for editing? A squiggle while typing wants the first; a banner wants
   the last.
2. **Which shape?** The squiggle points and follows; the banner lists and
   survives scrolling. Both, or one?
3. **Auto-apply?** No suggestion is applied without a tap in either drawing —
   the fix is always one action. Should the safest ones (closing \{\{title to
   \{\{title\}\}) ever be applied on save, or is every fix a user action?

## Re-rendering these

The sources are in [`html/`](html) — plain, self-contained HTML with no build
step and no external assets. Edit one and render it with headless Chrome:

```bash
chrome --headless --disable-gpu --hide-scrollbars \
  --window-size=1280,900 --screenshot=Shapes.png html/Shapes.html
```

They are mockups, not screenshots of the app: everything here is HTML drawn to
look like Niman, using the real palette from `lib/src/ui/theme/niman.dart`
(the dark set — `background #23262B`, `backdrop #1B1D21`, `surface #2C3037`,
`surfaceHigh #363B44`, `text #F2EDE5`, `muted #A6A29A`, `outline #4A4F59`,
`accent #587CD3`, `error #E0687A`, and the syntax colours `template #A8C77A`
and `task #8FBF7F`). Where a mockup and the app disagree, the app ships —
these record what was decided, and when.
