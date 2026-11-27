// A UTF-16 or UTF-32 note saved through the library keeps its history entry and
// its index entry, whichever way the editor hands it over (#1332): the whole
// text of an emptied note used to bypass the library writer, and so history
// and the index.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/markdown/note_encoding.dart';
import 'package:niman/src/markdown/note_load.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/ui/note_save_pipeline.dart';
import 'package:path/path.dart' as p;

import 'note_encoding_test.dart' show fileOf;

void main() {
  late Directory root;
  late NoteOps ops;
  late Indexer indexer;

  setUp(() async {
    root = await Directory.current.createTemp('niman_enc_lib_');
    final db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    indexer = Indexer(db);
    ops = NoteOps(
      root: root.path,
      db: db,
      indexer: indexer,
      config: LibraryConfigRepo(root.path),
    );
  });

  tearDown(() async {
    await ops.writer.indexed;
    await root.delete(recursive: true);
  });

  /// Opens the UTF-16 note holding [text], empties it, and saves it through
  /// the library as the shell wires it. [whole] hands the text over joined
  /// (no buffer to slice), as an emptied note is.
  Future<File> emptied(NoteEncoding encoding, {required bool whole}) async {
    final file = File(p.join(root.path, 'a.md'))
      ..writeAsBytesSync(fileOf(encoding, '# Заголовок\nслова\n'));
    await indexer.applyEvents(root.path, [file.path]);
    await ops.writer.indexed;
    final loaded = loadNoteSync(file.path) as LoadedNote;
    final buffer = loaded.buffer..replaceRange(0, loaded.buffer.length, '');
    var stamp = loaded.stamp;
    final pipeline = NoteSavePipeline(
      notePath: () => file.path,
      ready: () => true,
      text: () => buffer.text,
      buffer: () => whole ? null : buffer,
      references: () => null,
      framing: () => loaded.framing,
      saveNote: () =>
          (path, content, {required editSession, expected}) => ops.saveNote(
            p.relative(path, from: root.path),
            content,
            editSession: editSession,
            expected: expected,
          ),
      writeNote: () => null,
      saveNoteStream: () =>
          (path, content, {required editSession, references, expected}) =>
              ops.saveNoteStream(
                p.relative(path, from: root.path),
                content,
                editSession: editSession,
                references: references,
                expected: expected,
              ),
      onSaved: (_, saved) => stamp = saved ?? stamp,
      onSettled: () {},
      diskStamp: () => stamp,
    );
    addTearDown(pipeline.cancel);
    pipeline
      ..newSession()
      ..edited();
    await pipeline.save();
    await ops.writer.indexed;
    return file;
  }

  for (final encoding in [NoteEncoding.utf16le, NoteEncoding.utf32be]) {
    for (final whole in [true, false]) {
      test('${encoding.name} emptied, ${whole ? 'whole text' : 'slices'}: '
          'the file, its history and its index entry', () async {
        final file = await emptied(encoding, whole: whole);

        // Nothing but the byte order mark is left, in the note's encoding.
        expect(file.readAsBytesSync(), fileOf(encoding, ''));
        // The text it replaced is kept as a version.
        final versions = (await ops.noteHistory('a.md')).versions;
        expect(versions, hasLength(1));
        expect(
          versions.single.size,
          fileOf(encoding, '# Заголовок\nслова\n').length,
        );
        // And the index follows the file.
        final row = await indexer.dao.find('a.md');
        expect(row!.size, fileOf(encoding, '').length);
      });
    }
  }

  test('an empty buffer is what the test means by emptied', () {
    expect(SourceBuffer.fromText('').text, '');
  });
}
