// A Mermaid packet diagram (#530): its fields read bit by bit, laid out in
// rows of 32 with the bit numbers over them, and drawn on the canvas and in
// the SVG.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_svg.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/diagrams/packet_layout.dart';
import 'package:niman/src/diagrams/packet_parser.dart';

const DiagramStyle _style = DiagramStyle();

const String _udp = '''
packet-beta
title UDP #38; more
0-15: "Source Port"
16-31: "Destination Port"
+8: "Length"
40: "F"
+47: "A field that runs past the end of its row"
''';

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

PacketLayout _layout(String source) =>
    layoutPacket(parsePacket(source), _style);

void main() {
  test('fields are read by range, by bit and by count', () {
    final chart = parsePacket(_udp);
    expect(chart.title, 'UDP & more');
    expect(
      [for (final f in chart.fields) (f.start, f.end)],
      [(0, 15), (16, 31), (32, 39), (40, 40), (41, 87)],
    );
    expect(chart.fields.first.label, 'Source Port');
  });

  test('a field that leaves a gap or does not read names its line', () {
    expect(
      () => parsePacket('packet-beta\n0-7: "a"\n9-15: "b"'),
      _error(3, 'start at bit 8'),
    );
    expect(
      () => parsePacket('packet-beta\n0-7: "a"\n8-4: "b"'),
      _error(3, 'before it starts'),
    );
    expect(() => parsePacket('packet-beta\n+0: "a"'), _error(2, 'one bit'));
    expect(
      () => parsePacket('packet-beta\n0-99999999999999999999999: "a"'),
      _error(2, 'at most'),
    );
    expect(() => parsePacket('packet-beta\n0-7: ""'), _error(2, 'a name'));
    expect(() => parsePacket('packet-beta\nhello'), _error(2, 'a field'));
    expect(() => parsePacket('packet-beta\ntitle T'), _error(1, 'a field'));
  });

  test('a row holds 32 bits, every bit as wide', () {
    final layout = _layout(_udp);
    final [source, destination, length, flag, ...] = layout.boxes;
    expect(source.rect.top, destination.rect.top);
    expect(source.rect.right, closeTo(destination.rect.left, 1e-9));
    expect(length.rect.top, greaterThan(source.rect.bottom));
    expect(length.rect.left, closeTo(source.rect.left, 1e-9));
    final bit = flag.rect.width;
    expect(source.rect.width, closeTo(16 * bit, 1e-6));
    expect(length.rect.width, closeTo(8 * bit, 1e-6));
  });

  test('a field past the end of its row goes on in the next', () {
    final layout = _layout(_udp);
    final pieces = layout.boxes.skip(4).toList();
    expect(pieces, hasLength(2));
    expect(pieces[1].rect.top, greaterThan(pieces[0].rect.bottom));
    expect(pieces[1].rect.left, closeTo(layout.boxes.first.rect.left, 1e-9));
    expect(pieces[0].lines.join(' '), pieces[1].lines.join(' '));
    // 41-63 on one row, 64-87 on the next: 23 bits and 24.
    expect(pieces[0].rect.width / pieces[1].rect.width, closeTo(23 / 24, 1e-9));
  });

  test("a one-bit field is wide enough for its name's longest word", () {
    final layout = _layout('packet-beta\n0-5: "Reserved"\n6: "URG"\n7: "ACK"');
    final urg = layout.boxes[1].rect;
    expect(
      urg.width,
      greaterThanOrEqualTo(DiagramMetrics.textWidth('URG', _style.fontSize)),
    );
  });

  test('bit numbers stay clear of each other, however narrow the box', () {
    final layout = _layout(
      'packet-beta\n0-99: "a"\n100-101: "b"\n102: "c"\n103: "d"',
    );
    final numbers = [
      for (final n in layout.numbers)
        if (int.parse(n.text) >= 100) n.box,
    ];
    expect(numbers, hasLength(4));
    for (var i = 1; i < numbers.length; i++) {
      expect(numbers[i].left, greaterThan(numbers[i - 1].right));
    }
  });

  test('the drawing holds its boxes and title', () {
    final layout = _layout(_udp);
    final bounds = Offset.zero & layout.size;
    for (final box in [
      for (final b in layout.boxes) b.rect,
      layout.titleBox!,
    ]) {
      expect(bounds.contains(box.topLeft), isTrue);
      expect(
        bounds.contains(box.bottomRight - const Offset(1e-9, 1e-9)),
        isTrue,
      );
    }
  });

  test('a packet fence dispatches and exports', () {
    expect(parseMermaid(_udp), isA<MermaidPacket>());
    expect(parseMermaid('packet\n0: "a"'), isA<MermaidPacket>());
    final svg = diagramSvg(_udp, _style)!;
    expect(svg, contains('Destination Port'));
    expect(svg, contains('>87<'));
  });
}
