// Issue #75: what a drop holds is sorted — Markdown files to open,
// folders to import, the rest left alone — and a folder's Markdown is
// copied into a new folder of the library with its layout kept.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/library/markdown_import.dart';
import 'package:niman/src/ui/drop_target.dart';
import 'package:path/path.dart' as p;

void main() {
  test('a drop is sorted by what each thing can become', () {
    final drop = sortDrop([
      '/a/notes.md',
      '/a/README.MARKDOWN',
      '/a/todo.txt',
      '/a/pic.png',
      '/a/dir',
      // A Notion export goes the way a folder does: to import (#25).
      '/a/Export.ZIP',
    ], isFolder: (path) => path == '/a/dir');
    expect(drop.files, ['/a/notes.md', '/a/README.MARKDOWN', '/a/todo.txt']);
    expect(drop.folders, ['/a/dir', '/a/Export.ZIP']);
    expect(drop.rejected, ['/a/pic.png']);
  });

  group('importMarkdownFolder', () {
    late Directory tmp;
    late Directory source;
    late Directory library;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('niman-import');
      source = Directory(p.join(tmp.path, 'Drafts'))..createSync();
      library = Directory(p.join(tmp.path, 'library'))..createSync();
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    void write(String relative, String text) =>
        File(p.join(source.path, relative))
          ..createSync(recursive: true)
          ..writeAsStringSync(text);

    test('copies the Markdown, keeps the layout, leaves the rest', () async {
      write('one.md', '# One');
      write('sub/two.markdown', '# Two');
      write('sub/pic.png', 'png');
      write('.git/HEAD', 'ref');
      write('.obsidian/notes.md', 'hidden');
      final imported = await importMarkdownFolder(
        source: source.path,
        libraryRoot: library.path,
      );
      expect(imported?.folder, 'Drafts');
      expect(imported?.notes, 2);
      final target = p.join(library.path, 'Drafts');
      expect(File(p.join(target, 'one.md')).readAsStringSync(), '# One');
      expect(File(p.join(target, 'sub', 'two.markdown')).existsSync(), isTrue);
      expect(File(p.join(target, 'sub', 'pic.png')).existsSync(), isFalse);
      expect(Directory(p.join(target, '.obsidian')).existsSync(), isFalse);
      // Copied, not moved.
      expect(File(p.join(source.path, 'one.md')).existsSync(), isTrue);
    });

    test(
      'a `.txt` is not a note, so the import leaves it behind (#233)',
      () async {
        write('one.md', '# One');
        write('sub/todo.txt', 'buy milk');
        final imported = await importMarkdownFolder(
          source: source.path,
          libraryRoot: library.path,
        );
        expect(imported?.notes, 1);
        final target = p.join(library.path, 'Drafts');
        expect(File(p.join(target, 'one.md')).existsSync(), isTrue);
        expect(File(p.join(target, 'sub', 'todo.txt')).existsSync(), isFalse);
      },
    );

    test('a name already taken gets a number', () async {
      write('one.md', '# One');
      Directory(p.join(library.path, 'Drafts')).createSync();
      final imported = await importMarkdownFolder(
        source: source.path,
        libraryRoot: library.path,
      );
      expect(imported?.folder, 'Drafts 2');
    });

    test('a folder with no Markdown creates nothing', () async {
      write('pic.png', 'png');
      expect(
        await importMarkdownFolder(
          source: source.path,
          libraryRoot: library.path,
        ),
        isNull,
      );
      expect(library.listSync(), isEmpty);
    });

    test(
      'a folder of 2 000 notes is walked and copied off the UI isolate',
      () async {
        for (var i = 0; i < 2000; i++) {
          write('notes/$i.md', '# $i');
        }
        final import = importMarkdownFolder(
          source: source.path,
          libraryRoot: library.path,
        );
        // The gauge is counted in before the isolate is awaited, so the job is
        // visible on this isolate: an inline walk would leave it at zero
        // (#382).
        expect(
          IsolateGauge.inFlight,
          greaterThan(0),
          reason: 'the import starts a background job, not an inline walk',
        );
        final imported = await import;
        expect(IsolateGauge.inFlight, 0, reason: 'the job is counted back out');
        expect(
          IsolateGauge.peak,
          greaterThanOrEqualTo(1),
          reason: 'the walk and the copy ran as a counted job',
        );
        expect(imported?.notes, 2000);
      },
    );
  });
}
