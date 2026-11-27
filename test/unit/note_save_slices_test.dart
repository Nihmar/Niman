// The streaming save writes every line of the note (#1320): a slice cut short
// by its character limit leaves lines the next slice has to start with, and a
// note of long lines used to lose them silently.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/library/note_write_stream.dart';
import 'package:niman/src/markdown/line_ending.dart';
import 'package:niman/src/markdown/note_framing.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/ui/note_save_pipeline.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('niman_slices'));
  tearDown(() => dir.deleteSync(recursive: true));

  /// Saves [text] through the real pipeline and the real streaming writer,
  /// framed as [framing], and answers the file's bytes.
  Future<List<int>> save(
    String text, {
    NoteFraming framing = NoteFraming.plain,
  }) async {
    final file = File(p.join(dir.path, 'note.md'));
    final buffer = SourceBuffer.fromText(text);
    final pipeline = NoteSavePipeline(
      notePath: () => file.path,
      ready: () => true,
      text: () => buffer.text,
      buffer: () => buffer,
      references: () => null,
      framing: () => framing,
      saveNote: () => null,
      writeNote: () => null,
      saveNoteStream: () =>
          (path, content, {required editSession, references, expected}) async {
            await saveNoteStream(
              root: dir.path,
              rel: p.basename(path),
              produce: content,
            );
            return null;
          },
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

  List<int> expectedBytes(String text, NoteFraming framing) =>
      utf8.encode(framing.apply(text));

  test(
    'a line past the character limit does not take its neighbours',
    () async {
      final text =
          '# Title\n${'x' * (NoteSavePipeline.kSaveSliceChars + 200000)}'
          '\ntext one\ntext two\n';
      expect(await save(text), utf8.encode(text));
    },
  );

  test('a window of lines past the character limit is all there', () async {
    // 20 000 lines of 300 characters: the first slice stops short of its
    // 16 384 lines, at the 4 Mi characters.
    final text = [
      for (var i = 0; i < 20000; i++) ('$i ' * 60).padRight(300, '.'),
    ].join('\n');
    final saved = await save(text);
    expect(saved.length, utf8.encode(text).length);
    expect(saved, utf8.encode(text));
  });

  test('random line lengths, CRLF and a BOM: the file is the text', () async {
    for (final seed in [1, 2, 3]) {
      final random = Random(seed);
      final lines = <String>[];
      var chars = 0;
      // Past two character limits, so a slice is cut short more than once.
      while (chars < 2 * NoteSavePipeline.kSaveSliceChars + 5000) {
        final length = random.nextInt(10) == 0
            ? random.nextInt(60000)
            : random.nextInt(400);
        lines.add(String.fromCharCodes(List.filled(length, 97 + seed)));
        chars += length + 1;
      }
      final text = lines.join('\n');
      for (final framing in [
        NoteFraming.plain,
        const NoteFraming(lineEnding: LineEnding.crlf, bom: true),
      ]) {
        expect(
          await save(text, framing: framing),
          expectedBytes(text, framing),
          reason: 'seed $seed, ${framing.lineEnding}',
        );
      }
    }
  });
}
