// What the platform's keyboard can send that is not a clean keystroke: a delta
// that names half of a pair (#1353), a whole value standing for a keystroke
// (#1354), an insertion between a carriage return and its line feed, and the
// round trips a stored `\r\n` costs (#1374, #1376).
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('performSelector hands the selector on', () {
    final surface = _wire('abc');
    surface.input.performSelector('moveToBeginningOfLine:');
    expect(surface.selectors, ['moveToBeginningOfLine:']);
  });
}
