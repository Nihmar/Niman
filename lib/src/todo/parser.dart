/// Line model + text round-trip for todo.txt (T-TD-01).
///
/// The grammar authority is `reference/description.svg` (the todo.txt
/// project's syntax diagram):
///
/// ```text
/// x (A) 2016-05-20 2016-04-30 measure space for +chapelShelving @chapel
/// due:2016-05-30
/// ```
///
/// A line is an optional completion mark (`x `), an optional priority
/// (`(A)`…`(Z)`), optional dates (completion then creation — a completion
/// date without a creation date is invalid but preserved), and a free-form
/// description carrying `+project` / `@context` / `#tag` tokens and
/// `key:value` tags anywhere inside it. `due:` (a date) and `rem:`
/// (a `YYYY-MM-DDTHH:MM` local timestamp) are the known key/values;
/// everything else — including `rec:` — is an unknown tag kept verbatim.
///
/// The model is immutable and keeps the original [TodoTask.raw] line.
/// [TodoTask.toLine] returns that raw line, so an untouched task always
/// round-trips byte-stable (odd spacing, trailing whitespace); every
/// mutation ([completeTodoLine], [uncompleteTodoLine], [formatTodoLine])
/// builds a new canonical single-space line. The file store (T-TD-02)
/// writes untouched lines from [TodoTask.toLine] and is therefore
/// byte-identical for them by construction.
///
/// Pure Dart, no I/O: reads happen off the UI isolate per the Android FUSE
/// rule, but the parsing itself never touches the disk.
library;

import 'package:meta/meta.dart';

/// A `+project`, `@context` or `#tag` token found in a description.
@immutable
final class TodoToken {
  /// Creates a token of [kind] with [value] (without the sigil).
  const new({required this.kind, required this.value});

  /// The token kind: `+`, `@` or `#`.
  final String kind;

  /// The token text after the sigil, verbatim (case kept).
  final String value;
}

/// An unknown `key:value` tag kept verbatim (includes `rec:` and any
/// malformed `due:`/`rem:` — the consumed first valid `due:`/`rem:` land
/// on [TodoTask.due]/[TodoTask.reminder] instead).
@immutable
final class TodoKeyValue {
  /// Creates an unknown tag with [key] and [value].
  const new({required this.key, required this.value});

  /// The tag key before the colon.
  final String key;

  /// The tag value after the colon.
  final String value;

  /// The tag as written (`key:value`).
  String get token => '$key:$value';
}

/// One parsed todo.txt line.
@immutable
final class TodoTask {
  /// Creates a task; use [parseTodoLine], not this constructor directly.
  const new({
    required this.raw,
    required this.completed,
    required this.description,
    this.priority,
    this.completionDate,
    this.creationDate,
    this.projects = const <String>[],
    this.contexts = const <String>[],
    this.hashtags = const <String>[],
    this.keyValues = const <TodoKeyValue>[],
    this.due,
    this.reminder,
  });

  /// The original line without its terminator (a trailing `\r` of a CRLF
  /// split is stripped: the store owns the file's line ending, T-TD-02).
  /// Returned by [toLine], so untouched lines are byte-stable.
  final String raw;

  /// Whether the line starts with the lowercase completion mark `x `
  /// (uppercase `X` or `x` glued to text is description, not completion).
  final bool completed;

  /// The priority letter (`A`…`Z`) or null.
  final String? priority;

  /// The completion date (completed lines only), date-only local time.
  final DateTime? completionDate;

  /// The creation date, date-only local time.
  final DateTime? creationDate;

  /// The description after the `x`/`(P)`/date prefix, with surrounding
  /// whitespace trimmed. Carries the `+`/`@`/`#` and `key:value` tokens
  /// verbatim — including `due:`/`rem:` (they live in the text; [due] and
  /// [reminder] are extracted views for badges, filters and scheduling).
  final String description;

  /// `+project` token values, in occurrence order.
  final List<String> projects;

  /// `@context` token values, in occurrence order.
  final List<String> contexts;

  /// `#tag` token values, in occurrence order.
  final List<String> hashtags;

  /// Unknown `key:value` tags, in occurrence order (the consumed first
  /// valid `due:`/`rem:` excluded).
  final List<TodoKeyValue> keyValues;

  /// The first valid `due:YYYY-MM-DD` tag, date-only local time.
  final DateTime? due;

  /// The first valid `rem:YYYY-MM-DDTHH:MM` tag, local wall-clock time.
  final DateTime? reminder;

  /// A completion date without a creation date: invalid per the grammar
  /// (the completion date requires a creation date) but parsed and
  /// preserved verbatim instead of rejected.
  bool get missingCreationDate =>
      completed && completionDate != null && creationDate == null;

  /// The line to write back: the untouched [raw] line.
  String toLine() => raw;
}

/// A `YYYY-MM-DD` calendar date at the start of the remaining line.
final RegExp _dateHead = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?=\s|$)');

/// A priority `(A)`…`(Z)` at the start of the remaining line.
final RegExp _priorityHead = RegExp(r'^\(([A-Z])\)(?=\s|$)');

/// The key of a `key:value` tag.
final RegExp _keyValuePattern = RegExp(
  r'(?:^|\s)([A-Za-z][A-Za-z0-9_-]*):(\S+)',
);

/// Token patterns: the sigil must open the line or follow whitespace, so
/// `a+b`, `a@b` and `C#` stay plain description text.
final RegExp _projectPattern = RegExp(r'(?:^|\s)\+(\S+)');
final RegExp _contextPattern = RegExp(r'(?:^|\s)@(\S+)');
final RegExp _hashtagPattern = RegExp(r'(?:^|\s)#(\S+)');

/// A wikilink, `[[…]]`, as the Markdown tokenizer reads one: no bracket and
/// no line break inside.
final RegExp _wikilinkPattern = RegExp(r'\[\[[^\[\]\n]*\]\]');

/// The placeholder a wikilink is masked with: not blank space, not a sigil,
/// not a letter, so no token pattern can match inside or across it.
const String _linkMask = '\u0000';

/// The `[start, end)` offsets of the wikilinks in [text], in order.
///
/// A wikilink is one opaque run to a task line (#1152): the `+`, `@`, `#`
/// and `key:` inside `[[Ideas +work]]` are the link's own text, never a
/// project, a context, a tag or a tag-value. The editor's colouring reads
/// the same spans.
List<(int, int)> wikilinkSpans(String text) {
  if (!text.contains('[[')) return const <(int, int)>[];
  return <(int, int)>[
    for (final match in _wikilinkPattern.allMatches(text))
      (match.start, match.end),
  ];
}

/// [text] with every wikilink replaced by as many [_linkMask]s: the same
/// length, so a match offset on the result is an offset in [text], and no
/// token pattern sees into a link.
String maskWikilinks(String text) {
  if (!text.contains('[[')) return text;
  return text.replaceAllMapped(
    _wikilinkPattern,
    (match) => _linkMask * match.group(0)!.length,
  );
}

/// A strict `YYYY-MM-DD` value (also used to validate the date part of
/// `rem:`).
final RegExp _dateValue = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// A strict `YYYY-MM-DDTHH:MM` local-time value for `rem:`.
final RegExp _stampValue = RegExp(r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$');

/// Leading horizontal whitespace (tolerant: indented lines are tasks too).
final RegExp _leadingSpace = RegExp(r'^[ \t]+');

/// Trailing horizontal whitespace (kept in [TodoTask.raw], trimmed from
/// [TodoTask.description]).
final RegExp _trailingSpace = RegExp(r'[ \t]+$');

/// Parses one todo.txt line (without its `\n` terminator).
///
/// Never throws for malformed input: anything that is not a valid prefix
/// token stays description text, and [TodoTask.raw] always preserves the
/// input (minus a trailing `\r`, which belongs to a CRLF terminator).
TodoTask parseTodoLine(String line) {
  final raw = line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
  var rest = raw.replaceFirst(_leadingSpace, '');
  var completed = false;
  if (rest == 'x') {
    return TodoTask(raw: raw, completed: true, description: '');
  }
  if (rest.startsWith('x') &&
      rest.length > 1 &&
      (rest.codeUnitAt(1) == 0x20 || rest.codeUnitAt(1) == 0x09)) {
    completed = true;
    rest = rest.substring(1).replaceFirst(_leadingSpace, '');
  }
  String? priority;
  final priorityMatch = _priorityHead.firstMatch(rest);
  if (priorityMatch != null) {
    priority = priorityMatch.group(1);
    rest = rest.substring(priorityMatch.end).replaceFirst(_leadingSpace, '');
  }
  DateTime? firstDate;
  DateTime? secondDate;
  final firstMatch = _dateHead.firstMatch(rest);
  if (firstMatch != null) {
    final parsed = _checkedDate(
      int.parse(firstMatch.group(1)!),
      int.parse(firstMatch.group(2)!),
      int.parse(firstMatch.group(3)!),
    );
    if (parsed != null) {
      firstDate = parsed;
      rest = rest.substring(firstMatch.end).replaceFirst(_leadingSpace, '');
      // A completed line carries completion-then-creation; an incomplete
      // line carries at most a creation date, so a second date-like token
      // stays description text there.
      if (completed) {
        final secondMatch = _dateHead.firstMatch(rest);
        if (secondMatch != null) {
          final second = _checkedDate(
            int.parse(secondMatch.group(1)!),
            int.parse(secondMatch.group(2)!),
            int.parse(secondMatch.group(3)!),
          );
          if (second != null) {
            secondDate = second;
            rest = rest
                .substring(secondMatch.end)
                .replaceFirst(_leadingSpace, '');
          }
        }
      }
    }
  }
  // A lone date on a completed line is the completion date with the
  // creation missing ([TodoTask.missingCreationDate]).
  final completionDate = completed ? firstDate : null;
  final creationDate = completed ? secondDate : firstDate;
  final description = rest.replaceFirst(_trailingSpace, '');
  // The tokens are read off the description with its wikilinks masked, and
  // taken from the description itself: a link is never a token (#1152).
  final readable = maskWikilinks(description);
  final projects = _tokenValues(_projectPattern, readable, description);
  final contexts = _tokenValues(_contextPattern, readable, description);
  final hashtags = _tokenValues(_hashtagPattern, readable, description);
  DateTime? due;
  DateTime? reminder;
  final keyValues = <TodoKeyValue>[];
  for (final match in _keyValuePattern.allMatches(readable)) {
    final key = match.group(1)!;
    final value = _tailOf(match, 2, description);
    if (key == 'due' && due == null) {
      final date = _checkedDateValue(value);
      if (date != null) {
        due = date;
        continue;
      }
    }
    if (key == 'rem' && reminder == null) {
      final stamp = _checkedStampValue(value);
      if (stamp != null) {
        reminder = stamp;
        continue;
      }
    }
    keyValues.add(TodoKeyValue(key: key, value: value));
  }
  return TodoTask(
    raw: raw,
    completed: completed,
    description: description,
    priority: priority,
    completionDate: completionDate,
    creationDate: creationDate,
    projects: projects,
    contexts: contexts,
    hashtags: hashtags,
    keyValues: keyValues,
    due: due,
    reminder: reminder,
  );
}

/// Builds a canonical single-space line from fields.
///
/// Used for adds, edits and check/uncheck (T-TD-02/T-TD-06): touched lines
/// are normalized, untouched lines keep [TodoTask.raw] instead.
/// Throws [ArgumentError] for a malformed [priority] or for a
/// [completionDate] on an incomplete task.
String formatTodoLine({
  required bool completed,
  required String description,
  String? priority,
  DateTime? completionDate,
  DateTime? creationDate,
}) {
  if (priority != null && !RegExp(r'^[A-Z]$').hasMatch(priority)) {
    throw ArgumentError('Priority must be a single A-Z letter: "$priority"');
  }
  if (!completed && completionDate != null) {
    throw ArgumentError('An incomplete task has no completion date');
  }
  final out = StringBuffer();
  if (completed) {
    out.write('x ');
  }
  if (priority != null) {
    out.write('($priority) ');
  }
  if (completed && completionDate != null) {
    out.write('${formatTodoDate(completionDate)} ');
  }
  if (creationDate != null) {
    out.write('${formatTodoDate(creationDate)} ');
  }
  out.write(description.trim());
  return out.toString().trimRight();
}

/// Marks the task on [line] complete on [today]: prepends `x <today> `,
/// keeping priority and the creation date after it.
///
/// Already-completed lines come back unchanged (idempotent). A task with
/// no creation date yields `x <today> <description>` — a completion date
/// without a creation date, flagged by [TodoTask.missingCreationDate] and
/// preserved verbatim on every later round-trip.
String completeTodoLine(String line, DateTime today) {
  final task = parseTodoLine(line);
  if (task.completed) {
    return task.raw;
  }
  return formatTodoLine(
    completed: true,
    priority: task.priority,
    completionDate: DateTime(today.year, today.month, today.day),
    creationDate: task.creationDate,
    description: task.description,
  );
}

/// Marks the task on [line] open: strips `x <completion date> `, keeping
/// priority and the creation date.
///
/// Incomplete lines come back unchanged (idempotent).
String uncompleteTodoLine(String line) {
  final task = parseTodoLine(line);
  if (!task.completed) {
    return task.raw;
  }
  return formatTodoLine(
    completed: false,
    priority: task.priority,
    creationDate: task.creationDate,
    description: task.description,
  );
}

/// Returns [description] with the `key:` tag set to [value]: every
/// existing `key:<non-space>` token is removed and `key:value` appended;
/// with [value] null the tags are just removed. Leftover whitespace is
/// collapsed. Unknown tags are never touched otherwise, so an edit that
/// only manages `due:`/`rem:` keeps them verbatim.
///
/// A bare `key:` (no value — plain description text per the grammar)
/// counts as the picker's slot and is replaced too.
///
/// The edit dialog (T-TD-06) builds on this: picked dates rewrite their
/// own tag while the rest of the line stays byte-identical.
String withKeyValueTag(String description, String key, String? value) {
  final tag = RegExp('(?:^|\\s)${RegExp.escape(key)}:(?:\\S+)?(?=\\s|\$)');
  final out = _collapsed(_withoutMatches(description, tag));
  if (value == null) {
    return out;
  }
  final token = '$key:$value';
  return out.isEmpty ? token : '$out $token';
}

/// Returns [description] without the `+`/`@`/`#` [token] (sigil
/// included, e.g. `+groceries`): every whole-word occurrence removed,
/// leftover whitespace collapsed. Powers the dialog's token chips
/// (T-TD-06): unknown tags are words like any other here, so this only
/// ever removes the tapped token.
String withoutToken(String description, String token) {
  if (token.length < 2) {
    return description;
  }
  final word = RegExp('(?:^|\\s)${RegExp.escape(token)}(?=\\s|\$)');
  return _collapsed(_withoutMatches(description, word));
}

/// The word of a `key:value` annotation tag embedded in a description
/// (mirrors the parser's `[A-Za-z][A-Za-z0-9_-]*:\S+` tag shape).
final RegExp _keyValueWordPattern = RegExp(
  r'(?:^|\s)[A-Za-z][A-Za-z0-9_-]*:[^\s]+(?=\s|$)',
);

/// Returns the prose of [description]: [withoutKeyValueTags] plus the
/// `+project` / `@context` / `#tag` markers, leftover whitespace
/// collapsed. What is left is the phrase the user typed.
///
/// The default for the notification title, where the task is shown out of
/// its line and out of the app: in the list the markers carry meaning next
/// to the checkbox and the filter chips, while on a lock screen they are
/// syntax with nothing to explain them. A setting brings them back for
/// people who file by project.
String taskDisplayText(String description) {
  var out = withoutKeyValueTags(description);
  for (final pattern in [_projectPattern, _contextPattern, _hashtagPattern]) {
    out = _withoutMatches(out, pattern);
  }
  return _collapsed(out);
}

/// Returns [description] without its `key:value` annotation tags — the
/// model's managed slots (`due:`, `rem:`, `rec:`, … appended by the
/// dialog, not typed by the user) — collapsing leftover whitespace.
/// The `+project` / `@context` / `#tag` markers are kept.
String withoutKeyValueTags(String description) {
  if (!description.contains(':')) {
    return description.trim();
  }
  return _collapsed(_withoutMatches(description, _keyValueWordPattern));
}

/// Formats [date] as `YYYY-MM-DD` (drops any time part).
String formatTodoDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// Formats [stamp] as `YYYY-MM-DDTHH:MM` local wall-clock time (for `rem:`).
String formatTodoStamp(DateTime stamp) {
  final hours = stamp.hour.toString().padLeft(2, '0');
  final minutes = stamp.minute.toString().padLeft(2, '0');
  return '${formatTodoDate(stamp)}T$hours:$minutes';
}

/// The token values of [pattern] over [readable] (the description with its
/// wikilinks masked), in occurrence order, as [description] writes them.
List<String> _tokenValues(RegExp pattern, String readable, String description) {
  return <String>[
    for (final match in pattern.allMatches(readable))
      _tailOf(match, 1, description),
  ];
}

/// The text of [group] of [match] as [text] writes it: every pattern here
/// ends in its value group, so the group is the last of the match and
/// [text] and the masked text it was matched on agree on where it is.
String _tailOf(Match match, int group, String text) {
  return text.substring(match.end - match.group(group)!.length, match.end);
}

/// [text] without what [pattern] matches outside its wikilinks.
String _withoutMatches(String text, RegExp pattern) {
  final matches = pattern.allMatches(maskWikilinks(text)).toList();
  if (matches.isEmpty) return text;
  final out = StringBuffer();
  var from = 0;
  for (final match in matches) {
    out.write(text.substring(from, match.start));
    from = match.end;
  }
  out.write(text.substring(from));
  return out.toString();
}

/// [text] with each run of blank space outside a wikilink collapsed to one
/// space, and trimmed: a link keeps its own spacing.
String _collapsed(String text) {
  final out = StringBuffer();
  var from = 0;
  for (final match in RegExp(r'\s+').allMatches(maskWikilinks(text))) {
    out
      ..write(text.substring(from, match.start))
      ..write(' ');
    from = match.end;
  }
  out.write(text.substring(from));
  return out.toString().trim();
}

/// A calendar-valid date, or null (rejects e.g. month 13 or Feb 30 —
/// [DateTime] normalizes overflows, so the components are verified).
DateTime? _checkedDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  final date = DateTime(year, month, day);
  if (date.month != month || date.day != day) {
    return null;
  }
  return date;
}

/// A strict `YYYY-MM-DD` value, or null when malformed or impossible.
DateTime? _checkedDateValue(String value) {
  final match = _dateValue.firstMatch(value);
  if (match == null) {
    return null;
  }
  return _checkedDate(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

/// A strict `YYYY-MM-DDTHH:MM` local-time value, or null when malformed
/// or impossible.
DateTime? _checkedStampValue(String value) {
  final match = _stampValue.firstMatch(value);
  if (match == null) {
    return null;
  }
  final date = _checkedDate(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
  if (date == null) {
    return null;
  }
  final hours = int.parse(match.group(4)!);
  final minutes = int.parse(match.group(5)!);
  if (hours > 23 || minutes > 59) {
    return null;
  }
  return DateTime(date.year, date.month, date.day, hours, minutes);
}
