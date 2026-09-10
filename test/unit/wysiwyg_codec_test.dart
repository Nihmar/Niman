// T-WYS-02: the Markdown <-> Quill codec is byte-stable when nothing changed
// and preserves every construct it cannot represent.
import 'dart:convert';
import 'dart:io';

import 'package:copist/src/editor/wysiwyg/markdown_blocks.dart';
import 'package:copist/src/editor/wysiwyg/markdown_document_codec.dart';
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
