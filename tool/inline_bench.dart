/// Our inline parser against `package:markdown`'s, on the same leaves
/// (`docs/dev/block-tree.md`, "Speed"): the paragraphs and headings of the
/// markdown fixtures and of a math-heavy note, each parsed
///
/// * by ours (`InlineParser`);
/// * by the package's inline parser alone (`md.InlineParser`);
/// * the way the app reads a leaf today: masked, then the package's whole
///   parse of the block (`md.Document.parseLines`).
///
/// Usage: `dart run tool/inline_bench.dart` — the best of five runs each.
library;

// A command-line report: printing is its output.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_tree.dart';
import 'package:niman/src/markdown/extension_masker.dart';
import 'package:niman/src/markdown/html/leaf_text.dart';
import 'package:niman/src/markdown/inline/inline_parser.dart';
import 'package:niman/src/markdown/inline_syntaxes.dart';
import 'package:path/path.dart' as p;

/// [args]: more notes to measure, by path — a note of one's own, which
/// stays out of the repository.
void main(List<String> args) {
  final notes = <String, String>{
    for (final path in args) p.basename(path): File(path).readAsStringSync(),
    for (final name in const [
      'fixture-10kb.md',
      'fixture-200kb.md',
      'fixture-1mb.md',
    ])
      name: File(p.join('test', 'fixtures', 'markdown', name))
          .readAsStringSync(),
    'worst-note.md': File(p.join('test', 'fixtures', 'spec', 'worst-note.md'))
        .readAsStringSync(),
    'math prose (generated)': mathProse(4000),
  };
  print('| note | leaves | ours | package inline | app today |');
  print('|---|---:|---:|---:|---:|');
  for (final MapEntry(key: name, value: note) in notes.entries) {
    final texts = leafTexts(note);
    final ours = _best(() {
      for (final text in texts) {
        InlineParser(text).parse();
      }
    });
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      inlineSyntaxes: nimanInlineSyntaxes,
    );
    final package = _best(() {
      for (final text in texts) {
        md.InlineParser(text, document).parse();
      }
    });
    const masker = ExtensionMasker();
    final today = _best(() {
      for (final text in texts) {
        md.Document(
          extensionSet: md.ExtensionSet.gitHubFlavored,
          inlineSyntaxes: nimanInlineSyntaxes,
        ).parseLines(masker.mask(text).text.split('\n'));
      }
    });
    print(
      '| $name | ${texts.length} | ${_ms(ours)} | ${_ms(package)} '
      '| ${_ms(today)} |',
    );
  }
}

/// The inline texts of [note]'s paragraphs and headings.
List<String> leafTexts(String note) {
  final lines = note.split('\n');
  final texts = <String>[];
  void walk(List<BlockNode> nodes) {
    for (final node in nodes) {
      switch (node) {
        case QuoteNode(:final children) ||
            ItemNode(:final children) ||
            FootnoteNode(:final children):
          walk(children);
        case ListNode(:final items):
          walk(items);
        case LeafNode(:final kind) when kind == BlockKind.paragraph:
          texts.add(LeafText.paragraph(LeafText.linesOf(node, lines)));
        case LeafNode(:final kind) when kind == BlockKind.heading:
          final leaf = LeafText.linesOf(node, lines);
          texts.add(
            leaf.length == 1
                ? LeafText.atxHeading(leaf.single)
                : LeafText.setextHeading(leaf),
          );
        case LeafNode():
          break;
      }
    }
  }

  walk(BlockTree.of(note));
  return texts;
}

/// [paragraphs] of prose with inline formulas full of `_`, the case the
/// masker was measured on (7 530 `_` runs in one note, 17 of them
/// emphasis).
String mathProse(int paragraphs) {
  final out = <String>[];
  for (var at = 0; at < paragraphs; at++) {
    out.add(
      'Sia \$a_${at % 9} + b_{i_j} = c_k\$ con \$x_1, \\dots, x_n\$ e '
      '_un poco_ di testo, **forte**, `codice` e [un link](/u_$at).',
    );
  }
  return out.join('\n\n');
}

int _best(void Function() run) {
  var best = 1 << 62;
  for (var round = 0; round < 5; round++) {
    final watch = Stopwatch()..start();
    run();
    if (watch.elapsedMicroseconds < best) best = watch.elapsedMicroseconds;
  }
  return best;
}

String _ms(int micros) => '${(micros / 1000).toStringAsFixed(1)} ms';
