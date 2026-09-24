// Issue #60: the library's personal dictionary — the words the writer has
// added by right-click — lives one per line at <library>/.niman/
// dictionary.txt and is layered in front of the spell engines.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/spellcheck/personal_dictionary.dart';
import 'package:path/path.dart' as p;

void main() {
  group('PersonalDictionary', () {
    Directory dir0() {
      final dir = Directory.systemTemp.createTempSync('niman-dict');
      addTearDown(() => dir.deleteSync(recursive: true));
      return dir;
    }

    test('a missing file opens empty', () async {
      final dictionary = await PersonalDictionary.open(dir0().path);
      expect(dictionary.length, 0);
      expect(dictionary.contains('anything'), isFalse);
    });

    test('open reads the file case-insensitively', () async {
      final dir = dir0();
      File(p.join(dir.path, '.niman', 'dictionary.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync('zebra\nNim\n');
      final dictionary = await PersonalDictionary.open(dir.path);
      expect(dictionary.length, 2);
      expect(dictionary.contains('zebra'), isTrue);
      expect(dictionary.contains('ZEBRA'), isTrue);
      expect(dictionary.contains('nim'), isTrue);
    });

    test(
      'add appends the line, remembers the word and notifies once',
      () async {
        final dictionary = await PersonalDictionary.open(dir0().path);
        var notified = 0;
        dictionary.addListener(() => notified++);
        await dictionary.add('zebra');
        expect(notified, 1);
        expect(dictionary.contains('zebra'), isTrue);
        expect(File(dictionary.path).readAsStringSync(), 'zebra\n');
      },
    );

    test('adding an existing word is a no-op', () async {
      final dictionary = await PersonalDictionary.open(dir0().path);
      var notified = 0;
      dictionary.addListener(() => notified++);
      await dictionary.add('zebra');
      await dictionary.add('ZEBRA');
      expect(notified, 1);
      expect(dictionary.length, 1);
      // The file keeps the first form the writer typed.
      expect(File(dictionary.path).readAsStringSync(), 'zebra\n');
    });

    test(
      'add after a file without a trailing newline stays on its line',
      () async {
        final dir = dir0();
        final file = File(p.join(dir.path, '.niman', 'dictionary.txt'))
          ..createSync(recursive: true)
          ..writeAsStringSync('zebra'); // no newline
        final dictionary = await PersonalDictionary.open(dir.path);
        await dictionary.add('niman');
        expect(file.readAsStringSync(), 'zebra\nniman\n');
      },
    );

    test('the words survive a reopen', () async {
      final dir = dir0();
      var dictionary = await PersonalDictionary.open(dir.path);
      await dictionary.add('zebra');
      dictionary.dispose();
      dictionary = await PersonalDictionary.open(dir.path);
      expect(dictionary.contains('zebra'), isTrue);
    });

    test('reload picks up words written behind its back', () async {
      final dir = dir0();
      final dictionary = await PersonalDictionary.open(dir.path);
      await dictionary.add('zebra');
      var heard = 0;
      dictionary.addListener(() => heard++);
      // A sync merged in the words added on another device.
      File(dictionary.path).writeAsStringSync('zebra\nKaTeX\n');
      await dictionary.reload();
      expect(dictionary.contains('katex'), isTrue);
      expect(dictionary.length, 2);
      expect(heard, 1);
    });

    test('a hostile file opens empty rather than throwing', () async {
      // A directory where the file should be: the read fails and the
      // dictionary stays empty, the settings file's rule.
      final dir = dir0();
      Directory(p.join(dir.path, '.niman', 'dictionary.txt'))
          .createSync(recursive: true);
      final dictionary = await PersonalDictionary.open(dir.path);
      expect(dictionary.length, 0);
    });
  });
}
