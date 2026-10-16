// The hunks of lines that differ between two texts (#1050): what the undo
// history keeps of an edit over a long span.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/line_hunks.dart';

/// [removed] with each hunk replaced by what [inserted] says there.
String _applied(String removed, String inserted, List<LineHunk> hunks) {
  final out = StringBuffer();
  var at = 0;
  for (final hunk in hunks) {
    out
      ..write(removed.substring(at, hunk.removedStart))
      ..write(inserted.substring(hunk.insertedStart, hunk.insertedEnd));
    at = hunk.removedEnd;
  }
  return '$out${removed.substring(at)}';
}

/// What the hunks keep of both texts.
int _kept(List<LineHunk> hunks) => hunks.fold(
  0,
  (sum, h) =>
      sum + h.removedEnd - h.removedStart + h.insertedEnd - h.insertedStart,
);

void main() {
  test('equal texts have no hunks', () {
    expect(lineHunks('a\nb\n', 'a\nb\n'), isEmpty);
    expect(lineHunks('', ''), isEmpty);
  });

  test('a line changed in place is one hunk of that line', () {
    const before = 'one\ntwo\nthree\nfour\nfive\nsix\n';
    const after = 'one\ntwo\n3\nfour\nfive\nsix\n';
    final hunks = lineHunks(before, after);
    expect(hunks, hasLength(1));
    expect(
      before.substring(hunks[0].removedStart, hunks[0].removedEnd),
      'three\n',
    );
    expect(
      after.substring(hunks[0].insertedStart, hunks[0].insertedEnd),
      '3\n',
    );
  });

  test('changes far apart are hunks apart, with the lines between dropped', () {
    final lines = List<String>.generate(1000, (i) => 'line $i');
    final before = '${lines.join('\n')}\n';
    final changed = List<String>.of(lines)
      ..[3] = 'three'
      ..[500] = 'five hundred'
      ..[990] = 'nine ninety';
    final after = '${changed.join('\n')}\n';
    final hunks = lineHunks(before, after);
    expect(hunks, hasLength(3));
    expect(_applied(before, after, hunks), after);
    expect(_kept(hunks), lessThan(100));
  });

  test('a line inserted or dropped resynchronises', () {
    final lines = List<String>.generate(100, (i) => 'line $i');
    final before = '${lines.join('\n')}\n';
    final inserted = List<String>.of(lines)..insert(40, 'new');
    final dropped = List<String>.of(lines)..removeAt(40);
    for (final other in [inserted, dropped]) {
      final after = '${other.join('\n')}\n';
      final hunks = lineHunks(before, after);
      expect(_applied(before, after, hunks), after);
      expect(hunks, hasLength(1));
      expect(_kept(hunks), lessThan(40));
    }
  });

  test('a text without a last line break, and an empty side', () {
    for (final (before, after) in [
      ('a\nb', 'a\nc'),
      ('a\nb\n', 'a\nb'),
      ('', 'a\n'),
      ('a\n', ''),
      ('\n\n\n', '\n\nx\n'),
    ]) {
      final hunks = lineHunks(before, after);
      expect(_applied(before, after, hunks), after, reason: '$before|$after');
    }
  });

  test('a CRLF terminator is part of its line', () {
    const before = 'a\r\nb\r\nc\r\nd\r\ne\r\n';
    const after = 'a\r\nb\r\nX\r\nd\r\ne\r\n';
    final hunks = lineHunks(before, after);
    expect(_applied(before, after, hunks), after);
    expect(hunks, hasLength(1));
    expect(
      before.substring(hunks[0].removedStart, hunks[0].removedEnd),
      'c\r\n',
    );
  });

  test('whatever the edit, the hunks turn one text into the other', () {
    final random = Random(1050);
    for (var round = 0; round < 300; round++) {
      final lines = List<String>.generate(
        random.nextInt(80),
        (i) => 'l${random.nextInt(6)}',
      );
      final other = List<String>.of(lines);
      for (var edit = random.nextInt(8); edit > 0; edit--) {
        final at = other.isEmpty ? 0 : random.nextInt(other.length);
        switch (random.nextInt(3)) {
          case 0:
            if (other.isNotEmpty) other[at] = 'x${random.nextInt(9)}';
          case 1:
            other.insert(at, 'n${random.nextInt(9)}');
          default:
            if (other.isNotEmpty) other.removeAt(at);
        }
      }
      final before = lines.isEmpty ? '' : '${lines.join('\n')}\n';
      final after = other.isEmpty ? '' : '${other.join('\n')}\n';
      final hunks = lineHunks(before, after);
      expect(_applied(before, after, hunks), after, reason: 'round $round');
      for (var i = 1; i < hunks.length; i++) {
        expect(hunks[i].removedStart, greaterThan(hunks[i - 1].removedEnd));
      }
    }
  });

  test('a text that changes everywhere is one hunk, however long', () {
    final before = List<String>.generate(500, (i) => 'a$i').join('\n');
    final after = List<String>.generate(500, (i) => 'b$i').join('\n');
    final hunks = lineHunks(before, after);
    expect(hunks, hasLength(1));
    expect(_applied(before, after, hunks), after);
  });
}
