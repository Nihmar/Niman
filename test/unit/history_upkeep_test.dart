// The history's upkeep (#1148): packing never changes what a version reads,
// keeps every chain short, and the collection takes only what no log names.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_objects.dart';
import 'package:niman/src/history/history_store.dart';
import 'package:niman/src/history/history_upkeep.dart';
import 'package:niman/src/history/snapshot_policy.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  final t0 = DateTime(2026, 10, 21, 9);
  final later = t0.add(const Duration(days: 1));

  setUp(() async {
    root = await Directory.current.createTemp('niman_upkeep_');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  void write(String rel, String text) => File(p.join(root.path, rel))
    ..createSync(recursive: true)
    ..writeAsStringSync(text);

  String sha(String text) => sha256.convert(utf8.encode(text)).toString();

  /// The note's text after [n] sessions: a long note, one line changed a
  /// session.
  String textAt(int n) => [
    for (var line = 0; line < 300; line++)
      if (line == (n * 37) % 300)
        'Line $line, edited in session $n.'
      else
        'Line $line of a long note, the same in every version.',
  ].join('\n');

  /// Keeps [sessions] versions of [rel], one a session.
  void sessions(String rel, int sessions, {int limit = 100}) {
    write(rel, textAt(0));
    for (var n = 1; n <= sessions; n++) {
      snapshotBeforeWrite(
        root.path,
        rel,
        SnapshotRequest(
          limit: limit,
          interval: const Duration(minutes: 5),
          now: t0.add(Duration(hours: n)),
          sessionStart: true,
        ),
      );
      write(rel, textAt(n));
    }
  }

  test('a packed version reads back byte for byte', () {
    sessions('a.md', 40);
    final outcome = maintainHistory(root.path, now: later);
    expect(outcome.packed, greaterThan(30));
    final manifest = readHistoryManifest(root.path, 'a.md');
    expect(manifest.versions, hasLength(40));
    for (final (i, v) in manifest.versions.indexed) {
      expect(
        utf8.decode(readHistoryVersion(root.path, 'a.md', v.number)!),
        textAt(i),
        reason: 'v${v.number}',
      );
    }
  });

  test('no chain is longer than the bound, and the newest is whole', () {
    sessions('a.md', 40);
    maintainHistory(root.path, now: later);
    final versions = readHistoryManifest(root.path, 'a.md').versions;
    for (final v in versions) {
      expect(chainDepth(root.path, v.sha256), lessThanOrEqualTo(maxDeltaChain));
    }
    expect(chainDepth(root.path, versions.last.sha256), 0);
    expect(isFastWhole(root.path, versions.last.sha256), isFalse);
  });

  test('packing again after more sessions keeps every version', () {
    sessions('a.md', 10);
    maintainHistory(root.path, now: later);
    for (var n = 11; n <= 30; n++) {
      snapshotBeforeWrite(
        root.path,
        'a.md',
        SnapshotRequest(
          limit: 100,
          interval: const Duration(minutes: 5),
          now: t0.add(Duration(hours: n)),
          sessionStart: true,
        ),
      );
      write('a.md', textAt(n));
      if (n.isEven) maintainHistory(root.path, now: later);
    }
    final versions = readHistoryManifest(root.path, 'a.md').versions;
    expect(versions, hasLength(30));
    for (final (i, v) in versions.indexed) {
      expect(
        utf8.decode(readHistoryVersion(root.path, 'a.md', v.number)!),
        textAt(i),
      );
      expect(chainDepth(root.path, v.sha256), lessThanOrEqualTo(15));
    }
  });

  test('the collection takes what no log names, past the grace', () {
    sessions('a.md', 3, limit: 2);
    final rotatedOut = sha(textAt(0));
    expect(hasObject(root.path, rotatedOut), isTrue);
    // Fresh: within the grace, a snapshot may be about to name it.
    var outcome = maintainHistory(root.path);
    expect(outcome.collected, 0);
    expect(hasObject(root.path, rotatedOut), isTrue);
    outcome = maintainHistory(root.path, now: later);
    expect(outcome.collected, 1);
    expect(hasObject(root.path, rotatedOut), isFalse);
    for (final v in readHistoryManifest(root.path, 'a.md').versions) {
      expect(readHistoryVersion(root.path, 'a.md', v.number), isNotNull);
    }
  });

  test("a deleted note's objects go, a shared one stays", () {
    write('a.md', 'kept by both');
    write('b.md', 'kept by both');
    for (final rel in ['a.md', 'b.md']) {
      snapshotBeforeWrite(
        root.path,
        rel,
        SnapshotRequest(
          limit: 10,
          interval: const Duration(minutes: 5),
          now: t0,
          forced: HistoryReason.restore,
        ),
      );
    }
    write('a.md', 'only a');
    snapshotBeforeWrite(
      root.path,
      'a.md',
      SnapshotRequest(
        limit: 10,
        interval: const Duration(minutes: 5),
        now: t0,
        forced: HistoryReason.restore,
      ),
    );
    deleteNoteHistory(root.path, 'a.md');
    maintainHistory(root.path, now: later);
    expect(hasObject(root.path, sha('only a')), isFalse);
    expect(hasObject(root.path, sha('kept by both')), isTrue);
    expect(
      utf8.decode(readHistoryVersion(root.path, 'b.md', 1)!),
      'kept by both',
    );
  });

  test("a delta's base stays while the delta is named", () {
    sessions('a.md', 5);
    maintainHistory(root.path, now: later);
    final versions = readHistoryManifest(root.path, 'a.md').versions;
    final oldest = versions.first;
    // Every version but the oldest rotates out of the log: the oldest is a
    // delta whose chain runs through all of them.
    expect(deltaBaseOf(root.path, oldest.sha256), isNotNull);
    pinHistoryVersion(root.path, 'a.md', 'keep', oldest.number, limit: 0);
    expect(
      readHistoryManifest(root.path, 'a.md').versions.map((v) => v.number),
      [oldest.number],
    );
    maintainHistory(root.path, now: later);
    expect(
      utf8.decode(readHistoryVersion(root.path, 'a.md', oldest.number)!),
      textAt(0),
    );
  });

  test('an old object kept again is not collected before the log names it', () {
    // The collection's race: it lists what the logs name, a snapshot keeps
    // content an object already holds, and the object was old. Writing it
    // again marks it used, and the grace keeps it until the log line lands.
    final text = textAt(3);
    final object = File(historyObjectPath(root.path, sha(text)));
    writeObject(root.path, sha(text), utf8.encode(text));
    object.setLastModifiedSync(
      DateTime.now().subtract(const Duration(days: 2)),
    );
    writeObject(root.path, sha(text), utf8.encode(text));
    expect(maintainHistory(root.path).collected, 0);
    expect(object.existsSync(), isTrue);
  });

  test('a note renamed while the upkeep lists the logs keeps its objects', () {
    sessions('a.md', 3);
    final shas = {
      for (final v in readHistoryManifest(root.path, 'a.md').versions) v.sha256,
    };
    var moved = false;
    final named = namedObjects(
      root.path,
      afterListing: () {
        if (moved) return;
        moved = true;
        moveNoteHistory(root.path, 'a.md', 'b.md');
      },
    );
    expect(named, containsAll(shas));
    maintainHistory(root.path, now: later);
    for (final v in readHistoryManifest(root.path, 'b.md').versions) {
      expect(readHistoryVersion(root.path, 'b.md', v.number), isNotNull);
    }
  });

  test('a delta that would make a loop is refused', () {
    write('a.md', textAt(0));
    final first = sha(textAt(0));
    final second = sha(textAt(1));
    writeObject(root.path, first, utf8.encode(textAt(0)));
    writeObject(root.path, second, utf8.encode(textAt(1)));
    expect(storeAsDelta(root.path, first, second), isTrue);
    expect(storeAsDelta(root.path, second, first), isFalse);
    expect(utf8.decode(readObject(root.path, first)!), textAt(0));
    expect(utf8.decode(readObject(root.path, second)!), textAt(1));
  });

  test('every old history in the library moves in', () {
    for (final rel in ['a.md', 'Dir/b.md']) {
      File(p.join(root.path, historyFolderName, '$rel.v1'))
        ..createSync(recursive: true)
        ..writeAsStringSync('old $rel');
    }
    final outcome = maintainHistory(root.path, now: later);
    expect(outcome.migrated, 2);
    expect(
      utf8.decode(readHistoryVersion(root.path, 'Dir/b.md', 1)!),
      'old Dir/b.md',
    );
  });
}
