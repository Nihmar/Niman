// The surface's keyboard wiring (#245, phase 3): what arrives from the platform
// and what it does to the note.
//
// These drive `SourceInput` directly — no connection, no widget — because this
// is
// the layer that must be right about *text*, and it is the layer a device
// cannot
// be used to debug.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/edit/source_input.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// A wired surface over [text], with its caret and its tokenizer.
({
  SourceBuffer buffer,
  SourceInput input,
  HighlightDocument tokens,
  List<SelectionModel> carets,
})
_wire(String text, {int caret = 0}) {
  final buffer = SourceBuffer.fromText(text);
  final tokens = HighlightDocument.fromText(text);
  final carets = <SelectionModel>[];
  var current = SelectionModel.at(caret);
  final input = SourceInput(
    buffer: buffer,
    onTokenizer: (edit, buffer) => SourceInput.retokenize(tokens, edit, buffer),
    selection: () => current,
    onSelection: (next) {
      current = next;
      carets.add(next);
    },
    onEdited: (_) {},
  );
  return (buffer: buffer, input: input, tokens: tokens, carets: carets);
}

TextEditingDeltaInsertion _insert(String oldText, int at, String text) =>
    TextEditingDeltaInsertion(
      oldText: oldText,
      insertionOffset: at,
      textInserted: text,
      selection: TextSelection.collapsed(offset: at + text.length),
      composing: TextRange.empty,
    );

void main() {
  test('a keystroke is one character, and the note and caret follow it', () {
    final surface = _wire('ciao\n');
    surface.input.updateEditingValueWithDeltas(<TextEditingDelta>[
      _insert('ciao\n', 4, '!'),
    ]);
    expect(surface.buffer.text, 'ciao!\n');
    expect(surface.input.deltaCount, 1);
    expect(surface.carets.last.extent, 5, reason: 'the caret is after the !');
  });

  test('a deletion removes the range the platform named', () {
    final surface = _wire('ciao mondo\n', caret: 10);
    surface.input.updateEditingValueWithDeltas(<TextEditingDelta>[
      const TextEditingDeltaDeletion(
        oldText: 'ciao mondo\n',
        deletedRange: TextRange(start: 4, end: 10),
        selection: TextSelection.collapsed(offset: 4),
        composing: TextRange.empty,
      ),
    ]);
    expect(surface.buffer.text, 'ciao\n');
  });

  test('an autocorrect replacement replaces the word it names', () {
    final surface = _wire('sono alessandro\n', caret: 15);
    surface.input.updateEditingValueWithDeltas(<TextEditingDelta>[
      const TextEditingDeltaReplacement(
        oldText: 'sono alessandro\n',
        replacementText: 'Alessandro ',
        replacedRange: TextRange(start: 5, end: 15),
        selection: TextSelection.collapsed(offset: 16),
        composing: TextRange.empty,
      ),
    ]);
    expect(surface.buffer.text, 'sono Alessandro \n');
  });

  test(
    'a delta with an oldText behind is recovered onto the platform text',
    () {
      // The device sent this four times at a 921 600-character note: the
      // platform's copy was a keystroke behind the app's. Applying the delta to
      // the *buffer* would repeat or drop a character here.
      final surface = _wire('ab\n');
      surface.input.updateEditingValueWithDeltas(<TextEditingDelta>[
        _insert('ab\n', 2, 'c'),
      ]);
      expect(surface.buffer.text, 'abc\n');
      surface.input.updateEditingValueWithDeltas(<TextEditingDelta>[
        _insert('ab\n', 2, 'd'),
      ]);
      expect(surface.input.recoveredDeltas, 1);
      expect(
        surface.buffer.text,
        'abd\n',
        reason: 'the platform text is the base, then its delta lands on it',
      );
    },
  );

  test('a selection the note cannot hold does not move the caret', () {
    final surface = _wire('ciao\n', caret: 2);
    surface.input.updateEditingValueWithDeltas(<TextEditingDelta>[
      const TextEditingDeltaNonTextUpdate(
        oldText: 'ciao\n',
        selection: TextSelection.collapsed(offset: -1),
        composing: TextRange.empty,
      ),
    ]);
    expect(surface.buffer.text, 'ciao\n');
    expect(surface.carets, isEmpty, reason: 'nothing to report: nothing moved');
  });

  test('a whole value replaces the note, as the fallback path says', () {
    final surface = _wire('prima\n');
    surface.input.updateEditingValue(
      const TextEditingValue(
        text: 'tutto diverso\n',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );
    expect(surface.buffer.text, 'tutto diverso\n');
    expect(surface.input.lastWholeLength, 14);
  });

  test('Enter inserts a newline at the caret', () {
    final surface = _wire('unofine\n', caret: 3);
    surface.input.performAction(TextInputAction.newline);
    expect(surface.buffer.text, 'uno\nfine\n');
    expect(surface.carets.last.extent, 4);
  });

  test('the tokenizer follows the edit, and only the edited lines', () {
    final surface = _wire('plain\n');
    surface.input.updateEditingValueWithDeltas(<TextEditingDelta>[
      _insert('plain\n', 0, '# '),
    ]);
    expect(surface.tokens.lineAt(0).text, '# plain');
    expect(
      surface.tokens.lineAt(0).tokens.map((token) => token.kind),
      contains(TokenKind.headingMarker),
      reason: 'the hash became a heading marker, so the line was re-tokenized',
    );
  });
}
