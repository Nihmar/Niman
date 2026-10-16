import 'package:niman/src/editor/list_row.dart';
import 'package:niman/src/markdown/edit/list_indent_edit.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// What Enter does to a note: replace `[start, end)` with `text`, and put the
/// caret at `caret` — after the text when null. With `verbatim` the text's own
/// line endings are kept (see `SourceBuffer.replaceRange`).
typedef EnterEdit = ({
  int start,
  int end,
  String text,
  SelectionModel? caret,
  bool verbatim,
});

/// The edit Enter makes at [offset] of [buffer] when the line means more than
/// a line break (#142, #1049), or null for the platform's own line break.
///
/// A line is read behind the quote marks it opens with — the rule Tab and
/// Shift+Tab use ([ListRow]: each `>` up to three spaces in, one space after
/// it, nested as often as written) — so a list item inside a quote or a
/// callout is carried on like any other, and the quote itself is:
///
/// * a line in a quote starts the next one with the same marks: `> - a`
///   goes on as `> - `, `> > x` as `> > `, a callout's `> [!note]` as `> `;
/// * a line with nothing after its marks, `> `, loses them: the second Enter
///   everybody presses to get out of a quote;
/// * an empty list item at the margin loses its marker (keeping the quote
///   marks, which the next Enter takes), and an empty *nested* one goes back
///   one level, the edit Shift+Tab makes — [indentWidth] is the one it uses;
/// * a caret inside the marks, or inside a list marker, is the platform's.
///
/// Line-local: the caller knows whether the line is inside a code fence, a
/// math block or the frontmatter, where none of this applies.
EnterEdit? enterEdit(
  SourceBuffer buffer,
  int offset, {
  required int indentWidth,
}) {
  final line = buffer.lineOf(offset);
  final text = buffer.lineAt(line);
  final lineStart = buffer.offsetOfLine(line);
  final column = offset - lineStart;
  final row = ListRow(text);
  final marks = row.marks;
  final head = row.head;
  // What the line after this one opens with: the marks, with the space that
  // separates them from the text.
  final prefix = marks.isEmpty || marks.endsWith(' ') ? marks : '$marks ';
  if (head == null) {
    if (marks.isEmpty || column < marks.length) return null;
    if (row.blank) {
      // Nothing after the marks: leaving the quote.
      return (
        start: lineStart,
        end: lineStart + text.length,
        text: '',
        caret: null,
        verbatim: false,
      );
    }
    return (
      start: offset,
      end: offset,
      text: '\n$prefix',
      caret: null,
      verbatim: false,
    );
  }
  if (head.isEmpty) {
    // Enter on an item with nothing in it takes the marker away instead of
    // adding another empty item — the second Enter everybody presses to get
    // out of a list — or, in a nested item, goes back a level.
    if (head.indent.isNotEmpty) {
      final outdent = listIndentEdit(
        buffer,
        SelectionModel.at(offset),
        width: indentWidth,
        outdent: true,
      );
      if (outdent != null) {
        return (
          start: outdent.start,
          end: outdent.end,
          text: outdent.text,
          caret: outdent.caret,
          verbatim: true,
        );
      }
    }
    return (
      start: lineStart + marks.length,
      end: lineStart + text.length,
      text: '',
      caret: null,
      verbatim: false,
    );
  }
  // A caret inside the marker is not "in the item": leave it to the platform.
  if (column < text.length - head.content.length) return null;
  // One edit, not a line break and then a marker: one undo step, and no frame
  // where the marker is missing.
  return (
    start: offset,
    end: offset,
    text: '\n$prefix${head.continuation}',
    caret: null,
    verbatim: false,
  );
}
