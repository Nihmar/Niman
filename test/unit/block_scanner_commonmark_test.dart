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
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/block_tree.dart';
import 'package:niman/src/markdown/footnote_syntax.dart';
import 'package:niman/src/markdown/line_syntax.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Where a line's words are: its leaf, and the items (`L`) and quotes (`Q`)
/// around it, outermost first.
typedef Where = ({String kind, String path});

/// The lines documents are made of, `W` standing for a word of its own:
/// the containers in their forms — bullets and numbers, empty items, a
/// container right after a marker — and the blocks that end or interrupt
/// them.
const _forms = [
  '',
  'W',
  '- W',
  '* W',
  '+ W',
  '1. W',
  '2) W',
  '10. W',
  '-',
  '1.',
  '- - W',
  '- > W',
  '- # W',
  '- ```',
  '> W',
  '>W',
  '>',
  '> - W',
  '# W',
  '```',
  '~~~',
  '---',
  '* * *',
  '===',
  '| W | x |',
  '|---|---|',
  '<div>',
  '<!-- W -->',
  '[^f]: W',
  '[^f]:',
  '[r]: /u',
  '[r]:',
  '/u "t"',
];

/// What a line is indented with: mostly nothing, then spaces either side
/// of an item's content columns.
const _indents = ['', '', '', '  ', '   ', '    ', '      '];

/// The same in tabs, for a document indented as Obsidian writes one.
const _tabs = ['', '', '', '\t', '\t', '\t\t'];
final RegExp _token = RegExp(r'w\d+');
final RegExp _heading = RegExp(r'^h[1-6]$');

/// The text of an HTML block, as the package writes it: from a line break,
/// then its line as it stood.
final RegExp _htmlText = RegExp(r'^\n *<');

/// What the parser makes of each word of [lines]: a whole note, its
/// footnote [cited] so that the parser keeps the definition, or a block the
/// read view hands it alone.
Map<String, Where> _reference(List<String> lines, {bool cited = true}) {
  final doc = md.Document(
    encodeHtml: false,
    extensionSet: md.ExtensionSet.gitHubFlavored,
  );
  // The footnote is cited, or the parser drops its definition — first, so
  // that nothing the document leaves open takes the citation.
  final nodes = doc.parseLines(cited ? ['z[^f]', '', ...lines] : lines);
  final out = <String, Where>{};
  void walk(md.Node node, List<String> path) {
    if (node is md.Text) {
      for (final token in _token.allMatches(node.text)) {
        // An HTML block is a text node of its own, outside any paragraph,
        // and starts with its tag.
        // A footnote's last block is wrapped in a paragraph for its link
        // back, an HTML block too; the package's HTML block text starts
        // with a line break.
        final html =
            _htmlText.hasMatch(node.text) ||
            node.text.trimLeft().startsWith('<') &&
                !path.any(
                  (t) =>
                      t == 'p' ||
                      t == 'td' ||
                      t == 'th' ||
                      _heading.hasMatch(t),
                );
        final kind = path.contains('pre')
            ? 'code'
            : path.contains('table')
            ? 'table'
            : html
            ? 'html'
            : path.any(_heading.hasMatch)
            ? 'heading'
            : 'text';
        out[token.group(0)!] = (
          kind: kind,
          path: [
            for (final tag in path)
              if (tag == 'li')
                'L'
              else if (tag == 'blockquote')
                'Q'
              else if (tag == 'footnote')
                'F',
          ].join(),
        );
      }
    } else if (node is md.Element) {
      for (final child in node.children ?? const <md.Node>[]) {
        // A footnote's `li` is the footnote, not an item.
        walk(child, [
          ...path,
          if (node.footnoteLabel != null) 'footnote' else node.tag,
        ]);
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
  _scanInto(lines.join('\n'), '', out, 0);
  return out;
}

/// [raw], the text of [block], in the coordinates of the container it
/// stands in: each line without what [BlockParser.linePrefixLength] says
/// its containers take off it — the reading the package's parse was given.
String _contentText(Block block, String raw) {
  final lines = raw.split('\n');
  final first = lines.first;
  for (var at = 0; at < lines.length; at++) {
    final line = lines[at];
    lines[at] = line.substring(
      BlockParser.linePrefixLength(
        block,
        line,
        BlockParser.listStripOf(block, first, at, line),
      ),
    );
  }
  return lines.join('\n');
}

/// Scans [text], whose containers outside it are [outer], into [out], the
/// way the app draws it: a quote block's inside scanned again
/// (`BlockView._quoteContent`), a block of inline content — a paragraph, a
/// heading, an item — parsed by the package from the text the block parser
/// gives it (`BlockParser.contentText`), and code, HTML and tables taken as
/// the scanner says, since the read view draws those itself.
void _scanInto(String text, String outer, Map<String, Where> out, int depth) {
  final buffer = SourceBuffer.fromText(text);
  for (final block in BlockScanner(buffer).index.blocks) {
    final raw = BlockParser.blockText(block, buffer);
    // A footnote's blocks are drawn in the footnotes, not where they stand.
    final at = block.footnote == 0 ? outer : '${outer}F';
    if (block.quoteDepth > 0) {
      final path = at + 'L' * (block.listDepth + 1) + 'Q' * block.quoteDepth;
      // As deep as the read view reads quotes inside quotes.
      if (depth < 8) {
        _scanInto(_contentText(block, raw), path, out, depth + 1);
      }
      continue;
    }
    switch (block.kind) {
      case BlockKind.paragraph || BlockKind.heading || BlockKind.listItem:
        // An item's own block parses as the item, `L` and all.
        final content = _contentText(block, raw);
        final items = block.kind == BlockKind.listItem
            ? block.listDepth
            : block.listDepth + 1;
        for (final MapEntry(:key, :value) in _reference(
          content.split('\n'),
          cited: false,
        ).entries) {
          out[key] = (kind: value.kind, path: at + 'L' * items + value.path);
        }
      case BlockKind.fencedCode ||
          BlockKind.indentedCode ||
          BlockKind.html ||
          BlockKind.table ||
          BlockKind.math ||
          BlockKind.frontmatter ||
          BlockKind.thematicBreak ||
          BlockKind.blank ||
          BlockKind.quote:
        final kind = switch (block.kind) {
          BlockKind.fencedCode || BlockKind.indentedCode => 'code',
          _ => block.kind.name,
        };
        final path = at + 'L' * (block.listDepth + 1);
        for (final token in _token.allMatches(raw)) {
          out[token.group(0)!] = (kind: kind, path: path);
        }
    }
  }
}

/// What a reader of [lines] makes of each word: the reference, or one of
/// the app's readings.
typedef _Reader = Map<String, Where> Function(List<String> lines);

/// The words of [lines] as the block tree reads them
/// (`docs/dev/block-tree.md`): each leaf's kind, under the items and quotes
/// the tree puts it in — the package parses nothing.
Map<String, Where> _tree(List<String> lines) {
  final out = <String, Where>{};
  void walk(BlockNode node, String path) {
    switch (node) {
      case FootnoteNode(:final children):
        for (final child in children) {
          walk(child, '${path}F');
        }
      case QuoteNode(:final children):
        for (final child in children) {
          walk(child, '${path}Q');
        }
      case ListNode(:final items):
        for (final item in items) {
          walk(item, path);
        }
      case ItemNode(:final children):
        for (final child in children) {
          walk(child, '${path}L');
        }
      case LeafNode(:final definition) when definition:
        // A definition gives the parser no text.
        break;
      case LeafNode(:final kind, lines: final spans):
        final name = switch (kind) {
          BlockKind.paragraph => 'text',
          BlockKind.fencedCode || BlockKind.indentedCode => 'code',
          _ => kind.name,
        };
        for (final span in spans) {
          final text = lines[span.line].substring(span.start, span.end);
          for (final token in _token.allMatches(text)) {
            out[token.group(0)!] = (kind: name, path: path);
          }
        }
    }
  }

  for (final node in BlockTree.of(lines.join('\n'))) {
    walk(node, '');
  }
  return out;
}

String? _differs(List<String> lines, _Reader reader) {
  final want = _reference(lines);
  final got = reader(lines);
  final diffs = [
    for (final token in got.keys)
      if (want[token] != got[token])
        '$token: want ${want[token]} got ${got[token]}',
  ];
  return diffs.isEmpty ? null : diffs.join('; ');
}

/// The app's readings the gate holds to the reference: the read view's
/// pipeline, and the block tree that is to replace it.
const List<(String, _Reader)> _readers = [
  ('the read view', _scanner),
  ('the block tree', _tree),
];

/// Whether a leaf in [nodes], [inside] an item, a quote or a definition,
/// has a line that opens a footnote definition: one the scanner reads as
/// text, and the parser as a definition left where it stands.
bool _definesInside(List<BlockNode> nodes, List<String> lines, bool inside) {
  for (final node in nodes) {
    final found = switch (node) {
      QuoteNode(:final children) ||
      ItemNode(:final children) ||
      FootnoteNode(:final children) => _definesInside(children, lines, true),
      ListNode(:final items) => _definesInside(items, lines, inside),
      LeafNode(lines: final spans) =>
        inside &&
            spans.any(
              (span) =>
                  FootnoteSyntax.opening(
                    lines[span.line].substring(span.start),
                  ) !=
                  null,
            ),
    };
    if (found) return true;
  }
  return false;
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
const Set<int> _pending = <int>{};

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

  group('the block tree', () {
    for (final (name, text) in _shapes) {
      test(name, () {
        var w = 0;
        final lines = [
          for (final line in text.split('\n'))
            line.replaceAllMapped('w', (_) => 'w${w++}'),
        ];
        expect(_tree(lines), _reference(lines));
      });
    }
  });

  for (final (what, reader) in _readers) {
    test('$what reads a sample of documents as the parser does', () {
      // The gate: two thousand documents, every one read alike but those
      // the parser itself gets wrong (_quirkOf). The full report is behind
      // NIMAN_SCANNER_DIFF.
      final run = _run(2000, 1, reader);
      expect(
        run.found.keys.take(5).toList(),
        isEmpty,
        reason: '${run.docs} of 2000 documents differ',
      );
    });
  }

  test('the scanner reads containers as CommonMark does', skip: !_asked, () {
    // READER=tree reports on the block tree instead of the read view.
    const which = String.fromEnvironment('READER', defaultValue: 'view');
    final run = _run(
      40000,
      int.parse(const String.fromEnvironment('SEED', defaultValue: '1')),
      which == 'tree' ? _tree : _scanner,
    );
    final found = run.found;
    print(
      'docs differing: ${run.docs} / 40000, minimal: ${found.length} '
      '(left out: ${run.skipped})',
    );
    // The classes: each minimal repro's first difference, without its word.
    final classes = <String, int>{};
    final examples = <String, String>{};
    for (final MapEntry(:key, :value) in found.entries) {
      final first = value.split('; ').first.replaceFirst(_token, 'w');
      classes[first] = (classes[first] ?? 0) + 1;
      final example = examples[first];
      if (example == null || key.length < example.length) {
        examples[first] = key;
      }
    }
    final ranked = classes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in ranked) {
      print(
        'class ${entry.value}: ${entry.key}   '
        'e.g. ${examples[entry.key]!.replaceAll(' ', '·')}',
      );
    }
    final keys = found.keys.toList()
      ..sort((a, b) => a.length.compareTo(b.length));
    for (final key in keys) {
      print('== ${key.replaceAll(' ', '·')}   ${found[key]}');
    }
  });
}

/// [count] documents made from [seed]: how many differ, how many were left
/// out for the parser's own faults, and each difference shrunk to the
/// fewest lines that still show it, by its lines with the words blanked.
({int docs, Map<String, int> skipped, Map<String, String> found}) _run(
  int count,
  int seed,
  _Reader reader,
) {
  final random = math.Random(seed);
  final found = <String, String>{};
  var docs = 0;
  final skipped = <String, int>{};
  for (var n = 0; n < count; n++) {
    final lines = _document(random);
    if (lines.first.trim() == '---') continue;
    final quirk = _quirkOf(lines);
    if (quirk != null) {
      skipped[quirk] = (skipped[quirk] ?? 0) + 1;
      continue;
    }
    if (_differs(lines, reader) == null) continue;
    docs++;
    // Shrink: drop lines while it still differs.
    var small = lines;
    for (var changed = true; changed;) {
      changed = false;
      for (var i = 0; i < small.length && small.length > 1; i++) {
        final fewer = [...small]..removeAt(i);
        if (fewer.first.trim() != '---' &&
            _quirkOf(fewer) == null &&
            _differs(fewer, reader) != null) {
          small = fewer;
          changed = true;
          break;
        }
      }
    }
    final key = small.map((l) => l.replaceAll(_token, 'w')).join(r'\n');
    found.putIfAbsent(key, () => _differs(small, reader)!);
  }
  return (docs: docs, skipped: skipped, found: found);
}

/// A document of two to six lines, from [_forms] indented by [_indents] —
/// or, one in four, by [_tabs].
List<String> _document(math.Random random) {
  final indents = random.nextInt(4) == 0 ? _tabs : _indents;
  final count = 2 + random.nextInt(5);
  var w = 0;
  return [
    for (var i = 0; i < count; i++)
      indents[random.nextInt(indents.length)] +
          _forms[random.nextInt(_forms.length)].replaceFirst('W', 'w${w++}'),
  ];
}

/// What the parser itself gets wrong in [lines], or what the app cannot
/// hand it, if anything: the documents the comparison leaves out, by name.
///
/// * A lone `-` under a line of text. The text's paragraph takes it for a
///   setext underline and ends, but GFM's list syntax is tried before the
///   underline's, opens an empty item on it — and the paragraph's text is
///   gone from the output.
/// * `===` in the run of lines of a quote or an item. A lazy line is no
///   setext underline (the spec, and the tree since it knows lazy lines);
///   the package heads a lazy `===` in an item all the same, and the read
///   view's pipeline, reading a quote's content on its own, heads one in a
///   quote. Where the package and the spec part, the spec wins.
/// * Tabs and spaces indenting the lines of one list — the app's limit,
///   not the parser's. A tab an item's indent ends inside of leaves columns
///   of it to the item's text, which the text the read view hands the
///   parser — a substring of the line — cannot hold: the tab goes whole. A
///   list indented with tabs alone, as Obsidian writes one, loses the same
///   columns on every line and reads alike ([_tabs]); mixed with spaces it
///   does not. The documents made here do not mix them.
/// * The parser throws: a cited footnote whose last block is a list
///   (`Document._appendBackref` takes its children for elements).
/// * A footnote definition inside an item, a quote or another definition:
///   the parser reads it there, and leaves it where it stands — a
///   footnote's `li` in the middle of the note — where the scanner reads
///   definitions at the note's margin only, the ones taken to the
///   footnotes.
String? _quirkOf(List<String> lines) {
  final Map<String, Where> reference;
  try {
    reference = _reference(lines);
  } on Object {
    return 'the parser throws';
  }
  // A definition in an item, a quote or another definition stays where it
  // is, a footnote's `li` in the middle of the note.
  if (reference.values.any((where) => where.path.lastIndexOf('F') > 0) ||
      _definesInside(BlockTree.of(lines.join('\n')), lines, false)) {
    return 'a definition inside a container';
  }
  var contained = false;
  var listed = false;
  var tabs = false;
  var spaces = false;
  for (var at = 0; at < lines.length; at++) {
    final raw = lines[at];
    final line = raw.trim();
    if (line.isEmpty) {
      contained = false;
      continue;
    }
    if (at > 0 && line == '-' && lines[at - 1].trim().isNotEmpty) {
      return 'a lone `-`';
    }
    if (contained && line.replaceAll('=', '').isEmpty) {
      return '`===` in a quote or an item';
    }
    // `> - w` / `    ---`: no `>`, four columns in — neither code nor an
    // underline can start there over a paragraph, so the line goes on with
    // the paragraph lazily (cmark's `S_process_line`); the package heads
    // the item's text with it.
    if (contained &&
        !raw.contains('>') &&
        line.replaceAll('-', '').isEmpty &&
        LineSyntax.columnsOf(raw) >= 4) {
      return '`---` four columns in, lazily under a quote';
    }
    if (raw.contains('>') || LineSyntax.listMarkerOf(line) != null) {
      contained = true;
    }
    if (LineSyntax.listMarkerOf(line) != null) listed = true;
    final indent = raw.substring(0, raw.length - raw.trimLeft().length);
    if (listed && indent.contains('\t')) tabs = true;
    if (listed && indent.contains(' ')) spaces = true;
    if (tabs && spaces) return 'tabs and spaces in one list';
  }
  return null;
}
