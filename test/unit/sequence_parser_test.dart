// The Mermaid sequence-diagram parser (#530): participants, the message
// spellings, notes, the blocks and their sections, and the errors that name
// a line.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/sequence_model.dart';
import 'package:niman/src/diagrams/sequence_parser.dart';

SequenceDiagram _sequence(String source) => parseSequence(source);

List<SequenceMessage> _messages(SequenceDiagram diagram) =>
    diagram.items.whereType<SequenceMessage>().toList();

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

void main() {
  test('participants appear in order, an alias drawn in the box', () {
    final diagram = _sequence(
      'sequenceDiagram\nparticipant B as Bob\nactor A\nA->>B: hi\nC->>A: yo',
    );
    expect(diagram.participants.map((p) => p.id), ['B', 'A', 'C']);
    expect(diagram.participants.first.label, 'Bob');
  });

  test('every message spelling sets the line and the head', () {
    final diagram = _sequence(
      'sequenceDiagram\n'
      'A->B: solid\nA-->B: dotted\nA->>B: arrow\nA-->>B: dotted arrow\n'
      'A-xB: cross\nA--xB: dotted cross\nA-)B: async\nA--)B: dotted async\n'
      'A<<->>B: both\nA<<-->>B: both dotted',
    );
    final messages = _messages(diagram);
    expect(messages.map((m) => m.arrow), [
      SequenceArrow.none,
      SequenceArrow.none,
      SequenceArrow.filled,
      SequenceArrow.filled,
      SequenceArrow.cross,
      SequenceArrow.cross,
      SequenceArrow.open,
      SequenceArrow.open,
      SequenceArrow.filled,
      SequenceArrow.filled,
    ]);
    expect(messages.map((m) => m.dashed), [
      false, true, false, true, false, true, false, true, false, true, //
    ]);
    expect(messages.map((m) => m.twoWay).where((two) => two), hasLength(2));
    // No space round the arrow: the sender is still A, never "A-".
    expect(messages.map((m) => m.from).toSet(), {'A'});
    expect(messages.map((m) => m.to).toSet(), {'B'});
  });

  test('a name may hold a dash or an accent, and a message no text', () {
    final diagram = _sequence(
      'sequenceDiagram\nweb-server->>db: query\nUtente-->>Società\n',
    );
    expect(diagram.participants.map((p) => p.id), [
      'web-server',
      'db',
      'Utente',
      'Società',
    ]);
    expect(_messages(diagram).last.text, isEmpty);
  });

  test('an activation mark is read past, not taken for a name', () {
    final diagram = _sequence('sequenceDiagram\nA->>+B: open\nB-->>-A: close');
    expect(diagram.participants.map((p) => p.id), ['A', 'B']);
    expect(_messages(diagram), hasLength(2));
  });

  test('notes sit over, left of or right of their participants', () {
    final diagram = _sequence(
      'sequenceDiagram\nA->>B: hi\nNote over A,B: both\n'
      'note left of A: left\nNote right of B: right',
    );
    final notes = diagram.items.whereType<SequenceNote>().toList();
    expect(notes.map((n) => n.placement), [
      SequenceNotePlacement.over,
      SequenceNotePlacement.leftOf,
      SequenceNotePlacement.rightOf,
    ]);
    expect(notes.first.participants, ['A', 'B']);
    expect(notes.first.text, 'both');
  });

  test('blocks nest and split into sections', () {
    final diagram = _sequence(
      'sequenceDiagram\n'
      'loop Every minute\n'
      '  alt is sick\n    A->>B: not good\n  else is well\n    A->>B: fine\n'
      '  end\n'
      'end\n'
      'critical Connect\n  A->>B: open\noption Timeout\n  A->>B: retry\nend\n'
      'par\n  A->>B: one\nand\n  A->>C: two\nend\n'
      'break when down\n  A->>B: bail\nend',
    );
    final blocks = diagram.items.whereType<SequenceBlock>().toList();
    expect(blocks.map((b) => b.kind), [
      SequenceBlockKind.loop,
      SequenceBlockKind.critical,
      SequenceBlockKind.par,
      SequenceBlockKind.breakOut,
    ]);
    final alt = blocks.first.sections.single.items.single as SequenceBlock;
    expect(alt.sections.map((s) => s.label), ['is sick', 'is well']);
    expect(blocks[1].sections.map((s) => s.label), ['Connect', 'Timeout']);
    expect(blocks[2].sections, hasLength(2));
    expect(SequenceBlockKind.breakOut.title, 'break');
  });

  test('rect and box group what they hold and close at their own end', () {
    final diagram = _sequence(
      'sequenceDiagram\n'
      'box Aqua The team\n  participant A\n  participant B\nend\n'
      'loop forever\n  rect rgb(200, 220, 255)\n    A->>B: hi\n  end\n'
      '  B->>A: back\nend',
    );
    final loop = diagram.items.single as SequenceBlock;
    expect(loop.sections.single.items, hasLength(2));
  });

  test('what only colours or animates is stepped over', () {
    final diagram = _sequence(
      'sequenceDiagram\nautonumber\ntitle Hello\nactivate A\nA->>B: hi\n'
      'deactivate A\ncreate participant C\nB->>C: new\ndestroy C',
    );
    expect(_messages(diagram), hasLength(2));
    expect(diagram.participants.map((p) => p.id), ['A', 'B', 'C']);
  });

  test('front matter and comments come before the header', () {
    final diagram = _sequence(
      '---\ntitle: x\n---\n%% a note\n'
      'sequenceDiagram\nA->>B: "50%% off" %% gone',
    );
    expect(_messages(diagram).single.text, '"50%% off"');
  });

  test('a block left open names the line it opened on', () {
    expect(
      () => parseSequence('sequenceDiagram\nA->>B: hi\nloop again\nA->>B: x'),
      _error(3, 'missing "end"'),
    );
  });

  test('an end or an else with no block is an error on its line', () {
    expect(
      () => parseSequence('sequenceDiagram\nA->>B: hi\nend'),
      _error(3, 'unexpected "end"'),
    );
    expect(
      () => parseSequence('sequenceDiagram\nA->>B: hi\nelse no'),
      _error(3, 'unexpected "else"'),
    );
  });

  test('a line that is no statement names itself', () {
    expect(
      () => parseSequence('sequenceDiagram\nA->>B: hi\nA => B'),
      _error(3, 'found "A => B"'),
    );
  });

  test('a sequence with no participant is an error', () {
    expect(
      () => parseSequence('sequenceDiagram\n'),
      _error(1, 'needs a participant'),
    );
  });
}
