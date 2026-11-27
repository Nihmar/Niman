// What Enter does on a line (#142, #1049): a list carried on, a quote carried
// on, an empty item left — one rule, read behind the quote marks as Tab reads.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/enter_edit.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Presses Enter in [marked] — a note with `|` where the caret is — and says
/// what the note reads afterwards, the caret marked again; null when Enter is
/// left to the platform.
String? _enter(String marked, {int width = 2}) {
  final caret = marked.indexOf('|');
  final buffer = SourceBuffer.fromText(marked.replaceFirst('|', ''));
  final edit = enterEdit(buffer, caret, indentWidth: width);
  if (edit == null) return null;
  final before = buffer.length;
  buffer.replaceRange(edit.start, edit.end, edit.text, verbatim: edit.verbatim);
  final stored = buffer.length - before + (edit.end - edit.start);
  final at = edit.caret?.extent ?? edit.start + stored;
  final text = buffer.text;
  return '${text.substring(0, at)}|${text.substring(at)}';
}

void main() {
  group('a list is carried on', () {
    for (final (marked, expected) in <(String, String)>[
      ('- milk|', '- milk\n- |'),
      ('* milk|', '* milk\n* |'),
      ('3. milk|', '3. milk\n4. |'),
      ('- [x] milk|', '- [x] milk\n- [ ] |'),
      ('  - milk|', '  - milk\n  - |'),
      ('- mi|lk', '- mi\n- |lk'),
    ]) {
      test(marked, () => expect(_enter(marked), expected));
    }

    test("a caret inside the marker is the platform's", () {
      expect(_enter('-| milk'), isNull);
      expect(_enter('|- milk'), isNull);
    });
  });

  group('behind the quote marks, a list is carried on too', () {
    for (final (marked, expected) in <(String, String)>[
      ('> - a|', '> - a\n> - |'),
      ('> 1. a|', '> 1. a\n> 2. |'),
      ('> - [ ] a|', '> - [ ] a\n> - [ ] |'),
      ('> > - a|', '> > - a\n> > - |'),
      ('  > - a|', '  > - a\n  > - |'),
    ]) {
      test(marked, () => expect(_enter(marked), expected));
    }

    test("a caret inside the quote marks or the marker is the platform's", () {
      expect(_enter('|> - a'), isNull);
      expect(_enter('> -| a'), isNull);
    });
  });

  group('a quote line starts the next with its marks (#1049)', () {
    for (final (marked, expected) in <(String, String)>[
      ('> quoted|', '> quoted\n> |'),
      ('> > x|', '> > x\n> > |'),
      ('>> x|', '>> x\n>> |'),
      ('> [!note]|', '> [!note]\n> |'),
      ('> [!note] Title|', '> [!note] Title\n> |'),
      ('> # Heading|', '> # Heading\n> |'),
      ('>no space|', '>no space\n> |'),
      ('> ab|cd', '> ab\n> |cd'),
    ]) {
      test(marked, () => expect(_enter(marked), expected));
    }

    test("a caret inside the marks is the platform's", () {
      expect(_enter('|> x'), isNull);
    });

    test("a line without marks is the platform's", () {
      expect(_enter('plain|'), isNull);
      expect(_enter('|'), isNull);
      expect(_enter('    > code|'), isNull, reason: 'four spaces are code');
    });
  });

  group('an empty line leaves what it is in', () {
    for (final (marked, expected) in <(String, String)>[
      ('> |', '|'),
      ('>|', '|'),
      ('> > |', '|'),
      ('a\n> x\n> |', 'a\n> x\n|'),
      ('- |', '|'),
      ('1. |', '|'),
      ('- [ ] |', '|'),
      ('> - |', '> |'),
      ('> > 1. |', '> > |'),
    ]) {
      test(marked.replaceAll('\n', r'\n'), () {
        expect(_enter(marked), expected);
      });
    }
  });

  group('an empty nested item goes back a level (#1049)', () {
    test('with nothing above it, by the indent width', () {
      expect(_enter('    - |'), '  - |');
      expect(_enter('    - |', width: 4), '- |');
    });

    test("to its parent's indent, as Shift+Tab does", () {
      expect(_enter('- a\n  - b\n    - |'), '- a\n  - b\n  - |');
      expect(_enter('- a\n  - |'), '- a\n- |');
    });

    test("an ordered item takes the number after its parent's", () {
      expect(_enter('1. a\n   1. |'), '1. a\n2. |');
    });

    test('behind the quote marks', () {
      expect(_enter('> - a\n>   - |'), '> - a\n> - |');
    });

    test('and only at the margin is the marker taken away', () {
      expect(_enter('- a\n- |'), '- a\n|');
    });
  });

  group('a thematic break written with spaces is not a list (#1341)', () {
    for (final marked in <String>['- - -|', '* * *|', '_ _ _|', '-  -  -|']) {
      test(marked, () => expect(_enter(marked), isNull));
    }

    test("inside a quote only the quote's marks are carried on", () {
      expect(_enter('> - - -|'), '> - - -\n> |');
    });
  });

  group("the writer's own marks and numbers are kept (#1342)", () {
    for (final (marked, expected) in <(String, String)>[
      ('- [ ]|', '|'),
      ('- [x]|', '|'),
      ('1. [ ]|', '|'),
      ('> - [ ]|', '> |'),
      ('- [ ]x|', '- [ ]x\n- |'),
      ('- [ ] a|', '- [ ] a\n- [ ] |'),
      ('01. a|', '01. a\n02. |'),
      ('09. a|', '09. a\n10. |'),
      ('009) a|', '009) a\n010) |'),
      ('9. a|', '9. a\n10. |'),
      ('99. a|', '99. a\n100. |'),
      ('>- a|', '>- a\n>- |'),
      ('>> 1. a|', '>> 1. a\n>> 2. |'),
      ('> - a|', '> - a\n> - |'),
    ]) {
      test(marked, () => expect(_enter(marked), expected));
    }
  });

  group(
    'a line that goes on an item starts the next at its content (#1344)',
    () {
      for (final (marked, expected) in <(String, String)>[
        ('- a\n  more|', '- a\n  more\n  |'),
        ('1. a\n   more|', '1. a\n   more\n   |'),
        ('10. a\n    more|', '10. a\n    more\n    |'),
        ('- [ ] a\n  more|', '- [ ] a\n  more\n  |'),
        ('- a\n  - b\n    more|', '- a\n  - b\n    more\n    |'),
        ('- a\n  more\n  and more|', '- a\n  more\n  and more\n  |'),
        ('- a\n\n  second|', '- a\n\n  second\n  |'),
        ('- a\n  mo|re', '- a\n  mo\n  |re'),
        ('> - a\n>   more|', '> - a\n>   more\n>   |'),
        ('> > 1. a\n> >    more|', '> > 1. a\n> >    more\n> >    |'),
        ('- a\n      deeper|', '- a\n      deeper\n  |'),
      ]) {
        test(marked.replaceAll('\n', r'\n'), () {
          expect(_enter(marked), expected);
        });
      }

      for (final marked in <String>[
        '- a\nlazy|',
        '- a\n  more\nlazy|',
        '- a\n |more',
        '- a\n  |more',
        '  indented text|',
        'para\n  indented|',
        '- a\n\ntext\n  indented|',
        '- a\n - b\n   |',
        '1. a\n  too little|',
        '> - a\n  not in the quote|',
      ]) {
        test("the platform's: ${marked.replaceAll('\n', r'\n')}", () {
          expect(_enter(marked), isNull);
        });
      }

      test("a paragraph wrapped past the reach is the platform's", () {
        final lines = ['- a', for (var n = 0; n < 300; n++) '  line $n'];
        final marked = '${lines.join('\n')}|';
        expect(_enter(marked), isNull);
      });

      test('a CRLF note keeps its line endings', () {
        final buffer = SourceBuffer.fromText('- a\r\n  more');
        final edit = enterEdit(buffer, buffer.length, indentWidth: 2)!;
        buffer.replaceRange(
          edit.start,
          edit.end,
          edit.text,
          verbatim: edit.verbatim,
        );
        expect(buffer.text, '- a\r\n  more\r\n  ');
      });
    },
  );

  test('a CRLF note keeps its line endings through a quote', () {
    final buffer = SourceBuffer.fromText('> a\r\n> b');
    final edit = enterEdit(buffer, buffer.length, indentWidth: 2)!;
    buffer.replaceRange(
      edit.start,
      edit.end,
      edit.text,
      verbatim: edit.verbatim,
    );
    expect(buffer.text, '> a\r\n> b\r\n> ');
  });
}
