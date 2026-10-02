/// The parser behind a `packet-beta` Mermaid fence (#530).
///
/// A packet diagram is a `title` and one field a line: its bits and its
/// name, `0-15: "Source Port"`, `106: "URG"` for one bit, or `+16: "Length"`
/// for the next sixteen. The fields follow one another from bit 0 with no
/// gap, as in Mermaid; a field that does not start where the last one
/// ended, or ends before it starts, is a [MermaidParseException] naming its
/// line.
library;

import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';
import 'package:niman/src/diagrams/packet_model.dart';

/// The most bits a packet diagram draws: 256 rows of 32. A field written
/// past it would draw rows by the thousand.
const int packetMaxBits = 8192;

/// A field: its bits, absolute or `+count`, a colon and its name.
final RegExp _field = RegExp(
  r'^(?:(\d+)(?:\s*-\s*(\d+))?|\+(\d+))\s*:\s*(.*)$',
);

/// Parses a packet diagram (the fence's content, header included).
PacketChart parsePacket(String source) {
  final lines = source.split('\n');
  var index = mermaidBodyStart(lines);
  final header = index < lines.length
      ? stripMermaidComment(lines[index]).trim().toLowerCase()
      : '';
  if (header != 'packet-beta' && header != 'packet') {
    throw MermaidParseException(index + 1, 'expected "packet-beta"');
  }
  String? title;
  final fields = <PacketField>[];
  var description = false;
  for (index++; index < lines.length; index++) {
    final line = stripMermaidComment(lines[index]).trim();
    final number = index + 1;
    if (description) {
      // An `accDescr { … }` block: words for a screen reader.
      description = !line.contains('}');
      continue;
    }
    if (line.isEmpty) continue;
    final lower = line.toLowerCase();
    if (lower.startsWith('acctitle') || lower.startsWith('accdescr')) {
      description = line.contains('{') && !line.contains('}');
      continue;
    }
    if (lower.startsWith('title ') || lower == 'title') {
      title = line.substring('title'.length).trim();
      continue;
    }
    fields.add(
      _fieldOf(line, number, fields.isEmpty ? 0 : fields.last.end + 1),
    );
  }
  if (fields.isEmpty) {
    throw const MermaidParseException(1, 'a packet diagram needs a field');
  }
  return PacketChart(
    fields: List.unmodifiable(fields),
    title: title == null || title.isEmpty ? null : decodeMermaidEntities(title),
  );
}

/// The field [line] (diagram line [number]) writes, which must start at
/// bit [next].
PacketField _fieldOf(String line, int number, int next) {
  final match = _field.firstMatch(line);
  if (match == null) {
    throw MermaidParseException(
      number,
      'expected a field (0-15: "name" or +16: "name"), found "$line"',
    );
  }
  // A number too long for an int is past the last bit drawn anyway.
  int bit(String digits) => int.tryParse(digits) ?? packetMaxBits;
  final int start;
  final int end;
  final count = match.group(3);
  if (count != null) {
    final bits = bit(count);
    if (bits < 1) {
      throw MermaidParseException(number, 'a field takes one bit or more');
    }
    start = next;
    end = next + bits - 1;
  } else {
    start = bit(match.group(1)!);
    end = match.group(2) == null ? start : bit(match.group(2)!);
    if (start != next) {
      throw MermaidParseException(
        number,
        'expected the field to start at bit $next, found $start',
      );
    }
    if (end < start) {
      throw MermaidParseException(
        number,
        'a field cannot end (bit $end) before it starts (bit $start)',
      );
    }
  }
  if (end >= packetMaxBits) {
    throw MermaidParseException(
      number,
      'a packet diagram draws at most $packetMaxBits bits',
    );
  }
  final label = decodeMermaidEntities(unquoteMermaid(match.group(4)!.trim()));
  if (label.isEmpty) {
    throw MermaidParseException(number, 'a field needs a name');
  }
  return PacketField(start: start, end: end, label: label);
}
