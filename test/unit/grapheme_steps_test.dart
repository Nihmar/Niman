// Grapheme clusters read through windows (#1346, #1347): the steps a caret
// takes and the runs a word is made of, held against the slow answer that is
// obviously right — the whole text segmented from its first character.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/grapheme_steps.dart';

/// Pieces a note can be made of, the awkward ones in numbers: clusters longer
/// than any window, runs of flags, joiners, syllables of scripts whose letters
/// carry marks.
final List<String> _pieces = <String>[
  'a',
  'b',
  ' ',
  '_',
  '.',
  '\n',
  '\r\n',
  'é',
  'สวัสดี',
  'हिन्दी',
  'مَرْحَبًا',
  '\u{20BB7}',
  '👍🏽',
  '👨‍👩‍👧',
  '🇮🇹',
  '🇮',
  'a${'́' * 80}',
  List.filled(40, '👨').join('‍'),
  '${'ᄀ' * 70}ᅡᆨ',
  List.filled(70, '🇮').join(),
  '‍',
  '́',
  '\uD83D', // half of a pair: what a broken input leaves
];

String _randomText(math.Random random, int pieces) => List.generate(
  pieces,
  (_) => _pieces[random.nextInt(_pieces.length)],
).join();

/// Every cluster boundary of [text], from its start.
List<int> _boundaries(String text) {
  final boundaries = <int>[0];
  for (final cluster in text.characters) {
    boundaries.add(boundaries.last + cluster.length);
  }
  return boundaries;
}

void main() {
  test('every step agrees with the text segmented from its start', () {
    final random = math.Random(1346);
    for (var round = 0; round < 60; round++) {
      final text = _randomText(random, 1 + random.nextInt(12));
      final steps = GraphemeSteps.ofString(text);
      final boundaries = _boundaries(text);
      for (var i = 0; i < boundaries.length; i++) {
        final at = boundaries[i];
        if (i + 1 < boundaries.length) {
          expect(
            steps.next(at),
            boundaries[i + 1],
            reason: 'next($at) of #$round: ${text.runes.toList()}',
          );
        }
        if (i > 0) {
          expect(
            steps.previous(at),
            boundaries[i - 1],
            reason: 'previous($at) of #$round: ${text.runes.toList()}',
          );
        }
      }
    }
  });

  test('from the middle of a cluster, the cluster that holds the unit', () {
    final random = math.Random(1347);
    for (var round = 0; round < 40; round++) {
      final text = _randomText(random, 1 + random.nextInt(8));
      final steps = GraphemeSteps.ofString(text);
      final boundaries = _boundaries(text);
      for (var at = 1; at <= text.length; at += 1 + random.nextInt(7)) {
        final start = boundaries.lastWhere((b) => b < at);
        expect(
          steps.previous(at),
          start,
          reason:
              'previous($at) of #$round: ${text.runes.toList()} $boundaries',
        );
      }
    }
  });

  test('a cluster of any length is one step, either way', () {
    for (final marks in <int>[64, 65, 200, 1000]) {
      final text = 'a${'́' * marks}b';
      final steps = GraphemeSteps.ofString(text);
      expect(steps.next(0), 1 + marks, reason: '$marks marks, right');
      expect(steps.previous(1 + marks), 0, reason: '$marks marks, left');
      expect(steps.previous(text.length), 1 + marks);
    }
    // A chain of 40 people joined, 119 units, which `package:characters` threw
    // on from a window that began on half a pair.
    final chain = 'x${List.filled(40, '👨').join('‍')}';
    final steps = GraphemeSteps.ofString(chain);
    expect(steps.previous(chain.length), 1);
    expect(steps.next(1), chain.length);
  });

  test('a run of flags pairs from its first, whichever way it is read', () {
    for (final flags in <int>[1, 2, 3, 40, 41, 100, 101]) {
      final text = 'a${'🇮' * flags}';
      final steps = GraphemeSteps.ofString(text);
      final expected = flags.isOdd ? 2 : 4;
      expect(
        steps.previous(text.length),
        text.length - expected,
        reason: '$flags indicators',
      );
      expect(steps.next(1), math.min(text.length, 5));
    }
  });

  test('a word run agrees with the clusters read one at a time', () {
    final random = math.Random(1348);
    for (var round = 0; round < 60; round++) {
      final text = _randomText(random, 1 + random.nextInt(14));
      final steps = GraphemeSteps.ofString(text);
      final boundaries = _boundaries(text);
      bool word(int i) =>
          isWordChar(text.substring(boundaries[i], boundaries[i + 1]));
      for (var i = 0; i < boundaries.length; i++) {
        for (final kind in <bool>[true, false]) {
          var forward = i;
          while (forward + 1 < boundaries.length && word(forward) == kind) {
            forward++;
          }
          expect(
            steps.runForward(boundaries[i], word: kind),
            boundaries[forward],
            reason: 'runForward($i, $kind) of #$round',
          );
          var backward = i;
          while (backward > 0 && word(backward - 1) == kind) {
            backward--;
          }
          expect(
            steps.runBackward(boundaries[i], word: kind),
            boundaries[backward],
            reason: 'runBackward($i, $kind) of #$round',
          );
        }
      }
    }
  });

  test('a word longer than a window is walked, not cut', () {
    // Longer than every chunk a scan reads, to be crossed more than once.
    final word = 'é' * 5000;
    final text = ' ${word}x ';
    final steps = GraphemeSteps.ofString(text);
    expect(steps.runForward(1, word: true), text.length - 1);
    expect(steps.runBackward(text.length - 1, word: true), 1);
    final wide = '́' * 9000;
    final huge = 'a$wide b';
    expect(
      GraphemeSteps.ofString(huge).runForward(0, word: true),
      huge.length - 2,
    );
    expect(
      GraphemeSteps.ofString(huge).runBackward(huge.length - 2, word: true),
      0,
    );
  });

  test('a letter is a word character by its first code point', () {
    expect(isWordChar('a'), isTrue);
    expect(isWordChar('_'), isTrue);
    expect(isWordChar('7'), isTrue);
    expect(isWordChar('é'), isTrue);
    expect(isWordChar('\u{20BB7}'), isTrue);
    expect(isWordChar('ส'), isTrue);
    expect(isWordChar('́'), isFalse);
    expect(isWordChar(' '), isFalse);
    expect(isWordChar('👍🏽'), isFalse);
    expect(isWordChar(''), isFalse);
  });
}
