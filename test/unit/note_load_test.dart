// A note read and made ready off the UI isolate (`note_load.dart`): what
// comes back is the note as the editor holds it. Its word count is not
// waited for: the surface counts it once the note is on screen.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/word_count.dart';
import 'package:niman/src/editor/word_count_index.dart';
import 'package:niman/src/markdown/note_load.dart';
import 'package:niman/src/markdown/note_read_failure.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('niman_note_load'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('a note comes back ready: its text and its buffer', () async {
    final file = File(p.join(dir.path, 'note.md'))
      ..writeAsStringSync('# Title\r\n\r\nsome words here\rand more\n');
    final loaded = await loadNote(file.path);
    expect(loaded, isA<LoadedNote>());
    final note = loaded as LoadedNote;
    expect(note.text, '# Title\n\nsome words here\nand more\n');
    expect(note.buffer.text, note.text);
    expect(note.buffer.lineCount, 5);
  });

  test(
    'its count is left to the surface, which counts it off the page',
    () async {
      // The load counted the note's words before handing it over: ~1 s of the
      // 246 MB note's load, the note waiting behind it.
      final file = File(p.join(dir.path, 'note.md'))
        ..writeAsStringSync('one two\nthree\n');
      final before = WordCount.linesCountedHere;
      final note = await loadNote(file.path) as LoadedNote;
      final surface = MarkdownSurfaceController(note.buffer);
      expect(surface.words.isCounted, isFalse);
      await surface.buildWords();
      expect(surface.words.words, countWords(note.text));
      expect(
        WordCount.linesCountedHere,
        before,
        reason: 'counted in an isolate, not on the one that shows the note',
      );
    },
  );

  test('a file that is not text says so', () async {
    final file = File(p.join(dir.path, 'image.md'))
      ..writeAsBytesSync(<int>[0xFF, 0xFE, 0x00, 0xC3]);
    final loaded = await loadNote(file.path);
    expect(loaded, isA<NoteReadFailure>());
    expect((loaded as NoteReadFailure).notText, isTrue);
  });

  test('line endings are made LF, and an LF note is left as it is', () {
    expect(normalizedLineEndings('a\r\nb\rc\n'), 'a\nb\nc\n');
    const lf = 'a\nb\n';
    expect(identical(normalizedLineEndings(lf), lf), isTrue);
  });
}
