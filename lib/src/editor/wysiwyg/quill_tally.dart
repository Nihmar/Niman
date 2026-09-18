/// Counting a list in the WYSIWYG document (#136).
///
/// The source editor's twin (`editor/list_tally_edit.dart`), and the
/// counting itself is the same `editor/list_tally.dart` for both — only
/// the finding and the writing differ, because a list here is a Quill
/// block and a box is an attribute of a line rather than characters in
/// it.
///
/// It edits the document in place rather than re-decoding it from
/// Markdown: a round trip through the codec would be simpler and would
/// throw away the caret, the scroll position and the undo history, and
/// the block this writes lands at the bottom of the list it counts,
/// which is exactly where the writer is looking.
library;

import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';
import 'package:niman/src/editor/list_tally.dart';

/// The `list` attribute values a generated row wears.
const String _checked = 'checked';
const String _unchecked = 'unchecked';

/// One list in a Quill document the count could run on.
final class QuillTallyTarget {
  /// Creates a target.
  const new({
    required this.rows,
    required this.checks,
    required this.replaces,
    required this.start,
    required this.end,
    required this.at,
    required this.length,
    required this.closing,
    required this.trailingBlank,
  });

  /// The list's rows, without their markers (Quill keeps those as line
  /// attributes, so the text is already only the value).
  final List<String> rows;

  /// The ticks a previous run's block carries, by folded label.
  final Map<String, bool> checks;

  /// Whether a previous run's block is being replaced.
  final bool replaces;

  /// The document offset of the list's first line.
  final int start;

  /// The document offset one past the list's last line.
  final int end;

  /// Where the block is written.
  final int at;

  /// How much of the document the block replaces.
  final int length;

  /// The `list` attribute the source list's last line needs written back
  /// when the block goes at the very end of the document.
  ///
  /// Quill refuses an insert at `document.length` — its containers
  /// assert the index falls inside them — so a block that would go there
  /// is written one character earlier, before the document's final
  /// newline. That newline then closes the block's last row instead of
  /// the list's last line, so the list's line is given a new one of its
  /// own and the final newline is re-attributed as it is stepped over.
  ///
  /// Null whenever the block replaces one: deleting the old block frees
  /// the end of the document, and Delta normalization puts the insert
  /// before the delete, so the offset is inside the document either way.
  final String? closing;

  /// Whether a blank line is needed under the block, to keep the text
  /// that follows from reading as a continuation of the last row.
  final bool trailingBlank;
}

/// One line of the document as the count reads it.
typedef _Row = ({String text, String? list, int at, int length});

List<_Row> _rowsOf(quill.Document document) {
  final out = <_Row>[];
  void add(quill.Line line) {
    final text = line.toPlainText();
    out.add((
      text: text.endsWith('\n') ? text.substring(0, text.length - 1) : text,
      list: line.style.attributes['list']?.value as String?,
      at: line.documentOffset,
      length: line.length,
    ));
  }

  for (final node in document.root.children) {
    if (node is quill.Block) {
      for (final child in node.children) {
        if (child is quill.Line) add(child);
      }
    } else if (node is quill.Line) {
      add(node);
    }
  }
  return out;
}

/// Whether [row] is a row of a source list rather than a generated one.
bool _isSource(_Row row) =>
    row.list != null &&
    parseTallyContent(row.text, checked: row.list == _checked) == null;

/// Whether [row] is a row a previous run wrote.
bool _isTally(_Row row) =>
    (row.list == _checked || row.list == _unchecked) &&
    parseTallyContent(row.text, checked: row.list == _checked) != null;

/// Every list in [document] the count could run on, in order.
List<QuillTallyTarget> quillTallyTargets(quill.Document document) {
  final rows = _rowsOf(document);
  final out = <QuillTallyTarget>[];
  var i = 0;
  while (i < rows.length) {
    if (!_isSource(rows[i])) {
      i++;
      continue;
    }
    final first = i;
    while (i < rows.length && _isSource(rows[i])) {
      i++;
    }
    final last = i - 1;
    // At most one blank line between a list and the block that counts
    // it, exactly as in the source editor.
    var blockFirst = i;
    if (blockFirst < rows.length &&
        rows[blockFirst].list == null &&
        rows[blockFirst].text.trim().isEmpty) {
      blockFirst++;
    }
    var blockLast = blockFirst - 1;
    while (blockLast + 1 < rows.length && _isTally(rows[blockLast + 1])) {
      blockLast++;
    }
    final replaces = blockLast >= blockFirst;
    final at = replaces
        ? rows[blockFirst].at
        : rows[last].at + rows[last].length;
    var length = 0;
    if (replaces) {
      for (var j = blockFirst; j <= blockLast; j++) {
        length += rows[j].length;
      }
    }
    final next = last + 1;
    final atEnd = !replaces && at >= document.length;
    out.add(
      QuillTallyTarget(
        rows: <String>[for (var j = first; j <= last; j++) rows[j].text],
        checks: <String, bool>{
          for (var j = blockFirst; j <= blockLast; j++)
            if (parseTallyContent(
                  rows[j].text,
                  checked: rows[j].list == _checked,
                )
                case final row?)
              foldTallyLabel(row.label): row.checked,
        },
        replaces: replaces,
        start: rows[first].at,
        end: rows[last].at + rows[last].length,
        at: atEnd ? at - 1 : at,
        length: length,
        closing: atEnd ? rows[last].list : null,
        trailingBlank:
            !replaces &&
            next < rows.length &&
            !(rows[next].list == null && rows[next].text.trim().isEmpty),
      ),
    );
    i = replaces ? blockLast + 1 : i;
  }
  return out;
}

/// The list the caret at [offset] is in, or null when it is in none.
QuillTallyTarget? quillTallyTargetAt(quill.Document document, int offset) {
  for (final target in quillTallyTargets(document)) {
    final end = target.replaces ? target.at + target.length : target.end;
    if (offset >= target.start && offset <= end) return target;
  }
  return null;
}

/// Writes [rows] at [target] in [controller]'s document.
///
/// One Delta, so it is one change and one step of undo. A Delta given to
/// `replaceText` skips Quill's insert heuristics, which is what this
/// wants: the block's lines carry the attributes it says they do, and
/// nothing is inferred from the line above.
void applyQuillTally(
  quill.QuillController controller,
  QuillTallyTarget target,
  List<TallyRow> rows,
) {
  if (rows.isEmpty) return;
  final delta = Delta();
  final closing = target.closing;
  // The document's final newline is being stepped over rather than
  // written, so the line it used to close gets its attribute back first,
  // and it goes on to close the block's last row instead.
  if (closing != null) {
    delta.insert('\n', <String, dynamic>{'list': closing});
  }
  if (!target.replaces) delta.insert('\n');
  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    delta.insert('${row.label}: ${row.count}');
    final attribute = <String, dynamic>{
      'list': row.checked ? _checked : _unchecked,
    };
    if (closing != null && i == rows.length - 1) {
      delta.retain(1, attribute);
    } else {
      delta.insert('\n', attribute);
    }
  }
  // Without a blank line under it, the text that follows reads as a
  // continuation of the last row rather than as its own paragraph.
  if (target.trailingBlank) delta.insert('\n');
  controller.replaceText(
    target.at,
    target.length,
    delta,
    TextSelection.collapsed(offset: target.at),
  );
}
