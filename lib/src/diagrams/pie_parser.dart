/// The parser behind a `pie` Mermaid fence (#530).
///
/// A pie is a header — `pie`, with `showData` and a `title` if wanted — and
/// one slice a line, `"label" : value`. Like the other parsers it reports a
/// syntax error as a [MermaidParseException] naming the line.
library;

import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';
import 'package:niman/src/diagrams/pie_model.dart';

/// A slice: a quoted label, a colon, a number.
final RegExp _slice = RegExp(r'^"([^"]*)"\s*:\s*(\S+)$');

/// What the header may carry after `pie`: `showData`, then a title.
final RegExp _header = RegExp(
  r'^pie(?:\s+(showData))?(?:\s+title\s+(.*))?$',
  caseSensitive: false,
);

/// Parses a pie body (the fence's content, header included).
PieChart parsePie(String source) {
  final lines = source.split('\n');
  var index = mermaidBodyStart(lines);
  if (index >= lines.length) {
    throw const MermaidParseException(1, 'expected "pie"');
  }
  final header = _header.firstMatch(stripMermaidComment(lines[index]).trim());
  if (header == null) {
    throw MermaidParseException(
      index + 1,
      'expected "pie", then "showData" or "title" if wanted',
    );
  }
  var showData = header.group(1) != null;
  var title = header.group(2)?.trim();
  final slices = <PieSlice>[];
  var description = false;
  for (index++; index < lines.length; index++) {
    final line = stripMermaidComment(lines[index]).trim();
    final number = index + 1;
    if (description) {
      // An `accDescr { … }` block: words for a screen reader, not the pie.
      description = !line.contains('}');
      continue;
    }
    if (line.isEmpty) continue;
    final lower = line.toLowerCase();
    if (lower.startsWith('acctitle') || lower.startsWith('accdescr')) {
      description = line.contains('{') && !line.contains('}');
      continue;
    }
    if (lower == 'showdata') {
      showData = true;
      continue;
    }
    if (lower.startsWith('title ') || lower == 'title') {
      title = line.substring('title'.length).trim();
      continue;
    }
    slices.add(_sliceOf(line, number));
  }
  if (!slices.any((slice) => slice.value > 0)) {
    throw const MermaidParseException(
      1,
      'a pie needs a slice greater than zero',
    );
  }
  return PieChart(
    slices: List.unmodifiable(slices),
    title: title == null || title.isEmpty ? null : decodeMermaidEntities(title),
    showData: showData,
  );
}

/// The slice [line] (diagram line [number]) writes.
PieSlice _sliceOf(String line, int number) {
  final match = _slice.firstMatch(line);
  if (match == null) {
    throw MermaidParseException(
      number,
      line.startsWith('"')
          ? 'expected ":" and a value after the label'
          : 'expected a slice ("label" : value), found "$line"',
    );
  }
  final value = double.tryParse(match.group(2)!);
  if (value == null || !value.isFinite) {
    throw MermaidParseException(
      number,
      'expected a number after ":", found "${match.group(2)}"',
    );
  }
  if (value < 0) {
    throw MermaidParseException(number, 'a slice cannot be negative');
  }
  return PieSlice(
    label: decodeMermaidEntities(match.group(1)!.trim()),
    value: value,
  );
}
