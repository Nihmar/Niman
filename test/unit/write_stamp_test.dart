// The stamp a save stores is the one of the file it wrote (#1055).
//
// On Android's FUSE storage a `stat` of the path a rename just replaced can
// still answer the attributes of the file that went, from its lookup cache.
// A save that stored that stamp read its own next write as another
// program's: every second save took an `external` version and said
// "Another program changed this note". The stamp is taken from the temp
// file, before the rename, so it is the new file's (#1104 follow-up).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/library/note_write_stream.dart';
import 'package:niman/src/library/note_writer.dart';
import 'package:path/path.dart' as p;

/// The attributes a path's lookup cache still answers after a rename.
final class _StaleStat {
  final Map<String, FileStat> _once = {};

  /// What the target path answered before it was replaced.
  void remember(String path, FileStat stat) => _once[path] = stat;

  /// The stale answer for [path], once; the real file after.
  FileStat? take(String path) => _once.remove(path);
}

/// A [File] over the real one whose **target** path answers the replaced
/// file's attributes once after a rename, as Android's FUSE does.
final class _FuseStaleFile implements File {
  new(this._real, this._stale);

  final File _real;
  final _StaleStat _stale;

  @override
  String get path => _real.path;

  @override
  Directory get parent => _real.parent;

  @override
  bool existsSync() => _real.existsSync();

  @override
  FileStat statSync() => _stale.take(path) ?? _real.statSync();

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) async {
    await _real.writeAsBytes(bytes, mode: mode, flush: flush);
    return this;
  }

  @override
  IOSink openWrite({
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
  }) => _real.openWrite(mode: mode, encoding: encoding);

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) =>
      _real.open(mode: mode);

  @override
  Future<File> rename(String newPath) {
    // Before the rename: what the target's path answers now, and what a
    // lookup cache may keep answering right after the rename.
    _stale.remember(newPath, Zone.root.run(() => File(newPath).statSync()));
    return _real.rename(newPath);
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      _real.delete(recursive: recursive);

  @override
  void deleteSync({bool recursive = false}) =>
      _real.deleteSync(recursive: recursive);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('_FuseStaleFile.${invocation.memberName}');
}

void main() {
  late Directory root;
  late _StaleStat stale;
  late String target;

  /// Runs [body] with every `File` under the looking-glass that answers the
  /// replaced file's attributes once after a rename.
  Future<T> onFuse<T>(Future<T> Function() body) => IOOverrides.runZoned(
    body,
    createFile: (path) =>
        _FuseStaleFile(Zone.root.run(() => File(path)), stale),
  );

  setUp(() {
    root = Directory.systemTemp.createTempSync('niman_stamp');
    stale = _StaleStat();
    target = p.join(root.path, 'a.md');
    File(target).writeAsStringSync('the good copy');
  });
  tearDown(() => root.deleteSync(recursive: true));

  Future<void> expectFreshStamp(DateTime modified) async {
    final real = File(target).statSync();
    expect(
      modified.millisecondsSinceEpoch,
      real.modified.millisecondsSinceEpoch,
      reason: 'the stamp must be the written file, not the replaced one',
    );
  }

  test('the joined write stamps the file it wrote', () async {
    final result = await onFuse(
      () => writeNoteFile(target, 'the new copy', root: root.path, rel: 'a.md'),
    );
    await expectFreshStamp(result.modified);
    expect(File(target).readAsStringSync(), 'the new copy');
  });

  test('the streaming write stamps the file it wrote', () async {
    final result = await onFuse(
      () => saveNoteStream(
        root: root.path,
        rel: 'a.md',
        produce: (index) async =>
            index == 0 ? Uint8List.fromList(utf8.encode('one\ntwo\n')) : null,
        spawnWriter: (spawn) async {
          runNoteStreamWriter(spawn);
          return null;
        },
      ),
    );
    await expectFreshStamp(result!.modified);
    expect(File(target).readAsStringSync(), 'one\ntwo\n');
  });

  group('a save after the app wrote the note itself', () {
    late NoteOps ops;

    setUp(() async {
      final db = IndexDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      ops = NoteOps(
        root: root.path,
        db: db,
        indexer: Indexer(db),
        config: LibraryConfigRepo(root.path),
      );
    });

    tearDown(() => ops.writer.indexed);

    Future<void> expectNoExternal(NoteWriteResult written) async {
      final saved = await ops.saveNote(
        'a.md',
        'mine, edited',
        editSession: 1,
        expected: DiskStamp(size: written.bytes, modified: written.modified),
      );
      expect(saved!.keptExternal, isFalse);
      final versions = (await ops.noteHistory('a.md')).versions;
      expect(
        versions.where((v) => v.reason == HistoryReason.external),
        isEmpty,
        reason: "the app's own write must not be read as a stranger's",
      );
    }

    test("is not another program's: the joined write", () async {
      final written = await onFuse(
        () =>
            writeNoteFile(target, 'mine, saved', root: root.path, rel: 'a.md'),
      );
      await expectNoExternal(written);
    });

    test("is not another program's: the streaming write", () async {
      final written = await onFuse(
        () => saveNoteStream(
          root: root.path,
          rel: 'a.md',
          produce: (index) async => index == 0
              ? Uint8List.fromList(utf8.encode('mine, saved'))
              : null,
          spawnWriter: (spawn) async {
            runNoteStreamWriter(spawn);
            return null;
          },
        ),
      );
      await expectNoExternal(written!);
    });
  });
}
