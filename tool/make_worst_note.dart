/// Generates the adversarial Markdown fixture the engine is measured against.
///
/// The real worst note (`Geometria 1.md`) is one person's geometry notes: it
/// proves the math and the layout requirements decisively and exercises almost
/// nothing else — no code spans, no fences, no links, no images, no entities,
/// no escapes, no reference definitions. The synthetic fixtures in
/// `test/fixtures/markdown/` have those and lack the geometry note's density.
/// This fixture is the union of what each lacks, so one document can stand in
/// for the whole corpus in a benchmark.
///
/// The specification, with the measured corpus value each dimension exceeds, is
/// §5.7 of `docs/dev/unified-surface.md`. Its numbers are the contract:
/// `--check` prints what was generated and `test/unit/worst_note_test.dart`
/// asserts it, so the fixture cannot drift away from the spec unnoticed.
///
/// ```sh
/// dart run tool/make_worst_note.dart            # writes the fixture
/// dart run tool/make_worst_note.dart --check    # writes, then reports
/// ```
///
/// The output is deterministic: no randomness, no timestamps, so regenerating
/// it produces the same bytes and a diff means a real change.
library;

// A generator's whole output is its report.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;

/// Where the fixture goes.
final String _output = p.join('test', 'fixtures', 'spec', 'worst-note.md');

/// How many lines of each adversarial region to emit.
///
/// Named rather than inlined so `--check` can print them next to the generated
/// counts, and so the next person can tune one number and see what it costs.
const int _megaParagraphLines = 2000;
const int _longFenceLines = 2000;
const int _displayMathBlocks = 902;

/// Inline `$…$` spans wanted. Each term below emits two, so this is halved
/// when the paragraphs are written.
const int _inlineMathTarget = 19700;
const int _wikilinkTarget = 2109;
const int _footnoteRefs = 120;
const int _footnoteDefs = 60;
const int _crlfLines = 120;
const int _tableRows = 40;
const int _tableColumns = 12;
const int _deepListDepth = 7;
const int _deepQuoteDepth = 4;
const int _inlineSpansOnOneLine = 180;

void main(List<String> args) {
  final document = _build();
  File(_output)
    ..createSync(recursive: true)
    ..writeAsStringSync(document);
  print('wrote $_output: ${document.length} chars');

  if (args.contains('--check')) _report(document);
}

/// The whole fixture, in the order a reader would meet it.
String _build() {
  final out = StringBuffer();
  _frontmatter(out);
  _headings(out);
  _setextHeadings(out);
  _megaParagraph(out);
  _inlineDenseLine(out);
  _longUnbreakableWord(out);
  _codeSpans(out);
  _nestedLists(out);
  _nestedQuotes(out);
  _mathCorpus(out);
  _code(out);
  _tables(out);
  _htmlBlocks(out);
  _referenceDefinitions(out);
  _footnotes(out);
  _wikilinks(out);
  _crlfRegion(out);
  _longLines(out);
  return out.toString();
}

/// A YAML block with a byte-order mark in front of it, which is how a Windows
/// editor can leave a file and how a naive `---` check misses the block.
void _frontmatter(StringBuffer out) {
  out
    ..writeln('\uFEFF---')
    ..writeln('title: The worst note')
    ..writeln('tags: [fixture, adversarial]')
    ..writeln('date: 2026-09-21')
    ..writeln('---')
    ..writeln();
}

/// All six levels, which the geometry note stops at three of.
void _headings(StringBuffer out) {
  for (var level = 1; level <= 6; level++) {
    out
      ..writeln('${'#' * level} Heading at level $level')
      ..writeln();
  }
}

/// The two setext forms the corpus never has.
void _setextHeadings(StringBuffer out) {
  out
    ..writeln('A setext one')
    ..writeln('============')
    ..writeln()
    ..writeln('A setext two')
    ..writeln('------------')
    ..writeln();
}

/// One paragraph of 2 000 lines: a single `TextPainter` for the whole thing,
/// which is the shape that makes a block-per-paragraph layout visible.
void _megaParagraph(StringBuffer out) {
  out
    ..writeln('# A paragraph of $_megaParagraphLines lines')
    ..writeln();
  for (var line = 0; line < _megaParagraphLines; line++) {
    out.writeln(
      'paragraph line $line with enough words to wrap on a phone '
      'and to give the line breaker something to do.',
    );
  }
  out
    ..writeln()
    ..writeln();
}

/// One line carrying more inline spans than any line of the corpus (120).
void _inlineDenseLine(StringBuffer out) {
  out
    ..writeln('# A dense line')
    ..writeln();
  final parts = <String>[];
  for (var i = 0; i < _inlineSpansOnOneLine; i++) {
    parts.add(
      i.isEven
          ? '**b$i**'
          : r'$x_'
                '$i'
                r'$',
    );
  }
  out
    ..writeln(parts.join(' '))
    ..writeln();
}

/// Code spans, which the corpus's fixtures have and the geometry note does
/// not — and which matter beyond colouring, because a `$` or a `[[` inside one
/// is neither math nor a link.
void _codeSpans(StringBuffer out) {
  out
    ..writeln('# Code spans')
    ..writeln();
  for (var i = 0; i < 12; i++) {
    out.writeln(
      'Prose $i with `code $i` and '
      r'$x$'
      ' in backticks, plus '
      '`[[Note]]` and `#notatag` and a run of `` ` `` inside.',
    );
  }
  out.writeln();
}

/// A word no line breaker can break, longer than any in the corpus (73 in
/// text, 102 in a table row).
void _longUnbreakableWord(StringBuffer out) {
  out
    ..writeln('# An unbreakable word')
    ..writeln()
    ..writeln('x' * 400)
    ..writeln();
}

/// Seven levels of list, both ordered delimiters, a `start` that is not 1, and
/// task items nested inside — none of which the geometry note has at all.
void _nestedLists(StringBuffer out) {
  out
    ..writeln('# Lists')
    ..writeln();
  for (var depth = 0; depth < _deepListDepth; depth++) {
    final indent = '  ' * depth;
    out.writeln('$indent- level $depth item');
  }
  out
    ..writeln()
    ..writeln('3) starts at three')
    ..writeln('4) and counts on')
    ..writeln()
    ..writeln('1. dot delimiter')
    ..writeln('2. second')
    ..writeln();
  for (var depth = 0; depth < _deepListDepth; depth++) {
    final indent = '  ' * depth;
    out.writeln('$indent- [${depth.isEven ? ' ' : 'x'}] task at level $depth');
  }
  out
    ..writeln()
    // Display math inside a list item: the corpus has none, and the block
    // scanner has to keep the item's indentation through it.
    ..writeln('- an item with display math in it:')
    ..writeln()
    ..writeln(r'  $$\begin{pmatrix} a & b \\ c & d \end{pmatrix}$$')
    ..writeln();
}

/// Four levels of quote, with a display block at depth three.
void _nestedQuotes(StringBuffer out) {
  out
    ..writeln('# Quotes')
    ..writeln();
  for (var depth = 1; depth <= _deepQuoteDepth; depth++) {
    out.writeln('${'> ' * depth}quote at depth $depth');
  }
  const quote = '> > > ';
  out
    ..writeln()
    ..writeln('$quote\$\$')
    ..writeln('$quote\\int_0^1 x^2 \\, dx = \\frac{1}{3}')
    ..writeln('$quote\$\$')
    ..writeln();
}

/// The math the geometry note is made of, plus the environments it lacks: the
/// five it uses (`pmatrix`, `cases`, `aligned`, `vmatrix`, `array`) and
/// `bmatrix`.
void _mathCorpus(StringBuffer out) {
  final environments = <String>[
    'pmatrix',
    'bmatrix',
    'vmatrix',
    'cases',
    'aligned',
    'array',
  ];
  out
    ..writeln('# Math')
    ..writeln()
    // Brace depth five, which the corpus never reaches.
    ..writeln(
      r'$$\left\{ \frac{ \sqrt{ \frac{a}{b} } }{ \left( c + d '
      r'\right) } \right\}$$',
    )
    ..writeln()
    // One expression larger than the corpus's largest (1 094 B).
    ..writeln(r'$$\begin{aligned}')
    ..writeln(
      (List<String>.generate(
        40,
        (i) =>
            '  x_{'
            '$i'
            r'} &= \frac{ \alpha_{'
            '$i'
            '} + '
            r'\beta_{'
            '$i'
            r'} }{ \gamma_{'
            '$i'
            r'} } \\',
      )).join('\n'),
    )
    // The closing marker goes on a line of its own: the app's own rule is that
    // a display block closes at a line that *starts* with `$$`, and a fixture
    // that closed with `\end{aligned}$$` would leave the block open and swallow
    // the rest of the document — which is exactly what it did the first time.
    ..writeln(r'\end{aligned}')
    ..writeln(r'$$')
    ..writeln();

  for (var block = 0; block < _displayMathBlocks; block++) {
    final environment = environments[block % environments.length];
    out
      ..writeln(
        r'$$\begin{'
        '$environment'
        '}',
      )
      ..writeln(r'a_{$block} & b_{$block} \\ c & d')
      ..writeln(
        r'\end{'
        '$environment'
        r'}$$',
      )
      ..writeln();
  }

  out
    ..writeln('## Inline')
    ..writeln();
  var written = 0;
  var paragraph = 0;
  while (written < _inlineMathTarget ~/ 2) {
    final parts = <String>[];
    for (
      var i = 0;
      i < 20 && written < _inlineMathTarget ~/ 2;
      i++, written++
    ) {
      parts.add(
        'term $written is '
        r'$\frac{\alpha_'
        '$written'
        r'}{\beta}$'
        ' and '
        r'$x_{'
        '$written'
        r'}^2 + y^2 = z^2$',
      );
    }
    paragraph++;
    out
      ..writeln(parts.join(', '))
      ..writeln();
  }
  out
    ..writeln('(inline paragraphs: $paragraph)')
    ..writeln();
}

/// A tilde fence with no info string, one of 2 000 lines, and an indented code
/// block — the corpus has no fences at all.
void _code(StringBuffer out) {
  out
    ..writeln('# Code')
    ..writeln()
    ..writeln('~~~')
    ..writeln('no info string on this fence')
    ..writeln('~~~')
    ..writeln()
    ..writeln('~~~dart')
    ..writeln('final x = 1;')
    ..writeln('~~~')
    ..writeln()
    ..writeln('~~~')
    ..writeln('~~~')
    ..writeln()
    ..writeln('    an indented code block')
    ..writeln('    with two lines')
    ..writeln();

  // The header is two writes and the body is a loop, so the receiver is used
  // again after the cascade: a cascade for the header and then the loop is the
  // clearest shape, and the lint's preference is not available here.
  // ignore: cascade_invocations
  out
    ..writeln('~~~')
    ..writeln('a long fence, $_longFenceLines lines:');
  for (var line = 0; line < _longFenceLines; line++) {
    out.writeln('fence line $line with some text in it');
  }
  out
    ..writeln('~~~')
    ..writeln();
}

/// A table as wide as the corpus's widest (4 columns) and far longer, with
/// alignments, escaped pipes, an unbreakable cell and inline code.
void _tables(StringBuffer out) {
  out
    ..writeln('# Tables')
    ..writeln();
  final header = <String>[
    for (var column = 0; column < _tableColumns; column++) 'col $column',
  ];
  final rule = List<String>.generate(
    _tableColumns,
    (i) => i.isEven ? ':---' : '---:',
  ).join(' | ');
  out
    ..writeln('| ${header.join(' | ')} |')
    ..writeln('| $rule |');
  for (var row = 0; row < _tableRows; row++) {
    final cells = <String>[
      for (var column = 0; column < _tableColumns; column++)
        if (row == 0 && column == 0)
          r'a cell with an escaped \| pipe'
        else if (row == 1 && column == 0)
          r'a cell with `code $x$` in it'
        else if (row == 2 && column == 0)
          'unbreakable-${'y' * 340}'
        else
          'r${row}c$column',
    ];
    out.writeln('| ${cells.join(' | ')} |');
  }
  out.writeln();
}

/// HTML blocks that span lines and hold Markdown, which the corpus's two
/// single-line ones do not.
void _htmlBlocks(StringBuffer out) {
  out
    ..writeln('# HTML')
    ..writeln()
    ..writeln('<div class="wrapper">')
    ..writeln()
    ..writeln('Markdown *inside* an HTML block.')
    ..writeln()
    ..writeln('</div>')
    ..writeln()
    ..writeln('<table>')
    ..writeln('<tr><td>a</td><td>b</td></tr>')
    ..writeln('<tr><td>c</td><td>d</td></tr>')
    ..writeln('</table>')
    ..writeln()
    ..writeln('<!-- a comment block, which ends at its own marker -->')
    ..writeln()
    ..writeln('<pre>')
    ..writeln('raw text,')
    ..writeln()
    ..writeln('blank line and all')
    ..writeln('</pre>')
    ..writeln();
}

/// Reference definitions in all three forms, which the corpus has none of.
void _referenceDefinitions(StringBuffer out) {
  out
    ..writeln('# References')
    ..writeln()
    ..writeln('[full]: https://example.com/full "A title"')
    ..writeln('[collapsed]: https://example.com/collapsed')
    ..writeln('[shortcut]: https://example.com/shortcut')
    ..writeln('[second]: https://example.com/second')
    ..writeln('[third]: https://example.com/third')
    ..writeln()
    ..writeln('A [full][] link, a [collapsed][] one, a [shortcut] one, and ')
    ..writeln('two more: [second][] and [third].')
    ..writeln();
}

/// More footnote references and definitions than the corpus has (34 and 17).
void _footnotes(StringBuffer out) {
  out
    ..writeln('# Footnotes')
    ..writeln();
  for (var line = 0; line < _footnoteRefs ~/ 4; line++) {
    out.writeln(
      'A line with four references '
      '[^f${line}a][^f${line}b][^f${line}c][^f${line}d].',
    );
  }
  out.writeln();
  for (var note = 0; note < _footnoteDefs; note++) {
    out
      ..writeln(
        '[^f${note ~/ 1}${String.fromCharCode(97 + note % 4)}]: '
        'The definition of footnote $note, with a [link](https://example.com).',
      )
      ..writeln();
  }
}

/// Wikilinks in every shape the app resolves, including the two the corpus
/// has and the alias forms it does not.
void _wikilinks(StringBuffer out) {
  out
    ..writeln('# Wikilinks')
    ..writeln();
  var written = 0;
  while (written < _wikilinkTarget) {
    final parts = <String>[
      '[[Note ${written + 1}]]',
      '[[Note ${written + 2}|an alias]]',
      '[[Note ${written + 3}#A heading]]',
      '[[Note ${written + 4}#A heading|alias]]',
      '![[assets/image ${written + 5}.png]]',
      '![[assets/image ${written + 6}.png|300]]',
    ];
    written += parts.length;
    out
      ..writeln(parts.join(' and '))
      ..writeln();
  }
}

/// A region of CRLF lines inside an LF document, which is what a note edited on
/// two platforms looks like.
void _crlfRegion(StringBuffer out) {
  out
    ..writeln('# Mixed line endings')
    ..writeln();
  final crlf = StringBuffer();
  for (var line = 0; line < _crlfLines; line++) {
    crlf.writeln('a CRLF line $line\r');
  }
  out
    ..write(crlf)
    ..writeln();
}

/// Lines longer than any the corpus has (2 568 B), which stress the line
/// breaker, the horizontal scroll and the height estimate at once.
void _longLines(StringBuffer out) {
  out
    ..writeln('# Long lines')
    ..writeln();
  for (var line = 0; line < 48; line++) {
    out.writeln('line $line: ${'word$line ' * 600}');
  }
  out
    ..writeln()
    // Two thousand consecutive non-blank lines: the corpus's longest run is 67,
    // and this is the case where a re-scan has nowhere to converge early.
    ..writeln('# A long run of non-blank lines')
    ..writeln();
  for (var line = 0; line < 600; line++) {
    out.writeln('run line $line, no blank between these.');
  }
  out.writeln();
}

/// Prints what was generated, so it can be held against the spec's table.
void _report(String document) {
  final lines = document.split('\n');
  final blank = lines.where((line) => line.trim().isEmpty).length;
  final over2000 = lines.where((line) => line.length > 2000).length;
  var maxLine = 0;
  var maxLineNumber = 0;
  for (var at = 0; at < lines.length; at++) {
    if (lines[at].length > maxLine) {
      maxLine = lines[at].length;
      maxLineNumber = at + 1;
    }
  }
  final crlf = '\r\n'.allMatches(document).length;
  final inlineMath = RegExp(r'(?<!\\)\$[^$\n]+\$').allMatches(document).length;
  final displayMath = RegExp(
    r'^\s*\$\$',
    multiLine: true,
  ).allMatches(document).length;
  final fences = RegExp(
    r'^\s*(~~~|```)',
    multiLine: true,
  ).allMatches(document).length;
  final headings = <int, int>{
    for (var level = 1; level <= 6; level++)
      level: RegExp(
        '^${'#' * level} ',
        multiLine: true,
      ).allMatches(document).length,
  };
  final wikilinks = RegExp(r'\[\[[^\]\n]*\]\]').allMatches(document).length;
  final embeds = RegExp(r'!\[\[[^\]\n]*\]\]').allMatches(document).length;
  final footnoteDefs = RegExp(
    r'^\[\^[^\]]+\]:',
    multiLine: true,
  ).allMatches(document).length;
  final spanRuns =
      RegExp(r'\*\*[^*\n]+\*\*').allMatches(document).length +
      RegExp(r'(?<!\\)\$[^$\n]+\$').allMatches(document).length;

  print('');
  print('| dimension | generated |');
  print('|---|---:|');
  print('| bytes | ${document.length} |');
  print('| lines | ${lines.length} |');
  print(
    '| blank lines | $blank '
    '(${(blank * 100 / lines.length).toStringAsFixed(1)} %) |',
  );
  print('| max line | $maxLine B (line $maxLineNumber) |');
  print('| lines > 2 000 B | $over2000 |');
  print('| headings H1..H6 | ${headings.values.join(' / ')} |');
  print('| fences | $fences |');
  print('| display math markers | $displayMath |');
  print('| inline math | $inlineMath |');
  print('| inline span runs | $spanRuns |');
  print('| wikilinks | $wikilinks (embeds $embeds) |');
  print('| footnote definitions | $footnoteDefs |');
  print('| CRLF | $crlf |');
}
