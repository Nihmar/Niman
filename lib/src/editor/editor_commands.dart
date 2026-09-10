import 'package:copist/src/editor/toolbar_item.dart';

/// The formatting toolbar's commands against the active editor.
///
/// The toolbar is editor chrome on both surfaces; this is the seam that lets
/// the same buttons act on the Markdown buffer or on the WYSIWYG document
/// (T-WYS-06).
abstract interface class EditorCommands {
  /// Applies [item] to the active editor.
  void apply(ToolbarItem item);
}
