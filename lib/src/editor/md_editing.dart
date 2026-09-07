/// Pure Markdown editing commands (T-UI-08): text + selection in, new text
/// + selection out. No editor/model dependency - unit-testable and applied
/// through the re_editor controller by the toolbar (see ui/note_view.dart).
library;

import 'package:flutter/services.dart';

/// The result of a Markdown editing command.
final class MarkdownEdit {
  /// Creates an edit result.
  const MarkdownEdit({required this.text, required this.selection});

  /// The new full text.
  final String text;

  /// Where the caret/selection lands after the command.
  final TextSelection selection;
}

/// Wraps [selection] with [left]/[right] markers (bold '**', italic '*',
/// strike '~~', sup '<sup>…</sup>', underline '<u>…</u>', link '[[…]]').
/// A collapsed selection inserts the markers at the caret and leaves the
/// caret between them; a non-empty selection keeps the inner text selected.
MarkdownEdit wrapSelection({
  required String text,
  required TextSelection selection,
  required String left,
  required String right,
}) {
  final start = selection.start;
  final end = selection.end;
  final selected = text.substring(start, end);
  final newText = text.replaceRange(start, end, '$left$selected$right');
  if (selection.isCollapsed) {
    return MarkdownEdit(
      text: newText,
      selection: TextSelection.collapsed(offset: start + left.length),
    );
  }
  return MarkdownEdit(
    text: newText,
    selection: TextSelection(
      baseOffset: start + left.length,
      extentOffset: start + left.length + selected.length,
    ),
  );
}

/// Inserts a fenced code block at the caret: empty selection lands the
/// caret on the block's first line; a selection is wrapped in fences and
/// stays selected.
MarkdownEdit codeBlock({
  required String text,
  required TextSelection selection,
}) {
  const fence = '```';
  if (selection.isCollapsed) {
    final at = selection.start;
    // "fence + newline, caret line, newline + fence".
    const insert = '$fence\n\n$fence';
    final newText = text.replaceRange(at, at, insert);
    return MarkdownEdit(
      text: newText,
      selection: TextSelection.collapsed(offset: at + 4),
    );
  }
  return wrapSelection(
    text: text,
    selection: selection,
    left: '$fence\n',
    right: '\n$fence',
  );
}

/// Prefixes every line the [selection] touches with [prefix] ('- ' for
/// lists, '> ' for quotes), one pass per line. The selection shifts by the
/// total inserted length, keeping the caret in place.
MarkdownEdit prefixLines({
  required String text,
  required TextSelection selection,
  required String prefix,
}) {
  final startLine = _lineIndexOf(text, selection.start);
  final endLine = _lineIndexOf(text, selection.end);
  final lines = text.split('\n');
  final newLines = <String>[...lines];
  for (var i = startLine; i <= endLine; i++) {
    newLines[i] = '$prefix${newLines[i]}';
  }
  final newText = newLines.join('\n');
  final shift = prefix.length * (endLine - startLine + 1);
  return MarkdownEdit(
    text: newText,
    selection: TextSelection(
      baseOffset: selection.start + shift,
      extentOffset: selection.end + shift,
    ),
  );
}

/// The 0-based line index containing [offset].
int _lineIndexOf(String text, int offset) {
  var line = 0;
  for (var i = 0; i < offset && i < text.length; i++) {
    if (text.codeUnitAt(i) == 0x0A) line++;
  }
  return line;
}
