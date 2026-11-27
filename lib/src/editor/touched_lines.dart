import 'package:flutter/services.dart';
import 'package:niman/src/editor/line_selection.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The first and the last line (0-based) the [selection] touches in [text].
///
/// A selection that ends at the very start of a line does not touch that
/// line: it holds the break before it and none of its text, as a triple click
/// or a shift-down from a line's start leaves it. So the last line is the one
/// before, and a command that formats "the lines of the selection" leaves the
/// next one alone (#1345). A caret, and a selection that starts on that line,
/// touch the line they are on.
({int first, int last}) touchedLines(String text, TextSelection selection) {
  final first = lineIndexOf(text, selection.start);
  final last = lineIndexOf(text, selection.end);
  if (last > first && endsAtLineStart(text, selection)) {
    return (first: first, last: last - 1);
  }
  return (first: first, last: last);
}

/// The same over the lines of a [buffer], without reading any text.
({int first, int last}) touchedBufferLines(
  SourceBuffer buffer,
  SelectionModel selection,
) {
  final first = buffer.lineOf(selection.start);
  var last = buffer.lineOf(selection.end);
  if (last > first && selection.end == buffer.offsetOfLine(last)) last--;
  return (first: first, last: last);
}

/// Whether [selection] is a range that ends at the start of a line of [text],
/// right after a line break.
bool endsAtLineStart(String text, TextSelection selection) {
  final end = selection.end;
  return selection.start < end &&
      end <= text.length &&
      text.codeUnitAt(end - 1) == 0x0A;
}
