// Running a program to its end (#63, #531): a hung one is killed, and a
// talkative one is drained with only the head of its output kept.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/process_run.dart';
import 'package:path/path.dart' as p;

void main() {
  group('running a process', () {
    test('a process that never answers is killed', () async {
      final dir = await Directory.current.createTemp('niman_process_');
      addTearDown(() async {
        if (dir.existsSync()) await dir.delete(recursive: true);
      });
      final script = File(p.join(dir.path, 'hang.dart'));
      await script.writeAsString('void main() { while (true) {} }\n');

      final started = Stopwatch()..start();
      await expectLater(
        runProcess(Platform.resolvedExecutable, <String>[
          script.path,
        ], timeout: const Duration(milliseconds: 500)),
        throwsA(isA<ProcessTimedOut>()),
      );
      // Killed, not waited out: the script would run forever.
      expect(started.elapsed, lessThan(const Duration(seconds: 20)));
    });

    test('a talkative process is drained, but only the head is kept', () async {
      var seen = 0;
      final chunks =
          Stream<List<int>>.fromIterable(<List<int>>[
            for (var at = 0; at < 2000; at++) List<int>.filled(100, 0x78),
          ]).map((chunk) {
            seen += chunk.length;
            return chunk;
          });
      final out = await collectProcessOutput(chunks);
      // Every byte went through — a pipe left full would block the writer
      // — and the buffer kept the cap, not the two hundred kilobytes (P3).
      expect(seen, 2000 * 100);
      expect(out.length, processOutputLimit);
    });

    test('a caller that reads the output keeps as much as it asks', () async {
      Stream<List<int>> chunks() => Stream<List<int>>.fromIterable(<List<int>>[
        for (var at = 0; at < 2000; at++) List<int>.filled(100, 0x78),
      ]);
      // A page's DOM is the whole answer, not a log line (#531): a larger
      // limit keeps all of it, a smaller one cuts where it says.
      expect(
        (await collectProcessOutput(chunks(), limit: 1 << 20)).length,
        2000 * 100,
      );
      expect((await collectProcessOutput(chunks(), limit: 150)).length, 150);
    });

    test('the runner passes its limit to the output it keeps', () async {
      final dir = await Directory.current.createTemp('niman_process_');
      addTearDown(() async {
        if (dir.existsSync()) await dir.delete(recursive: true);
      });
      final text = File(p.join(dir.path, 'talk.txt'));
      await text.writeAsString('x' * 100000);
      // A program that prints a file is on every host: under `flutter test`
      // the resolved executable is the tester, not a Dart that runs scripts.
      Future<ProcessAnswer> printFile({int? outputLimit}) => Platform.isWindows
          ? runProcess('cmd', <String>[
              '/c',
              'type',
              text.path,
            ], outputLimit: outputLimit)
          : runProcess('cat', <String>[text.path], outputLimit: outputLimit);

      final whole = await printFile(outputLimit: 1 << 20);
      expect(whole.exit, 0);
      expect(whole.stdout.length, 100000);

      final head = await printFile();
      expect(head.stdout.length, processOutputLimit);
    });
  });
}
