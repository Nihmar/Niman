/// Converting a Markdown list into a `mindmap` fence (#530).
///
/// Pure text-in/text-out like the other editing commands, so it is
/// unit-testable and the surface applies it as one undoable edit. The list
/// around the caret becomes the tree: a single outermost item is the root,
/// several get a root of their own to hang from.
library;

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:niman/src/editor/md_editing.dart';

/// The block a list converts to, or null when the caret's line is not a
/// list item.
MarkdownEdit? convertListToMindMap({
  required String text,
  required TextSelection selection,
}) {
  final lines = text.split('\n');
  final caret = _lineOf(text, selection.start);
  if (caret < 0 || caret >= lines.length) return null;
  if (listItemHead(lines[caret]) == null) return null;

  var top = caret;
  while (top > 0 && listItemHead(lines[top - 1]) != null) {
    top--;
  }
  var bottom = caret;
  while (bottom + 1 < lines.length && listItemHead(lines[bottom + 1]) != null) {
    bottom++;
  }
  final heads = [
    for (var line = top; line <= bottom; line++) listItemHead(lines[line])!,
  ];
  final columns = [for (final head in heads) _columns(head.indent)];
  final least = columns.reduce(math.min);
  final severalRoots = columns.where((column) => column == least).length > 1;

  final nodes = <String>[];
  if (severalRoots) {
    nodes.add('  root');
    for (var i = 0; i < heads.length; i++) {
      final depth = (columns[i] - least) ~/ 2 + 1;
      nodes.add('${'  ' * (depth + 1)}${_label(heads[i])}');
    }
  } else {
    nodes.add('  ${_label(heads.first)}');
    for (var i = 1; i < heads.length; i++) {
      final depth = (columns[i] - least) ~/ 2;
      nodes.add('${'  ' * (depth + 1)}${_label(heads[i])}');
    }
  }

  final block = ['```mermaid', 'mindmap', ...nodes, '```'];
  final before = lines.sublist(0, top);
  final after = lines.sublist(bottom + 1);
  final offset = before.isEmpty ? 0 : before.join('\n').length + 1;
  return MarkdownEdit(
    text: [...before, ...block, ...after].join('\n'),
    selection: TextSelection.collapsed(offset: offset),
  );
}

/// The columns leading whitespace reaches, a tab to the next multiple of
/// four, as the mind-map parser measures indentation.
int _columns(String indent) {
  var columns = 0;
  for (final unit in indent.codeUnits) {
    if (unit == 0x20) {
      columns++;
    } else if (unit == 0x09) {
      columns = (columns ~/ 4 + 1) * 4;
    }
  }
  return columns;
}

/// A list item's text as a mind-map node's label.
String _label(ListItemHead head) {
  final content = head.content.trim();
  return content.isEmpty ? head.marker : content;
}

/// The 0-based line [offset] falls on.
int _lineOf(String text, int offset) {
  final clamped = offset.clamp(0, text.length);
  var line = 0;
  for (var i = 0; i < clamped; i++) {
    if (text.codeUnitAt(i) == 0x0A) line++;
  }
  return line;
}
