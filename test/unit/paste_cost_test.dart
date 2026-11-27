// What a paste costs before the text is in (#1356): prose is refused as a table
// at the first row that breaks the shape, a copy too long for a spreadsheet is
// not read at all, and the clipboard is read once.
//
// The numbers are printed, a generous backstop is asserted on any host, and
// the design's bar only by `NIMAN_PERF=1 flutter test
// test/unit/paste_cost_test.dart` (AGENTS.md).
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/table/clipboard_table.dart';
import 'package:niman/src/ui/note_paste.dart';
import 'package:niman/src/ui/note_view_handle.dart' show PastedText;

final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// Prose with commas, [megabytes] of it: what a pasted article looks like.
String _prose(int megabytes) {
  const line = 'The quick brown fox, who jumped over a lazy dog, went home.\n';
  final count = megabytes * 1024 * 1024 ~/ line.length;
  return List.filled(count, line).join();
}

void main() {
  group('plain text is refused as a table early', () {
    test('10 MB of comma prose: no table, in bounded time', () {
      final text = _prose(10);
      expect(text.length, greaterThan(clipboardTableLimit));
      final watch = Stopwatch()..start();
      final table = tableFromClipboard(text);
      watch.stop();
      print(
        'clipboard table, 10 MB of prose: ${watch.elapsedMilliseconds} ms '
        '(was 766 ms); bar 20 ms under NIMAN_PERF, backstop 500',
      );
      expect(table, isNull);
      expect(watch.elapsedMilliseconds, lessThan(500));
      if (_referenceHost) expect(watch.elapsedMilliseconds, lessThan(20));
    });

    test('prose under the limit is refused at its second row', () {
      // Read to its end, this is 1.5 MB of cells; refused at the second line
      // it is two rows. Proved by the answer being the same as before.
      final text = _prose(1);
      expect(text.length, lessThan(clipboardTableLimit));
      final watch = Stopwatch()..start();
      expect(tableFromClipboard(text), isNull);
      watch.stop();
      print('clipboard table, 1 MB of prose: ${watch.elapsedMilliseconds} ms');
      expect(watch.elapsedMilliseconds, lessThan(500));
    });

    test("a spreadsheet's copy is still a table", () {
      final rows = [
        for (var i = 0; i < 20000; i++) 'name $i\t${i * 3}\tnote $i',
      ].join('\n');
      expect(rows.length, lessThan(clipboardTableLimit));
      final table = tableFromClipboard(rows);
      expect(table, isNotNull);
      expect(table!.rows, hasLength(19999));
    });

    test('a data file past the limit is text', () {
      final rows = [for (var i = 0; i < 400000; i++) '$i,name $i,${i * 3}']
          .join('\n');
      expect(rows.length, greaterThan(clipboardTableLimit));
      expect(tableFromClipboard(rows), isNull);
    });

    test('rows that break the shape late are still refused', () {
      final rows = [
        for (var i = 0; i < 100; i++) '$i,a,b',
        'one,two',
      ].join('\n');
      expect(tableFromClipboard(rows), isNull);
      final tabs = [
        for (var i = 0; i < 100; i++) '$i\ta',
        'no tab here',
      ].join('\n');
      expect(tableFromClipboard(tabs), isNull);
    });
  });

  group('the clipboard is read once', () {
    test('text that is no table is pasted from the text just read', () async {
      var reads = 0;
      final pasted = <String>[];
      final paste = NotePaste(
        canInsert: () => true,
        clipboardFiles: () async => const <String>[],
        attach: (_) async => false,
        caretInCode: () => false,
        surroundings: () => (before: '', after: ''),
        plainText: () async {
          reads++;
          return 'one, two, three\nfour five six';
        },
        pasteText: (text) {
          pasted.add(text);
          return (start: 0, text: text);
        },
        replacePasted: (_, _) {},
        messenger: () => null,
      );
      expect(await paste.paste(), isTrue, reason: 'taken: nothing left to do');
      expect(reads, 1);
      expect(pasted, ['one, two, three\nfour five six']);
    });

    test(
      'a note that takes no text leaves the clipboard to the editor',
      () async {
        final paste = NotePaste(
          canInsert: () => true,
          clipboardFiles: () async => const <String>[],
          attach: (_) async => false,
          caretInCode: () => false,
          surroundings: () => (before: '', after: ''),
          plainText: () async => 'some text',
          pasteText: (_) => null as PastedText?,
          replacePasted: (_, _) {},
          messenger: () => null,
        );
        expect(await paste.paste(), isFalse);
      },
    );

    test('in code the clipboard is not read here at all', () async {
      var reads = 0;
      final paste = NotePaste(
        canInsert: () => true,
        clipboardFiles: () async => const <String>[],
        attach: (_) async => false,
        caretInCode: () => true,
        surroundings: () => (before: '', after: ''),
        plainText: () async {
          reads++;
          return 'x';
        },
        pasteText: (text) => (start: 0, text: text),
        replacePasted: (_, _) {},
        messenger: () => null,
      );
      expect(await paste.paste(), isFalse);
      expect(reads, 0);
    });
  });
}
