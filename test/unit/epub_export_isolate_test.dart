// A note's EPUB is written off the UI isolate, its pictures stored (#1305):
// the zip's pictures, opened, read and deflated on the UI isolate, froze a
// phone for seconds on a note with fifty photos.
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/epub_note.dart';
import 'package:niman/src/export/export_tree.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.current.createTemp('niman_epub_iso_');
    // A picture a deflate would shrink, so storing it is a choice.
    await File(p.join(root.path, 'photo.png'))
        .writeAsBytes(List<int>.filled(4096, 7));
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  Archive open(List<int> bytes) => ZipDecoder().decodeBytes(bytes);

  test("a picture is stored in the note's book, the text deflated", () async {
    final payload = await exportNoteEpub(
      text: '# T\n\nText text text text text text text.\n\n![p](photo.png)\n',
      title: 'T',
      path: 'T.md',
      root: root.path,
      language: 'en',
    );
    final archive = open(payload.bytes);
    final picture = archive.findFile('OEBPS/images/img-1.png')!;
    expect(picture.compression, CompressionType.none);
    expect(picture.size, 4096);
    expect(
      archive.findFile('mimetype')!.compression,
      CompressionType.none,
      reason: 'the mimetype stays stored',
    );
    expect(archive.files.first.name, 'mimetype', reason: 'and first');
    expect(
      archive.findFile('OEBPS/text/note.xhtml')!.compression,
      CompressionType.deflate,
    );
    expect(
      archive.findFile('OEBPS/content.opf')!.compression,
      CompressionType.deflate,
    );
  });

  test("a folder's book stores its pictures too", () async {
    final notes = Directory(p.join(root.path, 'Notes'))..createSync();
    File(p.join(notes.path, 'photo.png'))
        .writeAsBytesSync(List<int>.filled(4096, 7));
    File(p.join(notes.path, 'a.md')).writeAsStringSync('![p](photo.png)\n');
    final out = p.join(root.path, 'book.epub');
    await TreeExport.run(
      dir: notes.path,
      zipPath: out,
      format: ExportTreeFormat.epub,
      language: 'en',
    );
    final archive = open(File(out).readAsBytesSync());
    expect(
      archive.findFile('OEBPS/images/img-1.png')!.compression,
      CompressionType.none,
    );
  });

  test('the container is written off the UI isolate', () async {
    final probe = ReceivePort();
    final seen = probe.first;
    await exportNoteEpub(
      text: '# T\n\n![p](photo.png)\n',
      title: 'T',
      path: 'T.md',
      root: root.path,
      language: 'en',
      writerProbe: probe.sendPort,
    );
    final writer = await seen.timeout(const Duration(seconds: 5));
    expect(writer, isA<SendPort>());
    expect(writer, isNot(Isolate.current.controlPort));
    probe.close();
  });

  test('a stop while the container is written leaves no book', () async {
    final probe = ReceivePort();
    var started = false;
    probe.listen((_) => started = true);
    await expectLater(
      exportNoteEpub(
        text: '# T\n\n![p](photo.png)\n',
        title: 'T',
        path: 'T.md',
        root: root.path,
        language: 'en',
        // The writer says it began: from then on the user has stopped.
        isCancelled: () => started,
        writerProbe: probe.sendPort,
      ),
      throwsA(isA<EpubExportCancelled>()),
    );
    probe.close();
  });

  test('a failed writer is a failure, not a hang', () async {
    // The book's own file name is a folder here: the container cannot be
    // created, and the isolate's error comes back as a failure.
    final scratch = Directory(p.join(root.path, 'scratch'))..createSync();
    Directory(p.join(scratch.path, 'T.epub')).createSync();
    await expectLater(
      exportNoteEpub(
        text: '# T\n',
        title: 'T',
        path: 'T.md',
        root: root.path,
        language: 'en',
        scratch: scratch,
      ),
      throwsA(isA<EpubExportFailed>()),
    );
  });
}
