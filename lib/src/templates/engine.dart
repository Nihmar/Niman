/// The template placeholder engine (T-M4-06, widened by T-TPL-01).
///
/// Substitution, not a template language: `{{title}}`, `{{date}}`,
/// `{{date:YYYY-MM}}`, `{{time}}`, `{{now}}`, `{{uuid}}`, `{{counter:name}}`,
/// `{{cursor}}` and the two the user answers — `{{ask:Label}}` and
/// `{{choice:Label:a,b,c}}` — are replaced, each may be followed by
/// filters — `{{title|slug}}`, `{{date:YYYY-MM-DD|+7d}}`,
/// `{{counter:quest|pad:3}}` — and everything else in the file is copied
/// through byte for byte. There are no conditionals, no loops and no
/// expressions, because a template here is a note that happens to have
/// holes in it: a person should be able to read one and know exactly what
/// it will produce.
///
/// `{{cursor}}` is the one placeholder that writes nothing: the marker is
/// removed and the caret lands where it stood (first marker wins when
/// there are several; it takes no filters, like every other misuse a
/// filtered cursor is left standing).
///
/// A placeholder the engine does not know is left standing, and so is one
/// whose filter it does not know. That way a typo is visible in the note
/// that was created, instead of quietly deleting a line the user wrote.
///
/// This file is also where the syntax is written down: the placeholder
/// names, the filter names and the date-format tokens below are the
/// canonical vocabulary, and `checker.dart` (T-TPL-09) validates a
/// template against these very lists rather than against a copy of them,
/// so a name added here is a name the checker already knows.
library;

import 'dart:math';

import 'package:meta/meta.dart';
import 'package:niman/src/links/slug.dart';
import 'package:niman/src/ui/strings.dart';

/// Where the note is being made from (T-TPL-04): the four values a
/// template can ask about its surroundings rather than about a date or
/// the user.
///
/// A context that is supplied answers all four, empty string included —
/// an empty clipboard is an answer, not a missing one. A caller that
/// supplies none leaves the four placeholders standing, which is what
/// every other unknown does here.
@immutable
final class TemplateContext {
  /// Creates a context; anything not given is empty.
  const new({
    this.parent = '',
    this.folder = '',
    this.clipboard = '',
    this.selection = '',
  });

  /// Every value empty, but present: the four placeholders resolve, to
  /// nothing.
  static const TemplateContext empty = TemplateContext();

  /// The name of the note the creation was started from, without the
  /// `.md`; empty when it was started from the tree.
  ///
  /// The name, not a link: a placeholder that quietly wrapped itself in
  /// `[[…]]` could not be used in a sentence, in a frontmatter value or
  /// with a filter. A template that wants the backlink writes
  /// `[[{{parent}}]]`, which is also what it looks like in the note.
  final String parent;

  /// The library-relative folder the note lands in; empty at the root.
  ///
  /// Known only once the directives have been read, so it is empty while
  /// they are being read — `folder: {{folder}}` is a circle, and answers
  /// with nothing.
  final String folder;

  /// What is on the clipboard, empty when it holds no text.
  final String clipboard;

  /// The editor selection the creation came from; empty until there is a
  /// command that starts a note from one.
  final String selection;

  /// This context with [folder] filled in.
  TemplateContext withFolder(String folder) => TemplateContext(
    parent: parent,
    folder: folder,
    clipboard: clipboard,
    selection: selection,
  );

  /// The value of the placeholder called [name], or null when [name] is
  /// not one of the four.
  String? valueFor(String name) => switch (name) {
    'parent' => parent,
    'folder' => folder,
    'clipboard' => clipboard,
    'selection' => selection,
    _ => null,
  };
}

/// The `{{date}}` format used when none is given.
const String defaultDateFormat = 'YYYY-MM-DD';

/// The `{{time}}` format.
const String defaultTimeFormat = 'HH:mm';

/// The `{{now}}` format: a date and a time, local.
const String defaultNowFormat = 'YYYY-MM-DD HH:mm';

/// [source] with its placeholders substituted.
///
/// [title] fills `{{title}}` — the name the note is being created under.
/// [now] is the clock the date and time placeholders read (local time;
/// defaults to [DateTime.now], and tests pass a fixed one). [uuid]
/// generates `{{uuid}}` values, one per occurrence; the default is a
/// version 4 UUID from the platform's secure random.
/// [answers] fills `{{ask:…}}` and `{{choice:…}}` (T-TPL-03), keyed by
/// the field's label. A null map, or a label the map does not carry,
/// leaves the placeholder standing — the same thing every other unknown
/// does, and what a caller that never collected the answers should show.
/// [counter] fills `{{counter:name}}` (#52): it is called with the
/// trimmed name and must hand out the next value. A null callback, or an
/// empty name, leaves the placeholder standing.
String applyTemplate(
  String source, {
  required String title,
  DateTime? now,
  String Function()? uuid,
  Map<String, String>? answers,
  TemplateContext? context,
  int Function(String name)? counter,
}) => _substitute(
  source,
  title: title,
  now: now,
  uuid: uuid,
  answers: answers,
  context: context,
  counter: counter,
).text;

/// [source] substituted, with the caret landing (#53): the offset in the
/// returned text where the first `{{cursor}}` stood, or null when the
/// template holds none.
({String text, int? caret}) applyTemplateWithCaret(
  String source, {
  required String title,
  DateTime? now,
  String Function()? uuid,
  Map<String, String>? answers,
  TemplateContext? context,
  int Function(String name)? counter,
}) {
  final rendered = _substitute(
    source,
    title: title,
    now: now,
    uuid: uuid,
    answers: answers,
    context: context,
    counter: counter,
  );
  return (
    text: rendered.text,
    caret: rendered.carets.isEmpty ? null : rendered.carets.first,
  );
}

/// The single substitution pass both entry points share: one walk, so a
/// `{{counter}}` or `{{uuid}}` is consumed exactly once however many
/// markers the template holds.
({String text, List<int> carets}) _substitute(
  String source, {
  required String title,
  DateTime? now,
  String Function()? uuid,
  Map<String, String>? answers,
  TemplateContext? context,
  int Function(String name)? counter,
}) {
  final clock = now ?? DateTime.now();
  final newUuid = uuid ?? newUuidV4;
  final out = StringBuffer();
  final carets = <int>[];
  var cursor = 0;
  for (final match in templatePlaceholder.allMatches(source)) {
    out.write(source.substring(cursor, match.start));
    cursor = match.end;
    final whole = match.group(0)!;
    final parsed = parsePlaceholder(match.group(1)!);
    final name = parsed.name;
    final argument = parsed.argument;
    final filters = parsed.filters;
    // The caret writes nothing: the marker is dropped and its output
    // offset recorded. Numbered stops (`{{cursor:2}}`) are accepted and
    // land in position order — the editor cannot walk stops, so the
    // first one wins and the rest only vanish.
    if (name == 'cursor') {
      if (filters.isEmpty) {
        carets.add(out.length);
        continue;
      }
      out.write(whole);
      continue;
    }
    out.write(switch (name) {
      'title' => _applyTextFilters(title, filters) ?? whole,
      'uuid' => _applyTextFilters(newUuid(), filters) ?? whole,
      'counter' => switch (argument?.trim()) {
        null || '' => whole,
        final counterName =>
          counter == null
              ? whole
              : (_applyTextFilters(counter(counterName).toString(), filters) ??
                    whole),
      },
      'date' =>
        _dateValue(clock, argument, defaultDateFormat, filters) ?? whole,
      'time' =>
        _dateValue(clock, argument, defaultTimeFormat, filters) ?? whole,
      'now' => _dateValue(clock, argument, defaultNowFormat, filters) ?? whole,
      'ask' || 'choice' => switch (answers?[fieldLabel(argument)]) {
        final answer? => _applyTextFilters(answer, filters) ?? whole,
        null => whole,
      },
      'parent' || 'folder' || 'clipboard' || 'selection' => switch (context
          ?.valueFor(name)) {
        final value? => _applyTextFilters(value, filters) ?? whole,
        null => whole,
      },
      // Not ours: left exactly as written.
      _ => whole,
    });
  }
  out.write(source.substring(cursor));
  return (text: out.toString(), carets: carets);
}

/// `{{…}}`; the body runs to the closing braces, so a format may hold
/// colons, pipes and spaces.
final RegExp templatePlaceholder = RegExp(r'\{\{([^{}]*)\}\}');

/// A placeholder body split into the three things it can hold.
///
/// `date:YYYY-MM|+7d` is name `date`, argument `YYYY-MM`, one filter.
/// The name is lower-cased and the argument trimmed; the filters are
/// left as written, for [_applyTextFilters] to read.
({String name, String? argument, List<String> filters}) parsePlaceholder(
  String body,
) {
  final parts = splitPipes(body);
  final head = parts.first;
  final colon = head.indexOf(':');
  return (
    name: (colon < 0 ? head : head.substring(0, colon)).trim().toLowerCase(),
    argument: colon < 0 ? null : head.substring(colon + 1).trim(),
    filters: parts.skip(1).toList(),
  );
}

/// Every placeholder name this build answers, and the vocabulary the
/// checker (`checker.dart`) validates against.
///
/// Kept in step with the `switch (name)` in [_substitute] below, which is
/// where each one is written out; `include` is the one name that is read
/// earlier still, by `includes.dart`, before the substitution pass runs.
/// A name that is not here is left standing in the created note, and it is
/// what the checker calls an unknown placeholder.
const Set<String> templatePlaceholderNames = {
  'title',
  'uuid',
  'counter',
  'date',
  'time',
  'now',
  'ask',
  'choice',
  'parent',
  'folder',
  'clipboard',
  'selection',
  'cursor',
  'include',
};

/// Whether [source] holds a `{{name}}` placeholder, whatever argument or
/// filters it carries.
///
/// So a caller can skip work a template never asked for: reading the
/// clipboard is a platform round trip, and a template with no
/// `{{clipboard}}` in it should not cost one — nor should it reach into
/// the user's clipboard at all.
bool templateUses(String source, String name) {
  for (final match in templatePlaceholder.allMatches(source)) {
    if (parsePlaceholder(match.group(1)!).name == name) return true;
  }
  return false;
}

/// Every `{{counter:name}}` name in [source], in order and without
/// repeats — the numbers a creation has to reserve before it renders.
///
/// A store hands a value out once per name, and the whole note — the
/// frontmatter directives, the body, and an `{{include:…}}` already
/// pasted in — shares it. Reserving the set up front is what lets the
/// engine keep a synchronous `{{counter}}` callback while the store
/// itself reads and writes the file asynchronously (#359).
List<String> counterNames(String source) {
  final names = <String>[];
  for (final match in templatePlaceholder.allMatches(source)) {
    final parsed = parsePlaceholder(match.group(1)!);
    if (parsed.name != 'counter') continue;
    final name = parsed.argument ?? '';
    if (name.isEmpty || names.contains(name)) continue;
    names.add(name);
  }
  return names;
}

/// The label of an `{{ask:…}}` or `{{choice:…}}` argument: everything up
/// to the first colon, which is where a hint or a list of options
/// starts.
String fieldLabel(String? argument) {
  if (argument == null) return '';
  final colon = argument.indexOf(':');
  return (colon < 0 ? argument : argument.substring(0, colon)).trim();
}

/// [body] split on the `|` that separate a value from its filters.
///
/// A `|` inside single quotes belongs to a date format (`HH'|'mm`), not
/// to the pipeline, so quoted runs are stepped over.
List<String> splitPipes(String body) {
  final parts = <String>[];
  final current = StringBuffer();
  var quoted = false;
  for (var i = 0; i < body.length; i++) {
    final char = body[i];
    if (char == "'") {
      quoted = !quoted;
      current.write(char);
      continue;
    }
    if (char == '|' && !quoted) {
      parts.add(current.toString());
      current.clear();
      continue;
    }
    current.write(char);
  }
  parts.add(current.toString());
  return parts;
}

/// A date placeholder's value: the clock, moved by whatever date filters
/// come first, formatted, then run through the text filters that follow.
///
/// Left to right, and the value changes kind on the way: it is a moment
/// until a filter needs a string, and a string from then on. So
/// `{{date:YYYY|+1y|upper}}` moves the year and then upper-cases the
/// result, while `{{date:YYYY|upper|+1y}}` has nothing left to move and
/// is refused (null, i.e. the placeholder stands).
String? _dateValue(
  DateTime clock,
  String? argument,
  String defaultFormat,
  List<String> filters,
) {
  final format = (argument == null || argument.isEmpty)
      ? defaultFormat
      : argument;
  var when = clock;
  var index = 0;
  while (index < filters.length) {
    final moved = _moveDate(when, filters[index].trim());
    if (moved == null) break;
    when = moved;
    index++;
  }
  return _applyTextFilters(
    formatDateTime(when, format),
    filters.sublist(index),
  );
}

/// Every filter that reads its value as text — the names in the
/// `switch (name)` of [_applyTextFilters] below, and the vocabulary the
/// checker suggests corrections from.
///
/// A name not here is not a filter: the whole placeholder is left
/// standing, which is what makes a typo (`upperr`) visible in the note.
///
/// The engine lower-cases a filter's name before it looks it up, so
/// `{{title|UPPER}}` is the same filter as `{{title|upper}}`.
const Set<String> templateTextFilters = {
  'upper',
  'lower',
  'trim',
  'slug',
  'title',
  'pad',
  'default',
};

/// The two filters that snap a date to the start or the end of one of
/// [templateDateUnits]; see [_moveDate].
const Set<String> templateDateFilters = {'startof', 'endof'};

/// The units `startof:` and `endof:` take — a week, a month, a year.
const Set<String> templateDateUnits = {'week', 'month', 'year'};

/// [value] with every filter in [filters] applied in order, or null when
/// one of them is not a filter this build knows.
String? _applyTextFilters(String value, List<String> filters) {
  var out = value;
  for (final raw in filters) {
    final filter = raw.trim();
    final colon = filter.indexOf(':');
    final name = (colon < 0 ? filter : filter.substring(0, colon))
        .trim()
        .toLowerCase();
    final argument = colon < 0 ? null : filter.substring(colon + 1);
    final applied = switch (name) {
      'upper' => out.toUpperCase(),
      'lower' => out.toLowerCase(),
      'trim' => out.trim(),
      // The same slug the `[[note#heading]]` anchors use, so a template
      // can build a link to a note it is naming.
      'slug' => headingSlug(out),
      'title' => _titleCase(out),
      'pad' => _pad(out, argument),
      'default' => out.trim().isEmpty ? (argument ?? '') : out,
      _ => null,
    };
    if (applied == null) return null;
    out = applied;
  }
  return out;
}

/// Each word's first letter upper-cased — except a word that already has
/// a capital in it, which is left exactly as typed.
///
/// A title is not a place to rewrite the user's `iPhone` into `IPhone`,
/// and a word they capitalised themselves is a word they meant.
String _titleCase(String value) => value.replaceAllMapped(RegExp(r'\S+'), (m) {
  final word = m.group(0)!;
  if (word.contains(RegExp('[A-Z]'))) return word;
  return word[0].toUpperCase() + word.substring(1);
});

/// `pad:3` — left-padded with zeros to that width; a width that is not a
/// number is not a filter (null, so the placeholder stands).
String? _pad(String value, String? argument) {
  final width = int.tryParse(argument?.trim() ?? '');
  if (width == null || width < 0) return null;
  return value.padLeft(width, '0');
}

/// [when] moved by [filter], or null when [filter] does not move dates.
///
/// `+3d` `-1w` `+1m` `+1y` shift; `startof:week` and `endof:month` snap.
/// Adding months keeps the day where it fits — 31 January plus a month
/// is 28 February, not 3 March, because "next month" means the month.
DateTime? _moveDate(DateTime when, String filter) {
  final shift = templateDateShift.firstMatch(filter);
  if (shift != null) {
    final sign = shift.group(1) == '-' ? -1 : 1;
    final count = sign * int.parse(shift.group(2)!);
    return switch (shift.group(3)!.toLowerCase()) {
      'd' => _addDays(when, count),
      'w' => _addDays(when, count * 7),
      'm' => _addMonths(when, count),
      'y' => _addMonths(when, count * 12),
      _ => null,
    };
  }
  final colon = filter.indexOf(':');
  if (colon < 0) return null;
  final unit = filter.substring(colon + 1).trim().toLowerCase();
  return switch ((filter.substring(0, colon).trim().toLowerCase(), unit)) {
    ('startof', 'week') => _addDays(_atMidnight(when), -(when.weekday - 1)),
    ('endof', 'week') => _addDays(_atMidnight(when), 7 - when.weekday),
    ('startof', 'month') => DateTime(when.year, when.month),
    ('endof', 'month') => DateTime(when.year, when.month, _lastDay(when)),
    ('startof', 'year') => DateTime(when.year),
    ('endof', 'year') => DateTime(when.year, 12, 31),
    _ => null,
  };
}

/// `+3d`, `-1w`, `+2m`, `+1y` — the whole of a date move, unit and count
/// both.
///
/// A filter the checker sees starting with `+` or `-` is read against
/// this, so `+xd` is reported as a move whose count is not a number.
final RegExp templateDateShift = RegExp(r'^([+-])(\d+)\s*([dwmy])$');

DateTime _atMidnight(DateTime when) =>
    DateTime(when.year, when.month, when.day);

/// [when] moved [days] *calendar* days, keeping the time of day.
///
/// Not `Duration(days:)`, which is exactly 24 hours: the day a clock
/// springs forward is 23 hours long and the day it falls back is 25, so a
/// 24-hour shift from a time before the change lands on the same date
/// (or skips one) and `{{date|+1d}}` stops meaning "tomorrow". The
/// journal back-link `[[{{date|-1d}}]]` would then point at the day it
/// is written on (#359).
///
/// Built from the components rather than by adding, and the constructor
/// takes the calendar over the wall clock: a time that does not exist on
/// the landing day (the spring-forward gap) is shifted forward by an
/// hour, which is the whole of the correction there is.
DateTime _addDays(DateTime when, int days) => DateTime(
  when.year,
  when.month,
  when.day + days,
  when.hour,
  when.minute,
  when.second,
  when.millisecond,
  when.microsecond,
);

/// The last day of [when]'s month: day zero of the next one.
int _lastDay(DateTime when) => DateTime(when.year, when.month + 1, 0).day;

/// [when] moved [count] months, with the day clamped into the month it
/// lands in.
DateTime _addMonths(DateTime when, int count) {
  final months = when.year * 12 + (when.month - 1) + count;
  final year = months ~/ 12;
  final month = months % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(
    year,
    month,
    when.day < lastDay ? when.day : lastDay,
    when.hour,
    when.minute,
    when.second,
  );
}

/// [when] rendered with [format].
///
/// The tokens are the ones a person writing a date already knows:
///
/// | `YYYY` | 2026      | `MM`   | 03       | `DD` | 09 |
/// | `YY`   | 26        | `M`    | 3        | `D`  | 9  |
/// | `MMMM` | March     | `MMM`  | Mar      | `Q`  | 1  |
/// | `dddd` | Monday    | `ddd`  | Mon      |      |    |
/// | `HH`   | 07        | `mm`   | 05       | `ss` | 42 |
/// | `H`    | 7         | `m`    | 5        | `s`  | 42 |
/// | `WW`   | 07        | `W`    | 7        |      |    |
///
/// Month and weekday names follow the app language, so the same template
/// writes "lunedì" on an Italian phone and "Monday" on an English one.
/// `W` is the ISO week: the week owning the Thursday of [when]'s week.
///
/// Longer tokens are matched first, so `YYYY` never reads as two `YY`.
/// Anything else in [format] is literal, and text between single quotes
/// is literal too — `'on' YYYY` keeps the word.
String formatDateTime(DateTime when, String format) {
  final out = StringBuffer();
  var i = 0;
  while (i < format.length) {
    if (format[i] == "'") {
      // A quoted run is copied verbatim; '' is one literal quote.
      final end = format.indexOf("'", i + 1);
      if (end < 0) {
        out.write(format.substring(i + 1));
        break;
      }
      out.write(end == i + 1 ? "'" : format.substring(i + 1, end));
      i = end + 1;
      continue;
    }
    final token = templateDateTokenAt(format, i);
    if (token == null) {
      out.write(format[i]);
      i++;
      continue;
    }
    out.write(_render(when, token));
    i += token.length;
  }
  return out.toString();
}

/// The format token starting at [i], or null when none does.
///
/// [format] is a date format (`YYYY-MM-DD`), not the whole placeholder:
/// the checker walks a format with this same function, so a token it
/// knows is exactly a token the engine renders.
String? templateDateTokenAt(String format, int i) {
  for (final token in templateDateTokens) {
    if (format.startsWith(token, i)) return token;
  }
  return null;
}

/// Longest first within each letter, so `YYYY` wins over `YY` and
/// `MMMM` over `MM` — and so a walk of a format reads `YYYYY` as `YYYY`
/// and one letter the format does not know, which is what the checker
/// reports as an unknown token.
const List<String> templateDateTokens = [
  'YYYY',
  'YY',
  'MMMM',
  'MMM',
  'MM',
  'M',
  'DD',
  'D',
  'dddd',
  'ddd',
  'HH',
  'H',
  'mm',
  'm',
  'ss',
  's',
  'WW',
  'W',
  'Q',
];

String _render(DateTime when, String token) => switch (token) {
  'YYYY' => when.year.toString().padLeft(4, '0'),
  'YY' => (when.year % 100).toString().padLeft(2, '0'),
  'MMMM' => AppStrings.monthNames[when.month - 1],
  'MMM' => AppStrings.monthNamesShort[when.month - 1],
  'MM' => when.month.toString().padLeft(2, '0'),
  'M' => when.month.toString(),
  'DD' => when.day.toString().padLeft(2, '0'),
  'D' => when.day.toString(),
  'dddd' => AppStrings.weekdayNames[when.weekday - 1],
  'ddd' => AppStrings.weekdayNamesShort[when.weekday - 1],
  'HH' => when.hour.toString().padLeft(2, '0'),
  'H' => when.hour.toString(),
  'mm' => when.minute.toString().padLeft(2, '0'),
  'm' => when.minute.toString(),
  'ss' => when.second.toString().padLeft(2, '0'),
  's' => when.second.toString(),
  'WW' => isoWeekOf(when).toString().padLeft(2, '0'),
  'W' => isoWeekOf(when).toString(),
  'Q' => (((when.month - 1) ~/ 3) + 1).toString(),
  _ => token,
};

/// The ISO-8601 week number of [when]: 1 .. 53.
///
/// A week belongs to the year owning its Thursday, which is why the
/// calculation goes through that day rather than through 1 January.
int isoWeekOf(DateTime when) {
  final day = DateTime.utc(when.year, when.month, when.day);
  final thursday = day.add(Duration(days: 4 - day.weekday));
  final firstOfYear = DateTime.utc(thursday.year);
  return thursday.difference(firstOfYear).inDays ~/ 7 + 1;
}

/// A version 4 UUID from the platform's secure random.
String newUuidV4() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  // Version 4, variant 1 — the two fixed nibbles that make it a v4 UUID
  // rather than 16 random bytes with dashes in them.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
  return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
      '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
      '${hex.sublist(10).join()}';
}
