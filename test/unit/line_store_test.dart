// The chunked line store and the copies that share its chunks: every read
// has to be what a plain list would answer, and a write to one side must never
// be seen by the other — the snapshot the read pane holds depends on it.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/line_store.dart';
import 'package:niman/src/markdown/prefix_sums.dart';

/// A store and the plain lists it must agree with.
final class _Pair {
  new(this.lines, this.terminators)
    : store = LineStore(List<String>.of(lines), List<String>.of(terminators));

  new sharing(_Pair other)
    : lines = List<String>.of(other.lines),
      terminators = List<String>.of(other.terminators),
      store = LineStore.sharing(other.store);

  final List<String> lines;
  final List<String> terminators;
  final LineStore store;

  /// A random edit, made to both.
  void edit(Random random, String tag) {
    final start = random.nextInt(lines.length + 1);
    final end = min(lines.length, start + random.nextInt(3000));
    // Mostly small: typing, an Enter, a line joined; now and then a paste
    // long enough to be cut into chunks of its own.
    final count = switch (random.nextInt(10)) {
      0 => random.nextInt(5000),
      1 => end - start,
      _ => random.nextInt(3),
    };
    final added = [for (var at = 0; at < count; at++) '$tag$at'];
    String eol(int at) => at.isEven ? '\n' : '\r\n';
    final ends = [for (var at = 0; at < count; at++) eol(at)];
    lines.replaceRange(start, end, added);
    terminators.replaceRange(start, end, ends);
    store.replaceRange(start, end, added, ends);
  }

  void check(String reason) {
    expect(store.length, lines.length, reason: reason);
    // In order, as the scanner reads, and out of order, as a frame does.
    for (var at = 0; at < lines.length; at++) {
      expect(store.lineAt(at), lines[at], reason: '$reason line $at');
      expect(store.terminatorAt(at), terminators[at], reason: reason);
    }
    final random = Random(lines.length);
    for (var ask = 0; ask < 200 && lines.isNotEmpty; ask++) {
      final at = random.nextInt(lines.length);
      expect(store.lineAt(at), lines[at], reason: '$reason line $at');
    }
  }
}

void main() {
  test('reads as a list would, through edits of every size', () {
    final random = Random(3);
    final pair = _Pair(
      [for (var at = 0; at < 5000; at++) 'line $at'],
      [for (var at = 0; at < 5000; at++) '\n'],
    );
    for (var edit = 0; edit < 200; edit++) {
      pair
        ..edit(random, 'e$edit-')
        ..check('edit $edit');
    }
  });

  test("a copy and its source never see each other's writes", () {
    final random = Random(5);
    var older = _Pair(
      [for (var at = 0; at < 6000; at++) 'line $at'],
      [for (var at = 0; at < 6000; at++) '\n'],
    );
    for (var round = 0; round < 30; round++) {
      // A snapshot taken, then both written to, each on its own.
      final newer = _Pair.sharing(older);
      for (var edit = 0; edit < 5; edit++) {
        older.edit(random, 'o$round.$edit-');
        newer.edit(random, 'n$round.$edit-');
      }
      older.check('round $round, the source');
      newer.check('round $round, the copy');
      older = random.nextBool() ? older : newer;
    }
  });

  test("prefix sums: a copy and its source never see each other's writes", () {
    final random = Random(9);
    List<double> values(int count) => [
      for (var at = 0; at < count; at++) random.nextInt(50).toDouble(),
    ];
    void check(PrefixSums sums, List<double> plain, String reason) {
      expect(sums.length, plain.length, reason: reason);
      var sum = 0.0;
      for (var at = 0; at < plain.length; at++) {
        expect(sums.offsetOf(at), sum, reason: '$reason at $at');
        sum += plain[at];
      }
      expect(sums.total, sum, reason: reason);
    }

    void edit(PrefixSums sums, List<double> plain) {
      final at = random.nextInt(plain.length + 1);
      if (at < plain.length && random.nextBool()) {
        final value = random.nextInt(50).toDouble();
        plain[at] = value;
        sums.setValue(at, value);
        return;
      }
      final removed = min(plain.length - at, random.nextInt(2500));
      final inserted = values(random.nextInt(2500));
      plain.replaceRange(at, at + removed, inserted);
      sums.splice(at, removed, inserted);
    }

    var plain = values(5000);
    var sums = PrefixSums(List<double>.of(plain));
    for (var round = 0; round < 30; round++) {
      final copyPlain = List<double>.of(plain);
      final copy = PrefixSums.sharing(sums);
      for (var step = 0; step < 5; step++) {
        edit(sums, plain);
        edit(copy, copyPlain);
      }
      check(sums, plain, 'round $round, the source');
      check(copy, copyPlain, 'round $round, the copy');
      if (random.nextBool()) {
        sums = copy;
        plain = copyPlain;
      }
    }
  });
}
