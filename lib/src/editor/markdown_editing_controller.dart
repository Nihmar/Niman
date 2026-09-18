/// Enter carries a list on in the source editor (#141).
///
/// Every Markdown editor does this and ours did not: pressing Enter in
/// `- milk` left the writer on a blank line to type `- ` themselves,
/// once per item, all the way down a shopping list.
///
/// It hangs off the controller rather than off a key handler because
/// that is the one place both platforms meet. re_editor binds Enter two
/// different ways — an Actions intent on the desktop, a hardcoded
/// `Focus.onKey` on Android and iOS — and only the first can be
/// overridden through the widget's API; both end up calling
/// `applyNewLine` on the controller the editor was given.
/// `CodeLineEditingControllerDelegate` is the package's own seam for
/// exactly this.
library;

import 'package:niman/src/editor/md_editing.dart';
import 'package:re_editor/re_editor.dart';

/// A [CodeLineEditingController] whose Enter knows about Markdown lists.
final class MarkdownEditingController
    extends CodeLineEditingControllerDelegate {
  /// Wraps [delegate]; [isPlain] says whether a line is ordinary
  /// Markdown rather than fenced code, display math or frontmatter,
  /// where a dash starts nothing.
  new({required super.delegate, required this.isPlain});

  /// Whether the line at the given index is ordinary Markdown.
  ///
  /// The owner answers from the highlighter it already keeps, so the
  /// editor and the tokenizer agree about what a list is — the same
  /// arrangement the task-list GUI uses.
  final bool Function(int index) isPlain;

  @override
  void applyNewLine() {
    final at = selection;
    final line = at.baseIndex;
    if (!at.isCollapsed || line < 0 || line >= codeLines.length) {
      super.applyNewLine();
      return;
    }
    final text = codeLines[line].text;
    if (!isPlain(line)) {
      super.applyNewLine();
      return;
    }
    final head = listItemHead(text);
    if (head == null) {
      super.applyNewLine();
      return;
    }
    // Enter on an item with nothing in it ends the list instead of
    // adding another empty one — the second Enter everybody already
    // presses to get out.
    if (head.isEmpty) {
      replaceSelection(
        '',
        CodeLineSelection(
          baseIndex: line,
          baseOffset: 0,
          extentIndex: line,
          extentOffset: text.length,
        ),
      );
      return;
    }
    // One edit, not a newline and then a marker: one step of undo, and
    // no frame where the marker is missing. Splitting mid-item works out
    // of the box — what was after the caret becomes the new item's text.
    replaceSelection('\n${head.continuation}');
  }
}
