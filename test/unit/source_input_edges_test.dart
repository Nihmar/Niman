// What the platform's keyboard can send that is not a clean keystroke: a delta
// that names half of a pair (#1353), a whole value standing for a keystroke
// (#1354), an insertion between a carriage return and its line feed, and the
// round trips a stored `\r\n` costs (#1374, #1376).
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/bracket_pairs.dart';
import 'package:niman/src/markdown/edit/enter_edit.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/edit/source_input.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// A wired surface over [text] with the caret at [caret].
({
  SourceBuffer buffer,
  SourceInput input,
  List<SelectionModel> carets,
  List<String> selectors,
})
_wire(
  String text, {
  int caret = 0,
  bool Function(int start, int end)? onNewline,
  bool Function(int start, int end, String inserted)? onTyped,
}) {
  final buffer = SourceBuffer.fromText(text);
  final carets = <SelectionModel>[];
  final selectors = <String>[];
  var current = SelectionModel.at(caret);
  final input = SourceInput(
    buffer: buffer,
    onTokenizer: (edit, buffer) {},
    selection: () => current,
    onSelection: (next) {
      current = next;
      carets.add(next);
    },
    onEdited: (_) {},
    onNewline: onNewline,
    onTyped: onTyped,
    onSelector: selectors.add,
  );
  return (buffer: buffer, input: input, carets: carets, selectors: selectors);
}

/// A surface whose keystroke hooks do what the editor's do: Enter continues a
/// list, a typed bracket writes its pair.
({SourceBuffer buffer, SourceInput input, List<SelectionModel> carets}) _typing(
  String text, {
  required int caret,
}) {
  final buffer = SourceBuffer.fromText(text);
  final brackets = BracketPairs();
  late SourceInput input;
  var current = SelectionModel.at(caret);
  final carets = <SelectionModel>[];
  input = SourceInput(
    buffer: buffer,
    onTokenizer: (edit, buffer) {},
    selection: () => current,
    onSelection: (next) {
      current = next;
      carets.add(next);
    },
    onEdited: (_) {},
    onNewline: (start, end) {
      if (start != end) return false;
      final edit = enterEdit(buffer, start, indentWidth: 2);
      if (edit == null) return false;
      buffer.replaceRange(edit.start, edit.end, edit.text);
      current = edit.caret ?? SelectionModel.at(edit.start + edit.text.length);
      input.sendSelection();
      return true;
    },
    onTyped: (start, end, inserted) {
      if (inserted.length != 1) return false;
      final edit = brackets.typed(buffer, start, end, inserted);
      if (edit == null) return false;
      buffer.replaceRange(edit.start, edit.end, edit.text);
      current = SelectionModel(anchor: edit.anchor, extent: edit.extent);
      input.sendSelection();
      return true;
    },
  );
  return (buffer: buffer, input: input, carets: carets);
}

TextEditingDeltaInsertion _insert(String oldText, int at, String text) =>
    TextEditingDeltaInsertion(
      oldText: oldText,
      insertionOffset: at,
      textInserted: text,
      selection: TextSelection.collapsed(offset: at + text.length),
      composing: TextRange.empty,
    );

TextEditingDeltaDeletion _delete(String oldText, int from, int to) =>
    TextEditingDeltaDeletion(
      oldText: oldText,
      deletedRange: TextRange(start: from, end: to),
      selection: TextSelection.collapsed(offset: from),
      composing: TextRange.empty,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('half of a surrogate pair (#1353)', () {
    const text = 'a😀b';

    test('deleting its low half deletes the pair', () {
      final surface = _wire(text, caret: 3);
      surface.input.updateEditingValueWithDeltas([_delete(text, 2, 3)]);
      expect(surface.buffer.text, 'ab');
      expect(surface.carets.last.extent, 1);
    });

    test('deleting its high half deletes the pair', () {
      final surface = _wire(text, caret: 3);
      surface.input.updateEditingValueWithDeltas([_delete(text, 1, 2)]);
      expect(surface.buffer.text, 'ab');
    });

    test('a range that ends inside it takes the whole pair', () {
      final surface = _wire(text, caret: 3);
      surface.input.updateEditingValueWithDeltas([_delete(text, 0, 2)]);
      expect(surface.buffer.text, 'b');
    });

    test('a range that starts inside it takes the whole pair', () {
      final surface = _wire(text, caret: 3);
      surface.input.updateEditingValueWithDeltas([_delete(text, 2, 4)]);
      expect(surface.buffer.text, 'a');
    });

    test('an insertion inside it goes before it, the pair whole', () {
      final surface = _wire(text, caret: 1);
      surface.input.updateEditingValueWithDeltas([_insert(text, 2, 'X')]);
      expect(surface.buffer.text, 'aX😀b');
    });

    test('a replacement of half of it replaces the pair', () {
      final surface = _wire(text, caret: 1);
      surface.input.updateEditingValueWithDeltas([
        const TextEditingDeltaReplacement(
          oldText: text,
          replacementText: 'x',
          replacedRange: TextRange(start: 2, end: 3),
          selection: TextSelection.collapsed(offset: 3),
          composing: TextRange.empty,
        ),
      ]);
      expect(surface.buffer.text, 'axb');
    });

    test('a whole value that drops half of it drops the pair', () {
      final surface = _wire(text, caret: 3);
      surface.input.updateEditingValue(
        const TextEditingValue(
          text: 'a\uD83Db',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(surface.buffer.text, 'ab');
    });

    test('a lone surrogate the note already holds is left alone', () {
      const broken = 'a\uD83Db';
      final surface = _wire(broken, caret: 2);
      surface.input.updateEditingValueWithDeltas([_delete(broken, 1, 2)]);
      expect(surface.buffer.text, 'ab');
    });
  });

  group('a line ending is one position (#1353)', () {
    const text = 'a\r\nb\r\n';

    test(r'an insertion between the \r and the \n keeps the break', () {
      final surface = _wire(text, caret: 1);
      surface.input.updateEditingValueWithDeltas([_insert(text, 2, 'X')]);
      expect(surface.buffer.text, 'aX\r\nb\r\n');
    });

    test(r'a deletion of the \r alone deletes the break', () {
      final surface = _wire(text, caret: 2);
      surface.input.updateEditingValueWithDeltas([_delete(text, 1, 2)]);
      expect(surface.buffer.text, 'ab\r\n');
    });

    test('a deletion that ends between them takes the whole break', () {
      final surface = _wire(text, caret: 2);
      surface.input.updateEditingValueWithDeltas([_delete(text, 0, 2)]);
      expect(surface.buffer.text, 'b\r\n');
    });
  });

  group('a whole value is a keystroke too (#1354)', () {
    /// The note after [text] is typed at [caret] as deltas, and as whole
    /// values — the two ways a platform can say the same thing.
    (String, String) typed(String text, int caret, String character) {
      final byDelta = _typing(text, caret: caret);
      byDelta.input.updateEditingValueWithDeltas([
        _insert(text, caret, character),
      ]);
      final byValue = _typing(text, caret: caret);
      byValue.input.updateEditingValue(
        TextEditingValue(
          text: text.substring(0, caret) + character + text.substring(caret),
          selection: TextSelection.collapsed(offset: caret + character.length),
        ),
      );
      return (byDelta.buffer.text, byValue.buffer.text);
    }

    test('Enter after a list item continues the list', () {
      final (delta, value) = typed('- a', 3, '\n');
      expect(delta, '- a\n- ');
      expect(value, delta);
    });

    test('a typed bracket writes its pair', () {
      final (delta, value) = typed('ab ', 3, '(');
      expect(delta, 'ab ()');
      expect(value, delta);
    });

    test('a bracket typed beside an equal one is the one at the caret', () {
      // The two texts differ at 3 or at 4: the caret says which.
      final byValue = _typing('f( g', caret: 3);
      byValue.input.updateEditingValue(
        const TextEditingValue(
          text: 'f(( g',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      final byDelta = _typing('f( g', caret: 3);
      byDelta.input.updateEditingValueWithDeltas([_insert('f( g', 2, '(')]);
      expect(byValue.buffer.text, byDelta.buffer.text);
    });

    test('a composing bracket is not typed yet', () {
      final surface = _typing('ab ', caret: 3);
      surface.input.updateEditingValue(
        const TextEditingValue(
          text: 'ab (',
          selection: TextSelection.collapsed(offset: 4),
          composing: TextRange(start: 3, end: 4),
        ),
      );
      expect(surface.buffer.text, 'ab (');
    });

    test('a paste is the whole thing, hooks or not', () {
      final surface = _typing('ab ', caret: 3);
      surface.input.updateEditingValue(
        const TextEditingValue(
          text: 'ab (x)',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      expect(surface.buffer.text, 'ab (x)');
    });
  });

  group('a batch after a stored line break (#1374)', () {
    // The note's lines end `\r\n`; the platform's `\n` is stored as one.
    const text = 'ab\r\ncd';

    test('the next delta lands where the platform put it', () {
      final surface = _wire(text, caret: 1);
      surface.input.updateEditingValueWithDeltas([
        _insert(text, 1, '\n'),
        _insert('a\nb\r\ncd', 3, 'X'),
      ]);
      expect(surface.buffer.text, 'a\r\nbX\r\ncd');
      expect(surface.carets.last.extent, 5, reason: 'after the X');
    });

    test('and the one after it, and a deletion', () {
      final surface = _wire(text, caret: 1);
      surface.input.updateEditingValueWithDeltas([
        _insert(text, 1, '\n'),
        _insert('a\nb\r\ncd', 3, 'X'),
        _insert('a\nbX\r\ncd', 4, 'Y'),
        _delete('a\nbXY\r\ncd', 0, 1),
      ]);
      expect(surface.buffer.text, '\r\nbXY\r\ncd');
    });

    test("without a stored break the offsets are the platform's own", () {
      const plain = 'ab\ncd';
      final surface = _wire(plain, caret: 1);
      surface.input.updateEditingValueWithDeltas([
        _insert(plain, 1, 'X'),
        _insert('aXb\ncd', 3, 'Y'),
      ]);
      expect(surface.buffer.text, 'aXbY\ncd');
    });
  });

  test('performSelector hands the selector on', () {
    final surface = _wire('abc');
    surface.input.performSelector('moveToBeginningOfLine:');
    expect(surface.selectors, ['moveToBeginningOfLine:']);
  });
}
