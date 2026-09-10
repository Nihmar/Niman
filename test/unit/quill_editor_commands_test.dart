// T-WYS-06: the app toolbar maps onto the Quill document.
import 'package:copist/src/editor/toolbar_item.dart';
import 'package:copist/src/editor/wysiwyg/quill_editor_commands.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';

QuillEditorCommands _commands(quill.QuillController controller) =>
    QuillEditorCommands(
      controller: controller,
      onLink: () {},
      onImage: () {},
      onHeading: () {},
    );

quill.QuillController _controller() {
  final document = quill.Document.fromJson(<Map<String, dynamic>>[
    <String, dynamic>{'insert': 'hello'},
    <String, dynamic>{'insert': '\n'},
  ]);
  return quill.QuillController(
    document: document,
    selection: const TextSelection(baseOffset: 0, extentOffset: 5),
  );
}

bool _has(quill.QuillController controller, String key, Object? value) {
  for (final op in controller.document.toDelta().toJson()) {
    final attributes = op['attributes'];
    if (attributes is Map && attributes[key] == value) return true;
  }
  return false;
}

void main() {
  test('bold, italic and strikethrough become inline attributes', () {
    for (final entry in <ToolbarItem, String>{
      ToolbarItem.bold: 'bold',
      ToolbarItem.italic: 'italic',
      ToolbarItem.strikethrough: 'strike',
      ToolbarItem.underline: 'underline',
    }.entries) {
      final controller = _controller();
      addTearDown(controller.dispose);
      _commands(controller).apply(entry.key);
      expect(
        _has(controller, entry.value, true),
        isTrue,
        reason: entry.key.name,
      );
    }
  });

  test('list, ordered list and quote become line attributes', () {
    for (final entry in <ToolbarItem, String>{
      ToolbarItem.list: 'bullet',
      ToolbarItem.orderedList: 'ordered',
    }.entries) {
      final controller = _controller();
      addTearDown(controller.dispose);
      _commands(controller).apply(entry.key);
      expect(
        _has(controller, 'list', entry.value),
        isTrue,
        reason: entry.key.name,
      );
    }
    final quote = _controller();
    addTearDown(quote.dispose);
    _commands(quote).apply(ToolbarItem.quote);
    expect(_has(quote, 'blockquote', true), isTrue);
  });

  test('heading and link apply their dialog answers', () {
    final controller = _controller();
    addTearDown(controller.dispose);
    final commands = _commands(controller);
    commands.applyHeader(2);
    expect(_has(controller, 'header', 2), isTrue);
    commands.applyLink('https://example.com');
    expect(_has(controller, 'link', 'https://example.com'), isTrue);
  });

  test('indent and outdent move the line level', () {
    final controller = _controller();
    addTearDown(controller.dispose);
    final commands = _commands(controller);
    commands.apply(ToolbarItem.indent);
    expect(_has(controller, 'indent', 1), isTrue);
    commands.apply(ToolbarItem.outdent);
    expect(_has(controller, 'indent', 0), isTrue);
  });
}
