// The references of a note made of headings (#581): a heading's own hashes
// sent every heading through a whole parse while the index read its tags.
// Measured on this host 2026-10-07: 20,000 headings, 38 ms parsed whole,
// 22 ms with the hashes known for no tag — what is left is the block scan.
// The bar sits between the two.
//
// Every run holds it to ten times the bar, a backstop the hardware cannot
// fail; NIMAN_PERF=1 to the bar itself.
//
// Printing the measure is the point of a perf test.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/note_references.dart';

void main() {
  final measured = Platform.environment['NIMAN_PERF'] == '1';
  const bar = 30000;

  test('a note of headings is read for references within its bar', () {
    final text = [
      for (var i = 0; i < 20000; i++) '${'#' * (i % 6 + 1)} Section $i\n',
    ].join('\n');
    var best = 1 << 62;
    for (var round = 0; round < 5; round++) {
      final watch = Stopwatch()..start();
      final references = noteReferencesOf(text);
      if (watch.elapsedMicroseconds < best) best = watch.elapsedMicroseconds;
      expect(references.tags, isEmpty);
    }
    print(
      '20,000 headings: ${best ~/ 1000} ms '
      '(bar ${bar ~/ 1000} ms${measured ? '' : ', held to ten times it'})',
    );
    expect(best, lessThan(measured ? bar : bar * 10));
  });
}
