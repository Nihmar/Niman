/// Our reading held to `cmark-gfm` itself, on documents made at random
/// (`docs/dev/block-tree.md`, "Next"): the specs' examples cannot reach
/// every shape containers make, and where they do not, the reading was
/// the package's. Each document is written by `TreeHtml` and by
/// `cmark-gfm` (`tool/cmark_render.py`, `pip install cmarkgfm`), the two
/// compared normalized as the spec's runner compares them; a document
/// that differs is shrunk to the fewest lines that still do, and the
/// differences are reported by their shape, words blanked.
///
/// Usage: `dart run tool/cmark_harness.dart [count] [seed]` — 2 000
/// documents from seed 1 by default. `--cases` prints each shape's
/// smallest document with `cmark-gfm`'s HTML, as JSON, for the fixture
/// the gate reads (`test/fixtures/spec/cmark-cases.json`).
library;

// A command-line report: printing is its output.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:niman/src/markdown/html/tree_html.dart';

import 'html_normalize.dart';

/// The lines documents are made of, `W` standing for a word of its own:
/// the containers in their forms — bullets and numbers, empty items, a
/// container right after a marker — and the blocks that end or interrupt
/// them.
const List<String> _forms = [
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
  'W[^f]',
];

/// What a line is indented with: mostly nothing, then spaces either side
/// of an item's content columns.
const List<String> _indents = ['', '', '', '  ', '   ', '    ', '      '];

/// The same in tabs, for a document indented as Obsidian writes one.
const List<String> _tabs = ['', '', '', '\t', '\t', '\t\t'];

final RegExp _word = RegExp(r'w\d+');

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

/// `cmark-gfm`, kept running: one document a line in, its HTML a line out.
final class _Cmark {
  new _(this._process) {
    _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) => _waiting.removeAt(0).complete(jsonDecode(line) as String),
        );
    _process.stderr.transform(utf8.decoder).listen(stderr.write);
  }

  static Future<_Cmark> start() async =>
      _Cmark._(await Process.start('python', ['tool/cmark_render.py']));

  final Process _process;
  final List<Completer<String>> _waiting = <Completer<String>>[];

  Future<String> render(String markdown) {
    final done = Completer<String>();
    _waiting.add(done);
    _process.stdin.writeln(jsonEncode(markdown));
    return done.future;
  }

  void close() => _process.kill();
}

/// Whether our HTML of [lines] differs from `cmark-gfm`'s.
Future<bool> _differs(_Cmark cmark, List<String> lines) async {
  final markdown = '${lines.join('\n')}\n';
  final theirs = await cmark.render(markdown);
  final String ours;
  try {
    ours = TreeHtml(markdown, appSyntax: false).render();
  } on Object {
    return true;
  }
  return normalizeHtml(ours) != normalizeHtml(theirs);
}

Future<void> main(List<String> args) async {
  final cases = args.contains('--cases');
  final numbers = [for (final arg in args) ?int.tryParse(arg)];
  final count = numbers.isNotEmpty ? numbers[0] : 2000;
  final seed = numbers.length > 1 ? numbers[1] : 1;
  final cmark = await _Cmark.start();
  final random = math.Random(seed);
  final found = <String, List<String>>{};
  final counts = <String, int>{};
  var docs = 0;
  for (var n = 0; n < count; n++) {
    final lines = _document(random);
    if (!await _differs(cmark, lines)) continue;
    docs++;
    // Shrink: drop lines while it still differs.
    var small = lines;
    for (var changed = true; changed;) {
      changed = false;
      for (var i = 0; i < small.length && small.length > 1; i++) {
        final fewer = [...small]..removeAt(i);
        if (await _differs(cmark, fewer)) {
          small = fewer;
          changed = true;
          break;
        }
      }
    }
    final key = small.map((line) => line.replaceAll(_word, 'w')).join(r'\n');
    found.putIfAbsent(key, () => small);
    counts[key] = (counts[key] ?? 0) + 1;
  }
  final keys = found.keys.toList()
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  if (cases) {
    final out = <Map<String, String>>[];
    for (final key in keys) {
      final markdown = '${found[key]!.join('\n')}\n';
      out.add({'markdown': markdown, 'html': await cmark.render(markdown)});
    }
    print(const JsonEncoder.withIndent('  ').convert(out));
  } else {
    print(
      '$docs of $count documents differ from cmark-gfm (seed $seed), '
      '${keys.length} shapes:',
    );
    for (final key in keys) {
      final markdown = '${found[key]!.join('\n')}\n';
      print('');
      print('== ${counts[key]}x  ${key.replaceAll(' ', '·')}');
      print(
        '-- ours:  ${_oneLine(TreeHtml(markdown, appSyntax: false).render())}',
      );
      print('-- cmark: ${_oneLine(await cmark.render(markdown))}');
    }
  }
  cmark.close();
}

String _oneLine(String html) => html.trim().replaceAll('\n', r'\n');
