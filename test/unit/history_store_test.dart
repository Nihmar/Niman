import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_store.dart';
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
    expect(
      File(historyVersionPath(root.path, 'Notes/a.md', 1)).existsSync(),
      isTrue,
    );
    final manifest = readHistoryManifest(root.path, 'Notes/a.md');
    expect(manifest.versions.single.reason, HistoryReason.restore);
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

  test('a lost manifest is rebuilt from the version files', () {
    write('a.md', 'one');
    save('a.md', 'two', forced());
    save('a.md', 'three', forced());
    File(historyManifestPath(root.path, 'a.md')).deleteSync();
    final manifest = readHistoryManifest(root.path, 'a.md');
    expect(manifest.versions.map((v) => v.number), [1, 2]);
    expect(manifest.versions.first.reason, HistoryReason.unknown);
    // Numbering carries on after the rebuilt versions.
    expect(save('a.md', 'four', forced()).version!.number, 3);
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

  test('deleting history removes the files and empty folders', () {
    write('Dir/n.md', 'one');
    save('Dir/n.md', 'two', forced());
    expect(deleteNoteHistory(root.path, 'Dir/n.md'), 1);
    expect(
      Directory(p.join(root.path, historyFolderName, 'Dir')).existsSync(),
      isFalse,
    );
  });
}
