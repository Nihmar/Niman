/// The template placeholder engine (T-M4-06, widened by T-TPL-01).
///
/// Substitution, not a template language: `{{title}}`, `{{date}}`,
/// `{{date:YYYY-MM}}`, `{{time}}`, `{{now}}` and `{{uuid}}` are replaced,
/// each may be followed by filters — `{{title|slug}}`,
/// `{{date:YYYY-MM-DD|+7d}}` — and everything else in the file is copied
/// through byte for byte. There are no conditionals, no loops and no
/// expressions, because a template here is a note that happens to have
/// holes in it: a person should be able to read one and know exactly what
/// it will produce.
///
/// A placeholder the engine does not know is left standing, and so is one
/// whose filter it does not know. That way a typo is visible in the note
/// that was created, instead of quietly deleting a line the user wrote.
library;

import 'dart:math';

import 'package:copist/src/links/slug.dart';
import 'package:copist/src/ui/strings.dart';

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
String applyTemplate(
  String source, {
  required String title,
  DateTime? now,
  String Function()? uuid,
}) {
  final clock = now ?? DateTime.now();
  final newUuid = uuid ?? newUuidV4;
  return source.replaceAllMapped(_placeholder, (match) {
    final whole = match.group(0)!;
    final parts = splitPipes(match.group(1)!);
    final head = parts.first;
    final colon = head.indexOf(':');
    final name = (colon < 0 ? head : head.substring(0, colon))
        .trim()
        .toLowerCase();
    final argument = colon < 0 ? null : head.substring(colon + 1).trim();
    final filters = parts.skip(1).toList();
    return switch (name) {
      'title' => _applyTextFilters(title, filters) ?? whole,
      'uuid' => _applyTextFilters(newUuid(), filters) ?? whole,
      'date' =>
        _dateValue(clock, argument, defaultDateFormat, filters) ?? whole,
      'time' =>
        _dateValue(clock, argument, defaultTimeFormat, filters) ?? whole,
      'now' => _dateValue(clock, argument, defaultNowFormat, filters) ?? whole,
      // Not ours: left exactly as written.
      _ => whole,
    };
  });
}

/// `{{…}}`; the body runs to the closing braces, so a format may hold
/// colons, pipes and spaces.
final RegExp _placeholder = RegExp(r'\{\{([^{}]*)\}\}');

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
  final shift = _shiftPattern.firstMatch(filter);
  if (shift != null) {
    final sign = shift.group(1) == '-' ? -1 : 1;
    final count = sign * int.parse(shift.group(2)!);
    return switch (shift.group(3)!.toLowerCase()) {
      'd' => when.add(Duration(days: count)),
      'w' => when.add(Duration(days: count * 7)),
      'm' => _addMonths(when, count),
      'y' => _addMonths(when, count * 12),
      _ => null,
    };
  }
  final colon = filter.indexOf(':');
  if (colon < 0) return null;
  final unit = filter.substring(colon + 1).trim().toLowerCase();
  return switch ((filter.substring(0, colon).trim().toLowerCase(), unit)) {
    ('startof', 'week') => _atMidnight(
      when.subtract(Duration(days: when.weekday - 1)),
    ),
    ('endof', 'week') => _atMidnight(
      when.add(Duration(days: 7 - when.weekday)),
    ),
    ('startof', 'month') => DateTime(when.year, when.month),
    ('endof', 'month') => DateTime(when.year, when.month, _lastDay(when)),
    ('startof', 'year') => DateTime(when.year),
    ('endof', 'year') => DateTime(when.year, 12, 31),
    _ => null,
  };
}

/// `+3d`, `-1w`, `+2m`, `+1y`.
final RegExp _shiftPattern = RegExp(r'^([+-])(\d+)\s*([dwmy])$');

DateTime _atMidnight(DateTime when) =>
    DateTime(when.year, when.month, when.day);

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
    final token = _tokenAt(format, i);
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
String? _tokenAt(String format, int i) {
  for (final token in _tokens) {
    if (format.startsWith(token, i)) return token;
  }
  return null;
}

/// Longest first within each letter, so `YYYY` wins over `YY` and
/// `MMMM` over `MM`.
const List<String> _tokens = [
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
