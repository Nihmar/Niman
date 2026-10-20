// The 2026-10-20 device log: a 1.5 MB note saved twice in a second, its
// reindex reading the whole file between the two writes. The second write
// took 480 ms against the first's 123 ms. `NoteWriter.quietBeforeReindex`
// now holds a note of that size for two seconds, so the next save cannot
// fall inside the reindex.
//
// This is the same shape as the other benchmarks in this repository: the
// numbers are printed on every run, and the design's ratio is asserted only
// by a run that asks for it — `NIMAN_PERF=1 flutter test
// test/perf/save_reindex_quiet_test.dart`. What every run asserts is that the
// reindex is still waiting while the second save writes, and a wide ratio
// backstop.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_writer.dart';
import 'package:path/path.dart' as p;

/// Whether this run is the one that holds the design's ceilings.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

void main() {
  late Directory root;
  late Directory dbDir;
  late IndexDatabase db;
  late Indexer indexer;
  late NoteWriter writer;

  setUp(() async {
    root = await Directory.current.createTemp('niman_save_quiet_');
    dbDir = await Directory.current.createTemp('niman_save_quiet_db_');
    db = IndexDatabase(NativeDatabase(File(p.join(dbDir.path, 'test.sqlite'))));
    addTearDown(db.close);
    indexer = Indexer(db);
    writer = NoteWriter(root: root.path, indexer: indexer);
  });

  tearDown(() async {
    await writer.indexed;
    await db.close();
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  });

  test('a second save does not wait for the first reindex', () async {
    final firstText = 'a' * (1536 << 10);
    final secondText = 'b' * ((1536 << 10) - 1);
    // Both measured saves overwrite the same file: the first save of a
    // missing note creates it, and creating is not what the device log
    // measured. The warm-up also leaves the index caught up, so the two
    // measured saves differ only in the reindex being deferred.
    await writer.save('Big.md', firstText);
    await writer.indexed;

    final first = Stopwatch()..start();
    await writer.save('Big.md', firstText);
    first.stop();

    final second = Stopwatch()..start();
    await writer.save('Big.md', secondText);
    second.stop();

    // The reindex waits for the note to be quiet: the second save wrote the
    // disk without the first reindex reading the file beside it. The row
    // still holds the previous text, one byte longer.
    expect(
      (await indexer.dao.find('Big.md'))!.size,
      firstText.length,
      reason: 'the reindex is still waiting while the second save writes',
    );

    final reindex = Stopwatch()..start();
    await writer.indexed;
    reindex.stop();
    expect((await indexer.dao.find('Big.md'))!.size, secondText.length);

    // Before the fix the second write was 3.9 times the first's, because the
    // reindex of the first read the file while the second wrote it.
    const ceiling = 2.0;
    const backstop = 4.0;
    final bar = _referenceHost ? ceiling : backstop;
    final ratio = second.elapsedMicroseconds / first.elapsedMicroseconds;
    print(
      '1.5 MB saves: first ${first.elapsedMilliseconds} ms, '
      'second ${second.elapsedMilliseconds} ms '
      '(ratio ${ratio.toStringAsFixed(2)}x, held to $bar x), '
      'reindex ${reindex.elapsedMilliseconds} ms',
    );
    expect(ratio, lessThan(bar));
  });
}
