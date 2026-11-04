/// What `live` draws a source line of a block as — a callout's line, a
/// display formula, a diagram or a `todo` list, a fence's band — read off
/// the line's block and the note's text, for the source view's lines.
///
/// Functions of their arguments alone: the view asks them as it builds each
/// line, with the block the scan behind its colours has for the line.
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/callout.dart';
import 'package:niman/src/markdown/div_syntax.dart';
import 'package:niman/src/markdown/fence_body.dart';
import 'package:niman/src/markdown/render/callout_style.dart';
import 'package:niman/src/markdown/render/fence_band_painter.dart';
import 'package:niman/src/markdown/render/live_blocks.dart';
import 'package:niman/src/markdown/render/live_decorations.dart';
import 'package:niman/src/markdown/render/live_quote_content.dart';
import 'package:niman/src/markdown/render/live_run.dart';
import 'package:niman/src/markdown/render/math_text.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// What line [index] is in its callout, when [block] — its quote — is one
/// (#279): the callout's style, and on the title line where its mark is.
/// [quotes] reads the quote's content as blocks.
LiveCallout? liveCalloutLine(
  int index,
  Block? block,
  SourceBuffer buffer,
  LiveQuoteContent quotes,
) {
  final callout = quotes.calloutOf(block, buffer);
  if (callout == null) return null;
  final title = index == block!.startLine;
  var markStart = 0;
  var markEnd = 0;
  String? label;
  if (title) {
    final text = buffer.lineAt(index);
    final prefix = BlockParser.quotePrefixLength(
      text,
      block.quoteDepth,
      BlockParser.itemPrefixLength(block, text),
    );
    final rest = text.substring(prefix);
    markStart = prefix + rest.length - rest.trimLeft().length;
    markEnd = prefix + Callout.markLength(rest);
    // No title written: the type's, drawn after the icon.
    if (text.substring(markEnd).trim().isEmpty) label = callout.title;
  }
  return (
    style: calloutStyleOf(callout.type),
    title: title,
    markStart: markStart,
    markEnd: markEnd,
    label: label,
  );
}

/// The display formula [block] — a line's — is, for `live` mode to draw in
/// its lines' place: its lines and its TeX. Null for any other block.
LiveFormula? liveFormulaOf(Block? block, SourceBuffer buffer) {
  if (block == null || block.kind != BlockKind.math) return null;
  final tex = displayTexOf(BlockParser.blockText(block, buffer));
  if (tex.isEmpty) return null;
  return (start: block.startLine, end: block.endLine, tex: tex);
}

/// The Mermaid block line [index] is part of — [block] — for `live` mode to
/// draw in its lines' place: its fence's lines, and on the first of them —
/// the one the diagram is drawn under — the source between them. Null for
/// any other line, and for a `mermaid` fence with no code. A closed `todo`
/// fence is one too where the note's tasks are at hand ([drawsTodo], a
/// `TodoBlockScope` above the view): drawn as the list it asks for, empty or
/// not (#1152).
///
/// Every line of the block asks, every build: the block's text is read
/// for its first line alone, where reading it for each made a diagram of
/// k lines cost k² of them. The others only ask whether there is code,
/// which the first line of it answers.
LiveDiagram? liveDiagramOf(
  int index,
  Block? block,
  SourceBuffer buffer, {
  required bool Function() drawsTodo,
}) {
  if (block == null || block.kind != BlockKind.fencedCode) return null;
  final info = block.fenceInfo?.toLowerCase();
  if (info == 'todo' && drawsTodo()) {
    return _todoBlockOf(index, block, buffer);
  }
  if (info != 'mermaid') return null;
  if (index != block.startLine) {
    final lineAt = buffer.lineAt;
    if (!fenceHasCode(lineAt, block.startLine, block.endLine)) return null;
    return (
      start: block.startLine,
      end: block.endLine,
      source: null,
      todo: false,
    );
  }
  final lines = BlockParser.blockText(block, buffer).split('\n');
  // The code as the read view and the export read it.
  final code = fenceBody(lines)?.code;
  if (code == null || code.trim().isEmpty) return null;
  return (
    start: block.startLine,
    end: block.endLine,
    source: code,
    todo: false,
  );
}

/// The `todo` fence [block], line [index] of it, as [liveDiagramOf] answers
/// for a diagram: null for a fence the note has not closed, whose body would
/// be the rest of the note.
LiveDiagram? _todoBlockOf(int index, Block block, SourceBuffer buffer) {
  final lineAt = buffer.lineAt;
  final last = block.endLine - 1;
  if (last <= block.startLine ||
      fenceBody(<String>[lineAt(block.startLine), lineAt(last)])?.closed !=
          true) {
    return null;
  }
  if (index != block.startLine) {
    return (
      start: block.startLine,
      end: block.endLine,
      source: null,
      todo: true,
    );
  }
  final lines = BlockParser.blockText(block, buffer).split('\n');
  return (
    start: block.startLine,
    end: block.endLine,
    source: fenceBody(lines)?.code ?? '',
    todo: true,
  );
}

/// What line [index], in [block], draws as a fence line in `live`, or
/// null: a column's fence and a `columns` block's are bands, an unknown
/// div's are the text they are.
///
/// [runs] are the outermost `columns` blocks `live` draws, asked only for a
/// div's or a quote's line; [isHost] says whether a block's opener hosts
/// it side by side.
LiveFence? liveFenceOf(
  int index,
  Block? block,
  SourceBuffer buffer, {
  required List<LiveRun> Function() runs,
  required bool Function(int line) isHost,
}) {
  if (block == null) return null;
  final DivRole role;
  final LiveRun? run;
  if (block.kind == BlockKind.div) {
    role = block.divRole!;
    if (!role.laysOut) return null;
    run = LiveRun.holding(runs(), index);
  } else if (block.kind == BlockKind.quote) {
    // A fence in a quote is no block of the note's: its block's content,
    // read again, says what it does.
    run = LiveRun.holding(runs(), index);
    final quoted = run?.fences?[index];
    if (quoted == null) return null;
    role = quoted;
  } else {
    return null;
  }
  if (run == null) return null;
  final chip = switch (role) {
    DivRole.opensColumns => 'columns',
    DivRole.opensColumn => _columnChip(buffer.lineAt(index)),
    _ => null,
  };
  final hosted = isHost(run.start);
  final outer = index == run.start || (run.closed && index == run.end - 1);
  return (
    start: run.start,
    end: run.end,
    chip: chip,
    chipLeft: role == DivRole.opensColumns,
    hairline: role == DivRole.opensColumn,
    numbered: hosted && outer,
    numberUp: index != run.start,
  );
}

/// The chip a column's opener, [line], draws: `column`, and its width.
String _columnChip(String line) {
  final width = DivSyntax.opening(line.trimLeft())?.width;
  if (width == null) return 'column';
  final share = width == width.roundToDouble()
      ? width.round().toString()
      : width.toString();
  return 'column · $share%';
}
