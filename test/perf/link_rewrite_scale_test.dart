// What rewriting the links costs after a big folder moves (#507).
//
// A rename of a folder of 100 000 files, cited by 1 000 notes of 20 links
// each. Asking every link against every moved path was 20 000 × 100 000
// comparisons — minutes on the isolate the rename waits on; the moves are
// indexed once instead, and a link is a lookup.
//
// Same shape as the other benchmarks in this repository: the number is
// printed, a **backstop** is asserted on any host, and the design's ceiling
// is asserted only by a run that asks for it —
// `NIMAN_PERF=1 flutter test test/perf/link_rewrite_scale_test.dart`.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/links/link_moves.dart';
import 'package:niman/src/links/rewrite.dart';

/// Whether this run is the one that holds the design's ceilings.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

const int _files = 100000;
const int _notes = 1000;
const int _linksPerNote = 20;

/// Link [l] of a note, to moved file [i]: by path, by Markdown href, by the
/// tail of its path (which the rename leaves alone), and to a note that did
/// not move.
String _link(int l, int i) => switch (l % 4) {
  0 => '[[Docs/Sub${i % 100}/Note$i]]',
  1 => '[x](Docs/Sub${i % 100}/Note$i.md)',
  2 => '[[Sub${i % 100}/Note$i]]',
  _ => '[[Elsewhere/Note$l]]',
};

void main() {
  test('rewriting a thousand notes after a 100k-file folder rename', () {
    final clock = Stopwatch()..start();
    final moves = LinkMoves({
      for (var i = 0; i < _files; i++)
        'Docs/Sub${i % 100}/Note$i.md': 'Books/Sub${i % 100}/Note$i.md',
    });
    final texts = [
      for (var n = 0; n < _notes; n++)
        [
          for (var l = 0; l < _linksPerNote; l++)
            _link(l, (n * 37 + l) % _files),
        ].join(' and '),
    ];
    var changed = 0;
    for (final text in texts) {
      final out = rewriteMovedLinks(text, from: 'root.md', moves: moves);
      if (!identical(out, text)) changed++;
    }
    clock.stop();
    final ms = clock.elapsedMicroseconds / 1000;
    // 533 ms here, the fixture's building included; asking every link against
    // every moved path took 6 s for 20 of these notes, ~5 minutes for all.
    // The backstop is what a shared runner several times slower still reads.
    const ceiling = 1000.0;
    const backstop = 5000.0;
    final bar = _referenceHost ? ceiling : backstop;
    print(
      'link rewrite, $_notes notes x $_linksPerNote links over $_files '
      'moved files: ${ms.toStringAsFixed(1)} ms (held to $bar ms)',
    );
    expect(changed, _notes, reason: 'every note cites something that moved');
    expect(ms, lessThan(bar));
  });
}
