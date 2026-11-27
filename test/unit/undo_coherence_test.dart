// What an undo does and what it takes with it (#1337, #1338, #1339, #1358,
// #1359, #1376): the IME's composition is one step, an undo puts the selection
// back, a paste and a cut are steps of their own, a note undone to the saved
// text is the saved text, and a step holds what changed rather than copies.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/md_editing.dart';
import 'package:niman/src/markdown/edit/edit_history.dart';
import 'package:niman/src/markdown/edit/edit_step.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/edit/source_input.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_editor.dart';
import 'package:niman/src/markdown/render/source_view_config.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface_controller.dart';

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

SourceEditor _editor(
  String text, {
  SelectionModel at = const SelectionModel.at(0),
}) {
  final editor = SourceEditor(
    buffer: SourceBuffer.fromText(text),
    look: const SourceLook(theme: _theme),
    initialSelection: at,
    context: () => throw StateError('the core was asked for a view'),
  )..start();
  addTearDown(editor.dispose);
  return editor;
}

/// A keyboard over [text] recording into a history, as the editor wires it.
({
  SourceBuffer buffer,
  SourceInput input,
  EditHistory history,
  SelectionModel Function() caret,
})
_keyboard(String text) {
  final buffer = SourceBuffer.fromText(text);
  final history = EditHistory();
  var current = SelectionModel.at(buffer.length);
  final input = SourceInput(
    buffer: buffer,
    onTokenizer: (_, _) {},
    onRecord: history.record,
    selection: () => current,
    onSelection: (next) => current = next,
    onEdited: (_) {},
  );
  return (buffer: buffer, input: input, history: history, caret: () => current);
}

/// What a Gboard sends for the word [typed], one letter at a time: the first
/// an insertion, each of the others the composing region replaced by itself
/// and the new letter.
List<TextEditingDelta> _composing(String typed) {
  final deltas = <TextEditingDelta>[];
  for (var i = 1; i <= typed.length; i++) {
    final now = typed.substring(0, i);
    deltas.add(
      i == 1
          ? TextEditingDeltaInsertion(
              oldText: '',
              textInserted: now,
              insertionOffset: 0,
              selection: TextSelection.collapsed(offset: i),
              composing: TextRange(start: 0, end: i),
            )
          : TextEditingDeltaReplacement(
              oldText: typed.substring(0, i - 1),
              replacementText: now,
              replacedRange: TextRange(start: 0, end: i - 1),
              selection: TextSelection.collapsed(offset: i),
              composing: TextRange(start: 0, end: i),
            ),
    );
  }
  return deltas;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('an IME composition is one step (#1337)', () {
    test('a word composed letter by letter is undone whole', () {
      final k = _keyboard('');
      for (final delta in _composing('hello')) {
        k.input.updateEditingValueWithDeltas([delta]);
      }
      expect(k.buffer.text, 'hello');
      expect(k.history.length, 1, reason: 'five updates, one step');
      k.history.undo(k.buffer);
      expect(k.buffer.text, '');
      k.history.redo(k.buffer);
      expect(k.buffer.text, 'hello');
    });

    test('the commit that replaces the composing text stays in the step', () {
      final k = _keyboard('');
      for (final delta in _composing('hel')) {
        k.input.updateEditingValueWithDeltas([delta]);
      }
      // "hel" becomes "hello " and the composition ends with it.
      k.input.updateEditingValueWithDeltas([
        const TextEditingDeltaReplacement(
          oldText: 'hel',
          replacementText: 'hello ',
          replacedRange: TextRange(start: 0, end: 3),
          selection: TextSelection.collapsed(offset: 6),
          composing: TextRange.empty,
        ),
      ]);
      expect(k.buffer.text, 'hello ');
      expect(k.history.length, 1);
      k.history.undo(k.buffer);
      expect(k.buffer.text, '');
    });

    test('a composition cancelled leaves nothing to undo', () {
      final k = _keyboard('');
      k.input.updateEditingValueWithDeltas([_composing('h').single]);
      k.input.updateEditingValueWithDeltas([
        const TextEditingDeltaDeletion(
          oldText: 'h',
          deletedRange: TextRange(start: 0, end: 1),
          selection: TextSelection.collapsed(offset: 0),
          composing: TextRange.empty,
        ),
      ]);
      expect(k.buffer.text, '');
      expect(k.history.canUndo, isFalse);
    });

    test('a composition over a selection puts the selection back', () {
      final k = _keyboard('ab cd');
      k.input.updateEditingValueWithDeltas([
        const TextEditingDeltaReplacement(
          oldText: 'ab cd',
          replacementText: 'x',
          replacedRange: TextRange(start: 0, end: 2),
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange(start: 0, end: 1),
        ),
        const TextEditingDeltaReplacement(
          oldText: 'x cd',
          replacementText: 'xy',
          replacedRange: TextRange(start: 0, end: 1),
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange(start: 0, end: 2),
        ),
      ]);
      expect(k.buffer.text, 'xy cd');
      expect(k.history.length, 1);
      k.history.undo(k.buffer);
      expect(k.buffer.text, 'ab cd');
    });

    test('typing outside a composition still goes step by word', () {
      final k = _keyboard('');
      k.input.updateEditingValueWithDeltas([
        const TextEditingDeltaInsertion(
          oldText: '',
          textInserted: 'ab',
          insertionOffset: 0,
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange.empty,
        ),
      ]);
      k.input.updateEditingValueWithDeltas([
        const TextEditingDeltaReplacement(
          oldText: 'ab',
          replacementText: 'xy',
          replacedRange: TextRange(start: 0, end: 2),
          selection: TextSelection.collapsed(offset: 2),
          composing: TextRange.empty,
        ),
      ]);
      expect(
        k.history.length,
        2,
        reason: 'an autocorrect is a step of its own',
      );
    });
  });

  group('an undo puts the selection back (#1338)', () {
    test('Bold on a selected word: undo selects the word, redo too', () {
      const text = 'one two three';
      final surface = MarkdownSurfaceController(SourceBuffer.fromText(text))
        ..select(const SelectionModel(anchor: 4, extent: 7))
        ..applyLineCommand(
          (text, selection) => wrapSelection(
            text: text,
            selection: selection,
            left: '**',
            right: '**',
          ),
        );
      expect(surface.buffer.text, 'one **two** three');
      final afterBold = surface.selection;
      expect(surface.undo(), isTrue);
      expect(surface.buffer.text, text);
      expect(surface.selection, const SelectionModel(anchor: 4, extent: 7));
      expect(surface.redo(), isTrue);
      expect(surface.buffer.text, 'one **two** three');
      expect(surface.selection, afterBold);
    });

    test('two forward Deletes undone leave the caret where it was', () {
      final editor = _editor('abcdef', at: const SelectionModel.at(1))
        ..deleteForward()
        ..deleteForward();
      expect(editor.buffer.text, 'adef');
      expect(editor.undo(), isTrue);
      expect(editor.buffer.text, 'abcdef');
      expect(editor.selection, const SelectionModel.at(1));
      editor.redo();
      expect(editor.selection, const SelectionModel.at(1));
    });

    test('Backspaces undone leave the caret where they began', () {
      final editor = _editor('abcdef', at: const SelectionModel.at(4))
        ..deleteBackward()
        ..deleteBackward();
      expect(editor.buffer.text, 'abef');
      editor.undo();
      expect(editor.buffer.text, 'abcdef');
      expect(editor.selection, const SelectionModel.at(4));
    });

    test('a replaced selection comes back selected', () {
      final editor = _editor(
        'one two three',
        at: const SelectionModel(anchor: 4, extent: 7),
      )..replaceRange(4, 7, 'TWO');
      expect(editor.selection, const SelectionModel.at(7));
      editor.undo();
      expect(editor.buffer.text, 'one two three');
      expect(editor.selection, const SelectionModel(anchor: 4, extent: 7));
    });

    test('a step that merged keeps the selection of its first edit', () {
      final editor = _editor('')
        ..replaceRange(0, 0, 'a')
        ..replaceRange(1, 1, 'b')
        ..replaceRange(2, 2, 'c');
      expect(editor.history.length, 1);
      editor.undo();
      expect(editor.selection, const SelectionModel.at(0));
      editor.redo();
      expect(editor.selection, const SelectionModel.at(3));
    });

    test('a format command records the word, not the line', () {
      final line = '${'word ' * 4000}end';
      final surface = MarkdownSurfaceController(SourceBuffer.fromText(line))
        ..select(const SelectionModel(anchor: 10000, extent: 10004))
        ..applyLineCommand(
          (text, selection) => wrapSelection(
            text: text,
            selection: selection,
            left: '**',
            right: '**',
          ),
        );
      expect(surface.buffer.substring(9999, 10010), ' **word** w');
      // The word it was and the word it is: not the line, twice.
      expect(surface.history.units, lessThan(40));
      surface.undo();
      expect(surface.buffer.text, line);
    });

    test('applyEdit gives the text asked for, whatever it changed', () {
      // The slow, obviously right version: the note says what it was told to.
      final random = math.Random(1338);
      String text(int lines) => [
        for (var i = 0; i < lines; i++)
          [
            for (var j = random.nextInt(6); j > 0; j--)
              const ['a', 'b', ' ', '\u{1F600}', 'é', 'xx'][random.nextInt(6)],
          ].join(),
      ].join('\n');
      for (var round = 0; round < 300; round++) {
        final before = text(1 + random.nextInt(6));
        final after = random.nextBool()
            ? text(1 + random.nextInt(6))
            : before.replaceFirst('a', 'b');
        final surface = MarkdownSurfaceController(SourceBuffer.fromText(before))
          ..applyEdit(after, const TextSelection.collapsed(offset: 0));
        expect(surface.buffer.text, after, reason: '"$before" -> "$after"');
        if (after != before) {
          expect(surface.undo(), isTrue);
          expect(surface.buffer.text, before);
          expect(surface.redo(), isTrue);
          expect(surface.buffer.text, after);
        }
      }
    });

    test('a change inside a line of a CRLF note keeps its terminators', () {
      final random = math.Random(1359);
      const pieces = ['a', 'b', ' ', '\u{1F600}', 'é', 'xx', '**'];
      String line() => [
        for (var j = random.nextInt(7); j > 0; j--)
          pieces[random.nextInt(pieces.length)],
      ].join();
      for (var round = 0; round < 300; round++) {
        final lines = [for (var i = 0; i < 2 + random.nextInt(5); i++) line()];
        final changed = [...lines];
        changed[random.nextInt(lines.length)] = line();
        final before = lines.join('\r\n');
        final after = changed.join('\r\n');
        final surface = MarkdownSurfaceController(SourceBuffer.fromText(before))
          ..applyEdit(after, const TextSelection.collapsed(offset: 0));
        expect(surface.buffer.text, after, reason: '"$before" -> "$after"');
        if (after != before) {
          surface.undo();
          expect(surface.buffer.text, before);
        }
      }
    });
  });

  group('a paste and a cut are steps of their own (#1339)', () {
    late List<MethodCall> calls;
    String? clipboard;

    setUp(() {
      calls = <MethodCall>[];
      clipboard = 'PASTED';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            calls.add(call);
            if (call.method == 'Clipboard.getData') {
              return <String, dynamic>{'text': clipboard};
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('type, paste, undo: only the paste goes', () async {
      final editor = _editor('')
        ..replaceRange(0, 0, 'a')
        ..replaceRange(1, 1, 'b')
        ..replaceRange(2, 2, 'c');
      await editor.typing.paste();
      expect(editor.buffer.text, 'abcPASTED');
      expect(editor.history.length, 2);
      editor.undo();
      expect(editor.buffer.text, 'abc');
      // And the typing after a paste is not the paste's.
      await editor.typing.paste();
      editor.replaceRange(editor.buffer.length, editor.buffer.length, '!');
      editor.undo();
      expect(editor.buffer.text, 'abcPASTED');
    });

    test('Backspace, cut, undo: only the cut comes back', () async {
      // Two Backspaces from the end, and the second leaves the range that
      // comes right before them selected, as a platform that selects without
      // a caret move of its own would: a deletion run's next piece.
      final editor = _editor('abcdefgh', at: const SelectionModel.at(8))
        ..replaceRange(7, 8, '', caret: const SelectionModel.at(7))
        ..replaceRange(
          6,
          7,
          '',
          caret: const SelectionModel(anchor: 4, extent: 6),
        );
      expect(editor.buffer.text, 'abcdef');
      await editor.typing.cutSelection();
      expect(editor.buffer.text, 'abcd');
      expect(editor.history.length, 2);
      editor.undo();
      expect(editor.buffer.text, 'abcdef');
      editor.undo();
      expect(editor.buffer.text, 'abcdefgh');
    });

    test('an edit the shell asks for is a step of its own', () {
      final editor = _editor('')
        ..replaceRange(0, 0, 'a')
        ..replaceRange(1, 1, 'b')
        ..replaceRange(2, 2, '[[x]]', alone: true)
        ..replaceRange(7, 7, 'c');
      expect(editor.history.length, 3);
    });
  });

  group('a note undone to the saved text is the saved text (#1358)', () {
    test('the position names a place the history can come back to', () {
      final buffer = SourceBuffer.fromText('');
      final history = EditHistory();
      void type(int at, String text) {
        buffer.replaceRange(at, at, text);
        history.record(EditRecord(start: at, inserted: text), alone: true);
      }

      type(0, 'x');
      final saved = history.position;
      type(1, 'y');
      expect(history.position, isNot(saved));
      history.undo(buffer);
      expect(history.position, saved, reason: 'back on the saved text');
      history.redo(buffer);
      expect(history.position, isNot(saved));
      history
        ..undo(buffer)
        ..undo(buffer);
      expect(history.position, isNot(saved));
      expect(buffer.text, '');
    });

    test('a position is lost when the history is cleared or trimmed', () {
      final buffer = SourceBuffer.fromText('');
      final history = EditHistory(limit: 2);
      void type(int at, String text) {
        buffer.replaceRange(at, at, text);
        history.record(EditRecord(start: at, inserted: text), alone: true);
      }

      final opened = history.position;
      type(0, 'a');
      type(1, 'b');
      type(2, 'c');
      history
        ..undo(buffer)
        ..undo(buffer);
      expect(history.canUndo, isFalse, reason: 'the first step was dropped');
      expect(
        history.position,
        isNot(opened),
        reason: 'and with it the way back',
      );
      final before = history.position;
      history.clear();
      expect(history.position, isNot(before));
    });

    test('typing on in the step that was saved is another position', () {
      final history = EditHistory()
        ..record(const EditRecord(start: 0, inserted: 'a'));
      final saved = history.position;
      history.record(const EditRecord(start: 1, inserted: 'b'));
      expect(history.position, isNot(saved));
    });
  });

  group('a step holds what changed (#1359)', () {
    test("a whole-note delete is held as the note's own chunks", () {
      final text = '${'line of the note\n' * 70000}end';
      expect(text.length, greaterThan(HeldText.from));
      final surface = MarkdownSurfaceController(SourceBuffer.fromText(text))
        ..replaceRange(0, text.length, '');
      expect(surface.buffer.text, '');
      expect(surface.history.heldUnits, text.length);
      expect(surface.history.units, text.length);
      surface.undo();
      expect(surface.buffer.text, text);
      surface.redo();
      expect(surface.buffer.text, '');
      surface.undo();
      expect(surface.buffer.length, text.length);
      expect(surface.buffer.text, text);
    });

    test('a delete shorter than that is the text itself', () {
      final surface = MarkdownSurfaceController(
        SourceBuffer.fromText('hello world'),
      )..replaceRange(0, 5, '');
      expect(surface.history.heldUnits, 0);
    });

    test('Replace all as hunks: one a match, none of the span', () {
      final text = [for (var i = 0; i < 5000; i++) 'row $i: a cat, then a dog']
          .join('\n');
      final first = text.indexOf('cat');
      final last = text.lastIndexOf('cat') + 3;
      // Three matches, a long way apart.
      final starts = <int>[first, text.indexOf('cat', 60000), last - 3];
      final hunks = <EditHunk>[];
      final out = StringBuffer();
      var at = first;
      for (final start in starts) {
        final gap = text.substring(at, start);
        out
          ..write(gap)
          ..write('OWL');
        hunks.add(EditHunk(gap: gap.length, removed: 'cat', inserted: 'OWL'));
        at = start + 3;
      }
      final surface = MarkdownSurfaceController(SourceBuffer.fromText(text))
        ..replaceRange(first, at, out.toString(), verbatim: true, hunks: hunks);
      var expected = text;
      for (final start in starts.reversed) {
        expected = expected.replaceRange(start, start + 3, 'OWL');
      }
      expect(surface.buffer.text, expected);
      expect(surface.history.units, 3 * 6, reason: 'what each was and became');
      surface.undo();
      expect(surface.buffer.text, text);
      surface.redo();
      expect(surface.buffer.text, expected);
    });
  });

  group('the history is not trusted blindly (#1376)', () {
    test('a step the note no longer matches empties the history', () {
      final buffer = SourceBuffer.fromText('abc');
      final history = EditHistory()
        // Recorded, but never applied: the note is not what the step left.
        ..record(const EditRecord(start: 0, inserted: 'xyz'), alone: true);
      expect(history.undo(buffer), isNull);
      expect(buffer.text, 'abc', reason: 'nothing written over it');
      expect(history.canUndo, isFalse);
    });

    test('a redo the note no longer matches empties the history too', () {
      final buffer = SourceBuffer.fromText('abc');
      final history = EditHistory();
      buffer.replaceRange(0, 3, 'X');
      history
        ..record(
          const EditRecord(start: 0, removed: 'abc', inserted: 'X'),
          alone: true,
        )
        ..undo(buffer);
      expect(buffer.text, 'abc');
      // The note moved behind the history's back.
      buffer.replaceRange(0, 3, 'zzz');
      expect(history.redo(buffer), isNull);
      expect(buffer.text, 'zzz', reason: 'nothing written over it');
      expect(history.canRedo, isFalse);
    });

    test('the touch toolbar offers Undo and Redo only when they can run', () {
      final editor = _editor('abc', at: const SelectionModel.at(3));
      List<String?> labels() => [
        for (final item in editor.controls.menu.clipboardItems(
          () {},
          touch: true,
        ))
          item.label,
      ];
      expect(labels(), isNot(contains('Undo')));
      editor.replaceRange(3, 3, 'd');
      expect(labels(), contains('Undo'));
      expect(labels(), isNot(contains('Redo')));
      editor.controls.menu
          .clipboardItems(() {}, touch: true)
          .firstWhere((item) => item.label == 'Undo')
          .onPressed!();
      expect(editor.buffer.text, 'abc');
      expect(labels(), contains('Redo'));
      // The desktop's menu has keys for it.
      expect(
        editor.controls.menu.clipboardItems(() {}).map((item) => item.label),
        everyElement(isNull),
      );
    });

    test('a caret the platform moved away ends the typing step', () {
      final history = EditHistory()
        ..record(
          const EditRecord(
            start: 0,
            inserted: 'a',
            selectionAfter: SelectionModel.at(1),
          ),
        )
        // Where the step left it: nothing moved.
        ..selectionMoved(const SelectionModel.at(1))
        ..record(
          const EditRecord(
            start: 1,
            inserted: 'b',
            selectionAfter: SelectionModel.at(2),
          ),
        );
      expect(history.length, 1);
      history
        ..selectionMoved(const SelectionModel.at(0))
        ..record(const EditRecord(start: 2, inserted: 'c'));
      expect(history.length, 2, reason: 'the caret went away and came back');
    });

    test('the closers the editor wrote are forgotten by an undo', () {
      final editor = _editor('');
      // The editor wrote a `)` for a `(` typed.
      expect(editor.typing.brackets.typed(editor.buffer, 0, 0, '('), isNotNull);
      expect(editor.typing.brackets.isEmpty, isFalse);
      editor
        ..replaceRange(0, 0, '()')
        ..undo();
      expect(editor.typing.brackets.isEmpty, isTrue);
    });
  });
}
