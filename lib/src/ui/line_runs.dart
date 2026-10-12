/// A line's text with its `+`/`@`/`#`/`key:value` runs in the editor's
/// colours (#730): the two files share the vocabulary, so the journal, a
/// lone-token search and the Home draw a line alike.
///
/// An event's runs carry their offsets (the parse measured them); a
/// goal's tokens and a task's are values only, so their spellings are
/// found in the text — each at its first free occurrence, which keeps a
/// repeated token and a `due:` that repeats a value in place.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/todo/parser.dart';

/// One run of a line: what it says, and the role it wears.
typedef LineRun = ({String spelling, CalendarTokenKind kind});

/// An event's text, its tokens and asides in the editor's colours: the
/// same runs, from the same parse, the editor and the journal show.
Widget calendarEventText(
  BuildContext context,
  CalendarEvent event, {
  int maxLines = 2,
}) {
  final theme = Theme.of(context);
  final syntax = theme.extension<SyntaxColors>();
  final text = event.text;
  final runs = <({int start, int end, TextStyle style})>[];
  if (syntax != null) {
    for (final token in event.tokens) {
      final start = token.start - event.textStart;
      final end = token.end - event.textStart;
      if (start < 0 || end > text.length || start >= end) continue;
      runs.add((
        start: start,
        end: end,
        style: lineRunStyle(syntax, token.kind),
      ));
    }
    for (final aside in event.asides) {
      final start = aside.start - event.textStart;
      final end = aside.end - event.textStart;
      if (start < 0 || end > text.length || start >= end) continue;
      runs.add((
        start: start,
        end: end,
        style: TextStyle(
          color: syntax.calendarAside,
          fontStyle: FontStyle.italic,
        ),
      ));
    }
  }
  return Text.rich(
    TextSpan(children: _spans(context, text, runs, null)),
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
  );
}

/// [text] with [runs] coloured, their spellings found in [text].
Widget lineText(
  BuildContext context,
  String text,
  List<LineRun> runs, {
  int maxLines = 2,
  TextStyle? base,
}) => Text.rich(
  TextSpan(children: lineSpans(context, text, runs, base: base)),
  maxLines: maxLines,
  overflow: TextOverflow.ellipsis,
);

/// The spans of [text], its [runs] in the editor's colours and the rest
/// in [base] (the body style when none is given): for a line a caller
/// splices into a `Text.rich` of its own.
List<TextSpan> lineSpans(
  BuildContext context,
  String text,
  List<LineRun> runs, {
  TextStyle? base,
}) {
  final syntax = Theme.of(context).extension<SyntaxColors>();
  final placed = <({int start, int end, TextStyle style})>[];
  if (syntax != null) {
    for (final run in runs) {
      final at = _freeOccurrence(text, run.spelling, placed);
      if (at == null) continue;
      placed.add((
        start: at,
        end: at + run.spelling.length,
        style: lineRunStyle(syntax, run.kind),
      ));
    }
  }
  return _spans(context, text, placed, base);
}

/// The runs of a todo.txt [task]'s description: its `+`/`@`/`#` tokens
/// and its `key:value` tags, in the roles the two files share.
List<LineRun> todoLineRuns(TodoTask task) => [
  for (final value in task.projects)
    (spelling: '+$value', kind: CalendarTokenKind.project),
  for (final value in task.contexts)
    (spelling: '@$value', kind: CalendarTokenKind.context),
  for (final value in task.hashtags)
    (spelling: '#$value', kind: CalendarTokenKind.tag),
  for (final keyValue in task.keyValues)
    (spelling: keyValue.token, kind: CalendarTokenKind.keyValue),
];

/// The runs of a calendar line's own tokens (a goal's text).
List<LineRun> calendarLineRuns(List<CalendarToken> tokens) => [
  for (final token in tokens) (spelling: lineSpelling(token), kind: token.kind),
];

/// A calendar token as written: `+thesis`, `@phone`, `#family`,
/// `rem:16:30`.
String lineSpelling(CalendarToken token) => switch (token.kind) {
  CalendarTokenKind.project => '+${token.value}',
  CalendarTokenKind.context => '@${token.value}',
  CalendarTokenKind.tag => '#${token.value}',
  CalendarTokenKind.keyValue => token.value,
};

/// The editor's own colour for a calendar token (#730): the two files
/// share the vocabulary, so they share the roles.
TextStyle lineRunStyle(SyntaxColors syntax, CalendarTokenKind kind) =>
    switch (kind) {
      CalendarTokenKind.project => TextStyle(color: syntax.todoProject),
      CalendarTokenKind.context => TextStyle(color: syntax.todoContext),
      CalendarTokenKind.tag => TextStyle(color: syntax.tag),
      CalendarTokenKind.keyValue => TextStyle(color: syntax.todoKeyValue),
    };

/// The first occurrence of [spelling] in [text] that no placed run
/// covers, or null when the text does not carry it.
int? _freeOccurrence(
  String text,
  String spelling,
  List<({int start, int end, TextStyle style})> placed,
) {
  if (spelling.isEmpty) return null;
  var from = 0;
  while (from <= text.length - spelling.length) {
    final at = text.indexOf(spelling, from);
    if (at < 0) return null;
    final end = at + spelling.length;
    if (!_overlaps(placed, at, end)) return at;
    from = at + 1;
  }
  return null;
}

/// Whether [start]..[end] is taken by a placed run.
bool _overlaps(
  List<({int start, int end, TextStyle style})> placed,
  int start,
  int end,
) {
  for (final run in placed) {
    if (start < run.end && run.start < end) return true;
  }
  return false;
}

/// [text] with [runs] spliced in, everything else in [base] — the body
/// style when none is given.
List<TextSpan> _spans(
  BuildContext context,
  String text,
  List<({int start, int end, TextStyle style})> runs,
  TextStyle? base,
) {
  final body =
      base ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
  runs.sort((a, b) => a.start.compareTo(b.start));
  final spans = <TextSpan>[];
  var at = 0;
  for (final run in runs) {
    if (run.start < at) continue;
    if (run.start > at) {
      spans.add(TextSpan(text: text.substring(at, run.start), style: body));
    }
    spans.add(
      TextSpan(text: text.substring(run.start, run.end), style: run.style),
    );
    at = run.end;
  }
  if (at < text.length) {
    spans.add(TextSpan(text: text.substring(at), style: body));
  }
  return spans;
}
