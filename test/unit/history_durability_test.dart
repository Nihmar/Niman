import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/history/history_legacy.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_store.dart';
import 'package:niman/src/history/history_upkeep.dart';
import 'package:niman/src/history/snapshot_policy.dart';
import 'package:path/path.dart' as p;

/// What the history flushes (#1148 review): an object the upkeep replaces,
/// and the objects the old history's move writes before it deletes the old
/// files, are flushed; a save's new object is not.
void main() {
  late Directory root;
  final t0 = DateTime(2026, 9, 15, 10);

  setUp(() async {
    root = await Directory.current.createTemp('niman_history_flush_');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  String prose(int lines, [String extra = '']) => [
    for (var i = 0; i < lines; i++)
      'Line $i of a note that is long enough for a delta to win.',
    extra,
  ].join('\n');

  SnapshotRequest forced() => SnapshotRequest(
    limit: 10,
    interval: const Duration(minutes: 5),
    now: t0,
    forced: HistoryReason.restore,
  );

  void save(String rel, String text) {
    final file = File(p.join(root.path, rel));
    if (file.existsSync()) snapshotBeforeWrite(root.path, rel, forced());
    file.writeAsStringSync(text);
  }

  /// Runs [body] with every file recorded into the returned events.
  List<String> record(void Function() body) {
    final events = <String>[];
    IOOverrides.runZoned(
      body,
      createFile: (path) =>
          _RecordedFile(Zone.root.run(() => File(path)), events),
    );
    return events;
  }

  test('a save does not flush the object it keeps', () {
    save('a.md', prose(300));
    final events = record(() => save('a.md', prose(300, 'edited')));
    expect(events.where((e) => e.startsWith('write ')), isNotEmpty);
    expect(events.where((e) => e.endsWith('flush=true')), isEmpty);
  });

  test('the packer flushes each object it replaces before the rename', () {
    save('a.md', prose(300));
    save('a.md', prose(300, 'second'));
    save('a.md', prose(300, 'third'));
    final events = record(() {
      final outcome = packNoteHistory(root.path, 'a.md');
      expect(outcome.packed, greaterThan(0));
    });
    final writes = [
      for (var i = 0; i < events.length; i++)
        if (events[i].startsWith('write .')) i,
    ];
    // A delta for each older version, and the newest compressed hard.
    expect(writes.length, greaterThanOrEqualTo(2));
    for (final at in writes) {
      expect(events[at], endsWith('flush=true'));
      expect(events[at + 1], startsWith('rename .'));
    }
  });

  test('the old history is flushed in before its files are deleted', () {
    for (final n in [1, 2]) {
      File(p.join(root.path, historyFolderName, 'a.md.v$n'))
        ..createSync(recursive: true)
        ..writeAsStringSync('version $n');
    }
    File(legacyManifestPath(root.path, 'a.md')).writeAsStringSync(
      HistoryManifest(
        versions: [
          for (final n in [1, 2])
            HistoryVersion(
              number: n,
              savedAt: t0,
              reason: HistoryReason.session,
              size: 'version $n'.length,
              sha256: sha256.convert('version $n'.codeUnits).toString(),
            ),
        ],
      ).encode(),
    );
    final events = record(() => importLegacyHistory(root.path, 'a.md'));
    final flushed = [
      for (var i = 0; i < events.length; i++)
        if (events[i].endsWith('flush=true')) i,
    ];
    final deleted = [
      for (var i = 0; i < events.length; i++)
        if (events[i].startsWith('delete ') && events[i].contains('.v')) i,
    ];
    expect(flushed.length, 2, reason: events.join('\n'));
    expect(deleted, isNotEmpty);
    expect(flushed.last, lessThan(deleted.first), reason: events.join('\n'));
  });
}

/// A file that tells what is done to it: the writes with their flush flag,
/// the renames and the deletes. Everything else goes to the real file.
final class _RecordedFile implements File {
  new(this._real, this._events);

  final File _real;
  final List<String> _events;

  String get _name => p.basename(_real.path);

  @override
  String get path => _real.path;

  @override
  Directory get parent => _real.parent;

  @override
  bool existsSync() => _real.existsSync();

  @override
  FileStat statSync() => _real.statSync();

  @override
  int lengthSync() => _real.lengthSync();

  @override
  Uint8List readAsBytesSync() => _real.readAsBytesSync();

  @override
  String readAsStringSync({Encoding encoding = utf8}) =>
      _real.readAsStringSync(encoding: encoding);

  @override
  RandomAccessFile openSync({FileMode mode = FileMode.read}) =>
      _real.openSync(mode: mode);

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) {
    _events.add('write $_name flush=$flush');
    _real.writeAsBytesSync(bytes, mode: mode, flush: flush);
  }

  @override
  File renameSync(String newPath) {
    _events.add('rename $_name');
    return _real.renameSync(newPath);
  }

  @override
  void deleteSync({bool recursive = false}) {
    _events.add('delete $_name');
    _real.deleteSync(recursive: recursive);
  }

  @override
  void createSync({bool recursive = false, bool exclusive = false}) =>
      _real.createSync(recursive: recursive, exclusive: exclusive);

  @override
  void writeAsStringSync(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) => _real.writeAsStringSync(
    contents,
    mode: mode,
    encoding: encoding,
    flush: flush,
  );

  @override
  void setLastModifiedSync(DateTime time) => _real.setLastModifiedSync(time);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
