import 'package:flutter/services.dart';

import 'package:niman/src/editor/list_row.dart';
import 'package:niman/src/editor/list_tree.dart';
import 'package:niman/src/editor/list_window.dart';
import 'package:niman/src/editor/md_editing.dart' show MarkdownEdit;

/// Indents (or outdents, with [outdent] true) every line the [selection]
/// touches.
///
/// A list item moves to where the list says: indent nests it under the item
/// above it at its level — to that item's content column, which is what
/// CommonMark asks of a line to be inside it — and outdent brings it back to
/// its parent's indent. An ordered item is renumbered to the sublist it
/// joins (`1` for a new one, one past the last for an open one), and the
/// siblings it leaves behind close up. Its own subtree moves with it. Every
/// other line moves by [width] spaces: indent adds them at the line's start,
/// outdent removes up to [width] leading spaces (never content).
MarkdownEdit indentLines({
  required String text,
  required TextSelection selection,
  required int width,
  required bool outdent,
}) {
  final lines = text.split('\n');
  final base = _locate(lines, selection.baseOffset);
  final extent = _locate(lines, selection.extentOffset);
  final startLine = base.line < extent.line ? base.line : extent.line;
  final endLine = base.line < extent.line ? extent.line : base.line;
  final window = listIndentWindow(
    (at) => lines[at],
    lines.length,
    startLine,
    endLine,
  );
  final changed = indentListLines(
    lines.sublist(window.first, window.last + 1),
    first: startLine - window.first,
    last: endLine - window.first,
    width: width,
    outdent: outdent,
  );
  final next = <String>[...lines]
    ..replaceRange(window.first, window.last + 1, changed);
  int mapped(({int line, int column}) at) {
    var start = 0;
    for (var line = 0; line < at.line; line++) {
      start += next[line].length + 1;
    }
    return start + mapColumn(lines[at.line], next[at.line], at.column);
  }

  return MarkdownEdit(
    text: next.join('\n'),
    selection: TextSelection(
      baseOffset: mapped(base),
      extentOffset: mapped(extent),
    ),
  );
}

/// The line and column of [offset] in [lines] (joined by one `\n`).
({int line, int column}) _locate(List<String> lines, int offset) {
  var line = 0;
  var rest = offset < 0 ? 0 : offset;
  while (line < lines.length - 1 && rest > lines[line].length) {
    rest -= lines[line].length + 1;
    line++;
  }
  return (line: line, column: rest);
}

/// [lines], a list block, with the lines `first..last` indented (or
/// outdented): the same lines in the same number, by the rule of
/// [indentLines].
List<String> indentListLines(
  List<String> lines, {
  required int first,
  required int last,
  required int width,
  required bool outdent,
}) => _ListIndent(lines, width).run(first, last, outdent: outdent);

/// Where the items moved together went: the column of the sublist, and the
/// number its next item takes (null when the marker stays).
typedef _Sublist = ({int indent, int? number, String? delimiter});

final class _ListIndent {
  new(this.lines, this.width) {
    rows = [for (final line in lines) ListRow(line)];
    tree = ListTree(rows);
    out = <String>[...lines];
    delta = List<int>.filled(rows.length, 0);
    marker = List<String?>.filled(rows.length, null);
    moved = List<bool>.filled(rows.length, false);
    group = List<int>.filled(rows.length, 0);
    counted = List<bool>.filled(rows.length, false);
    grouped = List<bool>.filled(rows.length, false);
  }

  final List<String> lines;
  final int width;
  late final List<ListRow> rows;
  late final ListTree tree;
  late final List<String> out;

  /// Per line: the columns it moves by, and the marker it takes.
  late final List<int> delta;
  late final List<String?> marker;

  /// Per line: whether it moves as part of an item's subtree.
  late final List<bool> moved;

  /// The items moved by indent, by where they went.
  final Map<int, _Sublist> placed = <int, _Sublist>{};

  /// The next number under a parent that items were moved back to.
  final Map<int, int> backTo = <int, int>{};

  /// Per item nested: how many of its siblings moved with it (itself
  /// included), whether the list it left was counted one by one up to it,
  /// and whether a later item moved after it.
  late final List<int> group;
  late final List<bool> counted;
  late final List<bool> grouped;

  List<String> run(int first, int last, {required bool outdent}) {
    for (var at = first; at <= last; at++) {
      if (moved[at]) continue;
      if (rows[at].head == null) {
        out[at] = outdent ? _strip(lines[at]) : '${' ' * width}${lines[at]}';
      } else if (outdent) {
        _outdent(at);
      } else {
        _nest(at);
      }
    }
    if (outdent) {
      backTo.forEach(_closeUpBack);
    } else {
      for (var at = 0; at < rows.length; at++) {
        if (group[at] > 0 && counted[at] && !grouped[at]) {
          _renumberAfter(at, -group[at]);
        }
      }
    }
    for (var at = 0; at < rows.length; at++) {
      if (delta[at] != 0 || marker[at] != null) {
        out[at] = rows[at].reshape(delta[at], marker: marker[at]);
      }
    }
    return out;
  }

  /// [line] without up to [width] of its leading spaces.
  String _strip(String line) {
    var spaces = 0;
    while (spaces < width && spaces < line.length && line[spaces] == ' ') {
      spaces++;
    }
    return line.substring(spaces);
  }

  void _nest(int at) {
    final row = rows[at];
    final number = row.head!.number;
    final above = tree.previous[at];
    var indent = row.indent + width;
    int? take;
    String? delimiter;
    if (above >= 0) {
      final sibling = placed[above];
      if (sibling != null) {
        // Moved along with the item above it: the same column, and the
        // number after that one's.
        indent = sibling.indent;
        take = number == null ? null : sibling.number;
        delimiter = take == null ? null : sibling.delimiter;
        group[at] = group[above] + 1;
        counted[at] = counted[above] && _follows(above, at);
        grouped[above] = true;
      } else {
        // Into the sublist already open under the item above, or a new one.
        final open = tree.sublistEnd[at];
        final joined = open < 0 ? null : rows[open];
        indent = joined?.indent ?? rows[above].contentColumn;
        if (number != null) {
          final count = joined?.head!.number;
          take = count == null ? 1 : count + 1;
          delimiter = count == null ? row.delimiter : joined!.delimiter;
        }
        group[at] = 1;
        counted[at] = _follows(above, at);
      }
    }
    _place(at, indent, take, delimiter);
  }

  /// Whether the item [at] is numbered right after the item [above].
  bool _follows(int above, int at) {
    final before = rows[above].head!.number;
    final now = rows[at].head!.number;
    return before != null &&
        now == before + 1 &&
        rows[above].delimiter == rows[at].delimiter;
  }

  void _outdent(int at) {
    final row = rows[at];
    final parent = tree.parent[at];
    if (parent < 0) {
      final spaces = row.indent < width ? row.indent : width;
      _place(at, row.indent - spaces, null, null);
      return;
    }
    final up = rows[parent];
    int? take;
    String? delimiter;
    final parentNumber = up.head!.number;
    if (row.head!.number != null && parentNumber != null) {
      take = backTo[parent] ?? parentNumber + 1;
      delimiter = up.delimiter;
      backTo[parent] = take + 1;
    }
    _place(at, up.indent, take, delimiter);
  }

  /// Puts the item [at] on [indent] under [number] and [delimiter] (the
  /// number null: the marker stays), its subtree moving by as much as its
  /// content column did.
  void _place(int at, int indent, int? number, String? delimiter) {
    final row = rows[at];
    final head = row.head!;
    final next = number == null || delimiter == null
        ? head.marker
        : '$number$delimiter';
    delta[at] = indent - row.indent;
    marker[at] = next == head.marker ? null : next;
    placed[at] = (
      indent: indent,
      number: number == null || delimiter == null ? null : number + 1,
      delimiter: delimiter,
    );
    final shift = delta[at] + next.length - head.marker.length;
    final inside = row.contentColumn;
    for (var below = at + 1; below < rows.length; below++) {
      final line = rows[below];
      if (line.depth != row.depth) break;
      if (line.blank) continue;
      if (line.indent < inside) break;
      delta[below] += shift;
      moved[below] = true;
    }
  }

  /// The siblings after [parent] make room for the items moved back to it.
  void _closeUpBack(int parent, int next) {
    final number = rows[parent].head!.number!;
    _renumberAfter(parent, next - number - 1);
  }

  /// Adds [by] to the numbers of the siblings after [at] that count on from
  /// it one by one: a list numbered by hand stays as it was written.
  void _renumberAfter(int at, int by) {
    final head = rows[at].head!;
    final number = head.number;
    if (number == null || by == 0) return;
    var expected = number;
    var sibling = tree.next[at];
    while (sibling >= 0) {
      final row = rows[sibling];
      expected += 1;
      if (row.head!.number != expected || row.delimiter != rows[at].delimiter) {
        return;
      }
      marker[sibling] = '${expected + by}${row.delimiter}';
      sibling = tree.next[sibling];
    }
  }
}
