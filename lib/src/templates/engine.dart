/// The template placeholder engine (T-M4-06).
///
/// Substitution, not a template language: `{{title}}`, `{{date}}`,
/// `{{date:YYYY-MM}}`, `{{time}}`, `{{now}}` and `{{uuid}}` are replaced,
/// and everything else in the file is copied through byte for byte. There
/// are no conditionals, no loops and no expressions, because a template
/// here is a note that happens to have holes in it — a person should be
/// able to read one and know exactly what it will produce.
///
/// A placeholder the engine does not know is left standing. That way a
/// typo is visible in the note that was created, instead of quietly
/// deleting a line the user wrote.
library;

import 'dart:math';

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
    final name = match.group(1)!.trim().toLowerCase();
    final argument = match.group(2)?.trim();
    return switch (name) {
      'title' => title,
      'date' => formatDateTime(
        clock,
        (argument == null || argument.isEmpty) ? defaultDateFormat : argument,
      ),
      'time' => formatDateTime(
        clock,
        (argument == null || argument.isEmpty) ? defaultTimeFormat : argument,
      ),
      'now' => formatDateTime(
        clock,
        (argument == null || argument.isEmpty) ? defaultNowFormat : argument,
      ),
      'uuid' => newUuid(),
      // Not ours: left exactly as written.
      _ => match.group(0)!,
    };
  });
}

/// `{{name}}` or `{{name:argument}}`; the argument runs to the closing
/// braces, so a format may hold colons and spaces.
final RegExp _placeholder = RegExp(r'\{\{([^:{}]+)(?::([^{}]*))?\}\}');

/// [when] rendered with [format].
///
/// The tokens are the ones a person writing a date already knows:
///
/// | `YYYY` | 2026 | `MM` | 03 | `DD` | 09 |
/// | `YY`   | 26   | `M`  | 3  | `D`  | 9  |
/// | `HH`   | 07   | `mm` | 05 | `ss` | 42 |
/// | `H`    | 7    | `m`  | 5  | `s`  | 42 |
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

/// Longest first, so `YYYY` wins over `YY`.
const List<String> _tokens = [
  'YYYY',
  'YY',
  'MM',
  'M',
  'DD',
  'D',
  'HH',
  'H',
  'mm',
  'm',
  'ss',
  's',
];

String _render(DateTime when, String token) => switch (token) {
  'YYYY' => when.year.toString().padLeft(4, '0'),
  'YY' => (when.year % 100).toString().padLeft(2, '0'),
  'MM' => when.month.toString().padLeft(2, '0'),
  'M' => when.month.toString(),
  'DD' => when.day.toString().padLeft(2, '0'),
  'D' => when.day.toString(),
  'HH' => when.hour.toString().padLeft(2, '0'),
  'H' => when.hour.toString(),
  'mm' => when.minute.toString().padLeft(2, '0'),
  'm' => when.minute.toString(),
  'ss' => when.second.toString().padLeft(2, '0'),
  's' => when.second.toString(),
  _ => token,
};

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
