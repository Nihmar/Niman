import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/history/history_legacy.dart';
import 'package:niman/src/history/history_lock.dart';
import 'package:niman/src/history/history_log.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_objects.dart';
import 'package:niman/src/history/history_store.dart';
import 'package:niman/src/history/history_upkeep.dart';
import 'package:niman/src/history/snapshot_policy.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  final t0 = DateTime(2026, 9, 15, 10);

  setUp(() async {
    root = await Directory.current.createTemp('niman_history_');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  File note(String rel) => File(p.join(root.path, rel));

  void write(String rel, String text) {
    final file = note(rel);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(text);
  }

  String version(String rel, int n) =>
      utf8.decode(readHistoryVersion(root.path, rel, n)!);

  String sha(String text) => sha256.convert(utf8.encode(text)).toString();

  File object(String text) => File(historyObjectPath(root.path, sha(text)));

  SnapshotRequest forced({int limit = 10, DateTime? now}) => SnapshotRequest(
    limit: limit,
    interval: const Duration(minutes: 5),
    now: now ?? t0,
    forced: HistoryReason.restore,
  );

  /// Saves [text] the way the writer does: snapshot, then write.
  SnapshotOutcome save(String rel, String text, SnapshotRequest request) {
    final outcome = snapshotBeforeWrite(root.path, rel, request);
    write(rel, text);
    return outcome;
  }

  test('keeps the text a save replaces, byte for byte', () {
    write('Notes/a.md', 'first');
    final outcome = save('Notes/a.md', 'second', forced());
    expect(outcome.version!.number, 1);
    expect(version('Notes/a.md', 1), 'first');
    expect(object('first').existsSync(), isTrue);
    expect(File(historyLogPath(root.path, 'Notes/a.md')).existsSync(), isTrue);
    final manifest = readHistoryManifest(root.path, 'Notes/a.md');
    expect(manifest.versions.single.reason, HistoryReason.restore);
  });

  test('the same content is kept once, whichever note keeps it', () {
    write('a.md', 'shared text');
    write('b.md', 'shared text');
    save('a.md', 'a2', forced());
    save('b.md', 'b2', forced());
    final objects = listObjects(root.path);
    expect(objects.keys, [sha('shared text')]);
    expect(version('a.md', 1), 'shared text');
    expect(version('b.md', 1), 'shared text');
  });

  test('N+1 saves keep exactly N versions', () {
    write('a.md', 'text 0');
    for (var i = 1; i <= 4; i++) {
      save('a.md', 'text $i', forced(limit: 3));
    }
    final manifest = readHistoryManifest(root.path, 'a.md');
    expect(manifest.versions.map((v) => v.number), [2, 3, 4]);
    expect(version('a.md', 2), 'text 1');
    expect(readHistoryVersion(root.path, 'a.md', 1), isNull);
  });

  test('a pinned version survives rotation', () {
    write('a.md', 'base');
    save('a.md', 'one', forced(limit: 2));
    pinHistoryVersion(root.path, 'a.md', syncBasePin, 1, limit: 2);
    for (var i = 2; i <= 5; i++) {
      save('a.md', 'text $i', forced(limit: 2));
    }
    final manifest = readHistoryManifest(root.path, 'a.md');
    expect(manifest.pins, {syncBasePin: 1});
    expect(manifest.versions.map((v) => v.number), [1, 4, 5]);
    expect(version('a.md', 1), 'base');
  });

  test('a version whose bytes changed on disk is not returned as its hash '
      'claims', () {
    write('a.md', 'first');
    save('a.md', 'second', forced());
    // The object drifts: an edit by hand, a sync race.
    object('first').writeAsStringSync('damaged');
    expect(readHistoryVersion(root.path, 'a.md', 1), isNull);
  });

  test('an object a crash cut short reads as a missing version', () {
    write('a.md', 'first, long enough to be more than a header');
    save('a.md', 'second', forced());
    final file = object('first, long enough to be more than a header');
    file.writeAsBytesSync(file.readAsBytesSync().sublist(0, 9));
    expect(readHistoryVersion(root.path, 'a.md', 1), isNull);
    // The note holds that content again, unchanged since v1: the save takes
    // nothing and does not wait on checking v1; the upkeep finds it cut
    // short and writes it again from the note, whole.
    write('a.md', 'first, long enough to be more than a header');
    final outcome = save(
      'a.md',
      'first, long enough to be more than a header',
      forced(),
    );
    expect(outcome.version, isNull, reason: outcome.describe('a.md'));
    maintainHistory(root.path, now: t0.add(const Duration(days: 1)));
    expect(version('a.md', 1), 'first, long enough to be more than a header');
  });

  test('the sync base skips a drifted version and pins none', () {
    write('a.md', 'base');
    save('a.md', 'second', forced());
    object('base').writeAsStringSync('damaged');
    final result = pinSyncBaseVersion(
      root.path,
      'a.md',
      sha('base'),
      limit: 3,
      now: t0,
    );
    expect(result.pinned, isNull);
    expect(readHistoryManifest(root.path, 'a.md').pins[syncBasePin], isNull);
  });

  test('a pin on a version whose object went keeps its number to itself', () {
    write('a.md', 'agreed');
    save('a.md', 'edited', forced());
    pinHistoryVersion(root.path, 'a.md', syncBasePin, 1, limit: 10);
    // v1's object goes (by hand, or a sync tool), the pin still names v1.
    object('agreed').deleteSync();
    final outcome = save('a.md', 'edited again', forced());
    // The next version is not v1 again: the pin would have moved onto
    // content both sides never agreed on, and merged on it (#378).
    expect(outcome.version!.number, 2);
    final manifest = readHistoryManifest(root.path, 'a.md');
    expect(manifest.pins[syncBasePin], isNull);
    expect(version('a.md', 2), 'edited');
  });

  test('numbers stay unique through rotation and compaction', () {
    write('a.md', 'text 0');
    for (var i = 1; i <= 60; i++) {
      save('a.md', 'text $i', forced(limit: 1));
    }
    final numbers = readHistoryManifest(
      root.path,
      'a.md',
    ).versions.map((v) => v.number);
    expect(numbers, [60]);
  });

  test(
    'a save waits for the lock another writer holds, then appends',
    () async {
      write('a.md', 'one');
      save('a.md', 'two', forced());
      final lock = File(historyLockPath(root.path, 'a.md'))
        ..createSync(recursive: true);
      // Another isolate holds the note's lock for a while: a compaction, a
      // pin. The save waits for it rather than writing beside it.
      final releaser = Isolate.run(() {
        sleep(const Duration(milliseconds: 300));
        lock.deleteSync();
      });
      final clock = Stopwatch()..start();
      save('a.md', 'three', forced());
      expect(clock.elapsedMilliseconds, greaterThanOrEqualTo(250));
      await releaser;
      expect(
        readHistoryManifest(root.path, 'a.md').versions.map((v) => v.number),
        [1, 2],
      );
    },
  );

  test('a lock a crash left is broken once stale', () {
    write('a.md', 'one');
    File(historyLockPath(root.path, 'a.md'))
      ..createSync(recursive: true)
      ..setLastModifiedSync(
        DateTime.now().subtract(const Duration(minutes: 5)),
      );
    save('a.md', 'two', forced());
    expect(version('a.md', 1), 'one');
    expect(File(historyLockPath(root.path, 'a.md')).existsSync(), isFalse);
  });

  test('a log line cut short is skipped, and the next append reads', () {
    write('a.md', 'one');
    save('a.md', 'two', forced());
    // A crash in the middle of an append: half a line, no newline.
    File(historyLogPath(root.path, 'a.md'))
        .writeAsStringSync('{"v":2,"t":17', mode: FileMode.append);
    expect(readHistoryManifest(root.path, 'a.md').versions, hasLength(1));
    save('a.md', 'three', forced());
    final manifest = readHistoryManifest(root.path, 'a.md');
    expect(manifest.versions.map((v) => v.number), [1, 2]);
    expect(version('a.md', 2), 'two');
  });

  test('a log rotated many times is compacted, not grown', () {
    write('a.md', 'text 0');
    for (var i = 1; i <= 200; i++) {
      save('a.md', 'text $i', forced(limit: 2));
    }
    final lines = File(historyLogPath(root.path, 'a.md'))
        .readAsLinesSync()
        .where((l) => l.trim().isNotEmpty);
    expect(lines.length, lessThan(30));
    expect(
      readHistoryManifest(root.path, 'a.md').versions.map((v) => v.number),
      [199, 200],
    );
  });

  test('a similarly named note does not borrow versions', () {
    write('a.md', 'a');
    write('a.md.v1', 'decoy note');
    save('a.md', 'a2', forced());
    save('a.md.v1', 'decoy 2', forced());
    expect(readHistoryManifest(root.path, 'a.md').versions, hasLength(1));
    expect(readHistoryManifest(root.path, 'a.md.v1').versions, hasLength(1));
  });

  test('history follows a renamed note', () {
    write('Old.md', 'one');
    save('Old.md', 'two', forced());
    note('Old.md').renameSync(note('New.md').path);
    expect(moveNoteHistory(root.path, 'Old.md', 'New.md'), 1);
    expect(readHistoryManifest(root.path, 'Old.md').versions, isEmpty);
    expect(version('New.md', 1), 'one');
  });

  test('moving onto leftover history keeps both, renumbered', () {
    write('a.md', 'a1');
    save('a.md', 'a2', forced());
    write('b.md', 'b1');
    save('b.md', 'b2', forced());
    moveNoteHistory(root.path, 'a.md', 'b.md');
    final manifest = readHistoryManifest(root.path, 'b.md');
    expect(manifest.versions.map((v) => v.number), [1, 2]);
    expect(version('b.md', 1), 'b1');
    expect(version('b.md', 2), 'a1');
  });

  test('history follows a renamed folder', () {
    write('Dir/Sub/n.md', 'one');
    save('Dir/Sub/n.md', 'two', forced());
    expect(moveFolderHistory(root.path, 'Dir', 'Renamed'), 1);
    expect(version('Renamed/Sub/n.md', 1), 'one');
    expect(
      Directory(p.join(root.path, historyFolderName, 'Dir')).existsSync(),
      isFalse,
    );
  });

  test('a folder moved onto one with history merges note by note', () {
    write('A/n.md', 'a one');
    save('A/n.md', 'a two', forced());
    write('B/n.md', 'b one');
    save('B/n.md', 'b two', forced());
    expect(moveFolderHistory(root.path, 'A', 'B'), 1);
    expect(version('B/n.md', 1), 'b one');
    expect(version('B/n.md', 2), 'a one');
  });

  test('deleting history removes the log and empty folders', () {
    write('Dir/n.md', 'one');
    save('Dir/n.md', 'two', forced());
    expect(deleteNoteHistory(root.path, 'Dir/n.md'), 1);
    expect(
      Directory(p.join(root.path, historyFolderName, 'Dir')).existsSync(),
      isFalse,
    );
    // The object stays for the collection (history_upkeep_test.dart).
    expect(object('one').existsSync(), isTrue);
  });

  group('the history kept before #1148', () {
    /// Lays out the old history of [rel]: a whole copy a version and the
    /// manifest describing them.
    void legacy(
      String rel,
      Map<int, String> versions, {
      Map<String, int> pins = const {},
      Map<int, String> claimed = const {},
      bool manifest = true,
    }) {
      for (final MapEntry(key: n, value: text) in versions.entries) {
        File(p.join(root.path, historyFolderName, '$rel.v$n'))
          ..createSync(recursive: true)
          ..writeAsStringSync(text);
      }
      if (!manifest) return;
      File(legacyManifestPath(root.path, rel)).writeAsStringSync(
        HistoryManifest(
          versions: [
            for (final MapEntry(key: n, value: text) in versions.entries)
              HistoryVersion(
                number: n,
                savedAt: t0.add(Duration(minutes: n)),
                reason: HistoryReason.session,
                size: text.length,
                sha256: sha(claimed[n] ?? text),
              ),
          ],
          pins: pins,
        ).encode(),
      );
    }

    test('moves in the first time it is read, numbers and pins kept', () {
      legacy('Notes/a.md', {3: 'three', 5: 'five'}, pins: {syncBasePin: 3});
      final manifest = readHistoryManifest(root.path, 'Notes/a.md');
      expect(manifest.versions.map((v) => v.number), [3, 5]);
      expect(manifest.versions.first.reason, HistoryReason.session);
      expect(
        manifest.versions.first.savedAt,
        t0.add(const Duration(minutes: 3)),
      );
      expect(manifest.pins, {syncBasePin: 3});
      expect(version('Notes/a.md', 3), 'three');
      expect(version('Notes/a.md', 5), 'five');
      final folder = Directory(p.join(root.path, historyFolderName, 'Notes'));
      expect(folder.listSync().map((e) => p.basename(e.path)), [
        'a.md.log',
      ], reason: 'the old files go once the log is written');
    });

    test('a version that drifted stays out, as it always read', () {
      legacy('a.md', {1: 'damaged', 2: 'two'}, claimed: {1: 'one'});
      final manifest = readHistoryManifest(root.path, 'a.md');
      expect(manifest.versions.map((v) => v.number), [2]);
    });

    test('files without a manifest come in as unknown versions', () {
      legacy('a.md', {1: 'one', 2: 'two'}, manifest: false);
      final manifest = readHistoryManifest(root.path, 'a.md');
      expect(manifest.versions.map((v) => v.reason), [
        HistoryReason.unknown,
        HistoryReason.unknown,
      ]);
      expect(version('a.md', 1), 'one');
    });

    test('a snapshot on an old history numbers after it', () {
      legacy('a.md', {7: 'seven'});
      write('a.md', 'current');
      expect(save('a.md', 'newer', forced()).version!.number, 8);
      expect(version('a.md', 7), 'seven');
      expect(version('a.md', 8), 'current');
    });

    test('a move cut short before the old files went is finished', () {
      legacy('a.md', {1: 'one'});
      readHistoryManifest(root.path, 'a.md');
      // The old files again, as a crash between the log and the delete
      // would leave them: the log stands, the leftovers go.
      legacy('a.md', {1: 'stale'});
      expect(importLegacyHistory(root.path, 'a.md'), 0);
      expect(version('a.md', 1), 'one');
      expect(
        File(p.join(root.path, historyFolderName, 'a.md.v1')).existsSync(),
        isFalse,
      );
    });

    test('a move that loses the race to another writes nothing over it', () {
      // The upkeep and a save move the same history at once: the other one
      // finishes — its whole log written, the old files deleted — between
      // this one listing v2 and reading it.
      legacy('a.md', {1: 'one', 2: 'two'});
      final manifest = IOOverrides.runZoned(
        () => readHistoryManifest(root.path, 'a.md'),
        createFile: (path) {
          final real = Zone.root.run(() => File(path));
          return path.endsWith('.v2')
              ? _RacedFile(real, () => importLegacyHistory(root.path, 'a.md'))
              : real;
        },
      );
      expect(manifest.versions.map((v) => v.number), [1, 2]);
      expect(version('a.md', 2), 'two');
    });

    test('deleting an old history does not move it in first', () {
      legacy('a.md', {1: 'one', 2: 'two'});
      expect(deleteNoteHistory(root.path, 'a.md'), 2);
      expect(listObjects(root.path), isEmpty);
      expect(
        Directory(p.join(root.path, historyFolderName))
            .listSync()
            .where((e) => p.basename(e.path) != historyLocksFolderName),
        isEmpty,
      );
    });
  });
}

/// A version file whose first read lets another move of the same history run
/// to its end first: by then the file is gone, as the other move deleted it.
final class _RacedFile implements File {
  new(this._real, this._other);

  final File _real;
  final int Function() _other;
  static bool _raced = false;

  @override
  String get path => _real.path;

  @override
  Directory get parent => _real.parent;

  @override
  bool existsSync() => _real.existsSync();

  @override
  void deleteSync({bool recursive = false}) =>
      _real.deleteSync(recursive: recursive);

  @override
  FileStat statSync() => _real.statSync();

  @override
  Uint8List readAsBytesSync() {
    if (!_raced) {
      _raced = true;
      _other();
    }
    return _real.readAsBytesSync();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
