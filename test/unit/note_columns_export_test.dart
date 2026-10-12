// A note's columns as an export writes them (#729,
// `docs/records/note-columns.md`, "The other surfaces"): the HTML page,
// whose CSS lays them out as the app does, and a golden of one page.
//
// `NIMAN_UPDATE_GOLDEN=1` writes the golden again from what the code
// writes, for a change that means to change it.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/html_page.dart';
import 'package:niman/src/export/note_html.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

String _body(String text) =>
    NoteHtml(NoteHtmlSource(text: text, title: 't')).body();

void main() {
  test('the columns are a flex row of divs, each growing by its share', () {
    final html = _body(
      ':::: columns\n::: {.column width="40%"}\nLeft\n:::\n'
      '::: column\nRight\n:::\n::::\n',
    );
    expect(
      html,
      contains(
        '<div class="columns">\n'
        '<div class="column" style="flex-grow:40">\n<p>Left</p>\n</div>\n'
        '<div class="column" style="flex-grow:60">\n<p>Right</p>\n</div>\n'
        '</div>\n',
      ),
    );
  });

  test('three equal columns share a third each', () {
    final html = _body(
      ':::: columns\n::: column\na\n:::\n::: column\nb\n:::\n'
      '::: column\nc\n:::\n::::\n',
    );
    expect('flex-grow:33.3333'.allMatches(html).length, 3);
  });

  test("an unknown div's fences are the text they are", () {
    final html = _body('::: warning\nCareful.\n:::\n');
    expect(html, contains('<p>::: warning\nCareful.\n:::</p>'));
  });

  test("the page's CSS is the app's rule, and lets a block cross a page", () {
    expect(pageStyle, contains('.columns { display: flex; flex-wrap: wrap; '));
    expect(pageStyle, contains('gap: 1.5em;'));
    expect(
      pageStyle,
      contains('.column { flex: 1 1 0; min-width: min(16em, 100%); }'),
    );
    // Only the outermost level sits side by side: a deeper one stacks.
    expect(pageStyle, contains('.column .columns { flex-direction: column; }'));
    final print = pageStyle.substring(pageStyle.indexOf('@media print'));
    expect(print, isNot(contains('.columns')));
  });

  test('the golden page', () {
    final dir = p.join('test', 'fixtures', 'columns');
    final text = File(p.join(dir, 'columns.md')).readAsStringSync();
    final html = _body(text);
    // The page is XHTML too, as an EPUB's chapters are.
    expect(() => XmlDocument.parse('<div>$html</div>'), returnsNormally);
    final golden = File(p.join(dir, 'columns.html'));
    if (Platform.environment['NIMAN_UPDATE_GOLDEN'] == '1') {
      golden.writeAsStringSync(html);
    }
    expect(html, golden.readAsStringSync().replaceAll('\r\n', '\n'));
  });
}
