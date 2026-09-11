// T-TPL-06 AC: a two-level include, and a self-include that produces a
// visible error rather than a stack overflow.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/templates/includes.dart';

void main() {
  setUp(AppLanguages.reset);
  tearDown(AppLanguages.reset);

  /// A library of templates by path; `.md` is not part of these names,
  /// because the resolver is the caller's business, not the expander's.
  IncludeResolver library(Map<String, String> templates) =>
      (written) async => switch (templates[written]) {
        final text? => (path: written, text: text),
        null => null,
      };

  Future<String> expand(
    String source,
    Map<String, String> templates, {
    String? sourcePath,
    int maxDepth = maxIncludeDepth,
  }) => expandTemplateIncludes(
    source,
    resolve: library(templates),
    sourcePath: sourcePath,
    maxDepth: maxDepth,
  );

  test('a template with no includes comes back untouched', () async {
    expect(await expand('# {{title}}\n', const {}), '# {{title}}\n');
  });

  test('an include is pasted where it stands', () async {
    expect(
      await expand('top\n{{include:Header}}\nbottom\n', const {
        'Header': '## Shared',
      }),
      'top\n## Shared\nbottom\n',
    );
  });

  test('two levels deep', () async {
    expect(
      await expand('{{include:A}}', const {
        'A': 'a{{include:B}}a',
        'B': 'b{{include:C}}b',
        'C': 'c',
      }),
      'abcba',
    );
  });

  test('the same partial twice is pasted twice', () async {
    expect(
      await expand('{{include:P}}|{{include:P}}', const {'P': 'x'}),
      'x|x',
    );
  });

  test('placeholders inside the pasted text survive for the engine', () async {
    // Expansion runs before substitution, so what comes back still has
    // its holes in it.
    expect(
      await expand('{{include:H}}', const {'H': '# {{title}} {{ask:Who}}'}),
      '# {{title}} {{ask:Who}}',
    );
  });

  test('a missing template leaves the placeholder and says so', () async {
    final out = await expand('{{include:Nope}}', const {});
    expect(out, startsWith('{{include:Nope}}'));
    expect(out, contains('Nope'));
    expect(out, contains('⚠'));
  });

  test('a template that includes itself is caught, not followed', () async {
    final out = await expand('x{{include:Loop}}x', const {
      'Loop': 'y{{include:Loop}}y',
    }, sourcePath: 'Root');
    // The outer include is pasted once; the inner one names the loop.
    expect(out, startsWith('xy{{include:Loop}}'));
    expect(out, endsWith('yx'));
    expect(out, contains('⚠'));
  });

  test('the root template including itself is caught on the first step', () {
    expect(
      expand('{{include:Root}}', const {
        'Root': 'body {{include:Root}}',
      }, sourcePath: 'Root'),
      completion(startsWith('{{include:Root}} ⚠')),
    );
  });

  test('two templates including each other stop', () async {
    final out = await expand('{{include:A}}', const {
      'A': 'a{{include:B}}',
      'B': 'b{{include:A}}',
    });
    expect(out, startsWith('ab{{include:A}}'));
    expect(out, contains('⚠'));
  });

  test('a chain longer than the limit stops, saying it is too deep', () async {
    final out = await expand('{{include:1}}', const {
      '1': '1{{include:2}}',
      '2': '2{{include:3}}',
      '3': '3',
    }, maxDepth: 2);
    expect(out, startsWith('12{{include:3}}'));
    expect(out, contains('⚠'));
  });

  test('an include naming nothing is left standing, silently', () async {
    // A typo, treated like every other one: visible, and unexplained
    // because there is nothing to explain.
    expect(await expand('{{include:}}', const {}), '{{include:}}');
    expect(await expand('{{include: }}', const {}), '{{include: }}');
  });

  test('the reason is written in the app language', () async {
    AppLanguages.choice = AppLanguage.italian;
    expect(await expand('{{include:Nope}}', const {}), contains('modello'));
    AppLanguages.choice = AppLanguage.english;
    expect(await expand('{{include:Nope}}', const {}), contains('template'));
  });
}
