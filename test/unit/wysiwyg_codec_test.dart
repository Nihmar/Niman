// T-WYS-02: the Markdown <-> Quill codec is byte-stable when nothing changed
// and preserves every construct it cannot represent.
import 'dart:convert';
import 'dart:io';

import 'package:copist/src/editor/wysiwyg/markdown_blocks.dart';
import 'package:copist/src/editor/wysiwyg/markdown_document_codec.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';

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
}
