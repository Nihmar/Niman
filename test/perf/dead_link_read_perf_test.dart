// The dead-link read of a long note (#916): with no link record from the
// editor, the watcher's read joined every line of the note into one string on
// the UI isolate after each pause in typing, and only then handed it to an
// isolate. What the UI isolate pays now is the hand-over of the buffer.
//
// The number printed is the time `openNoteLinks` holds the calling isolate:
// from the call to the future it returns, before any of the read is awaited.
// Measured on this host 2026-10-14: see the figures the test prints, against
// the join it replaced, measured in the same run.
//
// Every run holds the hand-over to 60 % of the join it replaced (the same
// work on the same hardware: the code it replaced held the isolate for
// 70 % of it or more) and to ten times the bar, a backstop a slow runner
// cannot fail; NIMAN_PERF=1 holds it to the bar itself.
//
// Printing the measure is the point of a perf test.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/ui/note_dead_links.dart';

void main() {
  final measured = Platform.environment['NIMAN_PERF'] == '1';
  const barMs = 25;

  test('a long note is handed to the isolate without being joined', () async {
    // About 30 M characters in 800 000 lines, a link in every thousandth:
    // under [deadLinkTextLimit], so the note is read.
    const lines = 800000;
    final text = StringBuffer();
    for (var i = 0; i < lines; i++) {
      text.write(
        i % 1000 == 0
            ? 'A line with a [[Link $i]] in it.\n'
            : 'A line of plain prose, number $i.\n',
      );
    }
    // A note being edited holds lines of its own, not only views.
    final buffer = SourceBuffer.fromText(text.toString())
      ..insert(0, 'Typed in. ');
    expect(buffer.length, lessThan(deadLinkTextLimit));

    var join = 1 << 62;
    for (var round = 0; round < 3; round++) {
      final watch = Stopwatch()..start();
      final joined = buffer.text.length;
      watch.stop();
      if (watch.elapsedMicroseconds < join) join = watch.elapsedMicroseconds;
      expect(joined, buffer.length);
    }

    var held = 1 << 62;
    List<ParsedLink>? links;
    for (var round = 0; round < 3; round++) {
      final watch = Stopwatch()..start();
      final read = openNoteLinks(buffer: buffer, kept: () => null);
      watch.stop();
      if (watch.elapsedMicroseconds < held) held = watch.elapsedMicroseconds;
      links = await read;
    }
    print(
      '$lines lines, ${buffer.length >> 20} MiB: the UI isolate held '
      '${held / 1000} ms by the read (bar $barMs ms'
      '${measured ? '' : ', held to ten times it'}); '
      'the join it replaced: ${join ~/ 1000} ms',
    );

    expect(links, hasLength(lines ~/ 1000));
    expect(
      held,
      lessThan(join * 0.6),
      reason: 'handing the buffer over costs well under joining it',
    );
    expect(held, lessThan(barMs * 1000 * (measured ? 1 : 10)));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
