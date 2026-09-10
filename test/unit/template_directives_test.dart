// T-TPL-02 AC: a template can file its own notes, name them, add to them
// and say how they open — and the block that says so never reaches the
// note it made.
import 'package:copist/src/templates/directives.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final clock = DateTime(2026, 3, 9, 7, 5);

  TemplateDirectives read(String source, {String title = ''}) =>
      readTemplateDirectives(source, title: title, now: clock);

  String render(String source, {String title = 'My Note'}) =>
      renderTemplate(source, title: title, now: clock);

  group('reading the block', () {
    test('a template that says nothing declares nothing', () {
      expect(read('# Just a heading\n'), TemplateDirectives.none);
      expect(read('---\ntags: [x]\n---\n\nbody\n').folder, isNull);
      expect(read('---\ntags: [x]\n---\n\nbody\n').filename, isNull);
      expect(read('---\ntags: [x]\n---\n\nbody\n').namesItself, isFalse);
    });

    test('folder and filename, with their placeholders filled in', () {
      const source = '''
---
copist:
  folder: Journal/{{date:YYYY}}/{{date:MM}}
  filename: "{{date:YYYY-MM-DD}}"
---

# {{date:dddd}}
''';
      final directives = read(source);
      expect(directives.folder, 'Journal/2026/03');
      expect(directives.filename, '2026-03-09');
      expect(directives.namesItself, isTrue);
    });

    test('a filename may be built from the name the user typed', () {
      const source =
          '---\ncopist:\n  filename: "{{date:YYYY-MM}} {{title}}"\n'
          '---\n\nbody\n';
      expect(read(source, title: 'Standup').filename, '2026-03 Standup');
    });

    test('append and open', () {
      const source = '---\ncopist:\n  append: true\n  open: preview\n---\n';
      expect(read(source).append, isTrue);
      expect(read(source).open, TemplateOpen.preview);
      expect(read('---\ncopist:\n  open: none\n---\n').open, TemplateOpen.none);
      // Anything else means the editor, which is what creating a note
      // has always done.
      expect(
        read('---\ncopist:\n  open: sideways\n---\n').open,
        TemplateOpen.editor,
      );
      expect(
        read('---\ncopist:\n  folder: X\n---\n').open,
        TemplateOpen.editor,
      );
      expect(read('---\ncopist:\n  append: yes please\n---\n').append, isFalse);
    });

    test('a folder value out of a hand-edited file is sanitized', () {
      const source = '---\ncopist:\n  folder: "/../World//Places/"\n---\n';
      expect(read(source).folder, 'World/Places');
    });

    test('a filename keeps no path and no extension', () {
      const source = '---\ncopist:\n  filename: "Notes/Daily.md"\n---\n';
      // The separators go the way any typed note name loses them, and
      // the app adds the extension itself.
      expect(read(source).filename, 'NotesDaily');
    });

    test('an empty or whitespace value is no directive at all', () {
      expect(read('---\ncopist:\n  folder: "  "\n---\n').folder, isNull);
      expect(read('---\ncopist:\n  filename: ""\n---\n').namesItself, isFalse);
    });

    test('malformed frontmatter declares nothing rather than throwing', () {
      expect(read('---\ncopist: [unclosed\n---\n'), TemplateDirectives.none);
    });
  });

  group('rendering the note', () {
    test('the block is gone and the rest of the frontmatter stays', () {
      const source = '''
---
copist:
  folder: World/Characters
  filename: "{{title}}"
type: character
tags: [character]
---

# {{title}}
''';
      expect(render(source), '''
---
type: character
tags: [character]
---

# My Note
''');
    });

    test(
      'a template whose only frontmatter was the block loses the fences',
      () {
        const source = '---\ncopist:\n  folder: Journal\n---\n\n# {{title}}\n';
        expect(render(source), '# My Note\n');
      },
    );

    test('a template with no block is substituted and left alone', () {
      expect(render('# {{title}}\n'), '# My Note\n');
    });

    test('a nested key of another mapping is not the block', () {
      const source = '---\nmeta:\n  copist: keep me\n---\n\nbody\n';
      expect(render(source), source);
    });
  });
}
