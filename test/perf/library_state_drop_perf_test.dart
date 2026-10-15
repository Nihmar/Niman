// Dropping the entries of removed paths from a state file (#956): every key
// was tested against every removed path, so a bulk delete of 100 000 files
// from a library of 20 000 entries cost two thousand million prefix tests in
// the isolate, with every later grade of the file queued behind it. A key is
// now tested by looking up its own path and each folder above it in a set.
//
// The number printed is the time `LibraryStateFile.removed` takes end to end:
// read, drop, write.
//
// Every run holds it to 20 s, a backstop a slow runner cannot fail and the
// code it replaced cannot meet (two thousand million tests are minutes);
// NIMAN_PERF=1 holds it to the bar itself.
//
// Printing the measure is the point of a perf test.
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/library_state_file.dart';
import 'package:path/path.dart' as p;

void main() {
  final measured = Platform.environment['NIMAN_PERF'] == '1';
  const barMs = 1500;

  test('a bulk delete drops its entries without a test per pair', () async {
    final root = Directory.systemTemp.createTempSync('niman_state_drop_');
    addTearDown(() => root.deleteSync(recursive: true));
    const keys = 20000;
    const gone = 100000;
    Directory(p.join(root.path, '.niman')).createSync();
    File(p.join(root.path, '.niman', 'review.json')).writeAsStringSync(
      jsonEncode({
        for (var i = 0; i < keys; i++) 'Deck ${i % 200}/Note $i.md': i,
      }),
    );
    // Half of the removed paths are folders of the library, one file of
    // each of the first hundred decks is listed on its own, the rest are
    // files that never had an entry.
    final removed = [
      for (var i = 0; i < 100; i++) 'Deck $i',
      for (var i = 0; i < 100; i++) 'Deck ${100 + i}/Note ${100 + i}.md',
      for (var i = 0; i < gone - 200; i++) 'Elsewhere ${i % 500}/File $i.md',
    ];

    final file = LibraryStateFile(root.path, '.niman/review.json');
    final watch = Stopwatch()..start();
    final wrote = await file.removed(removed);
    watch.stop();
    print(
      '$keys entries, ${removed.length} removed paths: '
      '${watch.elapsedMilliseconds} ms (bar $barMs ms'
      '${measured ? '' : ', held to 20 s'})',
    );

    expect(wrote, isTrue);
    // Decks 0..99 went with their folders; of decks 100..199 only the one
    // listed note each; decks 200.. never existed (i % 200 stops at 199).
    expect((await file.readAll()).length, keys - 100 * (keys ~/ 200) - 100);
    expect(
      watch.elapsedMilliseconds,
      lessThan(measured ? barMs : 20000),
      reason: 'the drop must not test every key against every path',
    );
  });
}
