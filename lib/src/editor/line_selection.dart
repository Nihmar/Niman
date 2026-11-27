import 'package:flutter/services.dart';

/// Recomputes [selection] against the text after a line-level edit: the
/// touched lines (startLine..endLine) changed length at their starts, so
/// each endpoint lands on the same line, shifted by the lines at and
/// before it (clamped so an offset never goes negative).
TextSelection shiftSelectionForLines({
  required String oldText,
  required String newText,
  required TextSelection selection,
  required int startLine,
  required int endLine,
}) {
  return TextSelection(
    baseOffset: _mapEndpoint(
      oldText,
      newText,
      selection.baseOffset,
      startLine,
      endLine,
    ),
    extentOffset: _mapEndpoint(
      oldText,
      newText,
      selection.extentOffset,
      startLine,
      endLine,
    ),
  );
}

int _mapEndpoint(
  String oldText,
  String newText,
  int offset,
  int startLine,
  int endLine,
) {
  final (line, off) = _lineAndOffset(oldText, offset);
  if (line < startLine || line > endLine) {
    return lineStartOf(newText, line) + off;
  }
  final delta =
      newText.split('\n')[line].length - oldText.split('\n')[line].length;
  final newOff = off + delta;
  return lineStartOf(newText, line) + (newOff < 0 ? 0 : newOff);
}

/// The absolute offset where [line] starts in [text].
int lineStartOf(String text, int line) {
  var index = 0;
  for (var current = 0; current < line; current++) {
    final nl = text.indexOf('\n', index);
    if (nl < 0) return text.length;
    index = nl + 1;
  }
  return index;
}

/// The (line, offset-within-line) for the absolute [offset] in [text].
(int, int) _lineAndOffset(String text, int offset) {
  var line = 0;
  var lineStart = 0;
  for (var i = 0; i < offset && i < text.length; i++) {
    if (text.codeUnitAt(i) == 0x0A) {
      line++;
      lineStart = i + 1;
    }
  }
  return (line, offset - lineStart);
}

/// The 0-based line index containing [offset].
int lineIndexOf(String text, int offset) {
  var line = 0;
  for (var i = 0; i < offset && i < text.length; i++) {
    if (text.codeUnitAt(i) == 0x0A) line++;
  }
  return line;
}
