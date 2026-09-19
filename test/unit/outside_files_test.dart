// Issue #77: the files open outside any library — a tab each, one of
// them showing — and the file behind each, read and written where it is.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/editor_only.dart';
import 'package:niman/src/ui/outside_files.dart';
import 'package:path/path.dart' as p;

void main() {
  group('OutsideFiles', () {
    EditorOnlyDocument doc(String name) => EditorOnlyDocument('/x/$name');

    test('a file opens in a tab of its own and shows; opened again, it '
        'shows without a second tab', () {
      final files = OutsideFiles()
        ..open(doc('a.md'))
        ..open(doc('b.md'));
      expect(files.active?.name, 'b.md');
      files.open(doc('a.md'));
      expect(files.documents, hasLength(2));
      expect(files.active?.name, 'a.md');
    });

    test('closing the one showing shows the one after it, or before it '
        'when it was the last', () {
      final files = OutsideFiles()
        ..open(doc('a.md'))
        ..open(doc('b.md'))
        ..open(doc('c.md'))
        ..show('/x/b.md')
        ..close('/x/b.md');
      expect(files.active?.name, 'c.md');
      files.close('/x/c.md');
      expect(files.active?.name, 'a.md');
      files.close('/x/a.md');
      expect(files.isEmpty, isTrue);
      expect(files.active, isNull);
    });

    test('closing one before it keeps the one showing', () {
      final files = OutsideFiles()
        ..open(doc('a.md'))
        ..open(doc('b.md'))
        ..close('/x/a.md');
      expect(files.active?.name, 'b.md');
    });

    test('cycling goes round both ways', () {
      final files = OutsideFiles()
        ..open(doc('a.md'))
        ..open(doc('b.md'))
        ..cycle(1);
      expect(files.active?.name, 'a.md');
      files.cycle(-1);
      expect(files.active?.name, 'b.md');
    });
  });

  group('EditorOnlyDocument', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('niman-outside'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('reads and writes the file where it is', () async {
      final file = File(p.join(dir.path, 'README.md'))
        ..writeAsStringSync('# Hi');
      final document = EditorOnlyDocument(file.path);
      expect(document.name, 'README.md');
      expect(document.folder, dir.path);
      expect(document.exists, isTrue);
      expect(await document.read(), '# Hi');
      await document.write('# Hello');
      expect(file.readAsStringSync(), '# Hello');
      // Nothing else is written beside it: no library, no temp left over.
      expect(dir.listSync(), hasLength(1));
    });

    test('hears a change made by something else', () async {
      final file = File(p.join(dir.path, 'notes.md'))..writeAsStringSync('one');
      final changed = EditorOnlyDocument(file.path).changes().first;
      // The watch starts on listen; give it a moment to be in place.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      file.writeAsStringSync('two');
      await changed.timeout(const Duration(seconds: 5));
    });
  });
}
