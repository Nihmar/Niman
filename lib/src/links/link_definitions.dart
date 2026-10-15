/// The link reference definitions of a note, read as the links they are
/// (#972).
///
/// `[text][label]` names a file through `[label]: path.md`, and the index
/// draws its edge from the definition's destination. A move that carries the
/// file has to carry the definition, so it is read here as the Markdown link
/// the rewrite already knows how to retarget.
library;

import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/inline/inline_scanners.dart';
import 'package:niman/src/markdown/link_definition_syntax.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The definitions of [text], in document order, each as a [MarkdownLink]:
/// its `href` the destination as written (without the angle brackets of
/// `<a b.md>`, which `angled` says it had), its `text` the label, and its
/// `start`..`end` the destination's own span, brackets included — what a
/// rewrite replaces, leaving the label and the title as they are.
///
/// Read from the block scan, as the note is drawn: a line of a code fence
/// that looks like a definition is none. A definition is read where the
/// document's scope reads them, at the margin; one inside a quote or an item
/// is not a reference the index draws an edge for, and is left alone.
List<MarkdownLink> linkDefinitionsOf(String text) {
  // Every definition has its `]:`; without one there is nothing to scan.
  if (!text.contains(']:')) return const <MarkdownLink>[];
  final buffer = SourceBuffer.fromText(text);
  final out = <MarkdownLink>[];
  for (final block in BlockScanner(buffer).index.blocks) {
    if (block.definition != Block.opensDefinition ||
        block.quoteDepth != 0 ||
        block.listDepth != -1 ||
        block.footnote != 0 ||
        !LinkDefinitionSyntax.opens(buffer.lineAt(block.startLine))) {
      continue;
    }
    final definition = _definitionOf(buffer, block);
    if (definition != null) out.add(definition);
  }
  return out;
}

/// The definition [block] is, or null when its lines read as none.
MarkdownLink? _definitionOf(SourceBuffer buffer, Block block) {
  // The lines as the parser reads them, one text; `starts` says where each
  // begins in it, to put an offset of it back in the note.
  final lines = <String>[];
  final starts = <int>[];
  var length = 0;
  for (var line = block.startLine; line < block.endLine; line++) {
    lines.add(buffer.lineAt(line));
    starts.add(length);
    length += lines.last.length + 1;
  }
  final joined = lines.join('\n');
  int inNote(int offset) {
    var line = starts.length - 1;
    while (starts[line] > offset) {
      line--;
    }
    return buffer.offsetOfLine(block.startLine + line) + offset - starts[line];
  }

  final label = InlineScanners.linkLabel(joined, joined.indexOf('['));
  if (label == null ||
      label.$2 >= joined.length ||
      joined.codeUnitAt(label.$2) != 0x3A) {
    return null;
  }
  final at = InlineScanners.spaceNewline(joined, label.$2 + 1);
  final destination = InlineScanners.linkDestination(joined, at);
  if (destination == null) return null;
  final angled = at < joined.length && joined.codeUnitAt(at) == 0x3C;
  if (destination.$1.isEmpty) return null;
  return MarkdownLink(
    start: inNote(at),
    end: inNote(destination.$2 - 1) + 1,
    text: label.$1.trim(),
    href: destination.$1,
    angled: angled,
  );
}
