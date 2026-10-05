// The block scanner against CommonMark (package:markdown), line by line:
// a report, not a gate yet — the containers' rework that makes the two
// agree is in progress (docs/dev/block-scanner-containers.md).
//
// ignore_for_file: avoid_print
//
// Every content line carries a word of its own (`w17`), found again in the
// reference's tree: its leaf (text, code, heading) and the path of list
// items and quotes around it, in order (`LQL` is an item in a quote in an
// item). The scanner's side is read the way the app reads a note: a quote
// is one block, whose marks `BlockParser.contentText` takes off and whose
// inside is scanned again on its own (`BlockView._quoteContent`,
// `live_quote_content.dart`) — so a quote's own depth is its first line's,
// and what is nested further in is the inner scan's to find. Each document
// that differs is shrunk to the fewest lines that still differ, and the
// shrunk ones are printed, shortest first.
//
// Off by default: `NIMAN_SCANNER_DIFF=1 flutter test
// test/unit/block_scanner_commonmark_test.dart` (`--dart-define=SEED=n`
// for another sample).
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Where a line's words are: its leaf, and the items (`L`) and quotes (`Q`)
/// around it, outermost first.
typedef Where = ({String kind, String path});

const _forms = [
  '',
  'W',
  '- W',
  '* W',
  '1. W',
  '2) W',
  '> W',
  '> - W',
  '# W',
  '```',
  '---',
];
const _indents = [0, 0, 0, 2, 3, 4, 6];
final RegExp _token = RegExp(r'w\d+');

Map<String, Where> _reference(List<String> lines) {
  final doc = md.Document(
    encodeHtml: false,
    extensionSet: md.ExtensionSet.commonMark,
  );
  final nodes = doc.parseLines(lines);
  final out = <String, Where>{};
  void walk(md.Node node, List<String> path) {
    if (node is md.Text) {
      for (final token in _token.allMatches(node.text)) {
        final kind = path.contains('pre')
            ? 'code'
            : path.any((t) => RegExp(r'^h[1-6]$').hasMatch(t))
            ? 'heading'
            : 'text';
        out[token.group(0)!] = (
          kind: kind,
          path: [
            for (final tag in path)
              if (tag == 'li') 'L' else if (tag == 'blockquote') 'Q',
          ].join(),
        );
      }
    } else if (node is md.Element) {
      for (final child in node.children ?? const <md.Node>[]) {
        walk(child, [...path, node.tag]);
      }
    }
  }

  for (final node in nodes) {
    walk(node, const []);
  }
  return out;
}

Map<String, Where> _scanner(List<String> lines) {
  final out = <String, Where>{};
  _scanInto(lines.join('\n'), '', out);
  return out;
}

/// Scans [text], whose containers outside it are [outer], into [out]: a
/// quote block's inside scanned again, as the app draws it.
void _scanInto(String text, String outer, Map<String, Where> out) {
  final buffer = SourceBuffer.fromText(text);
  for (final block in BlockScanner(buffer).index.blocks) {
    final path = outer + 'L' * (block.listDepth + 1) + 'Q' * block.quoteDepth;
    if (block.quoteDepth > 0) {
      final raw = BlockParser.blockText(block, buffer);
      _scanInto(BlockParser.contentText(block, raw), path, out);
      continue;
    }
    final kind = switch (block.kind) {
      BlockKind.fencedCode || BlockKind.indentedCode => 'code',
      BlockKind.heading => 'heading',
      BlockKind.paragraph || BlockKind.listItem => 'text',
      _ => block.kind.name,
    };
    for (var line = block.startLine; line < block.endLine; line++) {
      for (final token in _token.allMatches(buffer.lineAt(line))) {
        out[token.group(0)!] = (kind: kind, path: path);
      }
    }
  }
}

String? _differs(List<String> lines) {
  final want = _reference(lines);
  final got = _scanner(lines);
  final diffs = [
    for (final token in got.keys)
      if (want[token] != got[token])
        '$token: want ${want[token]} got ${got[token]}',
  ];
  return diffs.isEmpty ? null : diffs.join('; ');
}

/// Whether the run asked for the report.
final bool _asked = Platform.environment['NIMAN_SCANNER_DIFF'] == '1';

/// The shapes `docs/dev/block-scanner-indent-model.md` pins, each with the
/// reason it is there; [_pending] marks the ones the model is for.
const List<(String, String)> _shapes = [
  ('a `>` past the item content opens a quote in it', '> - w\n    > w'),
  ('a `>` short of it is the item text', '> - w\n  > w'),
  ('a `>` under a quote with no item is text', '> w\n    > w'),
  ('a quote run nests on its own markers', '> w\n> > w'),
  ('an indented quote keeps a line in it', '  > w\n    w'),
  ('a quote block is the quote, not the items in it', '> - w'),
  ('a quote at the margin closes the item it leaves', '* w\n  > w\n> w'),
  ('a second indented line under a quote is code', '> w\n    w\n    w'),
  ('one indented line under a quote stays in it', '> w\n    w'),
  (
    'indented code in an item is measured from its marker',
    '  1. w\n      ---\n    w',
  ),
  ('the same for an ordered marker with a paren', '  2) w\n      ---\n    w'),
  (
    'a dedented marker opens a sublist of the item',
    '  1. w\n      - w\n    * w',
  ),
  ('indented code in an item after a fence', '  1. w\n      ```\n    w'),
  (
    'a fence closed short of the item leaves code behind it',
    '1. w\n   ```\n```\nw',
  ),
  ('an item after a closed fence and its sublist', '* w\n  ```\n* w\n  * w'),
];

/// The shapes the scanner does not read yet: what the rewrite is for.
const Set<int> _pending = <int>{9, 10, 11, 12, 13};

void main() {
  group('the indentation model', () {
    for (var at = 0; at < _shapes.length; at++) {
      final (name, text) = _shapes[at];
      test(
        name,
        skip: _pending.contains(at) ? 'phase 3 of the plan' : null,
        () {
          var w = 0;
          final lines = [
            for (final line in text.split('\n'))
              line.replaceAllMapped('w', (_) => 'w${w++}'),
          ];
          expect(_scanner(lines), _reference(lines));
        },
      );
    }
  });

  test('the scanner reads containers as CommonMark does', skip: !_asked, () {
    final random = math.Random(
      int.parse(const String.fromEnvironment('SEED', defaultValue: '1')),
    );
    final found = <String, String>{};
    var docs = 0;
    for (var n = 0; n < 40000; n++) {
      final count = 2 + random.nextInt(5);
      var w = 0;
      final lines = [
        for (var i = 0; i < count; i++)
          ' ' * _indents[random.nextInt(_indents.length)] +
              _forms[random.nextInt(_forms.length)].replaceFirst(
                'W',
                'w${w++}',
              ),
      ];
      if (lines.first.trim() == '---') continue;
      if (_differs(lines) == null) continue;
      docs++;
      // Shrink: drop lines while it still differs.
      var small = lines;
      for (var changed = true; changed;) {
        changed = false;
        for (var i = 0; i < small.length && small.length > 1; i++) {
          final fewer = [...small]..removeAt(i);
          if (fewer.first.trim() != '---' && _differs(fewer) != null) {
            small = fewer;
            changed = true;
            break;
          }
        }
      }
      final key = small.map((l) => l.replaceAll(_token, 'w')).join(r'\n');
      found.putIfAbsent(key, () => _differs(small)!);
    }
    print('docs differing: $docs / 40000, minimal: ${found.length}');
    // The classes: each minimal repro's first difference, without its word.
    final classes = <String, int>{};
    for (final diff in found.values) {
      final first = diff.split('; ').first.replaceFirst(_token, 'w');
      classes[first] = (classes[first] ?? 0) + 1;
    }
    final ranked = classes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in ranked) {
      print('class ${entry.value}: ${entry.key}');
    }
    final keys = found.keys.toList()
      ..sort((a, b) => a.length.compareTo(b.length));
    for (final key in keys) {
      print('== ${key.replaceAll(' ', '·')}   ${found[key]}');
    }
  });
}
