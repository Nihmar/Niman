// #730 phase 1: the calendar.txt file model — every line keeps its own
// ending, a BOM is kept, and a file that is not UTF-8 is shown but never
// written.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_file.dart';

void main() {
  Uint8List bytes(String text) => Uint8List.fromList(utf8.encode(text));

  test('a missing file is empty and does not exist', () {
    final file = splitCalendarFile(null);
    expect(file.exists, isFalse);
    expect(file.lines, isEmpty);
    expect(joinCalendarFile(file), '');
  });

  test('an empty file exists and has no lines', () {
    final file = splitCalendarFile(Uint8List(0));
    expect(file.exists, isTrue);
    expect(file.lines, isEmpty);
    expect(joinCalendarFile(file), '');
  });

  test('LF lines keep their endings, the last one included', () {
    final file = splitCalendarFile(bytes('2026  a\n2026-10  b\n'));
    expect(file.lines.map((l) => l.text), ['2026  a', '2026-10  b']);
    expect(file.lines.map((l) => l.ending), ['\n', '\n']);
    expect(joinCalendarFile(file), '2026  a\n2026-10  b\n');
  });

  test('a file without a trailing newline keeps that too', () {
    final file = splitCalendarFile(bytes('2026  a\n2026-10  b'));
    expect(file.lines.last.ending, '');
    expect(joinCalendarFile(file), '2026  a\n2026-10  b');
  });

  test('mixed endings stay mixed: each line keeps its own', () {
    const text = '2026  a\r\n2026-10  b\n2026-11  c\r\n';
    final file = splitCalendarFile(bytes(text));
    expect(file.lines.map((l) => l.ending), ['\r\n', '\n', '\r\n']);
    expect(file.lines.map((l) => l.text), [
      '2026  a',
      '2026-10  b',
      '2026-11  c',
    ]);
    expect(joinCalendarFile(file), text);
  });

  test('a byte-order mark is kept, and is not a line', () {
    const text = '\uFEFF2026  a\n';
    final file = splitCalendarFile(bytes(text));
    expect(file.bom, isTrue);
    expect(file.lines.single.text, '2026  a');
    expect(joinCalendarFile(file), text);
  });

  test('a file that is not UTF-8 is shown, and marked', () {
    final raw = Uint8List.fromList([...utf8.encode('2026  a\n'), 0xFF, 0xFE]);
    final file = splitCalendarFile(raw);
    expect(file.validUtf8, isFalse);
    expect(file.lines.first.text, '2026  a');
    expect(file.lines, hasLength(2), reason: 'the bad bytes are a line too');
  });

  test('lines compare by text and ending', () {
    expect(const CalendarRawLine('a', '\n'), const CalendarRawLine('a', '\n'));
    expect(
      const CalendarRawLine('a', '\n'),
      isNot(const CalendarRawLine('a', '\r\n')),
    );
  });

  test('encode is the inverse of split for a well-formed file', () {
    const text = '2026  a\r\n2026-10  b\n\n2026-11  c';
    final file = splitCalendarFile(bytes(text));
    expect(utf8.decode(encodeCalendarFile(file)), text);
  });
}
