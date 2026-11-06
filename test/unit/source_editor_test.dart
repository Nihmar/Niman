// The source editor's core, driven without a widget (#1261): an edit, a
// caret motion and a fold need no frame, and the core answers them alone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_editor.dart';
import 'package:niman/src/markdown/render/source_line.dart';
import 'package:niman/src/markdown/render/source_view_config.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';

const MarkdownTheme _theme = MarkdownTheme(
  body: TextStyle(fontSize: 14, height: 1.5, fontFamily: 'monospace'),
  heading1: TextStyle(fontSize: 25),
  heading2: TextStyle(fontSize: 21),
  heading3: TextStyle(fontSize: 18),
  heading4: TextStyle(fontSize: 16),
  heading5: TextStyle(fontSize: 14),
  heading6: TextStyle(fontSize: 13),
  code: TextStyle(fontSize: 14, fontFamily: 'monospace'),
  quote: TextStyle(fontSize: 14),
  tableCell: TextStyle(fontSize: 14),
  tableHeader: TextStyle(fontSize: 14),
  link: TextStyle(fontSize: 14),
  wikilink: TextStyle(fontSize: 14),
  tag: TextStyle(fontSize: 14),
  marker: TextStyle(fontSize: 14),
  codeHighlight: <String, TextStyle>{},
  rule: Color(0xFF888888),
  codeBackground: Color(0xFFEEEEEE),
  quoteBar: Color(0xFFCCCCCC),
  tableBorder: Color(0xFFCCCCCC),
  markerDim: Color(0xFF999999),
  blockSpacing: 10,
  listIndentPerLevel: 22,
  quoteIndentPerLevel: 12,
  codePadding: 8,
  quoteBarWidth: 3,
  ruleThickness: 1,
  tableCellPadding: EdgeInsets.all(4),
  lineHeight: 21,
);

/// An editor of [text] with its caret at [at], started as its view starts
/// it and let go after the test. Nothing here has a view: whatever asks for
/// one fails the test.
SourceEditor _editor(
  String text, {
  SelectionModel at = const SelectionModel.at(0),
  ValueChanged<SourceEdit>? onChanged,
}) {
  final editor = SourceEditor(
    buffer: SourceBuffer.fromText(text),
    look: const SourceLook(theme: _theme),
    initialSelection: at,
    onChanged: onChanged,
    context: () => throw StateError('the core was asked for a view'),
  )..start();
  addTearDown(editor.dispose);
  return editor;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('typing', () {
    test('an edit lands in the buffer, moves the caret and is told', () {
      final edits = <SourceEdit>[];
      var rebuilds = 0;
      final editor =
          _editor('Hello', at: const SelectionModel.at(5), onChanged: edits.add)
            ..addListener(() => rebuilds++)
            ..replaceRange(5, 5, ' world');

      expect(editor.buffer.text, 'Hello world');
      expect(editor.selection, const SelectionModel.at(11));
      expect(edits, hasLength(1));
      expect(rebuilds, greaterThan(0), reason: 'the view draws the edit');
    });

    test('undo and redo walk the history back and forth', () {
      final editor = _editor('Hello', at: const SelectionModel.at(5))
        ..replaceRange(5, 5, ' world');

      expect(editor.history.canUndo, isTrue);
      expect(editor.undo(), isTrue);
      expect(editor.buffer.text, 'Hello');
      expect(editor.selection.extent, 5);
      expect(editor.redo(), isTrue);
      expect(editor.buffer.text, 'Hello world');
      expect(editor.redo(), isFalse, reason: 'nothing left to redo');
    });

    test('Backspace deletes a character, or a word with the modifier', () {
      final editor = _editor('one two', at: const SelectionModel.at(7))
        ..deleteBackward();

      expect(editor.buffer.text, 'one tw');
      editor.deleteBackward(word: true);
      expect(editor.buffer.text, 'one ');
      expect(editor.selection, const SelectionModel.at(4));
    });

    test('Tab on a plain line puts the indent at the caret', () {
      final editor = _editor('text')..typing.indent();

      expect(editor.buffer.text, '  text');
      expect(editor.selection, const SelectionModel.at(2));
    });

    test('a change behind its back is read again at the next update', () {
      final editor = _editor('# Title\nbody\n');
      editor.buffer.replaceRange(0, editor.buffer.length, 'plain\n');

      editor.configure(
        buffer: editor.buffer,
        history: () => fail('the same note keeps its history'),
        initialSelection: () => fail('the same note keeps its caret'),
        look: editor.look,
        behaviour: editor.behaviour,
        services: editor.services,
        actions: editor.actions,
        selection: null,
        onSelection: null,
        onChanged: null,
        controller: null,
      );

      expect(editor.headings, isEmpty, reason: 'the heading went');
    });
  });

  group('caret motion', () {
    test('by characters and words, collapsed or extending', () {
      final editor = _editor('alpha beta gamma');
      final layout = editor.layout..moveCaretBy(CaretMotion.wordRight);

      expect(editor.selection, const SelectionModel.at(5), reason: 'word end');
      layout.moveCaretBy(CaretMotion.characterRight, extend: true);
      expect(editor.selection, const SelectionModel(anchor: 5, extent: 6));
      editor.placeCaret(13);
      layout.moveCaretBy(CaretMotion.wordLeft);
      expect(editor.selection, const SelectionModel.at(11));
      layout.moveCaretBy(CaretMotion.characterLeft);
      expect(editor.selection, const SelectionModel.at(10));
    });

    test("Home goes past a list item's marker, End to the line's end", () {
      final editor = _editor('- item\nnext', at: const SelectionModel.at(4));

      editor.layout.moveCaretBy(CaretMotion.lineTextStart);
      expect(editor.selection, const SelectionModel.at(2));
      editor.layout.moveCaretBy(CaretMotion.lineEnd);
      expect(editor.selection, const SelectionModel.at(6));
      editor.layout.moveCaretBy(CaretMotion.documentEnd);
      expect(editor.selection, SelectionModel.at(editor.buffer.length));
    });

    test('a move tells the caller where the caret went', () {
      final moves = <SelectionModel>[];
      _editor('abc')
        ..onSelection = moves.add
        ..placeCaret(2)
        ..selectAll();

      expect(moves, [
        const SelectionModel.at(2),
        const SelectionModel(anchor: 0, extent: 3),
      ]);
    });
  });

  group('folds', () {
    const note = '# One\nfirst\nmore\n# Two\nsecond\n';

    test("a heading's section folds away and comes back", () {
      final editor = _editor(note);

      expect(editor.foldMarkOf(0), SourceFoldMark.open);
      expect(editor.foldMarkOf(1), SourceFoldMark.none);

      editor.toggleFold(0);
      expect(editor.folds.isFolded(0), isTrue);
      expect(editor.folds.isHidden(1), isTrue);
      expect(editor.folds.isHidden(2), isTrue);
      expect(editor.folds.isHidden(3), isFalse, reason: 'the next heading');
      expect(editor.foldMarkOf(0), SourceFoldMark.closed);

      editor.toggleFold(0);
      expect(editor.folds.isFolded(0), isFalse);
      expect(editor.folds.isHidden(1), isFalse);
    });

    test('a caret inside the folded section goes to the heading', () {
      final editor = _editor(note, at: const SelectionModel.at(8))
        ..toggleFold(0);

      expect(editor.selection, const SelectionModel.at(5));
    });

    test('a caret moved into a folded section unfolds it', () {
      final editor = _editor(note)
        ..toggleFold(0)
        ..placeCaret(8);

      expect(editor.folds.isFolded(0), isFalse);
    });

    test('a note without line numbers offers no fold', () {
      final editor = SourceEditor(
        buffer: SourceBuffer.fromText(note),
        look: const SourceLook(theme: _theme, showLineNumbers: false),
        context: () => throw StateError('the core was asked for a view'),
      )..start();
      addTearDown(editor.dispose);

      expect(editor.foldMarkOf(0), SourceFoldMark.none);
    });
  });
}
