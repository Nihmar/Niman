// Issue #75: what a drop holds is sorted — Markdown files to open,
// folders to import, the rest left alone — and a folder's Markdown is
// copied into a new folder of the library with its layout kept.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
    ], isFolder: (path) => path == '/a/dir');
    expect(drop.files, ['/a/notes.md', '/a/README.MARKDOWN', '/a/todo.txt']);
    expect(drop.folders, ['/a/dir']);
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
  });
}
