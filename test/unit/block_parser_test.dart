// The bridge: a block in, styled runs with source offsets out. The offsets are
// the contract — a run that says [2, 10) has to be exactly `**bold**` in the
// block's own text — so most of this file checks ranges rather than kinds.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/extension_span.dart';
import 'package:niman/src/markdown/parsed_block.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/style_run.dart';

/// Parses the block at [index] of [document].
ParsedBlock _parse(String document, {int index = 0}) {
  final buffer = SourceBuffer.fromText(document);
  final scanner = BlockScanner(buffer);
  return BlockParser().parse(scanner.index.blocks[index], buffer);
}

/// The runs of the block at [index], as `kind:text` pairs.
List<String> _runs(String document, {int index = 0, bool onlyStyled = true}) {
  final parsed = _parse(document, index: index);
  return <String>[
    for (final run in parsed.runs)
      if (!onlyStyled || run.kind != StyleKind.plain)
        if (!onlyStyled || run.kind != StyleKind.heading)
          '${run.kind.name}:${parsed.text.substring(run.start, run.end)}',
  ];
}

/// The run of [kind], or null.
StyleRun? _run(ParsedBlock parsed, StyleKind kind) {
  for (final run in parsed.runs) {
    if (run.kind == kind) return run;
  }
  return null;
}

/// The source a run covers.
String _slice(ParsedBlock parsed, StyleRun run) =>
    parsed.text.substring(run.start, run.end);

void main() {
  group('a run covers the construct, markers included', () {
    test('plain text is one run over everything', () {
      final parsed = _parse('just some words');
      expect(parsed.runs, hasLength(1));
      expect(parsed.runs.single.kind, StyleKind.plain);
      expect(_slice(parsed, parsed.runs.single), 'just some words');
    });

    test('strong, both spellings', () {
      for (final source in <String>['a **bold** b', 'a __bold__ b']) {
        final parsed = _parse(source);
        final run = _run(parsed, StyleKind.strong);
        expect(run, isNotNull, reason: source);
        expect(
          _slice(parsed, run!),
          source.contains('**') ? '**bold**' : '__bold__',
        );
      }
    });

    test('emphasis, both spellings', () {
      for (final (source, expected) in <(String, String)>[
        ('a *it* b', '*it*'),
        ('a _it_ b', '_it_'),
      ]) {
        final parsed = _parse(source);
        final run = _run(parsed, StyleKind.emphasis);
        expect(run, isNotNull, reason: source);
        expect(_slice(parsed, run!), expected);
      }
    });

    test('strikethrough', () {
      final parsed = _parse('a ~~gone~~ b');
      expect(
        _slice(parsed, _run(parsed, StyleKind.strikethrough)!),
        '~~gone~~',
      );
    });

    test('the HTML the toolbar writes: underline, superscript, subscript', () {
      // The package passes inline HTML through as text, which a renderer
      // that draws runs showed as tags; these three are read as the
      // constructs they are, tags included in the run as its markers.
      for (final (source, kind, slice, inner)
          in <(String, StyleKind, String, String)>[
            ('a <u>under</u> b', StyleKind.underline, '<u>under</u>', 'under'),
            ('x<sup>2</sup> y', StyleKind.superscript, '<sup>2</sup>', '2'),
            ('H<sub>2</sub>O', StyleKind.subscript, '<sub>2</sub>', '2'),
            ('a <U>caps</U> b', StyleKind.underline, '<U>caps</U>', 'caps'),
          ]) {
        final parsed = _parse(source);
        final run = _run(parsed, kind);
        expect(run, isNotNull, reason: source);
        expect(_slice(parsed, run!), slice, reason: source);
        expect(
          parsed.text.substring(run.innerStart, run.innerEnd),
          inner,
          reason: source,
        );
      }
      expect(_runs('<u>**both**</u>'), <String>[
        'underline:<u>**both**</u>',
        'strong:**both**',
      ], reason: 'the contents are parsed like any other inline text');
      expect(
        _run(_parse('a `<u>x</u>` b'), StyleKind.underline),
        isNull,
        reason: 'in a code span it is code',
      );
    });

    test('a code span is a masked span, not a parser run', () {
      // The masker sets code spans aside before the parser sees the block,
      // precisely so that a `$` or a `[[` inside one is not read as something
      // else. So the renderer gets it from `extensions`, not from `runs`.
      final parsed = _parse('use `code` here');
      expect(parsed.extensions.single.kind, ExtensionKind.codeSpan);
      expect(parsed.extensions.single.text, '`code`');
      expect(_run(parsed, StyleKind.code), isNull);
      expect(parsed.approximate, isFalse);
    });

    test('a link, the whole construct', () {
      final parsed = _parse('see [the note](https://example.com) now');
      final run = _run(parsed, StyleKind.link)!;
      expect(_slice(parsed, run), '[the note](https://example.com)');
      expect(run.href, 'https://example.com');
    });

    test('an image, the whole construct', () {
      final parsed = _parse('an ![alt](a.png) here');
      final run = _run(parsed, StyleKind.image)!;
      expect(_slice(parsed, run), '![alt](a.png)');
      expect(run.href, 'a.png');
    });

    test('a heading', () {
      final parsed = _parse('# A title');
      final run = _run(parsed, StyleKind.heading)!;
      expect(_slice(parsed, run), '# A title');
    });
  });

  group('a run knows its markers from its text', () {
    /// The run of [kind] in [source] as `open|text|close`.
    String split(String source, StyleKind kind) {
      final parsed = _parse(source);
      final run = _run(parsed, kind)!;
      final text = parsed.text;
      return '${text.substring(run.start, run.innerStart)}|'
          '${text.substring(run.innerStart, run.innerEnd)}|'
          '${text.substring(run.innerEnd, run.end)}';
    }

    test('emphasis, strong and strikethrough', () {
      expect(split('a **bold** b', StyleKind.strong), '**|bold|**');
      expect(split('a _it_ b', StyleKind.emphasis), '_|it|_');
      expect(split('a ~~gone~~ b', StyleKind.strikethrough), '~~|gone|~~');
    });

    test('a link, an image and a heading', () {
      expect(split('see [the note](u) now', StyleKind.link), '[|the note|](u)');
      expect(
        split('an ![alt](a.png) here', StyleKind.image),
        '![|alt|](a.png)',
      );
      expect(split('## A title', StyleKind.heading), '## |A title|');
    });

    test('a plain run has none', () {
      final parsed = _parse('just words');
      expect(parsed.runs.single.hasMarkers, isFalse);
    });
  });

  group('nesting is a depth', () {
    test('emphasis inside strong', () {
      final parsed = _parse('**a *b* c**');
      final strong = _run(parsed, StyleKind.strong)!;
      final emphasis = _run(parsed, StyleKind.emphasis)!;
      expect(_slice(parsed, strong), '**a *b* c**');
      expect(_slice(parsed, emphasis), '*b*');
      expect(strong.depth, 0);
      expect(emphasis.depth, greaterThan(strong.depth));
    });

    test('a code span inside a link keeps its own span', () {
      final parsed = _parse('[see `x`](u)');
      expect(_slice(parsed, _run(parsed, StyleKind.link)!), '[see `x`](u)');
      expect(parsed.extensions.single.text, '`x`');
    });
  });

  group('the masked constructs come back as spans', () {
    test('a wikilink is a placeholder run and a span', () {
      final parsed = _parse('see [[Note|alias]] now');
      final span = parsed.extensions.single;
      expect(span.start, 4);
      expect(span.end, 4 + '[[Note|alias]]'.length);
      // The parser saw placeholders, so there is no link in the runs; the
      // renderer draws the span instead.
      expect(_run(parsed, StyleKind.link), isNull);
      expect(parsed.approximate, isFalse);
    });

    test('inline math is a span, and the emphasis inside it is not', () {
      final parsed = _parse(r'a $x_i$ b');
      expect(parsed.extensions.single.text, r'$x_i$');
      expect(_run(parsed, StyleKind.emphasis), isNull);
    });

    test('a tag is a span', () {
      final parsed = _parse('a #prova here');
      expect(parsed.extensions.single.text, '#prova');
    });
  });

  group('blocks with no inline content', () {
    test('a fence, a rule, a math block and a blank line have no runs', () {
      for (final (document, index) in <(String, int)>[
        ('```\ncode\n```', 0),
        ('---', 0),
        ('\$\$\na = b\n\$\$', 0),
        ('a\n\nb', 1),
      ]) {
        final parsed = _parse(document, index: index);
        expect(parsed.runs, isEmpty, reason: document);
      }
    });

    test('the frontmatter has no runs', () {
      final parsed = _parse('---\ntitle: x\n---\n\nbody');
      expect(parsed.block.kind, BlockKind.frontmatter);
      expect(parsed.runs, isEmpty);
    });
  });

  group('the ranges are sound', () {
    test('every run is inside the text and in order', () {
      const document = r'''
# A title with **bold** and `code`

A paragraph with *emphasis*, a [link](u), an ![image](i.png), a [[wikilink]],
inline math $x$ and a #tag, all in one block.
''';
      final buffer = SourceBuffer.fromText(document);
      final scanner = BlockScanner(buffer);
      final parser = BlockParser();
      for (final block in scanner.index.blocks) {
        final parsed = parser.parse(block, buffer);
        var previous = 0;
        for (final run in parsed.runs) {
          expect(run.start, greaterThanOrEqualTo(previous), reason: '$block');
          expect(run.start, lessThanOrEqualTo(run.end));
          expect(
            run.end,
            lessThanOrEqualTo(parsed.text.length),
            reason: '$block',
          );
          previous = run.start;
        }
      }
    });

    test('every kind of construct is found where it should be', () {
      // The fixture is generated; this only checks the invariant, not counts.
      final parsed = _parse('**a** *b* `c` [d](e) ~~f~~');
      expect(<String>[
        for (final run in parsed.runs)
          if (run.kind != StyleKind.plain) run.kind.name,
      ], containsAll(<String>['strong', 'emphasis', 'link', 'strikethrough']));
      for (final run in parsed.runs) {
        final slice = _slice(parsed, run);
        expect(slice, isNotEmpty);
      }
    });

    test('the runs of a heading do not include the marker twice', () {
      final parsed = _parse('## Two');
      final heading = _run(parsed, StyleKind.heading)!;
      expect(_slice(parsed, heading), '## Two');
      // The heading run covers the marker, so no plain run starts before it.
      expect(parsed.runs.first, heading);
    });
  });

  group('the cache', () {
    test('a block is parsed once until the buffer changes', () {
      final buffer = SourceBuffer.fromText('**bold**\n\nsecond');
      final scanner = BlockScanner(buffer);
      final parser = BlockParser();
      final block = scanner.index.blocks.first;
      parser
        ..of(block, buffer)
        ..of(block, buffer);
      expect(parser.parseCount, 1);

      buffer.insert(0, 'x');
      parser.of(block, buffer);
      expect(parser.parseCount, 2, reason: 'the revision moved');
    });

    test('two blocks are two parses', () {
      final buffer = SourceBuffer.fromText('one\n\ntwo');
      final scanner = BlockScanner(buffer);
      final parser = BlockParser();
      for (final block in scanner.index.blocks) {
        parser.of(block, buffer);
      }
      expect(parser.parseCount, scanner.index.blocks.length);
    });
  });

  test('a character reference is placed, not guessed', () {
    final parsed = _parse('a &amp; b');
    expect(parsed.approximate, isFalse, reason: 'its source form is known');
    final plain = parsed.runs.first;
    expect(_slice(parsed, plain), 'a &amp; b');
  });

  test('a list item deep in its list is parsed as an item, not as code', () {
    // Parsed alone, an item three levels down stands four spaces in, which
    // alone is an indented code block: the parse takes its marker's indent
    // off, and a reader adds it back ([BlockParser.linePrefixLength]).
    const raw = '    - a **bold** word';
    const block = Block(kind: BlockKind.listItem, startLine: 0, endLine: 1);
    final parsed = BlockParser().parseText(
      block,
      raw,
      () => DocumentScope.scan(SourceBuffer.fromText(raw), 0),
    );
    expect(parsed.text, '- a **bold** word');
    expect(_slice(parsed, _run(parsed, StyleKind.strong)!), '**bold**');
    expect(_run(parsed, StyleKind.code), isNull);
    final prefix = BlockParser.linePrefixLength(
      block,
      raw,
      BlockParser.listIndentOf(block, raw),
    );
    final strong = _run(parsed, StyleKind.strong)!;
    expect(
      raw.substring(strong.start + prefix, strong.end + prefix),
      '**bold**',
    );
  });

  test('a quotation mark is placed, and so is what follows it', () {
    // The package hands text back HTML-escaped: `"` is `&quot;` in the node,
    // which the source does not say, and every run after it was guessed.
    for (final source in <String>[
      'say "hi" then **bold**',
      'a &amp; "b" <c> **bold**',
    ]) {
      final parsed = _parse(source);
      expect(parsed.approximate, isFalse, reason: source);
      expect(_slice(parsed, _run(parsed, StyleKind.strong)!), '**bold**');
    }
  });

  test('the runs are the kinds the note actually uses', () {
    expect(_runs('a **b** c', onlyStyled: false), <String>[
      'plain:a ',
      'strong:**b**',
      'plain: c',
    ]);
    expect(_runs('see [n](u) now', onlyStyled: false), <String>[
      'plain:see ',
      'link:[n](u)',
      'plain: now',
    ]);
  });
}
