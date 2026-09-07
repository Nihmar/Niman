// T-M3-10: the exact whole-word replace runner over a real index + disk.
import 'dart:io';

import 'package:copist/src/db/database.dart';
import 'package:copist/src/db/indexer.dart';
import 'package:copist/src/search/replace.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late CopistDatabase db;
  late ReplaceRunner replace;

  File file(String rel) => File(p.join(root.path, rel));

  Future<String> read(String rel) => file(rel).readAsString();

  setUp(() async {
    root = await Directory.current.createTemp('copist_replace_');
    db = CopistDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    // The corpus: word-boundary traps and a multi-word phrase.
    await file('a.md').writeAsString(
      'cat catalog concatenate cats. Cat CAT.\n',
    );
    await file('b.md').writeAsString(
      'dog hello world, hello\nworld — città cittàx.\n',
    );
    await file('c.md').writeAsString('nothing here\n');
    await Directory(p.join(root.path, 'sub')).create();
    await file('sub/x.md').writeAsString('deep cat\n');
    await Indexer(db).fullScan(root.path);
    replace = ReplaceRunner(db, root.path);
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  group('replaceWholeWords', () {
    test('matches whole words only, case-insensitively by default', () {
      const text = 'cat catalog Cat, cats concatenate (cat) cat!';
      final (count, out) = replaceWholeWords(
        text,
        'cat',
        'dog',
        caseSensitive: false,
      );
      expect(count, 4); // cat, Cat, (cat), cat!
      expect(out, 'dog catalog dog, cats concatenate (dog) dog!');
    });

    test('case-sensitive flag narrows the matches', () {
      const text = 'cat Cat CAT';
      final (count, out) = replaceWholeWords(
        text,
        'Cat',
        'dog',
        caseSensitive: true,
      );
      expect(count, 1);
      expect(out, 'cat dog CAT');
    });

    test('a multi-word term matches across any whitespace', () {
      const text = 'a hello world b\nhello  world c hello\nworld d';
      final (count, out) = replaceWholeWords(
        text,
        'hello world',
        'bye',
        caseSensitive: false,
      );
      expect(count, 3);
      expect(out, 'a bye b\nbye c bye d');
    });

    test('unicode words keep their boundaries', () {
      const text = 'città cittàx la-città (città)';
      final (count, out) = replaceWholeWords(
        text,
        'città',
        'paese',
        caseSensitive: false,
      );
      expect(count, 3);
      expect(out, 'paese cittàx la-paese (paese)');
    });

    test('an empty replacement deletes the word', () {
      const text = 'one cat two';
      final (count, out) = replaceWholeWords(
        text,
        'cat',
        '',
        caseSensitive: false,
      );
      expect(count, 1);
      expect(out, 'one  two');
    });

    test('regex metacharacters in the term are literal', () {
      const text = 'a+b aab a+b.';
      final (count, out) = replaceWholeWords(
        text,
        'a+b',
        'x',
        caseSensitive: false,
      );
      expect(count, 2);
      expect(out, 'x aab x.');
    });
  });

  group('ReplaceRunner', () {
    test('countNotes approximates the phrase matches from the index', () async {
      expect(await replace.countNotes('cat'), 2); // a.md + sub/x.md
      expect(await replace.countNotes('hello world'), 1); // b.md
      expect(await replace.countNotes('absent'), 0);
    });

    test('replaces whole words across every matching note', () async {
      final report = await replace.replaceAll(
        term: 'cat',
        replacement: 'dog',
        caseSensitive: false,
      );
      expect(report.notesScanned, 2);
      expect(report.notesChanged, 2);
      expect(report.occurrences, 4); // a.md 3 + sub/x.md 1
      expect(report.skipped, isEmpty);
      expect(await read('a.md'), 'dog catalog concatenate cats. dog dog.\n');
      expect(await read('sub/x.md'), 'deep dog\n');
      expect(await read('c.md'), 'nothing here\n');
    });

    test('case-sensitive run touches only the exact case', () async {
      await file('a.md').writeAsString('cat Cat CAT\n');
      await Indexer(db).fullScan(root.path);
      final report = await replace.replaceAll(
        term: 'Cat',
        replacement: 'dog',
        caseSensitive: true,
      );
      expect(report.occurrences, 1);
      expect(await read('a.md'), 'cat dog CAT\n');
    });

    test('a multi-word term replaces across the phrase notes', () async {
      final report = await replace.replaceAll(
        term: 'hello world',
        replacement: 'bye moon',
        caseSensitive: false,
      );
      expect(report.notesChanged, 1);
      expect(report.occurrences, 2); // 'hello world' + 'hello\nworld'
      // The second match spans the newline, so it is replaced by the
      // single-space replacement text.
      expect(
        await read('b.md'),
        'dog bye moon, bye moon — città cittàx.\n',
      );
    });

    test('only limits the run to the given note', () async {
      final report = await replace.replaceAll(
        term: 'cat',
        replacement: 'dog',
        caseSensitive: false,
        only: {'a.md'},
      );
      expect(report.notesScanned, 1);
      expect(report.occurrences, 3);
      expect(await read('sub/x.md'), 'deep cat\n');
    });

    test('skip leaves the given notes alone and reports them', () async {
      final report = await replace.replaceAll(
        term: 'cat',
        replacement: 'dog',
        caseSensitive: false,
        skip: {'a.md'},
      );
      expect(report.notesScanned, 1); // only sub/x.md
      expect(report.skipped, ['a.md']);
      expect(await read('a.md'), contains('cat'));
      expect(await read('sub/x.md'), 'deep dog\n');
    });

    test('a term absent from every file changes nothing', () async {
      final report = await replace.replaceAll(
        term: 'encicl',
        replacement: 'x',
        caseSensitive: false,
      );
      expect(report.notesChanged, 0);
      expect(report.occurrences, 0);
    });

    test('an empty term is refused without touching anything', () async {
      final report = await replace.replaceAll(
        term: '   ',
        replacement: 'x',
        caseSensitive: false,
      );
      expect(report.notesScanned, 0);
      expect(report.occurrences, 0);
    });
  });
}
