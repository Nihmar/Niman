// T-TPL-03 AC: a template's questions are found in the order it asks
// them, each label asked once, and the answers reach the body, the
// frontmatter and the directives alike.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/templates/directives.dart';
import 'package:niman/src/templates/engine.dart';
import 'package:niman/src/templates/prompts.dart';

void main() {
  final clock = DateTime(2026, 3, 9, 7, 5);

  group('templateFields', () {
    test('a template with no questions asks none', () {
      expect(templateFields('# {{title}} on {{date}}\n'), isEmpty);
    });

    test('a text field, with and without a starting value', () {
      final fields = templateFields('{{ask:Character}} {{ask:Author:Ada}}');
      expect(fields, [
        const TemplateField(label: 'Character', kind: TemplateFieldKind.text),
        const TemplateField(
          label: 'Author',
          kind: TemplateFieldKind.text,
          hint: 'Ada',
        ),
      ]);
      expect(fields.first.initial, '');
      expect(fields.last.initial, 'Ada');
    });

    test('a choice field keeps its options in order, blanks dropped', () {
      final fields = templateFields(
        '{{choice:Faction:Crown, Rebels ,,Neutral}}',
      );
      expect(fields.single.kind, TemplateFieldKind.choice);
      expect(fields.single.choices, ['Crown', 'Rebels', 'Neutral']);
      // The form offers the first option before anything is touched.
      expect(fields.single.initial, 'Crown');
    });

    test('the same label twice is one question, asked where it first is', () {
      const source = '''
---
niman:
  filename: "{{ask:Name}}"
---

# {{ask:Name}}
Written by {{ask:Author}}, also {{ask:Name}}.
''';
      expect(templateFields(source).map((f) => f.label), ['Name', 'Author']);
    });

    test('a question with no label is not a question', () {
      expect(templateFields('{{ask:}} {{ask: }} {{choice:}}'), isEmpty);
    });

    test('the fields are found inside the frontmatter too', () {
      const source = '---\ntags: ["{{choice:Kind:a,b}}"]\n---\nbody\n';
      expect(templateFields(source).single.label, 'Kind');
    });
  });

  group('substituting the answers', () {
    String render(String source, Map<String, String>? answers) =>
        applyTemplate(source, title: 'N', now: clock, answers: answers);

    test('an answer fills every occurrence of its label', () {
      expect(
        render('{{ask:Name}} and {{ask:Name}}', {'Name': 'Elyria'}),
        'Elyria and Elyria',
      );
    });

    test('a choice is filled the same way', () {
      expect(
        render('{{choice:Faction:Crown,Rebels}}', {'Faction': 'Rebels'}),
        'Rebels',
      );
    });

    test('the hint is not a default: an unanswered field is left empty', () {
      // The form seeds the box with the hint, so an empty answer here is
      // one the user cleared on purpose.
      expect(render('[{{ask:Author:Ada}}]', {'Author': ''}), '[]');
    });

    test('filters apply to an answer like any other value', () {
      expect(
        render('{{ask:Name|slug}}', {'Name': 'The Iron Gate'}),
        'the-iron-gate',
      );
      expect(render('{{ask:Name|upper}}', {'Name': 'ada'}), 'ADA');
    });

    test('with no answers collected the placeholder stands', () {
      expect(render('{{ask:Name}}', null), '{{ask:Name}}');
      expect(render('{{ask:Name}}', const {}), '{{ask:Name}}');
      expect(
        render('{{ask:Name}} {{ask:Other}}', {'Name': 'x'}),
        'x {{ask:Other}}',
      );
    });
  });

  group('answers reach the directives', () {
    test('a field can name the file and pick the folder', () {
      const source = '''
---
niman:
  folder: World/{{choice:Kind:Characters,Places}}
  filename: "{{ask:Name}}"
---

# {{ask:Name}}
''';
      final directives = readTemplateDirectives(
        source,
        now: clock,
        answers: const {'Name': 'Elyria', 'Kind': 'Places'},
      );
      expect(directives.folder, 'World/Places');
      expect(directives.filename, 'Elyria');
      expect(directives.namesItself, isTrue);
    });

    test('the block still goes, and the answers stay in the note', () {
      const source =
          '---\nniman:\n  filename: "{{ask:Name}}"\ntype: character\n---\n\n'
          '# {{ask:Name}}\n';
      expect(
        renderTemplate(
          source,
          title: 'Elyria',
          now: clock,
          answers: const {'Name': 'Elyria'},
        ),
        '---\ntype: character\n---\n\n# Elyria\n',
      );
    });
  });
}
