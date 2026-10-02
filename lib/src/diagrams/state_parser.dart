/// The parser behind a `stateDiagram` (and `stateDiagram-v2`) Mermaid fence
/// (#530).
///
/// A state diagram is a graph of boxes, so it is parsed into the flowchart
/// model the engine lays out and draws. A state is a rounded box, `[*]` a
/// start (before an arrow) or an end (after one) — one of each per state
/// that holds others —, `<<fork>>` and `<<join>>` a bar, `<<choice>>` a
/// small diamond, a composite state a subgraph, a note a box tied to its
/// state. A transition into a composite state enters by its start, one out
/// of it leaves by its end, as Mermaid means them.
library;

import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';

/// A state's name: anything but spaces, a colon or a brace, and `[*]`.
const String _name = r'(?:\[\*\]|[^\s:{}]+?)';

/// `A --> B : label`.
final RegExp _transition = RegExp(
  '^($_name)\\s*-->\\s*($_name)\\s*(?::\\s*(.*))?\$',
);

/// `state "Description" as Id`, `state Id <<fork>>`, `state Id {`.
final RegExp _state = RegExp(
  r'^state\s+(?:"([^"]*)"\s+as\s+)?([^\s{<:]+)'
  r'\s*(?:<<(\w+)>>)?\s*(\{)?\s*$',
);

/// `Id : description`.
final RegExp _description = RegExp(r'^([^\s:]+)\s*:\s*(.*)$');

/// `note left of Id : text`, or the first line of a note that runs to
/// `end note`.
final RegExp _note = RegExp(
  r'^note\s+(left|right)\s+of\s+([^\s:]+)\s*(?::\s*(.*))?$',
  caseSensitive: false,
);

/// The words whose line carries nothing to draw.
const Set<String> _ignored = {
  'classdef',
  'class',
  'style',
  'scale',
  'hide',
  'acctitle',
  'accdescr',
};

/// Parses a state diagram (the fence's content, header included).
Flowchart parseStateDiagram(String source) => _StateParser(source).parse();

/// A state while it is being read.
typedef _State = ({
  String id,
  String? label,
  FlowNodeShape shape,
  List<String> lines,
});

/// An open composite state.
typedef _Composite = ({
  String id,
  String title,
  int line,
  String? parent,
  List<String> ids,
});

/// A transition, its ends as written: a composite is resolved once read.
typedef _Transition = ({String from, String to, String? label});

final class _StateParser {
  new(this.source);

  final String source;
  final Map<String, _State> _states = {};
  final List<FlowNode> _notes = [];
  final List<_Transition> _transitions = [];

  /// Each note and the state it was written for, tied once every
  /// composite is known.
  final List<(String, String)> _noteTargets = [];

  /// The composites closed so far, inner before outer.
  final List<_Composite> _closed = [];
  final List<_Composite> _open = [];

  /// Every composite's members once closed, by its id.
  final Map<String, List<String>> _members = {};
  FlowDirection _direction = FlowDirection.topDown;

  /// An open multi-line note: its state and the lines so far.
  ({String target, List<String> lines})? _noteBody;
  bool _accessible = false;

  Flowchart parse() {
    final lines = source.split('\n');
    var index = mermaidBodyStart(lines);
    final header = index < lines.length
        ? stripMermaidComment(lines[index]).trim().toLowerCase()
        : '';
    if (header != 'statediagram' && header != 'statediagram-v2') {
      throw MermaidParseException(index + 1, 'expected "stateDiagram"');
    }
    var noteLine = 0;
    for (index++; index < lines.length; index++) {
      final raw = stripMermaidComment(lines[index]).trim();
      final note = _noteBody;
      if (note != null) {
        if (raw.toLowerCase() == 'end note') {
          _noteFor(note.target, note.lines.join('\n'));
          _noteBody = null;
        } else {
          note.lines.add(raw);
        }
        continue;
      }
      if (raw.isEmpty) continue;
      if (raw.toLowerCase().startsWith('note')) noteLine = index + 1;
      _line(raw, index + 1);
    }
    if (_noteBody != null) {
      throw MermaidParseException(noteLine, 'missing "end note"');
    }
    if (_open.isNotEmpty) {
      throw MermaidParseException(_open.last.line, 'missing "}"');
    }
    final edges = [
      for (final transition in _transitions)
        FlowEdge(
          from: _exit(transition.from),
          to: _entry(transition.to),
          label: transition.label,
        ),
      ..._ties(),
    ];
    return Flowchart(
      direction: _direction,
      nodes: [
        // A composite state is its subgraph; one that holds nothing stays
        // a state, so a transition to it still has somewhere to land.
        for (final state in _states.values)
          if (_members[state.id]?.isNotEmpty != true)
            FlowNode(
              id: state.id,
              label: state.lines.isNotEmpty
                  ? state.lines.join('\n')
                  : state.label ?? state.id,
              shape: state.shape,
            ),
        ..._notes,
      ],
      edges: edges,
      subgraphs: List.unmodifiable([
        for (final composite in _closed)
          FlowSubgraph(
            id: composite.id,
            title: composite.title,
            nodeIds: List.unmodifiable(composite.ids),
            parent: composite.parent,
          ),
      ]),
    );
  }

  void _line(String written, int number) {
    // A `:::class` after a name is a colour, drawn without.
    final line = written.replaceAll(RegExp(r':::[\w-]+'), '');
    if (_accessible) {
      _accessible = !line.contains('}');
      return;
    }
    final word = line.split(RegExp(r'[\s:{]')).first.toLowerCase();
    if (_ignored.contains(word)) {
      _accessible =
          word == 'accdescr' && line.contains('{') && !line.contains('}');
      return;
    }
    if (line == '--') return; // A concurrent region's border.
    if (line == '}') return _close(number);
    if (word == 'direction') {
      final direction = FlowDirection.parse(line.substring(9).trim());
      if (direction == null) {
        throw MermaidParseException(number, 'unknown direction');
      }
      if (_open.isEmpty) _direction = direction;
      return;
    }
    final transition = _transition.firstMatch(line);
    if (transition != null) {
      final label = transition.group(3)?.trim();
      _transitions.add((
        from: _end(transition.group(1)!, start: true),
        to: _end(transition.group(2)!, start: false),
        label: label == null || label.isEmpty ? null : label,
      ));
      return;
    }
    final state = _state.firstMatch(line);
    if (state != null) return _declare(state, number);
    final note = _note.firstMatch(line);
    if (note != null) {
      final text = note.group(3);
      if (text == null) {
        _noteBody = (target: note.group(2)!, lines: <String>[]);
      } else {
        _noteFor(note.group(2)!, text.trim());
      }
      return;
    }
    final description = _description.firstMatch(line);
    if (description != null) {
      _stateOf(description.group(1)!).lines.add(description.group(2)!.trim());
      return;
    }
    throw MermaidParseException(
      number,
      'expected a transition ("A --> B") or a state, found "$line"',
    );
  }

  void _declare(RegExpMatch match, int number) {
    final id = match.group(2)!;
    final shape = switch (match.group(3)?.toLowerCase()) {
      'fork' || 'join' => FlowNodeShape.bar,
      'choice' => FlowNodeShape.diamond,
      _ => FlowNodeShape.round,
    };
    final label = match.group(1) ?? (shape == FlowNodeShape.round ? null : '');
    final state = _stateOf(id, shape: shape, label: label);
    if (match.group(4) == null) return;
    _open.add((
      id: id,
      title: state.label ?? id,
      line: number,
      parent: _open.isEmpty ? null : _open.last.id,
      ids: <String>[],
    ));
  }

  void _close(int number) {
    if (_open.isEmpty) throw MermaidParseException(number, 'unexpected "}"');
    final composite = _open.removeLast();
    _members[composite.id] = composite.ids;
    _closed.add(composite);
  }

  /// The state `[*]` is in the scope open now: its start before an arrow,
  /// its end after one. Any other name is itself.
  String _end(String name, {required bool start}) {
    if (name != '[*]') {
      _stateOf(name);
      return name;
    }
    final scope = _open.isEmpty ? '' : _open.last.id;
    final id = start ? '[*] start $scope' : '[*] end $scope';
    _stateOf(
      id,
      shape: start ? FlowNodeShape.start : FlowNodeShape.end,
      label: '',
    );
    return id;
  }

  /// Where a transition into [id] arrives: a composite's start, else its
  /// first state; any other state itself.
  String _entry(String id) {
    final members = _statesOf(id);
    if (members.isEmpty) return id;
    final start = '[*] start $id';
    return members.contains(start) ? start : _entry(members.first);
  }

  /// Where a transition out of [id] leaves: a composite's end, else its
  /// last state; any other state itself.
  String _exit(String id) {
    final members = _statesOf(id);
    if (members.isEmpty) return id;
    final end = '[*] end $id';
    return members.contains(end) ? end : _exit(members.last);
  }

  /// The states of composite [id], its notes left out: empty for a state
  /// that is not a composite.
  List<String> _statesOf(String id) => [
    for (final member in _members[id] ?? const <String>[])
      if (!_noteIds.contains(member)) member,
  ];

  Set<String> get _noteIds => {for (final note in _notes) note.id};

  void _noteFor(String target, String text) {
    final id = 'note-${_notes.length}';
    _notes.add(FlowNode(id: id, label: text, shape: FlowNodeShape.note));
    _join(id);
    _stateOf(target);
    _noteTargets.add((id, target));
  }

  /// The dotted ties from each note to its state. A composite state is a
  /// box rather than a node, so its note goes in the box — and in the
  /// boxes round it — tied to where the composite is entered.
  List<FlowEdge> _ties() {
    final byId = {for (final composite in _closed) composite.id: composite};
    return [
      for (final (note, target) in _noteTargets)
        FlowEdge(
          from: () {
            if (_statesOf(target).isEmpty) return target;
            for (var box = byId[target]; box != null;) {
              if (!box.ids.contains(note)) box.ids.add(note);
              box = box.parent == null ? null : byId[box.parent];
            }
            return _entry(target);
          }(),
          to: note,
          style: FlowEdgeStyle.dotted,
          end: FlowEdgeEnd.none,
        ),
    ];
  }

  /// State [id], made on first mention — inside every composite open now —
  /// and given a [shape] or [label] a declaration writes for it.
  _State _stateOf(String id, {FlowNodeShape? shape, String? label}) {
    final existing = _states[id];
    if (existing != null) {
      if (shape == null && label == null) return existing;
      return _states[id] = (
        id: id,
        label: label ?? existing.label,
        shape: shape ?? existing.shape,
        lines: existing.lines,
      );
    }
    _join(id);
    return _states[id] = (
      id: id,
      label: label,
      shape: shape ?? FlowNodeShape.round,
      lines: <String>[],
    );
  }

  void _join(String id) {
    for (final composite in _open) {
      composite.ids.add(id);
    }
  }
}
