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
    text: () => buffer.text,
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
  // `TextInput.attach` needs the binding: this file is not a widget test, but
  // the
  // connection it drives is a platform channel.
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('an insertion after our own caret move lands at our caret', () {
    // The device's lesson: a whole-value echo is 931 KB at note size, so the
    // platform hears about a tap late — and an insertion that lands where the
    // platform last thought the caret was is text in the wrong place. When *we*
    // moved the caret, ours is the newer truth.
    final surface = _wire('ciao mondo\n');
    surface.input.attach();
    surface.input.sendSelection();
    // The platform's copy still has the caret at 0, and sends its delta from
    // there; the app's caret is where the tap put it.
    surface.input.updateEditingValueWithDeltas(<TextEditingDelta>[
      _insert('ciao mondo\n', 0, 'X'),
    ]);
    expect(
      surface.buffer.text,
      'Xciao mondo\n',
      reason: 'a delta that agrees about the text but not the caret uses ours',
    );
    expect(surface.carets.last.extent, 1);
  });

  test('a delta the platform computed from its own caret is left alone', () {
    // The other half of the rule: until we move the caret ourselves, the
    // platform's offsets are the ones that count.
    final surface = _wire('ciao mondo\n', caret: 4);
    surface.input.updateEditingValueWithDeltas(<TextEditingDelta>[
      _insert('ciao mondo\n', 4, 'X'),
    ]);
    expect(surface.buffer.text, 'ciaoX mondo\n');
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
