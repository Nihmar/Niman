/// The parser behind a `block-beta` Mermaid fence (#530).
///
/// A block diagram is a grid: `columns 3` sets how many columns the
/// blocks after it fill, left to right and then a row down. A block is
/// written like a flowchart node (`a`, `a["text"]`, `a(("text"))`), takes
/// more than one column with `:2`, and is an arrow when written
/// `a<["text"]>(right)`. `space` (or `space:2`) leaves cells empty,
/// `block:id:2 … end` nests a group with a grid of its own, and
/// `a --> b`, `a -- "text" --> b` join two blocks.
///
/// A block named only in an edge is placed after the cells of the group
/// it was named in. `style`, `classDef` and `class` lines are colours a
/// note's diagram is drawn without, as in a flowchart. A syntax error is a
/// [MermaidParseException] naming its line.
library;

import 'package:niman/src/diagrams/block_model.dart';
import 'package:niman/src/diagrams/flow_cursor.dart';
import 'package:niman/src/diagrams/flow_edge_scanner.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';

/// The most columns a block spans.
const int _widest = 1 << 16;

/// The lines that only colour a diagram.
const Set<String> _colourLines = {'style', 'classdef', 'class', 'linkstyle'};

/// A group's header: `block`, `block:id` or `block:id:2`.
final RegExp _groupHeader = RegExp(r'^block(?::([^\s:]+))?(?::(\d+))?(?=\s|$)');

/// Parses a block diagram (the fence's content, header included).
BlockDiagram parseBlock(String source) => _BlockParser(source).parse();

final class _BlockParser {
  new(this.source);

  final String source;

  final _GroupBuild _root = _GroupBuild(id: null, span: 1, line: 1);
  late final List<_GroupBuild> _stack = [_root];
  final Map<String, _NodeBuild> _nodes = {};
  final Set<String> _groupIds = {};
  final List<BlockEdge> _edges = [];

  /// Blocks named only in an edge so far, with the group they were named
  /// in.
  final List<(String, _GroupBuild)> _pending = [];

  BlockDiagram parse() {
    final lines = source.split('\n');
    var index = mermaidBodyStart(lines);
    final header = index < lines.length
        ? stripMermaidComment(lines[index]).trim().toLowerCase()
        : '';
    if (header != 'block-beta' && header != 'block') {
      throw MermaidParseException(index + 1, 'expected "block-beta"');
    }
    for (index++; index < lines.length; index++) {
      final line = stripMermaidComment(lines[index]).trim();
      if (line.isNotEmpty) _statement(line, index + 1);
    }
    if (_stack.length > 1) {
      throw MermaidParseException(
        _stack.last.line,
        'expected "end" to close this block',
      );
    }
    for (final (id, group) in _pending) {
      final node = _nodes[id]!;
      if (!node.placed) {
        node.placed = true;
        group.items.add(node);
      }
    }
    if (_root.items.isEmpty) {
      throw const MermaidParseException(1, 'a block diagram needs a block');
    }
    return BlockDiagram(root: _root.build(), edges: List.unmodifiable(_edges));
  }

  void _statement(String line, int number) {
    final word = RegExp('^[A-Za-z_-]+').stringMatch(line)?.toLowerCase();
    final rest = word == null ? '' : line.substring(word.length);
    final isKeyword = rest.isEmpty || rest[0] == ' ' || rest[0] == '\t';
    if (isKeyword && _colourLines.contains(word)) return;
    if (word == 'end' && rest.trim().isEmpty) {
      if (_stack.length == 1) {
        throw MermaidParseException(number, '"end" closes no block');
      }
      _stack.removeLast();
      return;
    }
    if (word == 'columns' && isKeyword) {
      _stack.last.columns = _columns(rest.trim(), number);
      return;
    }
    final group = _groupHeader.firstMatch(line);
    if (group != null) {
      _openGroup(group, number);
      final after = line.substring(group.end).trim();
      if (after.isNotEmpty) _items(after, number);
      return;
    }
    _items(line, number);
  }

  int? _columns(String argument, int number) {
    if (argument.toLowerCase() == 'auto') return null;
    final count = int.tryParse(argument);
    if (count == null || count < 1) {
      throw MermaidParseException(
        number,
        'expected a number of columns or "auto", found "$argument"',
      );
    }
    return count;
  }

  void _openGroup(RegExpMatch header, int number) {
    final id = header.group(1);
    if (id != null && (_nodes.containsKey(id) || !_groupIds.add(id))) {
      throw MermaidParseException(number, '"$id" already names a block');
    }
    final span = header.group(2);
    final group = _GroupBuild(
      id: id,
      span: span == null ? 1 : _span(span),
      line: number,
    );
    _stack.last.items.add(group);
    _stack.add(group);
  }

  /// The cells and edges of one line: blocks and spaces in the order they
  /// fill the grid, an edge between the blocks either side of it.
  void _items(String line, int number) {
    final cursor = FlowCursor(line);
    final refs = <_Ref>[];
    final edges = <(int, int, FlowEdgeScan, String?)>[];
    final spaces = <(int, BlockSpace)>[];
    while (true) {
      cursor.skipSpaces();
      if (cursor.atEnd) break;
      if (refs.isNotEmpty) {
        final scan = scanFlowEdge(cursor.source, cursor.position, number);
        if (scan != null) {
          cursor
            ..position = scan.end
            ..skipSpaces();
          final label = cursor.readPipeLabel() ?? scan.label;
          final to = _ref(cursor, number);
          if (to == null) {
            throw MermaidParseException(number, 'an edge cannot reach a space');
          }
          edges.add((refs.length - 1, refs.length, scan, label));
          refs.add(to);
          continue;
        }
      }
      final ref = _ref(cursor, number);
      if (ref == null) {
        spaces.add((refs.length, BlockSpace(span: _readSpan(cursor))));
      } else {
        refs.add(ref);
      }
    }
    // A line without an edge places its blocks; one with an edge only
    // names them, so edges written after the grid do not move a block.
    final places = edges.isEmpty;
    var next = 0;
    for (var i = 0; i <= refs.length; i++) {
      while (next < spaces.length && spaces[next].$1 == i) {
        _stack.last.items.add(spaces[next++].$2);
      }
      if (i < refs.length) _declare(refs[i], places, number);
    }
    for (final (from, to, scan, label) in edges) {
      final a = refs[from].id;
      final b = refs[to].id;
      if (a == b) {
        throw MermaidParseException(
          number,
          'an edge cannot join "$a" to itself',
        );
      }
      final text = label == null
          ? null
          : decodeMermaidEntities(unquoteMermaid(label.trim()));
      _edges.add(
        BlockEdge(
          from: a,
          to: b,
          style: scan.style,
          start: scan.start,
          end: scan.endCap,
          label: text == null || text.isEmpty ? null : text,
        ),
      );
    }
  }

  /// The block at the cursor, or null for a `space`, the cursor left on
  /// the space's `:span`.
  _Ref? _ref(FlowCursor cursor, int number) {
    final id = cursor.readId();
    if (id.isEmpty) {
      throw MermaidParseException(
        number,
        'expected a block, found "${cursor.rest}"',
      );
    }
    final open = cursor.peek;
    if (id == 'space' && open != '[' && open != '(' && open != '{') {
      return null;
    }
    FlowNodeShape? shape;
    String? label;
    BlockArrowDirection? arrow;
    if (cursor.source.startsWith('<[', cursor.position)) {
      (label, arrow) = _arrow(cursor, number);
      shape = FlowNodeShape.rect;
    } else if (open == '[' || open == '(' || open == '{' || open == '>') {
      (:shape, :label) = cursor.readShape(number);
    }
    // A block's `:::class` is read past: the block diagram draws in the
    // theme's colours.
    cursor.readClass();
    final span = cursor.peek == ':' ? _readSpan(cursor) : null;
    cursor.readClass();
    return _Ref(id, shape, label, arrow, span);
  }

  /// A block arrow's `<["text"]>(direction)`, the cursor on its `<[`.
  (String, BlockArrowDirection) _arrow(FlowCursor cursor, int number) {
    final source = cursor.source;
    var i = cursor.position + 2;
    var quoted = false;
    while (i < source.length) {
      if (source[i] == '"') quoted = !quoted;
      if (!quoted && source.startsWith(']>', i)) break;
      i++;
    }
    if (i >= source.length) {
      throw MermaidParseException(number, 'expected "]>" after "<["');
    }
    final label = decodeMermaidEntities(
      unquoteMermaid(source.substring(cursor.position + 2, i).trim()),
    );
    final match = RegExp(r'\(\s*(\w+)\s*\)').matchAsPrefix(source, i + 2);
    final direction = match == null
        ? null
        : BlockArrowDirection.parse(match.group(1)!);
    if (direction == null) {
      throw MermaidParseException(
        number,
        "expected the arrow's direction, one of "
        '(right), (left), (up), (down), (x), (y)',
      );
    }
    cursor.position = match!.end;
    return (label, direction);
  }

  /// A `:span` at the cursor, 1 when none is written.
  int _readSpan(FlowCursor cursor) {
    final match = RegExp(r':(\d+)')
        .matchAsPrefix(cursor.source, cursor.position);
    if (match == null) return 1;
    cursor.position = match.end;
    return _span(match.group(1)!);
  }

  /// A span of [digits] columns, at most the widest a row takes: digits
  /// past what an int holds are past that too.
  int _span(String digits) =>
      (int.tryParse(digits) ?? _widest).clamp(1, _widest);

  void _declare(_Ref ref, bool place, int number) {
    if (_groupIds.contains(ref.id)) {
      if (ref.shape != null || ref.span != null || place) {
        throw MermaidParseException(
          number,
          '"${ref.id}" already names a group',
        );
      }
      return;
    }
    var node = _nodes[ref.id];
    if (node == null) {
      node = _NodeBuild(ref.id);
      _nodes[ref.id] = node;
    }
    if (ref.shape != null) {
      node
        ..shape = ref.shape!
        ..label = (ref.label == null || ref.label!.isEmpty)
            ? ref.id
            : ref.label!
        ..arrow = ref.arrow;
    }
    if (ref.span != null) node.span = ref.span!;
    if (node.placed) return;
    if (place) {
      node.placed = true;
      _stack.last.items.add(node);
    } else {
      _pending.add((ref.id, _stack.last));
    }
  }
}

/// A block as one mention writes it: what it says, and null for what it
/// leaves as it was.
final class _Ref {
  new(this.id, this.shape, this.label, this.arrow, this.span);

  final String id;
  final FlowNodeShape? shape;
  final String? label;
  final BlockArrowDirection? arrow;
  final int? span;
}

/// A block while the source is read: a later mention may reshape it.
final class _NodeBuild {
  new(this.id) : label = id;

  final String id;
  String label;
  FlowNodeShape shape = FlowNodeShape.rect;
  BlockArrowDirection? arrow;
  int span = 1;
  bool placed = false;

  BlockNode build() =>
      BlockNode(id: id, label: label, shape: shape, span: span, arrow: arrow);
}

/// A group while the source is read.
final class _GroupBuild {
  new({required this.id, required this.span, required this.line});

  final String? id;
  final int span;

  /// The line that opened it, for the error when it is never closed.
  final int line;
  int? columns;
  final List<Object> items = [];

  BlockGroup build() => BlockGroup(
    id: id,
    span: span,
    columns: columns,
    children: List.unmodifiable([
      for (final item in items)
        switch (item) {
          _NodeBuild() => item.build(),
          _GroupBuild() => item.build(),
          _ => item as BlockItem,
        },
    ]),
  );
}
