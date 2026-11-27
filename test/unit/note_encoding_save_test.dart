// A UTF-16 or UTF-32 note goes through the real save pipeline and comes out
// in the encoding it had, a one-character edit changing one character of the
// file (#1332).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/library/note_write_stream.dart';
import 'package:niman/src/markdown/note_encoding.dart';
import 'package:niman/src/markdown/note_load.dart';
import 'package:niman/src/ui/note_save_pipeline.dart';
import 'package:path/path.dart' as p;

import 'note_encoding_test.dart' show fileOf;

const List<NoteEncoding> _wide = [
  NoteEncoding.utf16le,
  NoteEncoding.utf16be,
  NoteEncoding.utf32le,
  NoteEncoding.utf32be,
];

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('niman_enc_save'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<List<int>> editAndSave(
    List<int> original, {
    required String after,
    required String typed,
    required bool streaming,
  }) async {
    final file = File(p.join(dir.path, 'note.md'))..writeAsBytesSync(original);
    final loaded = loadNoteSync(file.path) as LoadedNote;
    final buffer = loaded.buffer;
    buffer.insert(buffer.text.indexOf(after) + after.length, typed);
    final pipeline = NoteSavePipeline(
      notePath: () => file.path,
      ready: () => true,
      text: () => buffer.text,
      buffer: () => buffer,
      references: () => null,
      framing: () => loaded.framing,
      saveNote: () => null,
      writeNote: () => null,
      saveNoteStream: () => streaming
          ? (
              path,
              content, {
              required editSession,
              references,
              expected,
            }) async {
              await saveNoteStream(
                root: dir.path,
                rel: p.basename(path),
                produce: content,
              );
              return null;
            }
          : null,
      onSaved: (_, _) {},
      onSettled: () {},
    );
    addTearDown(pipeline.cancel);
    pipeline
      ..newSession()
      ..edited();
    await pipeline.save();
    return file.readAsBytesSync();
  }

  const samples = {
    'ASCII': ('# Title\nsome words\n', 'some'),
    'Cyrillic': ('# Заголовок\nнемного слов\n', 'немного'),
    'CJK': ('# 日本語の題\nいくつかの言葉\n', 'いくつ'),
  };

  for (final streaming in [true, false]) {
    for (final encoding in _wide) {
      for (final MapEntry(key: name, value: (text, after)) in samples.entries) {
        test('${encoding.name} $name, ${streaming ? 'streamed' : 'joined'}: '
            'one character of the file changes', () async {
          final saved = await editAndSave(
            fileOf(encoding, text),
            after: after,
            typed: 'X',
            streaming: streaming,
          );
          expect(
            saved,
            fileOf(encoding, text.replaceFirst(after, '${after}X')),
          );
        });
      }
    }
  }

  test('a UTF-16 note with CRLF lines keeps both', () async {
    const text = '# Заголовок\r\nслова\r\n';
    final saved = await editAndSave(
      fileOf(NoteEncoding.utf16le, text),
      after: 'слова',
      typed: '!',
      streaming: true,
    );
    expect(
      saved,
      fileOf(NoteEncoding.utf16le, text.replaceFirst('слова', 'слова!')),
    );
  });

  test('a UTF-8 note is untouched by all of this', () async {
    final saved = await editAndSave(
      utf8.encode('\u{FEFF}café\r\n'),
      after: 'caf',
      typed: 'X',
      streaming: true,
    );
    expect(Uint8List.fromList(saved), utf8.encode('\u{FEFF}cafXé\r\n'));
  });
}
