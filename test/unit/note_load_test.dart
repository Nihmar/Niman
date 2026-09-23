// A note read and made ready off the UI isolate (`note_load.dart`): what
// comes back is the note as the editor holds it, and nothing about it was
// worked out on the isolate that asked.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/word_count.dart';
import 'package:niman/src/editor/word_count_index.dart';
import 'package:niman/src/markdown/note_load.dart';
import 'package:niman/src/preview/preview_work_failure.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('niman_note_load'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('a note comes back ready: its text, its buffer, its count', () async {
    final file = File(p.join(dir.path, 'note.md'))
      ..writeAsStringSync('# Title\r\n\r\nsome words here\rand more\n');
    final before = WordCount.linesCountedHere;
    final loaded = await loadNote(file.path);
    expect(loaded, isA<LoadedNote>());
    final note = loaded as LoadedNote;
    expect(note.text, '# Title\n\nsome words here\nand more\n');
    expect(note.buffer.text, note.text);
    expect(note.buffer.lineCount, 5);
    expect(note.words.isCounted, isTrue);
    expect(note.words.words, countWords(note.text));
    expect(
      WordCount.linesCountedHere,
      before,
      reason: 'the count was made in the isolate, not here',
    );
  });

  test('a file that is not text says so', () async {
    final file = File(p.join(dir.path, 'image.md'))
      ..writeAsBytesSync(<int>[0xFF, 0xFE, 0x00, 0xC3]);
    final loaded = await loadNote(file.path);
    expect(loaded, isA<PreviewWorkFailure>());
    expect((loaded as PreviewWorkFailure).notText, isTrue);
  });

  test('line endings are made LF, and an LF note is left as it is', () {
    expect(normalizedLineEndings('a\r\nb\rc\n'), 'a\nb\nc\n');
    const lf = 'a\nb\n';
    expect(identical(normalizedLineEndings(lf), lf), isTrue);
  });
}
