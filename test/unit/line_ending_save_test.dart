// A note keeps its line endings through a save (#1056): the editor holds LF,
// the file's own ending is remembered with the note and written back, so
// changing one character of a CRLF note changes one character of the file.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/library/note_write_stream.dart';
import 'package:niman/src/markdown/line_ending.dart';
import 'package:niman/src/markdown/note_load.dart';
import 'package:niman/src/ui/note_save_pipeline.dart';
import 'package:path/path.dart' as p;

void main() {
  group('LineEnding.dominantOf', () {
    test('a note with no CR is LF', () {
      expect(LineEnding.dominantOf(''), LineEnding.lf);
      expect(LineEnding.dominantOf('one\ntwo\n'), LineEnding.lf);
    });

    test('a CRLF note is CRLF, with or without a last line ending', () {
      expect(LineEnding.dominantOf('one\r\ntwo\r\n'), LineEnding.crlf);
      expect(LineEnding.dominantOf('one\r\ntwo'), LineEnding.crlf);
    });

    test('a lone-CR note is CR', () {
      expect(LineEnding.dominantOf('one\rtwo\rthree'), LineEnding.cr);
    });

    test('a mixed note takes its majority, and LF when it is a tie', () {
      expect(LineEnding.dominantOf('a\r\nb\r\nc\nd\n'), LineEnding.lf);
      expect(LineEnding.dominantOf('a\r\nb\r\nc\r\nd\n'), LineEnding.crlf);
      expect(LineEnding.dominantOf('a\r\nb\nc\n'), LineEnding.lf);
      expect(LineEnding.dominantOf('a\rb\r\nc\n'), LineEnding.lf);
      expect(LineEnding.dominantOf('a\rb\rc\r\nd\n'), LineEnding.cr);
    });

    test('apply puts the ending on an LF text', () {
      expect(LineEnding.crlf.apply('a\nb\n'), 'a\r\nb\r\n');
      expect(LineEnding.cr.apply('a\nb'), 'a\rb');
      const text = 'a\nb\n';
      expect(identical(LineEnding.lf.apply(text), text), isTrue);
    });
  });

  group('normalizedLineEndings (#1366)', () {
    test('a lone CR is a character of its line in an LF or CRLF note', () {
      expect(normalizedLineEndings('a\rb\nc\nd\n'), 'a\rb\nc\nd\n');
      expect(normalizedLineEndings('a\rb\r\nc\r\nd\r\n'), 'a\rb\nc\nd\n');
    });

    test('CR CR LF is one line ending after a CR', () {
      expect(normalizedLineEndings('a\r\r\nb\r\n'), 'a\r\nb\n');
    });

    test('a note of lone-CR lines is read as lines', () {
      expect(normalizedLineEndings('one\rtwo\rthree'), 'one\ntwo\nthree');
    });

    test('a note with no CR is the same string', () {
      const text = 'one\ntwo\n';
      expect(identical(normalizedLineEndings(text), text), isTrue);
    });

    test('property: a note written with one ending, lone CRs and all, '
        'reads and writes back byte for byte', () {
      final random = Random(1366);
      var checked = 0;
      for (var round = 0; round < 500; round++) {
        final ending = random.nextBool() ? LineEnding.lf : LineEnding.crlf;
        final out = StringBuffer();
        for (var i = 0, n = random.nextInt(24); i < n; i++) {
          switch (random.nextInt(4)) {
            case 0:
              out.write('\r');
              // A lone CR right before an LF would be a CRLF line.
              if (ending == LineEnding.lf) out.write('x');
            case 1:
              out.write(ending.sequence);
            default:
              out.write('ab'[random.nextInt(2)]);
          }
        }
        final disk = out.toString();
        // The note's own ending decides, as the loader does: a note with
        // more lone CRs than line endings is a lone-CR note, not this one.
        final dominant = LineEnding.dominantOf(disk);
        if (dominant == LineEnding.cr) continue;
        checked++;
        final held = normalizedLineEndings(disk, dominant: dominant);
        expect(dominant.apply(held), disk, reason: 'note: ${jsonEncode(disk)}');
      }
      expect(checked, greaterThan(200));
    });
  });

  group('a note loaded, edited by one character and saved', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('niman_eol'));
    tearDown(() => dir.deleteSync(recursive: true));

    /// Loads [original] with the real loader, types [typed] after [after],
    /// and saves through the real streaming writer; answers the file's bytes
    /// afterwards.
    Future<List<int>> editAndSave(
      List<int> original, {
      required String after,
      required String typed,
    }) async {
      final file = File(p.join(dir.path, 'note.md'))
        ..writeAsBytesSync(original);
      final loaded = loadNoteSync(file.path) as LoadedNote;
      final buffer = loaded.buffer;
      final at = buffer.text.indexOf(after) + after.length;
      buffer.insert(at, typed);

      final pipeline = NoteSavePipeline(
        notePath: () => file.path,
        ready: () => true,
        text: () => buffer.text,
        buffer: () => buffer,
        references: () => null,
        framing: () => loaded.framing,
        saveNote: () => null,
        writeNote: () => null,
        saveNoteStream: () =>
            (
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

    List<int> bytes(String text) => utf8.encode(text);

    test('CRLF stays CRLF: only that character changes', () async {
      const lines = '# Title\r\n\r\nsome words\r\nin a note\r\nend\r\n';
      final saved = await editAndSave(bytes(lines), after: 'some', typed: 'X');
      expect(saved, bytes(lines.replaceFirst('some', 'someX')));
    });

    test('CRLF stays CRLF across slices, and without a last ending', () async {
      // More lines than one slice of the streaming save takes.
      final lines = [
        for (var i = 0; i < 3 * NoteSavePipeline.kSaveSliceLines; i++)
          'line $i',
      ];
      final original = lines.join('\r\n');
      final saved = await editAndSave(
        bytes(original),
        after: 'line 40000',
        typed: '!',
      );
      expect(saved, bytes(original.replaceFirst('line 40000', 'line 40000!')));
    });

    test('an LF note stays LF', () async {
      const original = '# Title\n\nsome words\nin a note\n';
      final saved = await editAndSave(
        bytes(original),
        after: 'some',
        typed: 'X',
      );
      expect(saved, bytes(original.replaceFirst('some', 'someX')));
    });

    test('a CRLF note with a BOM keeps both', () async {
      const original = '\u{FEFF}# Title\r\n\r\nsome words\r\n';
      final saved = await editAndSave(
        bytes(original),
        after: 'some',
        typed: 'X',
      );
      expect(saved.take(3), [0xEF, 0xBB, 0xBF]);
      expect(saved, bytes(original.replaceFirst('some', 'someX')));
    });

    test('a note of lone CRs stays lone CRs', () async {
      const original = 'one\rtwo\rthree\r';
      final saved = await editAndSave(
        bytes(original),
        after: 'two',
        typed: '2',
      );
      expect(saved, bytes('one\rtwo2\rthree\r'));
    });

    test('a lone CR inside an LF note stays a lone CR (#1366)', () async {
      const original = 'a\rb\nc\nd\n';
      final saved = await editAndSave(bytes(original), after: 'c', typed: 'X');
      expect(saved, bytes('a\rb\ncX\nd\n'));
    });

    test('CR CR LF in a CRLF note stays one CR CR LF (#1366)', () async {
      const original = 'a\r\nb\r\r\nc\r\n';
      final saved = await editAndSave(bytes(original), after: 'c', typed: 'X');
      expect(saved, bytes('a\r\nb\r\r\ncX\r\n'));
    });

    test('a mixed note is saved with its dominant ending', () async {
      const original = 'one\r\ntwo\r\nthree\nfour\r\n';
      final saved = await editAndSave(
        bytes(original),
        after: 'one',
        typed: '!',
      );
      expect(saved, bytes('one!\r\ntwo\r\nthree\r\nfour\r\n'));
    });
  });
}
