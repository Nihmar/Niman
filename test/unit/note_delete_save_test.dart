// A note deleted with edits pending stays deleted (#1321): the editor's save
// used to create the file and its folders again, so the delete — or another
// program's — achieved nothing and the trash held a copy of a note that was
// on disk all along.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_gone.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/markdown/note_framing.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/ui/note_save_pipeline.dart';
import 'package:niman/src/ui/note_view_adapters.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late NoteOps ops;
  late UnsavedTracker tracker;

  setUp(() async {
    root = await Directory.current.createTemp('niman_delete_');
    final db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    ops = NoteOps(
      root: root.path,
      db: db,
      indexer: Indexer(db),
      config: LibraryConfigRepo(root.path),
    );
    tracker = UnsavedTracker();
  });

  tearDown(() async {
    tracker.dispose();
    await ops.writer.indexed;
    await root.delete(recursive: true);
  });

  /// The library's writer as the shell hands it to an editor
  /// (`noteSaverFor`).
  NoteSaver saver({required bool mustExist}) =>
      (path, content, {required editSession, expected}) => ops.saveNote(
        p.relative(path, from: root.path),
        content,
        editSession: editSession,
        expected: expected,
        mustExist: mustExist,
      );

  /// The same for a note handed over in slices.
  NoteStreamSaver streamSaver({required bool mustExist}) =>
      (path, content, {required editSession, references, expected}) =>
          ops.saveNoteStream(
            p.relative(path, from: root.path),
            content,
            editSession: editSession,
            references: references,
            expected: expected,
            mustExist: mustExist,
          );

  /// An editor over the note at library-relative [rel], as the shell builds
  /// one: it saves through the library, and is registered with [tracker].
  Future<({NoteSavePipeline pipeline, SourceBuffer buffer, String abs})> open(
    String rel,
    String text,
  ) async {
    final abs = p.join(root.path, rel);
    final folder = p.dirname(rel);
    if (folder != '.') {
      final _ = await ops.ensureFolder(p.posix.joinAll(p.split(folder)));
    }
    final first = await ops.saveNote(rel, text, editSession: 1);
    await ops.writer.indexed;
    final buffer = SourceBuffer.fromText(text);
    var stamp = first!.stamp;
    late final NoteSavePipeline pipeline;
    pipeline = NoteSavePipeline(
      notePath: () => abs,
      ready: () => true,
      text: () => buffer.text,
      buffer: () => buffer,
      references: () => null,
      framing: () => NoteFraming.plain,
      saveNote: () => saver(mustExist: true),
      createNote: () => saver(mustExist: false),
      writeNote: () => null,
      saveNoteStream: () => streamSaver(mustExist: true),
      createNoteStream: () => streamSaver(mustExist: false),
      onSaved: (_, saved) => stamp = saved,
      onSettled: () {},
      diskStamp: () => stamp,
      hold: tracker.hold,
    );
    addTearDown(pipeline.cancel);
    pipeline.newSession();
    tracker.register(
      UnsavedNoteAdapter(
        notePath: () => abs,
        loading: () => false,
        revision: () => pipeline.revision,
        lastSavedRevision: () => pipeline.lastSavedRevision,
        saveForClose: pipeline.saveForClose,
        bufferText: () => buffer.text,
        bufferHead: (max) => buffer.text.substring(0, max),
        discardWrites: pipeline.discard,
        restoreWrites: pipeline.undiscard,
        discarded: () => pipeline.discarded,
      ),
    );
    return (pipeline: pipeline, buffer: buffer, abs: abs);
  }

  test('a deleted note with edits is not written back', () async {
    final note = await open('a.md', 'one');
    note.buffer.replaceRange(0, 3, 'edited');
    note.pipeline.edited();

    await tracker.discardUnder(note.abs);
    await ops.delete('a.md');
    // The tab closes with the delete, and the debounce may fire after it.
    await note.pipeline.close();
    note.pipeline.saveInBackground();
    await pumpEventQueue();

    expect(File(note.abs).existsSync(), isFalse);
    expect(tracker.hasUnsaved, isFalse);
  });

  test('a deleted folder holding a note with edits stays deleted', () async {
    final note = await open(p.join('Docs', 'Deep', 'a.md'), 'one');
    note.buffer.replaceRange(0, 3, 'edited');
    note.pipeline.edited();

    await tracker.discardUnder(p.join(root.path, 'Docs'));
    await ops.delete('Docs');
    await note.pipeline.close();
    await pumpEventQueue();

    expect(Directory(p.join(root.path, 'Docs')).existsSync(), isFalse);
  });

  test('a delete that fails leaves the edits to be saved', () async {
    final note = await open('a.md', 'one');
    note.buffer.replaceRange(0, 3, 'edited');
    note.pipeline.edited();

    await tracker.discardUnder(note.abs);
    tracker.restoreUnder(note.abs);
    await pumpEventQueue();
    await note.pipeline.saveForClose();

    expect(File(note.abs).readAsStringSync(), 'edited');
  });

  test('a note another program deleted is not created again', () async {
    final note = await open('a.md', 'one');
    File(note.abs).deleteSync();
    note.buffer.replaceRange(0, 3, 'edited');
    note.pipeline.edited();

    await expectLater(note.pipeline.save(), throwsA(isA<NoteGoneException>()));

    expect(File(note.abs).existsSync(), isFalse);
    expect(note.pipeline.dirty, isTrue, reason: 'the text is kept');
    expect(note.pipeline.failure.value?.error, isA<NoteGoneException>());
  });

  test('saving it again creates the note afresh', () async {
    final note = await open('a.md', 'one');
    File(note.abs).deleteSync();
    note.buffer.replaceRange(0, 3, 'edited');
    note.pipeline.edited();
    await expectLater(note.pipeline.save(), throwsA(isA<NoteGoneException>()));

    note.pipeline.retry();
    await pumpEventQueue();
    await note.pipeline.saveForClose();

    expect(File(note.abs).readAsStringSync(), 'edited');
    expect(note.pipeline.failure.value, isNull);
  });

  group('the writer, asked to replace a note', () {
    Uint8List one(int index, String text) =>
        Uint8List.fromList(utf8.encode(text));

    test('throws for a joined save of a file that is gone', () async {
      await expectLater(
        ops.saveNote('gone.md', 'text', editSession: 1, mustExist: true),
        throwsA(isA<NoteGoneException>()),
      );
      expect(File(p.join(root.path, 'gone.md')).existsSync(), isFalse);
    });

    test('throws for a streamed save of a file that is gone', () async {
      await expectLater(
        ops.saveNoteStream(
          'Docs/gone.md',
          (index) async => index == 0 ? one(index, 'text') : null,
          editSession: 1,
          mustExist: true,
        ),
        throwsA(isA<NoteGoneException>()),
      );
      expect(Directory(p.join(root.path, 'Docs')).existsSync(), isFalse);
    });

    test('replaces a note that is there, joined or streamed', () async {
      await ops.saveNote('a.md', 'one', editSession: 1);
      await ops.saveNote('a.md', 'two', editSession: 1, mustExist: true);
      expect(File(p.join(root.path, 'a.md')).readAsStringSync(), 'two');
      await ops.saveNoteStream(
        'a.md',
        (index) async => index == 0 ? one(index, 'three') : null,
        editSession: 1,
        mustExist: true,
      );
      expect(File(p.join(root.path, 'a.md')).readAsStringSync(), 'three');
    });

    test('creates the note when it is not asked to replace one', () async {
      await ops.saveNote('new.md', 'text', editSession: 1);
      expect(File(p.join(root.path, 'new.md')).existsSync(), isTrue);
    });
  });
}
