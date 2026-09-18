/// Reading and restoring where a note was left (issue #23), for the
/// source editor: the selection as flat offsets into the note, and the
/// scroll.
///
/// Offsets are summed from the controller's lines rather than read off a
/// joined text: joining is an O(n) copy of the whole note, and a memento
/// is taken on every tab switch.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:niman/src/workspace/note_memento.dart';
import 'package:re_editor/re_editor.dart';

/// The memento's name for the source editor.
const String sourceEditorKind = 'source';

/// The memento's name for the WYSIWYG surface.
const String wysiwygEditorKind = 'wysiwyg';

/// Where [controller]'s note was left, scrolled to [scroll].
NoteMemento sourceMemento(
  CodeLineEditingController controller,
  CodeScrollController scroll, {
  required bool preview,
}) {
  final lines = controller.codeLines;
  final selection = controller.selection;
  final vertical = scroll.verticalScroller;
  return NoteMemento(
    selectionBase: _flat(lines, selection.baseIndex, selection.baseOffset),
    selectionExtent: _flat(
      lines,
      selection.extentIndex,
      selection.extentOffset,
    ),
    scrollOffset: vertical.hasClients ? vertical.offset : null,
    editorKind: sourceEditorKind,
    preview: preview,
  );
}

/// Puts [controller]'s selection back where [memento] left it, clamped
/// into the note as it is now (it may have changed on disk since).
void restoreSourceSelection(
  CodeLineEditingController controller,
  NoteMemento memento,
) {
  final extent = memento.selectionExtent;
  if (extent == null) return;
  final lines = controller.codeLines;
  final (baseIndex, baseOffset) = _lineOf(
    lines,
    memento.selectionBase ?? extent,
  );
  final (extentIndex, extentOffset) = _lineOf(lines, extent);
  controller.selection = CodeLineSelection(
    baseIndex: baseIndex,
    baseOffset: baseOffset,
    extentIndex: extentIndex,
    extentOffset: extentOffset,
  );
}

/// Scrolls [scroll] back to [offset] once it has a layout to scroll.
void restoreScroll(ScrollController scroll, double? offset) {
  if (offset == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!scroll.hasClients) return;
    final position = scroll.position;
    scroll.jumpTo(math.min(offset, position.maxScrollExtent));
  });
}

int _flat(CodeLines lines, int index, int offset) {
  var flat = 0;
  final last = math.min(index, lines.length);
  for (var i = 0; i < last; i++) {
    flat += lines[i].text.length + 1;
  }
  return flat + offset;
}

(int, int) _lineOf(CodeLines lines, int flat) {
  var remaining = math.max(0, flat);
  for (var i = 0; i < lines.length; i++) {
    final length = lines[i].text.length;
    if (remaining <= length) return (i, remaining);
    remaining -= length + 1;
  }
  final last = lines.length - 1;
  return (last, lines[last].text.length);
}
