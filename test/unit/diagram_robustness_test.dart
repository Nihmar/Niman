// Whatever a note's Mermaid fence says, the engine (#530) answers with a
// drawing or a syntax error: never a throw, which the read view drew as
// Flutter's error box and which failed a whole export, and never a drawing
// of NaN or Infinity, which the SVG writes as attributes no reader takes.
//
// One sample of every kind drawn, then the same sample with each number
// swapped for an extreme one and, from a fixed seed, cut, doubled and
// sprinkled with Mermaid's punctuation — what a fence holds halfway through
// being typed.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_drawing.dart';
import 'package:niman/src/diagrams/diagram_result.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_svg.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';

const DiagramStyle _style = DiagramStyle();

const List<String> _samples = [
  '''
flowchart LR
  A[Start] -->|go| B{Choose}
  B -- yes --> C((Done))
  B -. no .-> D[(Store)]
  subgraph S [Group]
    D --> E>Flag]
  end
  E ==> A''',
  '''
mindmap
  root((Notes))
    Disk
      One file a note
    Index
      FTS5''',
  '''
sequenceDiagram
  participant A as Alice
  actor B
  A->>B: Hello
  loop Every 5 minutes
    B-->>A: Hi
  end
  Note over A,B: A note
  alt ok
    A-)B: Fine
  else not ok
    A-xB: Bad
  end''',
  '''
pie title Pets
  "Dogs" : 386
  "Cats" : 85.5
  "Rats" : 15''',
  '''
classDiagram
  Animal <|-- Duck
  Animal "1" *-- "many" Leg : has
  class Animal {
    +int age
    +isMammal() bool
  }''',
  '''
stateDiagram-v2
  [*] --> Still
  Still --> Moving : push
  state Moving {
    [*] --> Slow
    Slow --> Fast
  }
  Moving --> [*]''',
  '''
erDiagram
  CUSTOMER ||--o{ ORDER : places
  ORDER ||--|{ LINE-ITEM : contains
  CUSTOMER {
    string name
    int age
  }''',
  '''
gantt
  title Plan
  dateFormat YYYY-MM-DD
  excludes weekends
  section Build
    Parse :a1, 2024-01-01, 10d
    Lay out :after a1, 5d
  section Ship
    Release :milestone, 2024-02-01, 0d''',
  '''
timeline
  title History
  2002 : LinkedIn
  2004 : Facebook : Google
       : Orkut''',
  '''
journey
  title My day
  section Work
    Make tea: 5: Me
    Do work: 1: Me, Cat''',
  '''
gitGraph
  commit id: "Alpha"
  branch develop order: 2
  checkout develop
  commit
  checkout main
  merge develop tag: "v2.0"''',
  '''
kanban
  Todo
    [Write docs]
  id2[In progress]
    id6[Build]@{ priority: 'High' }''',
  '''
quadrantChart
  title Reach
  x-axis Low --> High
  y-axis Low --> High
  quadrant-1 Expand
  Campaign A: [0.3, 0.6]
  Campaign B: [0.95, 0.05] radius: 10''',
  '''
xychart-beta
  title "Sales"
  x-axis [jan, feb, mar]
  y-axis "Revenue" 0 --> 10000
  bar [5000, 6000, 7500]
  line [4000, 6500, 7000]''',
  '''
sankey-beta
Solar,Grid,60
Wind,Grid,40
Grid,Homes,70.5''',
  '''
block-beta
  columns 3
  a["A"]:2 b
  block:group:3
    c d
  end
  a --> c''',
  '''
packet-beta
0-15: "Source Port"
16-31: "Destination Port"
+8: "Length"''',
  '''
radar-beta
  axis m["Math"], s["Science"], e
  curve a{85, 90, 80}
  max 100
  ticks 4''',
  '''
treemap-beta
"Work"
    "Projects": 180
    "Meetings": 90
"Misc": 0.5''',
  '''
requirementDiagram
requirement disk {
  id: 1
  text: One file a note.
  risk: high
  verifymethod: test
}
element fts {
  type: "SQLite"
}
fts - satisfies -> disk''',
  '''
C4Context
  title System
  Person(user, "User", "Writes notes")
  System_Boundary(app, "Niman") {
    System(ui, "App", "Flutter")
  }
  Rel(user, ui, "Uses")''',
  '''
architecture-beta
  group api(cloud)[API]
  service db(database)[Database] in api
  service server(server)[Server] in api
  db:L -- R:server''',
];

/// What a number in a sample is swapped for.
final List<String> _extremes = [
  '0',
  '-1',
  '0.000001',
  '0.0000000000000000000001',
  '100000000000000000',
  '9' * 40,
  '1e308',
  'NaN',
  'Infinity',
  '-Infinity',
];

/// The punctuation Mermaid's grammars turn on.
const String _punctuation = '[](){}<>|"\':;,-.=%#&@*+\\/~`';

/// What is wrong with [source]'s outcome, or null when it is a drawing of
/// finite numbers or a syntax error.
///
/// It asks the engine itself, not [resolveDiagram]: that one shows any other
/// throw as an error on the first line too, which would hide the fault this
/// test is here to find.
String? _fault(String source) {
  final DiagramDrawing drawing;
  try {
    drawing = layOutDiagram(source, _style);
  } on MermaidParseException {
    return null;
  } on Object catch (error) {
    return 'threw $error';
  }
  final size = drawing.size;
  if (!size.width.isFinite || !size.height.isFinite) return 'drew $size';
  final String svg;
  try {
    svg = drawingSvg(drawing, _style);
  } on Object catch (error) {
    return 'threw $error writing the SVG';
  }
  // In an attribute, where the numbers are: a label may say NaN.
  final unreadable = _unreadable.firstMatch(svg);
  if (unreadable != null) return 'drew ${unreadable.group(0)}';
  return null;
}

/// An attribute holding a number no SVG reader takes.
final RegExp _unreadable = RegExp(r'\w+="[^"]*(?:NaN|Infinity)[^"]*"');

/// Every source of [sources] whose outcome is wrong, with what is wrong.
List<String> _faults(Iterable<String> sources) => [
  for (final source in sources)
    if (_fault(source) case final fault?) '$fault for:\n$source',
];

/// The first few of [faults], to read in a failure.
String _firstOf(List<String> faults) => faults.take(5).join('\n\n');

void main() {
  test('a fault of the engine is shown as the source, not thrown', () {
    // No fence is known to reach it: a throw of the layout's own stands in.
    final result = guardDiagram(() => throw StateError('broken layout'));
    expect(
      result,
      isA<DiagramFailed>()
          .having((r) => r.error.line, 'line', 1)
          .having((r) => r.error.message, 'message', contains('broken layout')),
    );
    final parse = guardDiagram(
      () => throw const MermaidParseException(3, 'expected "-->"'),
    );
    expect(parse, isA<DiagramFailed>().having((r) => r.error.line, 'line', 3));
  });

  test('every sample draws', () {
    for (final source in _samples) {
      expect(
        resolveDiagram(source, _style),
        isA<DiagramReady>(),
        reason: source,
      );
    }
  });

  test('every number swapped for an extreme one draws or names a line', () {
    final number = RegExp(r'-?\d+(?:\.\d+)?');
    final faults = _faults([
      for (final source in _samples)
        for (final match in number.allMatches(source))
          for (final extreme in _extremes)
            source.replaceRange(match.start, match.end, extreme),
    ]);
    expect(faults, isEmpty, reason: _firstOf(faults));
  });

  test('a fence cut, doubled or punctuated draws or names a line', () {
    final random = math.Random(530);
    final mutations = <String>[];
    for (final source in _samples) {
      for (var round = 0; round < 300; round++) {
        final lines = source.split('\n');
        final at = random.nextInt(lines.length);
        final String mutated;
        switch (random.nextInt(5)) {
          case 0:
            mutated = source.substring(0, random.nextInt(source.length + 1));
          case 1:
            mutated = ([...lines]..removeAt(at)).join('\n');
          case 2:
            mutated = ([...lines]..insert(at, lines[at])).join('\n');
          case 3:
            final other = random.nextInt(lines.length);
            final swapped = [...lines];
            swapped[at] = lines[other];
            swapped[other] = lines[at];
            mutated = swapped.join('\n');
          default:
            final spot = random.nextInt(source.length + 1);
            final mark = _punctuation[random.nextInt(_punctuation.length)];
            mutated = source.replaceRange(spot, spot, mark);
        }
        mutations.add(mutated);
      }
    }
    final faults = _faults(mutations);
    expect(faults, isEmpty, reason: _firstOf(faults));
  });
}
