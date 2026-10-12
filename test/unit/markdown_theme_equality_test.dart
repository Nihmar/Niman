// #789: `MarkdownTheme`'s `==` and `hashCode` are what tell a surface its
// theme still stands (#722, #745). A field they leave out is a change the
// surfaces never see — a table kept measured in a face it is no longer
// drawn in. Every field the constructor takes is flipped here, one at a
// time, and must make the theme another one.
//
// The fields are read through [_Theme.pick], which records each name: a
// field added to the constructor is required, so it has to be added to
// [_Theme.build] to compile, and taking it through `pick` like the rest
// puts it in the flips below without a second list to forget.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';

/// Builds the theme with every field set, [flip] (a field's name) set to
/// another value.
final class _Theme {
  new([this.flip]);

  final String? flip;

  /// The names [pick] was asked for.
  final Set<String> fields = {};

  T pick<T>(String name, T value, T other) {
    fields.add(name);
    return name == flip ? other : value;
  }

  TextStyle style(String name) =>
      pick(name, const TextStyle(fontSize: 14), const TextStyle(fontSize: 15));

  Color color(String name) =>
      pick(name, const Color(0xFF111111), const Color(0xFF222222));

  double number(String name) => pick(name, 4, 5);

  MarkdownTheme build() => MarkdownTheme(
    body: style('body'),
    heading1: style('heading1'),
    heading2: style('heading2'),
    heading3: style('heading3'),
    heading4: style('heading4'),
    heading5: style('heading5'),
    heading6: style('heading6'),
    code: style('code'),
    quote: style('quote'),
    tableCell: style('tableCell'),
    tableHeader: style('tableHeader'),
    link: style('link'),
    wikilink: style('wikilink'),
    tag: style('tag'),
    marker: style('marker'),
    rule: color('rule'),
    codeHighlight: pick(
      'codeHighlight',
      const <String, TextStyle>{'keyword': TextStyle(fontSize: 14)},
      const <String, TextStyle>{'keyword': TextStyle(fontSize: 15)},
    ),
    codeBackground: color('codeBackground'),
    quoteBar: color('quoteBar'),
    tableBorder: color('tableBorder'),
    markerDim: color('markerDim'),
    highlight: color('highlight'),
    blockSpacing: number('blockSpacing'),
    listIndentPerLevel: number('listIndentPerLevel'),
    quoteIndentPerLevel: number('quoteIndentPerLevel'),
    codePadding: number('codePadding'),
    quoteBarWidth: number('quoteBarWidth'),
    ruleThickness: number('ruleThickness'),
    tableCellPadding: pick(
      'tableCellPadding',
      const EdgeInsets.all(4),
      const EdgeInsets.all(5),
    ),
    lineHeight: number('lineHeight'),
  );
}

void main() {
  test('two themes of the same values are one, hash included', () {
    final a = _Theme().build();
    final b = _Theme().build();
    expect(identical(a, b), isFalse);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('every field the theme has makes it another theme', () {
    final probe = _Theme()..build();
    final base = _Theme().build();
    // The constructor's 30 today: a new one changes the count here too.
    expect(probe.fields, hasLength(30), reason: 'every field taken');
    for (final field in probe.fields) {
      final flipped = _Theme(field).build();
      expect(
        flipped == base,
        isFalse,
        reason: '`==` leaves out $field: a change of it goes unseen',
      );
    }
  });
}
