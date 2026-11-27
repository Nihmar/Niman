// Tab and Shift+Tab in the source editor: a list item is moved where its list
// says, and anything that is only text — a line of code, maths or the
// frontmatter, a plain line — is moved by spaces, one the inverse of the other
// (#1335, #1345).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_editor.dart';
import 'package:niman/src/markdown/render/source_view_config.dart';
import 'package:niman/src/markdown/source_buffer.dart';

const MarkdownTheme _theme = MarkdownTheme(
  body: TextStyle(fontSize: 14, height: 1.5, fontFamily: 'monospace'),
  heading1: TextStyle(fontSize: 25),
  heading2: TextStyle(fontSize: 21),
  heading3: TextStyle(fontSize: 18),
  heading4: TextStyle(fontSize: 16),
  heading5: TextStyle(fontSize: 14),
  heading6: TextStyle(fontSize: 13),
  code: TextStyle(fontSize: 14, fontFamily: 'monospace'),
  quote: TextStyle(fontSize: 14),
  tableCell: TextStyle(fontSize: 14),
  tableHeader: TextStyle(fontSize: 14),
  link: TextStyle(fontSize: 14),
  wikilink: TextStyle(fontSize: 14),
  tag: TextStyle(fontSize: 14),
  marker: TextStyle(fontSize: 14),
  codeHighlight: <String, TextStyle>{},
  rule: Color(0xFF888888),
  codeBackground: Color(0xFFEEEEEE),
  quoteBar: Color(0xFFCCCCCC),
  tableBorder: Color(0xFFCCCCCC),
  markerDim: Color(0xFF999999),
  blockSpacing: 10,
  listIndentPerLevel: 22,
  quoteIndentPerLevel: 12,
  codePadding: 8,
  quoteBarWidth: 3,
  ruleThickness: 1,
  tableCellPadding: EdgeInsets.all(4),
  lineHeight: 21,
);

/// An editor of [text] with its caret at [at], started as its view starts
/// it and let go after the test. Nothing here has a view: whatever asks for
/// one fails the test.
SourceEditor _editor(
  String text, {
  SelectionModel at = const SelectionModel.at(0),
}) {
  final editor = SourceEditor(
    buffer: SourceBuffer.fromText(text),
    look: const SourceLook(theme: _theme),
    initialSelection: at,
    context: () => throw StateError('the core was asked for a view'),
  )..start();
  addTearDown(editor.dispose);
  return editor;
}

/// Where the `|` marks of [marked] are: one is a caret, two a selection.
SelectionModel _marks(String marked) {
  final marks = <int>[];
  var removed = 0;
  for (var at = 0; at < marked.length; at++) {
    if (marked[at] == '|') marks.add(at - removed++);
  }
  return SelectionModel(anchor: marks.first, extent: marks.last);
}

/// The note [marked] reads after Tab (or Shift+Tab), marked again.
String _press(String marked, {bool outdent = false}) {
  final editor = _editor(marked.replaceAll('|', ''), at: _marks(marked));
  if (outdent) {
    editor.typing.outdent();
  } else {
    editor.typing.indent();
  }
  final text = editor.buffer.text;
  final at = <int>{editor.selection.anchor, editor.selection.extent}.toList()
    ..sort();
  var result = text;
  for (var n = at.length - 1; n >= 0; n--) {
    result = result.replaceRange(at[n], at[n], '|');
  }
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('code, maths and the frontmatter are text (#1335)', () {
    test('Tab in a fence puts the spaces at the caret, nothing is nested', () {
      expect(
        _press('```\n1. a\n2. |b\n3. c\n```'),
        '```\n1. a\n2.   |b\n3. c\n```',
      );
    });

    test('Shift+Tab takes them back', () {
      expect(
        _press('```\n1. a\n2.   |b\n3. c\n```', outdent: true),
        '```\n1. a\n2. |b\n3. c\n```',
      );
    });

    test('a selection in a fence is indented line by line, verbatim', () {
      expect(
        _press('```\n|1. a\n2. b|\n3. c\n```'),
        '```\n  |1. a\n  2. b|\n3. c\n```',
      );
      expect(
        _press('```\n|  1. a\n  2. b|\n3. c\n```', outdent: true),
        '```\n|1. a\n2. b|\n3. c\n```',
      );
    });

    test('a bullet in a shell fence is not an item', () {
      expect(_press('```sh\n- a\n- |b\n```'), '```sh\n- a\n-   |b\n```');
    });

    test('display maths', () {
      expect(_press('\$\$\n- a\n- |b\n\$\$'), '\$\$\n- a\n-   |b\n\$\$');
      expect(
        _press('\$\$\n|1. a\n2. b|\n\$\$'),
        '\$\$\n  |1. a\n  2. b|\n\$\$',
      );
    });

    test('the frontmatter', () {
      expect(
        _press('---\ntags:\n- a\n- |b\n---\ntext'),
        '---\ntags:\n- a\n-   |b\n---\ntext',
      );
      expect(
        _press('---\ntags:\n|- a\n- b|\n---\ntext'),
        '---\ntags:\n  |- a\n  - b|\n---\ntext',
      );
    });

    test('a selection from prose into a fence is text, whatever it holds', () {
      expect(
        _press('|1. a\n2. b\n```\n3. c|\n```'),
        '  |1. a\n  2. b\n  ```\n  3. c|\n```',
      );
    });

    test('a list item outside the fence still nests', () {
      expect(_press('- a\n- |b\n```\n- c\n```'), '- a\n  - |b\n```\n- c\n```');
    });
  });

  group('a plain line: Tab and Shift+Tab are inverses (#1345)', () {
    for (final marked in <String>[
      'foo|',
      '|foo',
      'fo|o',
      '  fo|o',
      '  |foo',
      'a b| c',
    ]) {
      test(marked, () {
        final tabbed = _press(marked);
        expect(tabbed, isNot(marked));
        expect(_press(tabbed, outdent: true), marked);
      });
    }

    test(
      'Shift+Tab with no spaces before the caret takes the leading ones',
      () {
        expect(_press('    fo|o', outdent: true), '  fo|o');
      },
    );

    test('Shift+Tab never takes anything but spaces', () {
      expect(_press('\tfo|o', outdent: true), '\tfo|o');
    });

    test('blank lines of a selection are not padded', () {
      expect(_press('|a\n\nb|'), '  |a\n\n  b|');
      expect(_press('|a\n  \nb|'), '  |a\n  \n  b|');
    });
  });
}
