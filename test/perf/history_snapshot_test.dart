// What keeping a note's history costs (#1148): the snapshot a save waits for,
// the room the versions take, and reading the oldest one back.
//
// The device log of 2026-10-20 had the first save of an editing session wait
// 85 ms at the median and 219 ms at worst for its snapshot, the same for a
// 10 KB note as for a 1.5 MB one: two flushed writes, a whole copy and the
// manifest. This holds the snapshot a save waits for, and the room twenty
// sessions of small edits take on disk once the upkeep has packed them.
//
// On this host, before #1148: 4.0 / 19.4 ms a snapshot (10 KB / 1.5 MB),
// and 100 % of twenty copies on disk, 30 MB for the long note. After: 1.0 /
// 26 ms with nothing flushed, and 4.4 / 2.1 % of the copies packed.
//
// Printed, like every perf file here; the bars are asserted under
// `NIMAN_PERF=1` alone, with a backstop everywhere (AGENTS.md).
@Timeout(Duration(minutes: 5))
library;

// The point of this file is to print its measurements into the test log.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/history/history_store.dart';
import 'package:niman/src/history/history_upkeep.dart';
import 'package:niman/src/history/snapshot_policy.dart';
import 'package:path/path.dart' as p;

final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// The bars under `NIMAN_PERF`, by note: a snapshot's median, in
/// milliseconds, and what the packed history may take of twenty copies.
const Map<String, ({double snapshotMs, double packedShare})> _bars = {
  '10 KB': (snapshotMs: 5, packedShare: 0.10),
  '1.5 MB': (snapshotMs: 50, packedShare: 0.05),
};

const List<String> _words = [
  'the',
  'history',
  'keeps',
  'what',
  'a',
  'save',
  'replaces',
  'note',
  'long',
  'version',
  'next',
  'reader',
  'chapter',
  'river',
  'stone',
  'light',
  'morning',
  'quiet',
  'letter',
  'window',
  'garden',
  'shadow',
  'memory',
  'winter',
  'paper',
  'voice',
  'distant',
  'harbour',
  'travel',
  'answer',
  'question',
  'promise',
  'silver',
  'evening',
  'between',
  'under',
  'across',
  'without',
  'before',
  'after',
  'slowly',
  'never',
  'always',
  'perhaps',
];

/// A note of [bytes] bytes of prose, one paragraph a line: words drawn by a
/// fixed sequence, so it compresses about as prose does and the same every
/// run.
String _note(int bytes) {
  final out = StringBuffer('# A long note\n\n');
  var seed = 7;
  while (out.length < bytes) {
    final words = 20 + seed % 40;
    for (var i = 0; i < words; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
      out
        ..write(i == 0 ? '' : ' ')
        ..write(_words[(seed >> 8) % _words.length]);
    }
    out.writeln('.');
  }
  return out.toString();
}

/// [text] with one paragraph inserted at a place [session] picks: the edit
/// an editing session makes.
String _edited(String text, int session) {
  final lines = text.split('\n');
  final at = 2 + (session * 7919) % (lines.length - 3);
  lines.insert(at, 'An added paragraph, session $session.');
  return lines.join('\n');
}

int _folderBytes(Directory dir) {
  if (!dir.existsSync()) return 0;
  var total = 0;
  for (final entry in dir.listSync(recursive: true)) {
    if (entry is File) total += entry.lengthSync();
  }
  return total;
}

int _median(List<int> values) => ([...values]..sort())[values.length ~/ 2];

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.current.createTemp('niman_history_perf_');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  for (final (name, size) in [('10 KB', 10 * 1024), ('1.5 MB', 1536 * 1024)]) {
    test('$name: twenty sessions of small edits', () {
      const sessions = 20;
      const rel = 'Notes/long.md';
      final file = File(p.join(root.path, rel))..createSync(recursive: true);
      var text = _note(size);
      file.writeAsStringSync(text);
      final times = <int>[];
      final splits = <String>[];
      for (var session = 0; session < sessions; session++) {
        final request = SnapshotRequest(
          limit: sessions,
          interval: const Duration(minutes: 5),
          now: DateTime(2026, 10, 21, 9).add(Duration(hours: session)),
          sessionStart: true,
        );
        final clock = Stopwatch()..start();
        final outcome = snapshotBeforeWrite(root.path, rel, request);
        times.add(clock.elapsedMicroseconds);
        if (session == sessions ~/ 2) splits.add(outcome.describe(rel));
        expect(outcome.decision.take, isTrue, reason: outcome.describe(rel));
        text = _edited(text, session);
        file.writeAsStringSync(text);
      }
      final history = Directory(p.join(root.path, historyFolderName));
      final stored = _folderBytes(history);
      final pack = Stopwatch()..start();
      final upkeep = maintainHistory(root.path);
      final packMs = pack.elapsedMilliseconds;
      final packed = _folderBytes(history);
      final manifest = readHistoryManifest(root.path, rel);
      expect(manifest.versions, hasLength(sessions));
      final oldest = manifest.versions.first.number;
      final clock = Stopwatch()..start();
      final bytes = readHistoryVersion(root.path, rel, oldest);
      final readMs = clock.elapsedMilliseconds;
      expect(bytes, isNotNull);
      final median = _median(times) / 1000;
      final ratio = stored / (size * sessions);
      final packedRatio = packed / (size * sessions);
      print(
        '[perf] history $name: snapshot median '
        '${median.toStringAsFixed(1)} ms, worst '
        '${(times.reduce((a, b) => a > b ? a : b) / 1000).toStringAsFixed(1)}'
        ' ms; $sessions versions take ${(stored / 1024).round()} KB '
        '(${(ratio * 100).toStringAsFixed(1)} % of $sessions copies), '
        '${(packed / 1024).round()} KB packed '
        '(${(packedRatio * 100).toStringAsFixed(1)} %, ${upkeep.packed} '
        'deltas in $packMs ms); oldest read in $readMs ms\n'
        '[perf]   ${splits.single}',
      );
      // The backstop: a snapshot past a second is not a store, it is a hang,
      // and a packed history as big as the copies packed nothing.
      expect(median, lessThan(1000));
      expect(readMs, lessThan(5000));
      expect(packedRatio, lessThan(0.5));
      expect(upkeep.packed, sessions - 2, reason: 'one whole every 16');
      if (_referenceHost) {
        final bar = _bars[name]!;
        expect(median, lessThan(bar.snapshotMs), reason: 'snapshot median');
        expect(
          packedRatio,
          lessThan(bar.packedShare),
          reason: 'the packed history',
        );
      }
    });
  }
}
