// #141: Enter, through the controller both platforms go through.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/markdown_editing_controller.dart';
import 'package:re_editor/re_editor.dart';

/// A controller over [text] with the caret at the end of [line], or at
/// [offset] when given. [plain] answers the fenced-code question.
MarkdownEditingController _at(
  String text, {
  int line = 0,
  int? offset,
  bool plain = true,
}) {
  final controller = MarkdownEditingController(
    delegate: CodeLineEditingController.fromText(text),
    isPlain: (_) => plain,
  );
  controller.selection = CodeLineSelection.collapsed(
    index: line,
    offset: offset ?? controller.codeLines[line].text.length,
  );
  return controller;
}

void main() {
  group('Enter on a list item', () {
    test('carries a bullet on', () {
      final controller = _at('- milk')..applyNewLine();
      expect(controller.text, '- milk\n- ');
      addTearDown(controller.dispose);
    });

    test('counts an ordered item on', () {
      final controller = _at('3. milk')..applyNewLine();
      expect(controller.text, '3. milk\n4. ');
      addTearDown(controller.dispose);
    });

    test('carries a task item on, with an empty box', () {
      final controller = _at('- [x] milk')..applyNewLine();
      expect(controller.text, '- [x] milk\n- [ ] ');
      addTearDown(controller.dispose);
    });

    test('keeps the indent', () {
      final controller = _at('  - milk')..applyNewLine();
      expect(controller.text, '  - milk\n  - ');
      addTearDown(controller.dispose);
    });

    test('splitting an item mid-word makes the rest the next item', () {
      final controller = _at('- milkbread', offset: 6)..applyNewLine();
      expect(controller.text, '- milk\n- bread');
      addTearDown(controller.dispose);
    });

    test('the caret lands after the new marker, ready to type', () {
      final controller = _at('- milk')..applyNewLine();
      expect(controller.selection.baseIndex, 1);
      expect(controller.selection.baseOffset, 2);
      addTearDown(controller.dispose);
    });

    test('it is one step of undo, not two', () {
      final controller = _at('- milk')
        ..applyNewLine()
        ..undo();
      expect(controller.text, '- milk');
      addTearDown(controller.dispose);
    });
  });

  group('Enter on an item with nothing in it', () {
    test('ends the list instead of adding another', () {
      final controller = _at('- milk\n- ', line: 1)..applyNewLine();
      expect(controller.text, '- milk\n');
      addTearDown(controller.dispose);
    });

    test('ends it for a numbered list too, indent and all', () {
      final controller = _at('1. milk\n  2. ', line: 1)..applyNewLine();
      expect(controller.text, '1. milk\n');
      addTearDown(controller.dispose);
    });

    test('an empty task item ends the list', () {
      final controller = _at('- [ ] milk\n- [ ] ', line: 1)..applyNewLine();
      expect(controller.text, '- [ ] milk\n');
      addTearDown(controller.dispose);
    });
  });

  group('Enter everywhere else', () {
    test('a plain line just breaks', () {
      final controller = _at('prose')..applyNewLine();
      expect(controller.text, 'prose\n');
      addTearDown(controller.dispose);
    });

    test('a dash inside a code fence starts nothing', () {
      final controller = _at('- milk', plain: false)..applyNewLine();
      expect(controller.text, '- milk\n');
      addTearDown(controller.dispose);
    });

    test('a selection is replaced, not carried on', () {
      final controller =
          MarkdownEditingController(
              delegate: CodeLineEditingController.fromText('- milk and bread'),
              isPlain: (_) => true,
            )
            ..selection = const CodeLineSelection(
              baseIndex: 0,
              baseOffset: 6,
              extentIndex: 0,
              extentOffset: 16,
            )
            ..applyNewLine();
      expect(controller.text, '- milk\n');
      addTearDown(controller.dispose);
    });
  });
}
