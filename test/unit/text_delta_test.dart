// The history's deltas (#1148): whatever two versions are, the delta
// rebuilds the newer from the older byte for byte, and a damaged one never
// rebuilds anything.
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/history/text_delta.dart';

Uint8List _bytes(String text) => Uint8List.fromList(utf8.encode(text));

void main() {
  void roundTrip(String base, String target) {
    final delta = computeDelta(_bytes(base), _bytes(target));
    expect(utf8.decode(applyDelta(_bytes(base), delta)), target);
  }

  test('rebuilds the target from the base', () {
    roundTrip('', '');
    roundTrip('', 'all new\n');
    roundTrip('all gone\n', '');
    roundTrip('same\n' * 50, 'same\n' * 50);
    roundTrip('no newline at the end', 'no newline at the end, changed');
  });

  test('a small edit to a long note is a small delta', () {
    final base = [
      for (var i = 0; i < 2000; i++) 'Line $i of a long note, as written.',
    ].join('\n');
    final lines = base.split('\n')..insert(1000, 'An added line.');
    final target = lines.join('\n');
    final delta = computeDelta(_bytes(base), _bytes(target));
    expect(utf8.decode(applyDelta(_bytes(base), delta)), target);
    expect(delta.length, lessThan(100), reason: 'two copies and an insert');
  });

  test('random edits round-trip', () {
    final random = Random(1148);
    const alphabet = 'abc \n\n.#é漢';
    String text(int length) => String.fromCharCodes([
      for (var i = 0; i < length; i++)
        alphabet.codeUnitAt(random.nextInt(alphabet.length)),
    ]);
    for (var round = 0; round < 300; round++) {
      final base = text(random.nextInt(400));
      var target = base;
      for (var edit = random.nextInt(6); edit > 0; edit--) {
        final at = target.isEmpty ? 0 : random.nextInt(target.length);
        final cut = min(random.nextInt(30), target.length - at);
        target =
            target.substring(0, at) +
            text(random.nextInt(30)) +
            target.substring(at + cut);
      }
      roundTrip(base, target);
    }
  });

  test('a delta made against another base is refused', () {
    final delta = computeDelta(_bytes('one\n' * 20), _bytes('two\n' * 20));
    expect(
      () => applyDelta(_bytes('three\n' * 20), delta),
      throwsFormatException,
    );
  });

  test('a delta cut short is refused', () {
    final base = _bytes('a line long enough to copy from\n' * 10);
    final target = _bytes(
      'a line long enough to copy from\n' * 5 + 'new text\n',
    );
    final delta = computeDelta(base, target);
    expect(
      () => applyDelta(base, Uint8List.sublistView(delta, 0, delta.length - 3)),
      throwsFormatException,
    );
  });
}
