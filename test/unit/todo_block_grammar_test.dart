// The colours of a `todo` fence's source (#1152): the keys it knows, the keys
// it does not, and the values; the same for the read view, `live` and the
// export, which all colour through the one highlighter.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/html_blocks.dart';
import 'package:niman/src/markdown/render/code_themes.dart';
import 'package:niman/src/preview/code_highlight.dart';

void main() {
  const highlighter = CodeHighlighter(
    language: 'todo',
    theme: atomOneDarkTheme,
  );

  /// The colour [text] is drawn in on [line] of the coloured block.
  Color? colourOf(
    List<List<CodeRun>> lines,
    int line,
    String source,
    String text,
  ) {
    final at = source.split('\n')[line].indexOf(text);
    final run = lines[line].firstWhere(
      (run) => run.start <= at && at < run.end,
    );
    return run.style.color;
  }

  const source =
      'link: any\n'
      'prio: A\n'
      'due: <=+7d\n'
      'link: [[Repairs]]';
  final lines = highlighter.lines(source);

  test('a known key, an unknown key and a value are three colours', () {
    final key = colourOf(lines, 0, source, 'link');
    final unknown = colourOf(lines, 1, source, 'prio');
    final value = colourOf(lines, 0, source, 'any');
    expect(key, atomOneDarkTheme['attr']!.color);
    expect(unknown, atomOneDarkTheme['deletion']!.color);
    expect(value, atomOneDarkTheme['string']!.color);
    expect({key, unknown, value}, hasLength(3));
  });

  test('the colon is plain text', () {
    final colon = colourOf(lines, 0, source, ':');
    expect(colon, atomOneDarkTheme['root']!.color);
  });

  test('a date and a [[Note]] are set apart in a value', () {
    expect(
      colourOf(lines, 2, source, '<=+7d'),
      atomOneDarkTheme['number']!.color,
    );
    expect(
      colourOf(lines, 3, source, '[[Repairs]]'),
      atomOneDarkTheme['link']!.color,
    );
  });

  test('keys are known in any case', () {
    final upper = highlighter.lines('Project: house');
    expect(
      colourOf(upper, 0, 'Project: house', 'Project'),
      atomOneDarkTheme['attr']!.color,
    );
  });

  test('the export colours it the same way', () {
    final html = fencedCodeHtml(<String>[
      '```todo',
      'link: any',
      'prio: A',
      '```',
    ]);
    expect(html, contains('<span class="hljs-attr">link</span>'));
    expect(html, contains('<span class="hljs-deletion">prio</span>'));
  });
}
