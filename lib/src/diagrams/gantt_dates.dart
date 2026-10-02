/// The dates of a Gantt chart (#530): reading them in the chart's
/// `dateFormat`, writing them in its `axisFormat`, and the durations
/// between.
///
/// Mermaid takes a dayjs format to read a date (`YYYY-MM-DD`) and a d3
/// strftime one to write the axis (`%d/%m`); both are kept to the tokens a
/// note uses. Every date is UTC, so no daylight-saving hour stretches a
/// day.
library;

/// The dayjs tokens a `dateFormat` is read with, longest first.
const List<String> _readTokens = [
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
  'X',
  'x',
];

/// The month names the axis writes with `%b` and `%B`.
const List<String> _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// The day names the axis writes with `%a` and `%A`, Monday first.
const List<String> _days = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// A `dateFormat` made into a reader of dates.
final class GanttDateFormat {
  /// Reads dates written in the dayjs [format].
  factory of(String format) {
    final tokens = <String>[];
    final pattern = StringBuffer('^');
    var i = 0;
    while (i < format.length) {
      final token = _readTokens.firstWhere(
        (t) => format.startsWith(t, i),
        orElse: () => '',
      );
      if (token.isEmpty) {
        pattern.write(RegExp.escape(format[i]));
        i++;
        continue;
      }
      tokens.add(token);
      pattern.write(switch (token) {
        'YYYY' => r'(\d{4})',
        'X' || 'x' => r'(\d+)',
        _ when token.length == 2 => r'(\d{2})',
        _ => r'(\d{1,2})',
      });
      i += token.length;
    }
    pattern.write(r'$');
    return GanttDateFormat._(RegExp(pattern.toString()), tokens);
  }

  new _(this._pattern, this._tokens);

  final RegExp _pattern;
  final List<String> _tokens;

  /// [text] as a date, or null when it is not written in this format.
  DateTime? read(String text) {
    final match = _pattern.firstMatch(text.trim());
    if (match == null) return null;
    var year = 1970;
    var month = 1;
    var day = 1;
    var hour = 0;
    var minute = 0;
    var second = 0;
    for (var i = 0; i < _tokens.length; i++) {
      final value = int.parse(match.group(i + 1)!);
      switch (_tokens[i]) {
        case 'YYYY':
          year = value;
        case 'YY':
          year = 2000 + value;
        case 'MM' || 'M':
          month = value;
        case 'DD' || 'D':
          day = value;
        case 'HH' || 'H':
          hour = value;
        case 'mm' || 'm':
          minute = value;
        case 'ss' || 's':
          second = value;
        case 'X':
          return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
        case 'x':
          return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
      }
    }
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (hour > 23 || minute > 59 || second > 59) return null;
    final date = DateTime.utc(year, month, day, hour, minute, second);
    // 31 February rolls over into March: not a date.
    return date.month == month && date.day == day ? date : null;
  }
}

/// A duration as Mermaid writes one — `3d`, `2w`, `12h`, `30m`, `1.5d` —
/// or null when [text] is none.
Duration? ganttDuration(String text) {
  final match = RegExp(r'^(\d+(?:\.\d+)?)\s*(ms|s|m|h|d|w)$')
      .firstMatch(text.trim());
  if (match == null) return null;
  final amount = double.parse(match.group(1)!);
  final unit = switch (match.group(2)!) {
    'ms' => 1,
    's' => 1000,
    'm' => 60 * 1000,
    'h' => 60 * 60 * 1000,
    'd' => 24 * 60 * 60 * 1000,
    _ => 7 * 24 * 60 * 60 * 1000,
  };
  return Duration(milliseconds: (amount * unit).round());
}

/// [date] written in the strftime [format] the axis uses.
String formatGanttDate(DateTime date, String format) {
  final out = StringBuffer();
  for (var i = 0; i < format.length; i++) {
    if (format[i] != '%' || i + 1 == format.length) {
      out.write(format[i]);
      continue;
    }
    i++;
    out.write(switch (format[i]) {
      'Y' => '${date.year}',
      'y' => _two(date.year % 100),
      'm' => _two(date.month),
      'd' => _two(date.day),
      'e' => '${date.day}',
      'H' => _two(date.hour),
      'I' => _two((date.hour + 11) % 12 + 1),
      'M' => _two(date.minute),
      'S' => _two(date.second),
      'p' => date.hour < 12 ? 'AM' : 'PM',
      'b' => _months[date.month - 1].substring(0, 3),
      'B' => _months[date.month - 1],
      'a' => _days[date.weekday - 1].substring(0, 3),
      'A' => _days[date.weekday - 1],
      'j' => _three(date.difference(DateTime.utc(date.year)).inDays + 1),
      '%' => '%',
      final other => '%$other',
    });
  }
  return out.toString();
}

String _two(int value) => value.toString().padLeft(2, '0');

String _three(int value) => value.toString().padLeft(3, '0');
