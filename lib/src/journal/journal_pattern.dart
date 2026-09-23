/// The journal's entry names (#7): the pattern that turns a day into the
/// path of its entry, and a path back into its day.
///
/// Numbers only — `YYYY`, `MM`, `M`, `DD`, `D` — so an entry is named the
/// same on every device whatever the app's language: a month written as
/// `September` on one phone and `settembre` on another would be two
/// entries for one day. A `/` makes a folder, a quoted run is copied as
/// it is (`'week' YYYY-MM-DD`), and any other character is itself.
library;

import 'package:meta/meta.dart';

/// The entry name a fresh library uses: a folder per year and month,
/// the day's ISO date as the note's name.
const String defaultJournalEntryName = 'YYYY/MM/YYYY-MM-DD';

/// A parsed entry-name pattern.
@immutable
final class JournalPattern {
  new _(this.source, this._parts);

  /// The pattern for [source], or the default one when [source] cannot
  /// be one.
  factory orDefault(String source) =>
      tryParse(source) ?? tryParse(defaultJournalEntryName)!;

  /// The pattern for [source], or null when it cannot name one entry per
  /// day: it lacks the year, the month or the day, or holds a character
  /// no file name may, an empty folder, a `.` or `..` folder, or an
  /// unquoted `Y` that is not `YYYY`.
  static JournalPattern? tryParse(String source) {
    final parts = <_Part>[];
    var i = 0;
    final literal = StringBuffer();
    void flush() {
      if (literal.isEmpty) return;
      parts.add(_Part.literal(literal.toString()));
      literal.clear();
    }

    while (i < source.length) {
      final char = source[i];
      if (char == "'") {
        final end = source.indexOf("'", i + 1);
        if (end < 0) return null;
        literal.write(end == i + 1 ? "'" : source.substring(i + 1, end));
        i = end + 1;
        continue;
      }
      final token = _tokenAt(source, i);
      if (token != null) {
        flush();
        parts.add(_Part.token(token));
        i += token.length;
        continue;
      }
      if (char == 'Y') return null;
      literal.write(char);
      i++;
    }
    flush();
    final tokens = {for (final part in parts) ?part.token};
    if (!tokens.contains('YYYY') ||
        !(tokens.contains('MM') || tokens.contains('M')) ||
        !(tokens.contains('DD') || tokens.contains('D'))) {
      return null;
    }
    final pattern = JournalPattern._(source, List.unmodifiable(parts));
    // A sample day tells whether the names it makes are usable paths.
    final sample = pattern.format(DateTime(2026, 12, 31));
    if (sample.contains(RegExp(r'[<>:"\\|?*]'))) return null;
    final segments = sample.split('/');
    if (segments.any((s) => s.trim().isEmpty || s == '.' || s == '..')) {
      return null;
    }
    return pattern;
  }

  /// What the pattern was written as.
  final String source;

  final List<_Part> _parts;

  /// The entry name of [day], folders included, without `.md`.
  String format(DateTime day) => [
    for (final part in _parts)
      if (part.token case final token?) _render(day, token) else part.text,
  ].join();

  /// The day [name] (folders included, without `.md`) is the entry of,
  /// or null when this pattern would not have made it.
  ///
  /// The name is checked by making it again: `2026/09/2026-09-31` reads
  /// as numbers, but no day is named that.
  DateTime? dayOf(String name) {
    final match = _regex.firstMatch(name);
    if (match == null) return null;
    int? year;
    int? month;
    int? day;
    var group = 1;
    for (final part in _parts) {
      final token = part.token;
      if (token == null) continue;
      final value = int.parse(match.group(group++)!);
      switch (token) {
        case 'YYYY':
          year ??= value;
        case 'MM' || 'M':
          month ??= value;
        case 'DD' || 'D':
          day ??= value;
      }
    }
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    return format(date) == name ? date : null;
  }

  late final RegExp _regex = RegExp(
    '^${[for (final part in _parts) switch (part.token) {
        null => RegExp.escape(part.text),
        'YYYY' => r'(\d{4})',
        'MM' || 'DD' => r'(\d{2})',
        _ => r'(\d{1,2})',
      }].join()}\$',
  );

  @override
  bool operator ==(Object other) =>
      other is JournalPattern && other.source == source;

  @override
  int get hashCode => source.hashCode;
}

/// Longest first, so `MM` wins over `M` and `DD` over `D`.
const List<String> _tokens = ['YYYY', 'MM', 'M', 'DD', 'D'];

String? _tokenAt(String source, int i) {
  for (final token in _tokens) {
    if (source.startsWith(token, i)) return token;
  }
  return null;
}

String _render(DateTime day, String token) => switch (token) {
  'YYYY' => day.year.toString().padLeft(4, '0'),
  'MM' => day.month.toString().padLeft(2, '0'),
  'M' => day.month.toString(),
  'DD' => day.day.toString().padLeft(2, '0'),
  _ => day.day.toString(),
};

/// A run of literal text, or a date token.
@immutable
final class _Part {
  const new literal(this.text) : token = null;
  const new token(String this.token) : text = '';

  final String text;
  final String? token;
}
