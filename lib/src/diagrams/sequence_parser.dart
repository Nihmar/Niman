/// The parser behind a `sequenceDiagram` Mermaid fence (#530).
///
/// Like the flowchart parser it reports a syntax error as a
/// [MermaidParseException] naming the line, never a silent mis-draw. What
/// a sequence draws is read — participants, messages, notes, the frames of
/// `loop`, `alt`, `opt`, `par`, `critical` and `break` — and what it would
/// only colour or animate (`rect`, `box`, activations, `autonumber`) is
/// stepped over without breaking the blocks around it.
library;

import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';
import 'package:niman/src/diagrams/sequence_model.dart';

/// Parses a sequence body (the fence's content, header included).
SequenceDiagram parseSequence(String source) => _SequenceParser(source).parse();

/// A participant's name: anything but spaces and the characters a message
/// or a note uses round it. A `-` may be part of it (`web-server`).
const String _name = r'[^\s:,;<>+]+';

/// A participant declaration, `create` or not, with its alias.
final RegExp _participant = RegExp(
  '^(?:create\\s+)?(?:participant|actor)\\s+($_name)'
  r'(?:\s+as\s+(.+))?$',
  caseSensitive: false,
);

/// A message: sender, arrow, an activation mark, receiver, text. The
/// sender is the shortest name before an arrow, as Mermaid reads it, so
/// `A-->>B` is from A and `web-server->>db` from `web-server`.
final RegExp _message = RegExp(
  '^($_name?)\\s*'
  r'(<<-->>|<<->>|-->>|->>|-->|->|--x|-x|--\)|-\))\s*[+-]?\s*'
  '($_name)\\s*(?::\\s*(.*))?\$',
);

/// `Note over A`, `Note left of A: text`, `Note right of A,B: text`.
final RegExp _note = RegExp(
  r'^note\s+(over|left of|right of)\s+'
  '($_name(?:\\s*,\\s*$_name)*)\\s*:\\s*(.*)\$',
  caseSensitive: false,
);

/// The block openers and the frame they draw.
const Map<String, SequenceBlockKind> _openers = {
  'loop': SequenceBlockKind.loop,
  'opt': SequenceBlockKind.opt,
  'alt': SequenceBlockKind.alt,
  'par': SequenceBlockKind.par,
  'critical': SequenceBlockKind.critical,
  'break': SequenceBlockKind.breakOut,
};

/// The words that split a block into sections: `alt … else`, `par … and`,
/// `critical … option`.
const Set<String> _splitters = {'else', 'and', 'option'};

/// The blocks that colour or group what they hold and draw no frame: their
/// content is read as if they were not there, and their `end` closes them.
const Set<String> _groups = {'rect', 'box'};

/// The words whose line carries nothing to draw.
const Set<String> _ignored = {
  'activate',
  'deactivate',
  'autonumber',
  'title',
  'acctitle',
  'accdescr',
  'link',
  'links',
  'properties',
  'details',
  'destroy',
};

/// One section of an open block: the text after its opener or splitter,
/// and what it holds so far.
typedef _OpenSection = ({String label, List<SequenceItem> items});

/// An open block: its frame (none for a group), the line it opened on, and
/// its sections.
typedef _OpenBlock = ({
  SequenceBlockKind? kind,
  int line,
  List<_OpenSection> sections,
});

/// Parses one sequence diagram.
final class _SequenceParser {
  new(this.source);

  final String source;
  final List<SequenceParticipant> _participants = [];
  final Map<String, int> _byId = {};
  final List<SequenceItem> _items = [];
  final List<_OpenBlock> _stack = [];

  /// Runs the parse.
  SequenceDiagram parse() {
    final lines = source.split('\n');
    var sawHeader = false;
    for (var index = mermaidBodyStart(lines); index < lines.length; index++) {
      final line = stripMermaidComment(lines[index]).trim();
      if (line.isEmpty) continue;
      if (!sawHeader) {
        if (_firstWord(line).toLowerCase() != 'sequencediagram') {
          throw MermaidParseException(index + 1, 'expected "sequenceDiagram"');
        }
        sawHeader = true;
        continue;
      }
      _line(line, index + 1);
    }
    if (!sawHeader) {
      throw const MermaidParseException(1, 'expected "sequenceDiagram"');
    }
    if (_stack.isNotEmpty) {
      throw MermaidParseException(_stack.last.line, 'missing "end"');
    }
    if (_participants.isEmpty) {
      throw const MermaidParseException(1, 'a sequence needs a participant');
    }
    return SequenceDiagram(
      participants: List.unmodifiable(_participants),
      items: List.unmodifiable(_items),
    );
  }

  void _line(String line, int number) {
    final word = _firstWord(line).toLowerCase();
    if (word == 'end') return _close(number);
    if (_ignored.contains(word)) return;
    final declaration = _participant.firstMatch(line);
    if (declaration != null) {
      return _declare(declaration.group(1)!, declaration.group(2)?.trim());
    }
    final opener = _openers[word];
    if (opener != null || _groups.contains(word)) {
      final label = opener == null ? '' : line.substring(word.length).trim();
      _stack.add((
        kind: opener,
        line: number,
        sections: [(label: label, items: <SequenceItem>[])],
      ));
      return;
    }
    if (_splitters.contains(word)) {
      if (_stack.isEmpty || _stack.last.kind == null) {
        throw MermaidParseException(number, 'unexpected "$word"');
      }
      _stack.last.sections.add((
        label: line.substring(word.length).trim(),
        items: <SequenceItem>[],
      ));
      return;
    }
    final note = _note.firstMatch(line);
    if (note != null) return _noteItem(note);
    final message = _message.firstMatch(line);
    if (message != null) return _messageItem(message);
    throw MermaidParseException(
      number,
      'expected a message ("A->>B: text"), a note or a block, found "$line"',
    );
  }

  void _messageItem(RegExpMatch match) {
    final from = match.group(1)!;
    final to = match.group(3)!;
    final operator = match.group(2)!;
    _ensure(from);
    _ensure(to);
    _current.add(
      SequenceMessage(
        from: from,
        to: to,
        text: (match.group(4) ?? '').trim(),
        dashed: operator.contains('--'),
        twoWay: operator.startsWith('<<'),
        arrow: operator.endsWith('>>')
            ? SequenceArrow.filled
            : operator.endsWith('x')
            ? SequenceArrow.cross
            : operator.endsWith(')')
            ? SequenceArrow.open
            : SequenceArrow.none,
      ),
    );
  }

  void _noteItem(RegExpMatch match) {
    final ids = [for (final id in match.group(2)!.split(',')) id.trim()]
      ..forEach(_ensure);
    _current.add(
      SequenceNote(
        placement: switch (match.group(1)!.toLowerCase()) {
          'over' => SequenceNotePlacement.over,
          'left of' => SequenceNotePlacement.leftOf,
          _ => SequenceNotePlacement.rightOf,
        },
        participants: ids,
        text: match.group(3)!.trim(),
      ),
    );
  }

  void _close(int number) {
    if (_stack.isEmpty) {
      throw MermaidParseException(number, 'unexpected "end"');
    }
    final open = _stack.removeLast();
    final kind = open.kind;
    if (kind == null) {
      // A group: what it held is read as if it were not there.
      _current.addAll(open.sections.single.items);
      return;
    }
    _current.add(
      SequenceBlock(
        kind: kind,
        sections: [
          for (final section in open.sections)
            SequenceSection(
              label: section.label,
              items: List.unmodifiable(section.items),
            ),
        ],
      ),
    );
  }

  /// The list new items land in: the open section, or the top level.
  List<SequenceItem> get _current =>
      _stack.isEmpty ? _items : _stack.last.sections.last.items;

  /// Names participant [id], in the order it first appears.
  void _ensure(String id) {
    if (_byId.containsKey(id)) return;
    _byId[id] = _participants.length;
    _participants.add(SequenceParticipant(id: id, label: id));
  }

  /// Declares participant [id], with the [alias] drawn in its box.
  void _declare(String id, String? alias) {
    _ensure(id);
    if (alias == null || alias.isEmpty) return;
    _participants[_byId[id]!] = SequenceParticipant(id: id, label: alias);
  }

  static String _firstWord(String line) =>
      RegExp('^[A-Za-z_][A-Za-z0-9_-]*').firstMatch(line)?.group(0) ?? '';
}
