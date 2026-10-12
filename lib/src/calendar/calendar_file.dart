/// Line model for `calendar.txt` (#730): every line keeps its own ending,
/// so an untouched line goes back byte for byte.
///
/// `todo.txt`'s file model normalises mixed endings to the file's dominant
/// one. `calendar.txt` must not: a template file
/// written on one system and edited on another is exactly where endings
/// mix, and the format's promise is that only the line Niman was asked to
/// change ever changes. A byte-order mark is kept; a file that is not
/// valid UTF-8 is shown (decoded leniently) and never written.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// One line of the file: its text and its own ending (`''` at end of file
/// without a trailing newline, `'\n'` or `'\r\n'` otherwise).
@immutable
final class CalendarRawLine {
  /// Creates a line of [text] followed by [ending].
  const new(this.text, this.ending);

  /// The line's text, without its terminator.
  final String text;

  /// The line's terminator, as written.
  final String ending;

  /// The line exactly as it sits in the file.
  String get raw => '$text$ending';

  @override
  bool operator ==(Object other) =>
      other is CalendarRawLine && other.text == text && other.ending == ending;

  @override
  int get hashCode => Object.hash(text, ending);

  @override
  String toString() => 'CalendarRawLine(${jsonEncode(raw)})';
}

/// The whole file as lines: [exists] false is a missing file, `bom` a
/// leading byte-order mark, [validUtf8] false a file that is not UTF-8
/// (shown as best it can be, and never written).
final class CalendarFileContent {
  /// Creates a file view.
  const new({
    required this.lines,
    this.exists = true,
    this.bom = false,
    this.validUtf8 = true,
  });

  /// The file's lines, in order.
  final List<CalendarRawLine> lines;

  /// Whether the file exists on disk.
  final bool exists;

  /// Whether the file starts with a UTF-8 byte-order mark.
  final bool bom;

  /// Whether the file decoded as UTF-8. False means the text is lossy and
  /// the file must not be written back.
  final bool validUtf8;

  /// Whether the file has no content at all.
  bool get isEmpty => lines.isEmpty;
}

/// Splits raw [bytes] (null = missing file) into lines that keep their own
/// endings.
CalendarFileContent splitCalendarFile(Uint8List? bytes) {
  if (bytes == null) {
    return const CalendarFileContent(lines: <CalendarRawLine>[], exists: false);
  }
  var data = bytes;
  var bom = false;
  if (data.length >= 3 &&
      data[0] == 0xEF &&
      data[1] == 0xBB &&
      data[2] == 0xBF) {
    bom = true;
    data = Uint8List.sublistView(data, 3);
  }
  var valid = true;
  String content;
  try {
    content = utf8.decode(data);
  } on FormatException {
    // The bytes are shown as well as they can be and never written back:
    // the writer refuses a file that is not UTF-8 (#730).
    valid = false;
    content = utf8.decode(data, allowMalformed: true);
  }
  final lines = <CalendarRawLine>[];
  var start = 0;
  for (var at = 0; at < content.length; at++) {
    if (content.codeUnitAt(at) != 0x0A) continue;
    var textEnd = at;
    if (at > start && content.codeUnitAt(at - 1) == 0x0D) textEnd = at - 1;
    lines.add(
      CalendarRawLine(
        content.substring(start, textEnd),
        content.substring(textEnd, at + 1),
      ),
    );
    start = at + 1;
  }
  if (start < content.length) {
    lines.add(CalendarRawLine(content.substring(start), ''));
  }
  return CalendarFileContent(lines: lines, bom: bom, validUtf8: valid);
}

/// Joins [file] back into the text it came from (the BOM included).
String joinCalendarFile(CalendarFileContent file) {
  final body = StringBuffer();
  if (file.bom) body.write('\uFEFF');
  for (final line in file.lines) {
    body.write(line.raw);
  }
  return body.toString();
}

/// The file's bytes as [joinCalendarFile] writes them.
Uint8List encodeCalendarFile(CalendarFileContent file) {
  return Uint8List.fromList(utf8.encode(joinCalendarFile(file)));
}
