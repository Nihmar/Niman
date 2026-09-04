import 'package:copist/src/editor/highlighting.dart';
import 'package:copist/src/editor/outline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects headings with level, line and text', () {
    final doc = HighlightDocument.fromText('# Title\n\nplain\n## Sub\nbody');
    final o = outlineOf(doc.lines);
    expect(o, hasLength(2));
    expect(o[0].line, 0);
    expect(o[0].level, 1);
    expect(o[0].text, 'Title');
    expect(o[1].line, 3);
    expect(o[1].level, 2);
    expect(o[1].text, 'Sub');
  });

  test('a # line inside a code fence is not a heading', () {
    final doc = HighlightDocument.fromText(
      '```\n# not a heading\n```\n# Real',
    );
    final o = outlineOf(doc.lines);
    expect(o, hasLength(1));
    expect(o[0].line, 3);
    expect(o[0].text, 'Real');
  });

  test('a # with no following space is not a heading', () {
    final doc = HighlightDocument.fromText('#tag\n# real');
    final o = outlineOf(doc.lines);
    expect(o, hasLength(1));
    expect(o[0].line, 1);
    expect(o[0].text, 'real');
  });

  test('up to six hashes; seven is not a heading', () {
    final doc = HighlightDocument.fromText('###### six\n####### seven');
    final o = outlineOf(doc.lines);
    expect(o, hasLength(1));
    expect(o[0].level, 6);
    expect(o[0].text, 'six');
  });

  test('no headings in plain text', () {
    final doc = HighlightDocument.fromText('just text\nmore text');
    expect(outlineOf(doc.lines), isEmpty);
  });
}
