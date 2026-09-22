// The lazy tokenizer against the eager one (0.0.9 stress test): the block
// state is carried through every line before the one asked for, the inline
// tokens are made only for the lines asked for — and the answer is the same
// as tokenizing the whole note, in any order of asking and across edits.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';

/// A line of a note that has every block the state carries.
String _line(Random random) => switch (random.nextInt(12)) {
  0 => '```dart',
  1 => '```',
  2 => r'$$',
  3 => '---',
  4 => '# Heading ${random.nextInt(9)}',
  5 => '- item **bold** and `code`',
  6 => r'inline $x^2$ and [[link]]',
  7 => '',
  8 => '~~~',
  _ => 'plain words ${random.nextInt(100)}',
};

String _describe(StyledLine line) {
  final tokens = [
    for (final t in line.tokens) '${t.kind.name}@${t.start}-${t.end}',
  ];
  return '${line.text}: ${tokens.join(' ')}';
}

void _same(HighlightDocument lazy, List<String> lines, Random random) {
  final eager = HighlightDocument.fromText(lines.join('\n'));
  final order = List<int>.generate(lines.length, (at) => at)..shuffle(random);
  for (final at in order) {
    expect(
      _describe(lazy.lineAt(at)),
      _describe(eager.lineAt(at)),
      reason: 'line $at',
    );
  }
}

void main() {
  test('any order of asking gives the eager answer', () {
    final random = Random(11);
    for (var round = 0; round < 30; round++) {
      final lines = [for (var at = 0; at < 60; at++) _line(random)];
      _same(HighlightDocument.fromLines(lines), lines, random);
    }
  });

  test('and so does every edit after it', () {
    final random = Random(12);
    for (var round = 0; round < 30; round++) {
      final lines = [for (var at = 0; at < 60; at++) _line(random)];
      final lazy = HighlightDocument.fromLines(List<String>.of(lines));
      for (var edit = 0; edit < 8; edit++) {
        // Some lines drawn, the rest not: the mix an editor leaves.
        for (var ask = 0; ask < 5; ask++) {
          lazy.lineAt(random.nextInt(lines.length));
        }
        final first = random.nextInt(lines.length);
        final removed = random.nextInt(min(3, lines.length - first) + 1);
        final inserted = [
          for (var at = 0; at < random.nextInt(3); at++) _line(random),
        ];
        if (lines.length - removed + inserted.length == 0) continue;
        lines.replaceRange(first, first + removed, inserted);
        lazy.replaceLines(first, removed, inserted);
        _same(lazy, lines, random);
      }
    }
  });

  test('the last line of a long note is asked for without the rest', () {
    final lines = [
      for (var at = 0; at < 300000; at++)
        if (at % 50 == 0) '# Section $at' else 'a **line** with `code` and $at',
    ];
    final lazy = HighlightDocument.fromLines(lines);
    final clock = Stopwatch()..start();
    lazy.lineAt(lines.length - 1);
    final last = clock.elapsedMicroseconds;
    clock.reset();
    HighlightDocument.fromLines(lines).lines;
    final whole = clock.elapsedMicroseconds;
    // Carrying the block state through the lines above is a few comparisons
    // a line; tokenizing them inline — what asking for the last one did — is
    // the whole note's cost (163 s on a real one).
    expect(
      last,
      lessThan(whole ~/ 5),
      reason: 'last $last us, whole $whole us',
    );
  });
}
