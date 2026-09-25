// Exporting a folder (or the library) as one zip (#24): the Markdown zip,
// the HTML zip with its relative links and pictures, and cancellation.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/export_tree.dart';
import 'package:path/path.dart' as p;

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
