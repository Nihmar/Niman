import 'package:copist/src/editor/editor_commands.dart';
import 'package:copist/src/editor/toolbar_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// The formatting toolbar mapped onto a [quill.QuillController].
///
/// The same buttons as the source editor, acting on the WYSIWYG document.
/// The dialogs (link, image, heading) belong to the owner and arrive as
/// callbacks; the toolbar itself never changes.
final class QuillEditorCommands implements EditorCommands {
  /// Creates the commands over [controller].
  const new({
    required this.controller,
    required this.onLink,
    required this.onImage,
    required this.onHeading,
  });

  /// The document the toolbar formats.
  final quill.QuillController controller;

  /// Opens the link dialog and applies the chosen href.
  final VoidCallback onLink;

  /// Runs the library-relative image insertion.
  final VoidCallback onImage;

  /// Opens the heading-level dialog and applies the chosen level.
  final VoidCallback onHeading;

  @override
  void apply(ToolbarItem item) {
    switch (item) {
      case ToolbarItem.bold:
        _toggle(quill.Attribute.bold);
      case ToolbarItem.italic:
        _toggle(quill.Attribute.italic);
      case ToolbarItem.underline:
        _toggle(quill.Attribute.underline);
      case ToolbarItem.strikethrough:
        _toggle(quill.Attribute.strikeThrough);
      case ToolbarItem.superscript:
        _toggle(quill.Attribute.superscript);
      case ToolbarItem.link:
        onLink();
      case ToolbarItem.code:
        _toggle(quill.Attribute.codeBlock);
      case ToolbarItem.image:
        onImage();
      case ToolbarItem.heading:
        onHeading();
      case ToolbarItem.list:
        _toggle(const quill.ListAttribute('bullet'));
      case ToolbarItem.orderedList:
        _toggle(const quill.ListAttribute('ordered'));
      case ToolbarItem.quote:
        _toggle(quill.Attribute.blockQuote);
      case ToolbarItem.outdent:
        _indent(-1);
      case ToolbarItem.indent:
        _indent(1);
    }
  }

  /// Applies a header level (the heading dialog's answer).
  void applyHeader(int level) {
    controller.formatSelection(quill.HeaderAttribute(level: level));
  }

  /// Applies a link href (the link dialog's answer).
  void applyLink(String href) {
    controller.formatSelection(quill.LinkAttribute(href));
  }

  void _toggle(quill.Attribute<Object?> attribute) {
    final active = controller.getSelectionStyle().attributes.containsKey(
      attribute.key,
    );
    controller.formatSelection(
      active ? quill.Attribute.clone(attribute, null) : attribute,
    );
  }

  void _indent(int delta) {
    final current = controller
        .getSelectionStyle()
        .attributes[quill.Attribute.indent.key];
    final value = current?.value;
    final level = (value is int ? value : 0) + delta;
    controller.formatSelection(
      quill.IndentAttribute(level: level < 0 ? 0 : level),
    );
  }
}
