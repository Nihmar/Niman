// T-WYS-02: the Markdown <-> Quill codec is byte-stable when nothing changed
// and preserves every construct it cannot represent.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/wysiwyg/markdown_blocks.dart';
import 'package:niman/src/editor/wysiwyg/markdown_document_codec.dart';

void main() {
  const codec = MarkdownDocumentCodec();

  test('an unedited note round-trips byte for byte over spec.json', () {
    final examples = (jsonDecode(
      File('test/spec.json').readAsStringSync(),
    ) as List<dynamic>).cast<Map<String, dynamic>>();
    final failures = <String>[];
    for (final example in examples) {
      final source = example['markdown'] as String;
      final decoded = codec.decode(source);
      final back = codec.encode(decoded.document, decoded: decoded);
      if (back != source) {
        failures.add('#${example['example']}');
      }
    }
    expect(
      failures,
      isEmpty,
      reason:
          'codec changed ${failures.length} notes: '
          '${failures.take(20).join(', ')}',
    );
  });

  test('every construct the app adds survives untouched', () {
    const note = r'''
---
id: 1
title: Note
---

# Heading

A paragraph with **bold** and *italic*.

- [x] done
- [ ] pending

| A | B |
| --- | --- |
| 1 | 2 |

A footnote[^n].

[^n]: The note.

Math $x^2$ and $$y^2$$.

A [[wikilink]] and an ![[embed.png]].
''';
    final decoded = codec.decode(note);
    expect(codec.encode(decoded.document, decoded: decoded), note);
  });

  test('an empty note decodes to one empty line and stays empty', () {
    // Quill refuses an empty document; without the guard this threw and the
    // release build showed the grey ErrorWidget (device report, 2026-09-11).
    final decoded = codec.decode('');
    expect(decoded.document.toPlainText(), '\n');
    expect(codec.encode(decoded.document, decoded: decoded), '');
  });

  test('a blank note decodes without throwing', () {
    final decoded = codec.decode('\n');
    expect(codec.encode(decoded.document, decoded: decoded), '\n');
  });

  test('a code block keeps its lines inside the fence', () {
    const note = '~~~dart\nvoid main() {}\nprint(1);\n~~~\n';
    final decoded = codec.decode(note);
    final ops = decoded.document.toDelta().toJson();
    // Every code line carries the attribute on its newline: without it the
    // code sat outside the block and the next edit moved it out of the
    // fence (device report, 2026-09-11).
    expect(
      (ops[1]['attributes'] as Map<Object?, Object?>?)?['code-block'],
      isTrue,
    );
    expect(
      (ops[3]['attributes'] as Map<Object?, Object?>?)?['code-block'],
      isTrue,
    );
    final controller = quill.QuillController(
      document: decoded.document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    addTearDown(controller.dispose);
    controller.replaceText(
      0,
      0,
      '// ',
      const TextSelection.collapsed(offset: 3),
    );
    expect(
      codec.encode(controller.document),
      '~~~dart\n// void main() {}\nprint(1);\n~~~\n',
    );
  });

  test('an empty code block still has its line', () {
    final decoded = codec.decode('~~~\n~~~\n');
    expect(codec.encode(decoded.document, decoded: decoded), '~~~\n~~~\n');
    final ops = decoded.document.toDelta().toJson();
    expect(
      (ops.first['attributes'] as Map<Object?, Object?>?)?['code-block'],
      isTrue,
    );
  });

  test('an empty code block is dropped on the next write', () {
    // The code button on an empty line left pairs of stray markers in the
    // note (device report, 2026-09-11).
    final decoded = codec.decode('a\n\n~~~\n~~~\n');
    final controller = quill.QuillController(
      document: decoded.document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    addTearDown(controller.dispose);
    controller.replaceText(0, 0, 'X', const TextSelection.collapsed(offset: 1));
    expect(codec.encode(controller.document), 'Xa\n\n');
  });

  test('a code block with blank lines keeps them inside the fence', () {
    final decoded = codec.decode('a\n\n~~~\n\ncode\n~~~\n');
    final controller = quill.QuillController(
      document: decoded.document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    addTearDown(controller.dispose);
    controller.replaceText(0, 0, 'X', const TextSelection.collapsed(offset: 1));
    expect(codec.encode(controller.document), 'Xa\n\n~~~\n\ncode\n~~~\n');
  });

  test('the blank lines between blocks survive', () {
    final decoded = codec.decode('a\n\n\nb\n');
    expect(decoded.document.toPlainText(), 'a\n\n\nb\n');
    expect(codec.encode(decoded.document, decoded: decoded), 'a\n\n\nb\n');
  });

  test('an edit keeps the blank lines', () {
    final decoded = codec.decode('a\n\n\nb\n');
    final controller = quill.QuillController(
      document: decoded.document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    addTearDown(controller.dispose);
    controller.replaceText(0, 0, 'X', const TextSelection.collapsed(offset: 1));
    expect(codec.encode(controller.document), 'Xa\n\n\nb\n');
  });

  test('the splitter marks unrepresentable blocks opaque', () {
    final blocks = splitMarkdownBlocks(
      '# H\n'
      '\n'
      '| A | B |\n'
      '| --- | --- |\n'
      '| 1 | 2 |\n',
    );
    expect(blocks, hasLength(2));
    expect(blocks[0].tag, 'h1');
    expect(blocks[0].opaque, isFalse);
    expect(blocks[1].tag, 'table');
    expect(blocks[1].opaque, isTrue);
  });

  test('an edit keeps every opaque block byte for byte', () {
    const note = r'''
# Heading

A paragraph.

| A | B |
| --- | --- |
| 1 | 2 |

Math $x^2$.

A [[wikilink]].
''';
    final decoded = codec.decode(note);
    final controller = quill.QuillController(
      document: decoded.document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    addTearDown(controller.dispose);
    // Edit the supported heading only.
    controller.replaceText(
      0,
      0,
      'Edited ',
      const TextSelection.collapsed(offset: 7),
    );
    final out = codec.encode(controller.document);
    expect(out, contains('# Edited Heading'));
    expect(out, contains('| A | B |\n| --- | --- |\n| 1 | 2 |\n'));
    expect(out, contains(r'Math $x^2$.'));
    expect(out, contains('A [[wikilink]].'));
  });

  test('an edited document serializes canonically', () {
    final document = quill.Document.fromJson(<Map<String, dynamic>>[
      <String, dynamic>{'insert': 'Edited '},
      <String, dynamic>{'insert': 'Heading'},
      <String, dynamic>{
        'insert': '\n',
        'attributes': <String, dynamic>{'header': 1},
      },
      <String, dynamic>{'insert': 'A '},
      <String, dynamic>{
        'insert': 'bold',
        'attributes': <String, dynamic>{'bold': true},
      },
      <String, dynamic>{'insert': ' line'},
      <String, dynamic>{'insert': '\n'},
    ]);
    final out = codec.encode(document);
    expect(out, contains('# Edited Heading'));
    expect(out, contains('A **bold** line'));
  });

  group('a loose list survives an edit', () {
    /// What [source] comes back as after the document was touched — the
    /// byte-stability guard is skipped, so this is what a save writes.
    String edited(String source) => codec.encode(codec.decode(source).document);

    test('its checkboxes are kept', () {
      // A loose list wraps each item's content in a paragraph and puts
      // the checkbox inside it, so the box was not found where a tight
      // list keeps it, and `- [x] done` was written back as `- done`.
      expect(edited('- a\n\n- [x] done\n'), '- a\n\n- [x] done\n');
      expect(
        edited('- [x] done\n\n- [ ] open\n'),
        '- [x] done\n\n- [ ] open\n',
      );
    });

    test('its blank lines are kept, and only where they were', () {
      // A blank line between two items is what makes the list loose; the
      // AST says a list is loose but not where, so they are counted in
      // the source. Tightening them on save both reflowed the list and
      // glued a list under another one to it.
      expect(edited('- a\n\n- b\n\n- c\n'), '- a\n\n- b\n\n- c\n');
      expect(edited('- a\n- b\n\n- c\n'), '- a\n- b\n\n- c\n');
      expect(edited('- a\n- b\n'), '- a\n- b\n');
    });

    test('an ordered one keeps its numbers across the blank lines', () {
      expect(edited('1. a\n\n2. b\n\n3. c\n'), '1. a\n\n2. b\n\n3. c\n');
    });

    test('an item whose content looks like a marker claims nothing', () {
      // The markers found have to be the items parsed, or a blank line
      // would land in the wrong gap: the old behaviour is the fallback.
      const note = '- a\n\n  ~~~\n  - not an item\n  ~~~\n\n- b\n';
      expect(edited(note), isNot(contains('- not an item\n\n')));
    });
  });

  group('an ordered list keeps its numbers', () {
    String edited(String source) => codec.encode(codec.decode(source).document);

    test('counting, instead of writing 1. down every item', () {
      // Device report, 2026-09-18: a numbered list came back all 1s.
      expect(edited('1. a\n2. b\n3. c\n'), '1. a\n2. b\n3. c\n');
    });

    test('including the number it starts at', () {
      // This one was not cosmetic: 3. 4. came back as 1. 1. and then
      // rendered 1. 2., two numbers lower than it was written.
      expect(edited('3. a\n4. b\n'), '3. a\n4. b\n');
      expect(edited('10. a\n11. b\n'), '10. a\n11. b\n');
    });

    test('a list of its own after prose starts over', () {
      expect(edited('1. a\n\nprose\n\n1. b\n'), '1. a\n\nprose\n\n1. b\n');
    });

    test('a bulleted list before it does not feed it a number', () {
      expect(edited('- x\n\n1. a\n2. b\n'), '- x\n\n1. a\n2. b\n');
    });

    test('a list written all 1s is counted instead', () {
      // The one style this changes. Both render the same - CommonMark
      // numbers from the first marker and ignores the rest - and the
      // Delta has room for where a list starts, not for each item's
      // own number. Counting is what the report asked for.
      expect(edited('1. a\n1. b\n1. c\n'), '1. a\n2. b\n3. c\n');
    });
  });
}
