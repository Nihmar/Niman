/// The edge spellings of a Mermaid flowchart (#530): what stroke and caps
/// the run of dashes, equals and dots between two nodes means.
///
/// Mermaid writes an edge as an optional tail cap, a run of `-`, `=` or a
/// dotted `-.-`, and an optional head cap — and a longer run is a longer
/// link (`--->`, `===>`, `-..->`), drawn here like a short one. A label is
/// written in pipes after the edge (`-->|yes|`) or inside it, between an
/// opening and a closing run (`-- yes -->`, `== yes ==>`, `-. yes .->`).
library;

import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';

/// One scanned edge: where it ends in the statement and what it means.
typedef FlowEdgeScan = ({
  int end,
  FlowEdgeStyle style,
  FlowEdgeEnd start,
  FlowEdgeEnd endCap,
  String? label,
});

/// An unlabelled edge: tail cap, run, head cap.
final RegExp _plain = RegExp(r'([<xo])?(-{2,}|={2,}|-\.+-)([>xo])?');

/// An edge with its label inside: an opening run, the label, a closing run
/// of the same stroke.
final RegExp _labelled = RegExp(
  r'--\s*(.+?)\s*(-{2,}[>xo]|-{3,})'
  r'|==\s*(.+?)\s*(={2,}[>xo]|={3,})'
  r'|-\.\s*(.+?)\s*(-?\.+-+[>xo]?)',
);

/// The opening runs that must be followed by an edge spelling, with the
/// spellings to suggest when they are not (the error a dangling `--` gives).
const List<(String, List<String>)> _dangling = [
  ('--', ['-->', '--x', '--o', '---']),
  ('==', ['==>', '==x', '==o', '===']),
  ('-.', ['-.->', '-.-x', '-.-o', '-.-']),
];

/// The edge at [position] of [source], a statement on diagram line [line];
/// null when there is none. A run that opens an edge and is not closed is
/// a [MermaidParseException] naming the spellings that would close it.
FlowEdgeScan? scanFlowEdge(String source, int position, int line) {
  final plain = _plainAt(source, position);
  if (plain != null) return plain;
  final labelled = _labelled.matchAsPrefix(source, position);
  if (labelled != null) {
    final (style, text, close) = labelled.group(1) != null
        ? (FlowEdgeStyle.solid, labelled.group(1)!, labelled.group(2)!)
        : labelled.group(3) != null
        ? (FlowEdgeStyle.thick, labelled.group(3)!, labelled.group(4)!)
        : (FlowEdgeStyle.dotted, labelled.group(5)!, labelled.group(6)!);
    return (
      end: labelled.end,
      style: style,
      start: FlowEdgeEnd.none,
      endCap: _cap(close[close.length - 1]),
      label: text.trim(),
    );
  }
  for (final (prefix, options) in _dangling) {
    if (source.startsWith(prefix, position)) {
      throw MermaidParseException(
        line,
        'expected ${options.join(", ")} after "$prefix"',
      );
    }
  }
  return null;
}

/// The unlabelled edge at [position], or null. A bare `--` or `==` is the
/// opening of a labelled one, not an edge; an `x` or `o` straight before
/// a letter is the label's first letter, not a cap (`--xenon-->`).
FlowEdgeScan? _plainAt(String source, int position) {
  final match = _plain.matchAsPrefix(source, position);
  if (match == null) return null;
  final run = match.group(2)!;
  var head = match.group(3);
  var end = match.end;
  if ((head == 'x' || head == 'o') && end < source.length) {
    if (_isWordUnit(source.codeUnitAt(end))) {
      head = null;
      end--;
    }
  }
  final tail = match.group(1);
  final dotted = run.contains('.');
  if (!dotted && head == null && tail == null && run.length < 3) return null;
  return (
    end: end,
    style: dotted
        ? FlowEdgeStyle.dotted
        : run.startsWith('=')
        ? FlowEdgeStyle.thick
        : FlowEdgeStyle.solid,
    start: _cap(tail),
    endCap: _cap(head),
    label: null,
  );
}

/// The cap a spelling's end character draws.
FlowEdgeEnd _cap(String? char) => switch (char) {
  '>' || '<' => FlowEdgeEnd.arrow,
  'x' => FlowEdgeEnd.cross,
  'o' => FlowEdgeEnd.circle,
  _ => FlowEdgeEnd.none,
};

/// Whether [unit] can be part of a node id or a word.
bool _isWordUnit(int unit) =>
    (unit >= 0x41 && unit <= 0x5A) ||
    (unit >= 0x61 && unit <= 0x7A) ||
    (unit >= 0x30 && unit <= 0x39) ||
    unit == 0x5F ||
    unit > 0x7F;
