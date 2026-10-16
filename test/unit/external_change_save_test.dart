// A save that finds another program's version of the note on disk keeps it
// in the history before overwriting it (#1055): the editor tells the writer
// what it last saw of the file, and the writer compares.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late NoteOps ops;

  setUp(() async {
    root = await Directory.current.createTemp('niman_external_');
    final db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    ops = NoteOps(
      root: root.path,
      db: db,
      indexer: Indexer(db),
      config: LibraryConfigRepo(root.path),
    );
  });

  tearDown(() async {
    await ops.writer.indexed;
    await root.delete(recursive: true);
  });

  File note() => File(p.join(root.path, 'a.md'));

  Future<List<HistoryVersion>> versions() async =>
      (await ops.noteHistory('a.md')).versions;

  test(
    'the version another program wrote is kept before it is replaced',
    () async {
      final first = await ops.saveNote('a.md', 'mine, saved', editSession: 1);
      // Another program rewrites the file.
      note().writeAsStringSync('theirs, written outside, and longer');

      final second = await ops.saveNote(
        'a.md',
        'mine, edited',
        editSession: 1,
        expected: first!.stamp,
      );

      expect(second!.keptExternal, isTrue);
      expect(note().readAsStringSync(), 'mine, edited');
      final kept = (await versions()).where(
        (v) => v.reason == HistoryReason.external,
      );
      expect(kept, hasLength(1));
      expect(
        await ops.readNoteVersion('a.md', kept.single.number),
        'theirs, written outside, and longer',
      );
    },
  );

  test('a streamed save keeps it too', () async {
    final first = await ops.saveNote('a.md', 'mine, saved', editSession: 1);
    note().writeAsStringSync('theirs, streamed over');

    final second = await ops.saveNoteStream(
      'a.md',
      (index) async =>
          index == 0 ? Uint8List.fromList(utf8.encode('mine again')) : null,
      editSession: 1,
      expected: first!.stamp,
    );

    expect(second!.keptExternal, isTrue);
    final kept = (await versions()).singleWhere(
      (v) => v.reason == HistoryReason.external,
    );
    expect(
      await ops.readNoteVersion('a.md', kept.number),
      'theirs, streamed over',
    );
  });

  test("the editor's own last write is not another program's", () async {
    final first = await ops.saveNote('a.md', 'mine, saved', editSession: 1);
    final second = await ops.saveNote(
      'a.md',
      'mine, edited',
      editSession: 1,
      expected: first!.stamp,
    );
    expect(second!.keptExternal, isFalse);
    expect(
      (await versions()).where((v) => v.reason == HistoryReason.external),
      isEmpty,
    );
  });

  test('a save that expects nothing overwrites without a version', () async {
    await ops.saveNote('a.md', 'mine, saved', editSession: 1);
    note().writeAsStringSync('theirs, written outside, and longer');
    final saved = await ops.saveNote('a.md', 'mine, edited', editSession: 1);
    expect(saved!.keptExternal, isFalse);
    expect(
      (await versions()).where((v) => v.reason == HistoryReason.external),
      isEmpty,
      reason: 'this is the loss #1055 describes, when nothing is expected',
    );
  });
}
