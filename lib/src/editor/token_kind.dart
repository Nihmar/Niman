/// The kind of a styled run within a line.
enum TokenKind {
  /// Plain text. Not emitted as a token: any offset not covered by a token
  /// is plain.
  plain,

  /// The `#` markers of a heading line.
  headingMarker,

  /// Bold (`**…**` or `__…__`).
  bold,

  /// Italic (`*…*` or `_…_`).
  italic,

  /// Strikethrough (`~~…~~`).
  strike,

  /// Highlighted (`==…==`, #279).
  highlight,

  /// `<u>…</u>`. Made by the surface's styler only: this tokenizer reads
  /// HTML tags as text.
  underline,

  /// `<sup>…</sup>`, the unified engine's only.
  superscript,

  /// `<sub>…</sub>`, the unified engine's only.
  subscript,

  /// An inline code span (`` `…` ``).
  codeInline,

  /// A line of a fenced code block (fence lines and content), or, from the
  /// unified engine, a fence line alone: the syntax around a code block.
  codeFence,

  /// A line of a code block's content — fenced or indented — from the
  /// unified engine: the code itself, drawn in every mode. It is told apart
  /// from its fences because `live` hides the fences and showed nothing of
  /// a block whose code was a fence's.
  codeBlock,

  /// The language info on a fence-opening line.
  codeLanguage,

  /// A link (`[text](url)`).
  link,

  /// An image (`![alt](url)`).
  image,

  /// A wikilink (`[[target]]`, `[[target|alias]]`, `[[target#heading]]`).
  wikilink,

  /// A list marker (`-`, `*`, `+`, `1.`, `1)`).
  listMarker,

  /// A task-list checkbox (`[ ]` or `[x]`).
  taskBox,

  /// A blockquote marker (`>`).
  blockquote,

  /// A horizontal rule line.
  horizontalRule,

  /// Inline math (`$…$`).
  mathInline,

  /// A display-math line (a `$$` block line, or single-line `$$…$$`).
  mathBlock,

  /// An inline tag (`#tag`).
  tag,

  /// A line of the leading frontmatter block.
  frontmatter,

  /// A template command (`{{date:YYYY-MM-DD}}`, `{{cursor}}`…): a
  /// placeholder the template engine answers, laid over whatever the line
  /// holds there (`templates/template_commands.dart`).
  templateCommand,

  /// A task's priority, `(A)`, in a task list (`todo_txt_tokens.dart`).
  todoPriority,

  /// A task's creation or completion date, at the head of its line.
  todoDate,

  /// A task's `+project`.
  todoProject,

  /// A task's `@context`.
  todoContext,

  /// A task's `key:value` tag — `due:`, `rem:` and the rest.
  todoKeyValue,

  /// A `rec:` tag — or, in calendar.txt, an `until:` or `except:` — the
  /// recurrence grammar does not read (#1189, #1190): the text keeps
  /// [todoKeyValue]'s colour and wears the wavy flag the calendar's
  /// mismatches wear. It does nothing, as any unknown tag does.
  todoUnreadableRule,

  /// A completed task, the whole line.
  todoDone,

  /// The date at a calendar.txt head (`2026-10-12`, `2026-10`, `2026`).
  calendarDate,

  /// The week and the weekday of a calendar.txt head (`w42 Mon`).
  calendarHead,

  /// A goal's head in calendar.txt (`2026`, `2026-10`, `2026-10-05
  /// w41`).
  calendarGoal,

  /// An event's time (`9-12`, `0600Z`).
  calendarTime,

  /// A `( … )` aside in a calendar.txt event, shown dimmed.
  calendarAside,

  /// A week number or a weekday that does not match the line's date: the
  /// text keeps [calendarHead]'s colour and wears a wavy flag.
  calendarMismatch,
}
