// T-WYS-08: the WYSIWYG find controller searches, navigates and replaces.
import 'package:copist/src/editor/wysiwyg/wysiwyg_find_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';

quill.QuillController _controller(String text) {
  final document = quill.Document.fromJson(<Map<String, dynamic>>[
    <String, dynamic>{'insert': text},
    <String, dynamic>{'insert': '\n'},
  ]);
  return quill.QuillController(
    document: document,
    selection: const TextSelection.collapsed(offset: 0),
  );
}

void main() {
  test('finds every match and selects the first', () {
    final controller = _controller('one two one two one');
    addTearDown(controller.dispose);
    final find = WysiwygFindController(controller);
    addTearDown(find.dispose);

    find.findInput.text = 'one';
    find.search();
    expect(find.matchCount, 3);
    expect(find.matchIndex, 0);
    expect(controller.selection.start, 0);
    find.nextMatch();
    expect(controller.selection.start, 8);
    find.nextMatch();
    expect(controller.selection.start, 16);
    find.nextMatch();
    expect(controller.selection.start, 0, reason: 'wraps around');
    find.previousMatch();
    expect(controller.selection.start, 16, reason: 'wraps backwards');
  });

  test('case sensitivity is a toggle', () {
    final controller = _controller('One one ONE');
    addTearDown(controller.dispose);
    final find = WysiwygFindController(controller);
    addTearDown(find.dispose);
    find.findInput.text = 'one';
    find.search();
    expect(find.matchCount, 3);
    find.toggleCaseSensitive();
    expect(find.matchCount, 1);
    expect(controller.selection.start, 4);
  });

  test('replace one and all go through the document', () {
    final controller = _controller('one two one');
    addTearDown(controller.dispose);
    final find = WysiwygFindController(controller);
    addTearDown(find.dispose);
    find.findInput.text = 'one';
    find.replaceInput.text = '1';
    find
      ..search()
      ..replaceMatch();
    expect(controller.document.toPlainText().trim(), '1 two one');
    find.replaceAllMatches();
    expect(controller.document.toPlainText().trim(), '1 two 1');
  });

  test('closing drops the matches', () {
    final controller = _controller('one one');
    addTearDown(controller.dispose);
    final find = WysiwygFindController(controller);
    addTearDown(find.dispose);
    find.findInput.text = 'one';
    find.search();
    expect(find.matchCount, 2);
    find.close();
    expect(find.visible, isFalse);
    expect(find.matchCount, 0);
  });
}
