// A note read and made ready off the UI isolate (`note_load.dart`): what
// comes back is the note as the editor holds it. Its word count is not
// waited for: the surface counts it once the note is on screen.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/word_count.dart';
import 'package:niman/src/editor/word_count_index.dart';
import 'package:niman/src/markdown/note_bytes.dart';
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

  test(
    'a Latin-1 note the rest of the app reads opens as text (#353)',
    () async {
      // `caf\xE9\n`: 0xE9 is not UTF-8, but an imported vault is full of such
      // notes, and note ops, the index, the widget and export all read them —
      // so the editor does too, the byte read as the Windows-1252 character
      // it is — not U+FFFD, which the first save wrote over it.
      final file = File(p.join(dir.path, 'latin1.md'))
        ..writeAsBytesSync(<int>[0x63, 0x61, 0x66, 0xE9, 0x0A]);
      final loaded = await loadNote(file.path);
      expect(loaded, isA<LoadedNote>());
      final note = loaded as LoadedNote;
      expect(note.text, 'caf\u00E9\n');
      expect(note.buffer.text, note.text);
      // One rule for every path: the text the loader hands the editor is what
      // note ops, the index, the widget and export decode.
      expect(note.text, decodeNoteText(<int>[0x63, 0x61, 0x66, 0xE9, 0x0A]));
      // The reload path reads the same file the same way.
      expect(await readNoteText(file.path), 'caf\u00E9\n');
    },
  );

  test('a genuinely binary file (NUL bytes) is not text', () async {
    // A UTF-16 BOM and a NUL: nothing a person writes as a note, and the
    // refusal of a file that is not text (issue #156) still holds.
    final file = File(p.join(dir.path, 'image.md'))
      ..writeAsBytesSync(<int>[0xFF, 0xFE, 0x00, 0xC3]);
    final loaded = await loadNote(file.path);
    expect(loaded, isA<NoteReadFailure>());
    expect((loaded as NoteReadFailure).notText, isTrue);
  });

  test('a NUL-free file of undecodable bytes is not text either', () async {
    // No NUL to catch it, but no byte belongs to a UTF-8 sequence: binary,
    // not a Latin-1 note.
    final file = File(p.join(dir.path, 'blob.md'))
      ..writeAsBytesSync(List<int>.filled(64, 0xFF));
    final loaded = await loadNote(file.path);
    expect(loaded, isA<NoteReadFailure>());
    expect((loaded as NoteReadFailure).notText, isTrue);
  });

  test(
    'a note with a single U+0000 is refused by both readers (#496)',
    () async {
      // A third of the file is NUL — the share the binary rule draws the line
      // at — so both the editor loader and the reload path refuse it, the
      // same answer, rather than one taking it and the other not.
      final file = File(p.join(dir.path, 'nul.md'))
        ..writeAsBytesSync(<int>[0x61, 0x00, 0x62]);
      final loaded = await loadNote(file.path);
      expect(loaded, isA<NoteReadFailure>());
      expect((loaded as NoteReadFailure).notText, isTrue);
      expect(await readNoteText(file.path), isA<NoteReadFailure>());
    },
  );

  test('line endings are made LF, and an LF note is left as it is', () {
    expect(normalizedLineEndings('a\r\nb\rc\n'), 'a\nb\nc\n');
    const lf = 'a\nb\n';
    expect(identical(normalizedLineEndings(lf), lf), isTrue);
  });
}
