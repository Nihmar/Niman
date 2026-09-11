// T-TPL-04 AC: the four placeholders that describe where a note is being
// made from. An empty clipboard is an answer, not a missing one; a caller
// that supplies no context leaves them standing.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/templates/directives.dart';
import 'package:niman/src/templates/engine.dart';

void main() {
  final clock = DateTime(2026, 3, 9, 7, 5);

  String render(String source, {TemplateContext? context}) =>
      applyTemplate(source, title: 'N', now: clock, context: context);

  group('the four values', () {
    const surroundings = TemplateContext(
      parent: 'Kingdoms',
      folder: 'World/Places',
      clipboard: 'pasted text',
      selection: 'a selected line',
    );

    test('each one answers where it stands', () {
      expect(render('{{parent}}', context: surroundings), 'Kingdoms');
      expect(render('{{folder}}', context: surroundings), 'World/Places');
      expect(render('{{clipboard}}', context: surroundings), 'pasted text');
      expect(render('{{selection}}', context: surroundings), 'a selected line');
    });

    test('parent is a name, so a template writes its own brackets', () {
      // The backlink is the template's to spell: a placeholder that
      // wrapped itself could not be used in a sentence or a filter.
      expect(
        render('Spun out of [[{{parent}}]].', context: surroundings),
        'Spun out of [[Kingdoms]].',
      );
      expect(render('{{parent|slug}}', context: surroundings), 'kingdoms');
    });

    test('an empty value is an answer, not a missing one', () {
      expect(render('[{{clipboard}}]', context: TemplateContext.empty), '[]');
      expect(render('[{{parent}}]', context: TemplateContext.empty), '[]');
      // The selection stays empty until a command starts a note from one.
      expect(render('[{{selection}}]', context: TemplateContext.empty), '[]');
    });

    test('with no context at all the placeholders stand', () {
      expect(render('{{parent}}'), '{{parent}}');
      expect(render('{{clipboard}}'), '{{clipboard}}');
      expect(render('{{folder}} {{selection}}'), '{{folder}} {{selection}}');
    });

    test('withFolder fills the one value that is known late', () {
      const before = TemplateContext(parent: 'Kingdoms', clipboard: 'x');
      final after = before.withFolder('Journal/2026');
      expect(render('{{folder}}', context: before), '');
      expect(render('{{folder}}', context: after), 'Journal/2026');
      // And carries the rest across.
      expect(render('{{parent}}', context: after), 'Kingdoms');
      expect(render('{{clipboard}}', context: after), 'x');
    });
  });

  group('in a template', () {
    test('a directive can be built from the parent note', () {
      const source = '---\nniman:\n  folder: World/{{parent}}\n---\nbody\n';
      final directives = readTemplateDirectives(
        source,
        now: clock,
        context: const TemplateContext(parent: 'Places'),
      );
      expect(directives.folder, 'World/Places');
    });

    test('the note gets the backlink and the pasted text', () {
      const source = '# {{title}}\n\nFrom [[{{parent}}]]\n\n{{clipboard}}\n';
      expect(
        renderTemplate(
          source,
          title: 'Elyria',
          now: clock,
          context: const TemplateContext(
            parent: 'Kingdoms',
            clipboard: 'a stack trace',
          ),
        ),
        '# Elyria\n\nFrom [[Kingdoms]]\n\na stack trace\n',
      );
    });
  });
}
