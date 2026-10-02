// The block scanner against CommonMark (package:markdown), line by line:
// a report, not a gate yet — the containers' rework that makes the two
// agree is in progress (docs/dev/block-scanner-containers.md).
//
// Every content line carries a word of its own (`w17`), found again in the
// reference's tree: its leaf (text, code, heading), the list items around
// it and the quotes. A quote is one block to the scanner, its inside
// scanned again on its own, so inside one only the quotes and the items
// outside them are compared. Each document that differs is shrunk to the
// fewest lines that still differ, and the shrunk ones are printed, shortest
// first.
//
// Off by default: `NIMAN_SCANNER_DIFF=1 flutter test
// test/unit/block_scanner_commonmark_test.dart` (`--dart-define=SEED=n`
// for another sample).
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Where a line's words are: its leaf, the items around it, the quotes.
typedef Where = ({String kind, int list, int quote});

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
        // A quote is one block to the scanner, its inside scanned again on
        // its own: what counts is the quotes, and the items outside them.
        final firstQuote = path.indexOf('blockquote');
        final outside = firstQuote < 0 ? path : path.sublist(0, firstQuote);
        final kind = firstQuote >= 0
            ? 'quoted'
            : path.contains('pre')
            ? 'code'
            : path.any((t) => RegExp(r'^h[1-6]$').hasMatch(t))
            ? 'heading'
            : 'text';
        out[token.group(0)!] = (
          kind: kind,
          list: outside.where((t) => t == 'li').length - 1,
          quote: path.where((t) => t == 'blockquote').length,
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
  final buffer = SourceBuffer.fromText(lines.join('\n'));
  final scanner = BlockScanner(buffer);
  final out = <String, Where>{};
  for (var i = 0; i < lines.length; i++) {
    final token = _token.firstMatch(lines[i])?.group(0);
    if (token == null) continue;
    final block = scanner.blockAt(i)!;
    final kind = block.quoteDepth > 0
        ? 'quoted'
        : switch (block.kind) {
            BlockKind.fencedCode || BlockKind.indentedCode => 'code',
            BlockKind.heading => 'heading',
            BlockKind.paragraph ||
            BlockKind.listItem ||
            BlockKind.quote => 'text',
            _ => block.kind.name,
          };
    out[token] = (kind: kind, list: block.listDepth, quote: block.quoteDepth);
  }
  return out;
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

void main() {
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
    final keys = found.keys.toList()
      ..sort((a, b) => a.length.compareTo(b.length));
    for (final key in keys) {
      print('== ${key.replaceAll(' ', '·')}   ${found[key]}');
    }
  });
}
