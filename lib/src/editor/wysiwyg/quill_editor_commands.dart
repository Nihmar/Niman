import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/editor/editor_commands.dart';
import 'package:niman/src/editor/toolbar_item.dart';

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

  static const AppLogger _log = AppLogger(name: 'wysiwyg');

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
    final before = _styleKeys();
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
    _log.debug('toolbar ${item.name}: [$before] -> [${_styleKeys()}]');
  }

  String _styleKeys() =>
      controller.getSelectionStyle().attributes.keys.join(',');

  /// Applies a header level (the heading dialog's answer).
  void applyHeader(int level) {
    controller.formatSelection(quill.HeaderAttribute(level: level));
  }

  /// Applies a link href (the link dialog's answer).
  void applyLink(String href) {
    controller.formatSelection(quill.LinkAttribute(href));
  }

  void _toggle(quill.Attribute<Object?> attribute) {
    final active = _isOn(_attributesOf(controller), attribute);
    controller.formatSelection(
      active ? quill.Attribute.clone(attribute, null) : attribute,
    );
  }

  /// The styles at the caret, merged with the ones kept for the next typed
  /// character: a toggle tapped on an empty selection has to look active
  /// before anything is typed (T-WYS-06).
  ///
  /// Inline attributes come from the selection style; block attributes come
  /// from the line the caret sits on. The selection style inherits the
  /// previous line's block style when the caret is at the start of an empty
  /// line, which is how the code button stayed lit — and the toggle direction
  /// flipped — after a double Enter left the fence (2026-09-13, code-block
  /// follow-up). Reading the line directly keeps the button in step with the
  /// document.
  static Map<String, quill.Attribute<dynamic>> _attributesOf(
    quill.QuillController controller,
  ) {
    final line = controller.document.queryChild(controller.selection.end).node;
    final attributes = <String, quill.Attribute<dynamic>>{};
    for (final entry in controller.getSelectionStyle().attributes.entries) {
      if (entry.value.scope == quill.AttributeScope.inline) {
        attributes[entry.key] = entry.value;
      }
    }
    if (line is quill.Line) {
      attributes.addAll(line.style.attributes);
    }
    attributes.addAll(controller.toggledStyle.attributes);
    return attributes;
  }

  /// Whether [item] is already on at the caret, for the toolbar's pressed
  /// state.
  static bool isActive(quill.QuillController controller, ToolbarItem item) {
    final attributes = _attributesOf(controller);
    return switch (item) {
      ToolbarItem.bold => _isOn(attributes, quill.Attribute.bold),
      ToolbarItem.italic => _isOn(attributes, quill.Attribute.italic),
      ToolbarItem.underline => _isOn(attributes, quill.Attribute.underline),
      ToolbarItem.strikethrough => _isOn(
        attributes,
        quill.Attribute.strikeThrough,
      ),
      ToolbarItem.superscript =>
        attributes[quill.Attribute.script.key]?.value ==
            quill.Attribute.superscript.value,
      ToolbarItem.link => _isOn(attributes, quill.Attribute.link),
      ToolbarItem.code =>
        _isOn(attributes, quill.Attribute.codeBlock) ||
            _isOn(attributes, quill.Attribute.inlineCode),
      ToolbarItem.image => false,
      ToolbarItem.heading => _isOn(attributes, quill.Attribute.header),
      ToolbarItem.list =>
        attributes[quill.Attribute.list.key]?.value == 'bullet',
      ToolbarItem.orderedList =>
        attributes[quill.Attribute.list.key]?.value == 'ordered',
      ToolbarItem.quote => _isOn(attributes, quill.Attribute.blockQuote),
      ToolbarItem.outdent || ToolbarItem.indent => false,
    };
  }

  /// An attribute is "on" only when it carries a value: a removed one stays
  /// in the style map with a null value.
  static bool _isOn(
    Map<String, quill.Attribute<dynamic>> attributes,
    quill.Attribute<dynamic> attribute,
  ) => attributes[attribute.key]?.value != null;

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
