// The upkeep's guards (#1148 review): one note's failure stops no other, a
// log moved while the walk ran is never taken for unnamed, two packers
// never make a loop, and a library cleared of old history is not scanned
// for it again.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/history/history_folders.dart';
import 'package:niman/src/history/history_objects.dart';
import 'package:niman/src/history/history_store.dart';
import 'package:niman/src/history/history_upkeep.dart';
import 'package:niman/src/history/snapshot_policy.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  // The logs' times: any fixed day will do.
  final t0 = DateTime(2026, 10, 21, 9);
  // An upkeep past the grace. The grace is read on the objects' file
  // times, which the store stamps with the real clock, so this one
  // comes from that clock too: a day after [t0] was past the grace
  // only until the morning of that day.
  final later = DateTime.now().add(const Duration(days: 1));

  setUp(() async {
    root = await Directory.current.createTemp('niman_upkeep_guards_');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  void write(String rel, String text) => File(p.join(root.path, rel))
    ..createSync(recursive: true)
    ..writeAsStringSync(text);

  String sha(String text) => sha256.convert(utf8.encode(text)).toString();

  String textAt(int n, [String tag = '']) => [
    for (var line = 0; line < 300; line++)
      if (line == (n * 37) % 300)
        'Line $line, edited in session $n.$tag'
      else
        'Line $line of a long note, the same in every version.$tag',
  ].join('\n');

  /// Keeps [sessions] versions of [rel], one a session.
  void sessions(String rel, int sessions, {String tag = ''}) {
    write(rel, textAt(0, tag));
    for (var n = 1; n <= sessions; n++) {
      snapshotBeforeWrite(
        root.path,
        rel,
        SnapshotRequest(
          limit: 100,
          interval: const Duration(minutes: 5),
          now: t0.add(Duration(hours: n)),
          sessionStart: true,
        ),
      );
      write(rel, textAt(n, tag));
    }
  }

  Set<String> shasOf(String rel) => {
    for (final v in readHistoryManifest(root.path, rel).versions) v.sha256,
  };

  /// An object no log names, old enough to be collected.
  File orphan(String text) {
    writeObject(root.path, sha(text), utf8.encode(text));
    return File(historyObjectPath(root.path, sha(text)))
      ..setLastModifiedSync(DateTime.now().subtract(const Duration(days: 2)));
  }

  group('one failure does not stop the pass', () {
    test('a note that cannot be done leaves the others packed', () {
      sessions('a.md', 4);
      sessions('b.md', 4, tag: ' (b)');
      final stray = orphan('stray content');
      final outcome = maintainHistory(
        root.path,
        now: later,
        beforeNote: (rel) {
          if (rel == 'a.md') throw const FileSystemException('denied');
        },
      );
      expect(outcome.failed, 1);
      expect(outcome.failure, contains('a.md'));
      expect(outcome.packed, greaterThan(0), reason: 'b.md was packed');
      expect(outcome.collected, 1, reason: 'and the sweep ran');
      expect(stray.existsSync(), isFalse);
    });

    test('an object another pass collected first is not a failure', () {
      sessions('a.md', 2);
      final first = orphan('first stray');
      final second = orphan('second stray');
      final outcome = maintainHistory(
        root.path,
        now: later,
        beforeCollect: (file) {
          // Another upkeep collects it between the listing and the stat.
          if (p.equals(file.path, first.path) && first.existsSync()) {
            first.deleteSync();
          }
        },
      );
      expect(outcome.failed, 0);
      expect(second.existsSync(), isFalse);
      // The one taken away is not counted as ours.
      expect(outcome.collected, 1);
    });
  });

  test('a log moved from a folder not yet walked is never collected', () {
    sessions('A/a.md', 3);
    sessions('Z/b.md', 3, tag: ' (z)');
    final a = shasOf('A/a.md');
    final b = shasOf('Z/b.md');
    var moved = false;
    final named = namedObjects(
      root.path,
      afterFolder: (dir) {
        if (moved) return;
        // Whichever of the two folders the walk reaches first, the other's
        // note moves into it: in neither listing, and no read fails.
        final name = p.basename(dir.path);
        if (name == 'A') {
          moved = true;
          moveNoteHistory(root.path, 'Z/b.md', 'A/b.md');
        } else if (name == 'Z') {
          moved = true;
          moveNoteHistory(root.path, 'A/a.md', 'Z/a.md');
        }
      },
    );
    expect(moved, isTrue);
    expect(named, isNotNull);
    expect(named, containsAll(a));
    expect(named, containsAll(b));
  });

  test('a folder moved while the walk ran is never collected either', () {
    sessions('A/a.md', 3);
    sessions('Z/Deep/b.md', 3, tag: ' (z)');
    final b = shasOf('Z/Deep/b.md');
    var moved = false;
    final named = namedObjects(
      root.path,
      afterFolder: (dir) {
        if (moved || p.basename(dir.path) != 'A') return;
        moved = true;
        moveFolderHistory(root.path, 'Z/Deep', 'A/Deep');
      },
    );
    expect(named, isNotNull);
    expect(named, containsAll(b));
  });

  test('a move that never settles collects nothing', () {
    sessions('A/a.md', 3);
    sessions('Z/b.md', 3, tag: ' (z)');
    final stray = orphan('stray content');
    var flip = false;
    final named = namedObjects(
      root.path,
      afterListing: () {
        // A note moves back and forth at every listing.
        flip = !flip;
        if (flip) {
          moveNoteHistory(root.path, 'Z/b.md', 'A/b.md');
        } else {
          moveNoteHistory(root.path, 'A/b.md', 'Z/b.md');
        }
      },
    );
    expect(named, isNull);
    expect(stray.existsSync(), isTrue);
  });

  test('two packers cannot make two objects deltas of each other', () {
    final first = sha(textAt(0));
    final second = sha(textAt(1));
    writeObject(root.path, first, utf8.encode(textAt(0)));
    writeObject(root.path, second, utf8.encode(textAt(1)));
    final stored = storeAsDelta(
      root.path,
      first,
      second,
      // The other packer, in its own isolate, stores the second as a delta
      // of the first between this one's check and its write.
      beforeLock: () => expect(storeAsDelta(root.path, second, first), isTrue),
    );
    expect(stored, isFalse, reason: 'the base now leads back');
    expect(utf8.decode(readObject(root.path, first)!), textAt(0));
    expect(utf8.decode(readObject(root.path, second)!), textAt(1));
  });

  group('old history is looked for until the library is clear of it', () {
    File legacyFile(String rel) =>
        File(p.join(root.path, historyFolderName, '$rel.v1'))
          ..createSync(recursive: true)
          ..writeAsStringSync('old $rel');

    File marker() =>
        File(p.join(root.path, historyFolderName, historyLegacyDoneFileName));

    test('moved in, then recorded as done', () {
      legacyFile('a.md');
      expect(maintainHistory(root.path, now: later).migrated, 1);
      expect(marker().existsSync(), isTrue);
    });

    test('a library with none is recorded too, and not scanned again', () {
      sessions('a.md', 2);
      maintainHistory(root.path, now: later);
      expect(marker().existsSync(), isTrue);
      // Old files that appear after (a copy from an older version) are
      // left alone until the marker goes: the walk of every open is what
      // this spares a big library.
      legacyFile('b.md');
      expect(maintainHistory(root.path, now: later).migrated, 0);
      marker().deleteSync();
      expect(maintainHistory(root.path, now: later).migrated, 1);
    });

    test('a read of a note without a log lists nothing once recorded', () {
      sessions('a.md', 2);
      maintainHistory(root.path, now: later);
      legacyFile('b.md');
      // Recorded as done, so b.md's files are not even looked for.
      expect(readHistoryManifest(root.path, 'b.md').versions, isEmpty);
      marker().deleteSync();
      expect(readHistoryManifest(root.path, 'b.md').versions, hasLength(1));
    });

    test('the objects and locks folders are not taken for notes', () {
      sessions('a.md', 2);
      File(p.join(root.path, historyFolderName, '.objects', 'zz', 'x.md.v1'))
        ..createSync(recursive: true)
        ..writeAsStringSync('not a note');
      expect(maintainHistory(root.path, now: later).migrated, 0);
    });
  });
}
