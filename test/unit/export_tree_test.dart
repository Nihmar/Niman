// Exporting a folder (or the library) as one zip (#24): the Markdown zip,
// the HTML zip with its relative links and pictures, and cancellation.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/export_tree.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:path/path.dart' as p;

/// The engine's stand-in for a folder's PDF run: writes the page itself as
/// the "PDF", so the test can read what the page was. Top-level, so the
/// spawned isolate may take it — a closure cannot cross the boundary.
Future<ProcessAnswer> _printPage(
  String exe,
  List<String> args, {
  Duration? timeout,
}) async {
  final pdf = args
      .firstWhere((arg) => arg.startsWith('--print-to-pdf='))
      .substring('--print-to-pdf='.length);
  final html = Uri.parse(args.last).toFilePath();
  await File(pdf).writeAsString('PDF\n${await File(html).readAsString()}');
  return (exit: 0, stdout: '');
}

void main() {
  late Directory lib;
  late String notes;
  late String zip;

  setUp(() async {
    lib = await Directory.current.createTemp('niman_tree_');
    notes = p.join(lib.path, 'Notes');
    await Directory(p.join(notes, 'sub')).create(recursive: true);
    await Directory(p.join(lib.path, '.niman')).create(recursive: true);
    await File(p.join(lib.path, '.niman', 'settings.json')).writeAsString('{}');
    // Outside the exported folder: its links become text, not links.
    await File(p.join(lib.path, 'Top.md')).writeAsString('# Top\n');
    await File(p.join(notes, 'a.md')).writeAsString(
      '# A\n\n'
      'See [[b]] and [[sub/c#Part|cee]].\n\n'
      'Out: [[Top]].\n\n'
      '![p](photo.png)\n',
    );
    await File(p.join(notes, 'b.md')).writeAsString('# B\n');
    await File(p.join(notes, 'sub', 'c.md')).writeAsString('# C\n\n## Part\n');
    await File(p.join(notes, 'photo.png')).writeAsBytes(<int>[1, 2, 3]);
    zip = p.join(lib.path, 'out.zip');
  });

  tearDown(() async {
    if (lib.existsSync()) await lib.delete(recursive: true);
  });

  /// The zip's files, by name, their text decoded.
  Future<Map<String, String>> contents() async {
    final archive = ZipDecoder().decodeBytes(await File(zip).readAsBytes());
    return <String, String>{
      for (final file in archive.files)
        if (file.isFile) file.name: utf8.decode(file.content as List<int>),
    };
  }

  test('the Markdown zip mirrors the folder, dot folders out', () async {
    await TreeExport.run(
      dir: notes,
      zipPath: zip,
      format: ExportTreeFormat.markdown,
      language: 'en',
    );
    final files = await contents();
    expect(files.keys, containsAll(<String>['a.md', 'b.md', 'sub/c.md']));
    expect(files.keys.any((name) => name.contains('.niman')), isFalse);
    expect(files['a.md'], contains('[[b]]'));
  });

  test('the HTML zip makes a page a note, and copies the rest', () async {
    await TreeExport.run(
      dir: notes,
      zipPath: zip,
      format: ExportTreeFormat.html,
      language: 'en',
    );
    final files = await contents();
    expect(
      files.keys,
      containsAll(<String>['a.html', 'b.html', 'sub/c.html', 'photo.png']),
    );
    expect(files.keys, isNot(contains('a.md')));
    // A picture stored once, beside the page that shows it.
    expect(files['photo.png'], isNot(contains('<html')));
  });

  test('the pages link relatively, and a link outside is text', () async {
    await TreeExport.run(
      dir: notes,
      zipPath: zip,
      format: ExportTreeFormat.html,
      language: 'en',
    );
    final a = (await contents())['a.html']!;
    expect(a, contains('href="b.html"'));
    expect(a, contains('href="sub/c.html#part"'));
    expect(a, contains('src="photo.png"'));
    // `[[Top]]` is outside the exported folder: highlighted text, not a
    // link to a page the zip does not hold.
    expect(a, contains('<span class="wikilink">Top</span>'));
    expect(a, isNot(contains('Top.html')));
  });

  test('a PDF folder needs an engine', () async {
    await expectLater(
      TreeExport.run(
        dir: notes,
        zipPath: zip,
        format: ExportTreeFormat.pdf,
        language: 'en',
      ),
      throwsA(isA<TreeExportNoEngine>()),
    );
    expect(File(zip).existsSync(), isFalse);
  });

  test('a # or ? in a name is escaped in the page URL', () async {
    await File(p.join(notes, 'q?x.md')).writeAsString('# Q\n');
    await File(p.join(notes, 'weird#one.png')).writeAsBytes(<int>[1, 2, 3]);
    await File(p.join(notes, 'links.md'))
        .writeAsString('See [[q?x]].\n\n![w](weird#one.png)\n');
    await TreeExport.run(
      dir: notes,
      zipPath: zip,
      format: ExportTreeFormat.html,
      language: 'en',
    );
    final page = (await contents())['links.html']!;
    // `#` and `?` are URI delimiters: left alone they would make the URL a
    // fragment, and the file it names would be dead (#63 review, L3).
    expect(page, contains('href="q%3Fx.html"'));
    expect(page, contains('src="weird%23one.png"'));
  });

  test('an empty folder is in every zip', () async {
    await Directory(p.join(notes, 'empty')).create();
    await TreeExport.run(
      dir: notes,
      zipPath: zip,
      format: ExportTreeFormat.html,
      language: 'en',
    );
    final archive = ZipDecoder().decodeBytes(await File(zip).readAsBytes());
    expect(
      archive.files.any(
        (file) => !file.isFile && file.name.startsWith('empty'),
      ),
      isTrue,
    );
  });

  test('a PDF folder embeds its pictures in the page', () async {
    await TreeExport.run(
      dir: notes,
      zipPath: zip,
      format: ExportTreeFormat.pdf,
      language: 'en',
      engine: '/usr/bin/chromium',
      runner: _printPage,
    );
    final files = await contents();
    expect(files.keys, containsAll(<String>['a.pdf', 'b.pdf', 'sub/c.pdf']));
    // The page is printed from a scratch directory, where the zip's
    // pictures are not: relative, every one of them would be broken
    // (#63 review, H1). A `file:` URL points at the tree itself.
    expect(files['a.pdf'], contains('src="file:'));
    expect(files['a.pdf'], contains('photo.png'));
    expect(files['a.pdf'], isNot(contains('src="photo.png"')));
    // The links point at the PDFs the zip holds.
    expect(files['a.pdf'], contains('href="b.pdf"'));
  });

  test('a note with a broken byte still exports, decoded leniently', () async {
    // `# Broken`, one byte of it not UTF-8: the app reads such a note, so
    // the export does too, instead of failing the whole folder (E9).
    await File(p.join(notes, 'broken.md')).writeAsBytes(<int>[
      0x23,
      0x20,
      0x42,
      0x72,
      0xFF,
      0x6F,
      0x6B,
      0x65,
      0x6E,
      0x0A,
    ]);
    await TreeExport.run(
      dir: notes,
      zipPath: zip,
      format: ExportTreeFormat.html,
      language: 'en',
    );
    final files = await contents();
    expect(files.keys, contains('broken.html'));
    expect(files['broken.html'], contains('Br\uFFFDoken'));
    // The book's chapters take the same read.
    zip = p.join(lib.path, 'book.epub');
    await TreeExport.run(
      dir: notes,
      zipPath: zip,
      format: ExportTreeFormat.epub,
      language: 'en',
    );
    expect(
      (await contents())['OEBPS/text/broken.xhtml'],
      contains('Br\uFFFDoken'),
    );
  });

  test('a cancelled export leaves no zip behind', () async {
    // Enough entries that the isolate is still writing when the cancel
    // lands.
    for (var at = 0; at < 300; at++) {
      await File(p.join(notes, 'n$at.md'))
          .writeAsString('# Note $at\n\n${'parola ' * 200}\n');
    }
    final export = await TreeExport.start(
      dir: notes,
      zipPath: zip,
      format: ExportTreeFormat.markdown,
      language: 'en',
    );
    final started = Completer<void>();
    void listener() {
      if (export.progress.value != null && !started.isCompleted) {
        started.complete();
      }
    }

    export.progress.addListener(listener);
    await started.future.timeout(const Duration(seconds: 30));
    export.progress.removeListener(listener);
    await export.cancel();

    await expectLater(export.done, throwsA(isA<ExportCancelled>()));
    expect(File(zip).existsSync(), isFalse);
  });
}
