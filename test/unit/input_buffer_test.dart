// The surface's text input, held to the facts a device established (#245 phase
// 3): deltas arrive one per character, the fallback carries the whole note, and
// at size the platform's copy can be a keystroke behind.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/input_buffer.dart';

TextEditingDeltaInsertion _insert(
  String oldText,
  int at,
  String text, {
  int? caret,
}) => TextEditingDeltaInsertion(
  oldText: oldText,
  insertionOffset: at,
  textInserted: text,
  selection: TextSelection.collapsed(offset: caret ?? at + text.length),
  composing: TextRange.empty,
);

void main() {
  test('insertions arrive one character at a time and stay in step', () {
    final buffer = InputBuffer();
    var kind = InputKind.unchanged;
    for (final (at, char) in 'fjfj'.split('').indexed) {
      kind = buffer.applyDeltas(<TextEditingDelta>[
        _insert(buffer.text, at, char),
      ]);
    }
    expect(kind, InputKind.deltas);
    expect(buffer.text, 'fjfj');
    expect(buffer.selection.start, 4);
    expect(
      buffer.needsEcho,
      isFalse,
      reason: 'the platform sent these; its copy is the one that is current',
    );
  });

  test('a delta whose oldText is behind wins as the base', () {
    // The device sent this four times at a 921 600-character buffer: the echo
    // of
    // the whole note takes long enough that the IME computes its next delta
    // from
    // a copy that predates it (`DELTA insert @921601` twice, the second with
    // `oldText 921601, ours 921602`). Applying that delta to the buffer would
    // repeat or drop a character.
    final buffer = InputBuffer(text: 'ab');
    final kind = buffer.applyDeltas(<TextEditingDelta>[
      _insert('ab', 2, 'c'),
      // The platform's copy missed the 'c' it never heard about.
      _insert('ab', 2, 'd'),
    ]);
    expect(kind, InputKind.deltasRecovered);
    expect(
      buffer.text,
      'abd',
      reason: 'the platform text is the base, then its delta applies to it',
    );
  });

  test('a selection the note cannot hold does not become the caret', () {
    // Nine non-text updates arrived with `sel -1..-1` or `-1..0`; adopting one
    // leaves a selection that cannot be painted or scrolled to.
    final buffer = InputBuffer(text: 'ciao', caret: 2)
      ..applyDeltas(<TextEditingDelta>[
        const TextEditingDeltaNonTextUpdate(
          oldText: 'ciao',
          selection: TextSelection.collapsed(offset: -1),
          composing: TextRange.empty,
        ),
      ]);
    expect(buffer.selection.start, 2, reason: 'the caret stays where it was');
    expect(buffer.text, 'ciao');
  });

  test(
    'a whole-value update is the fallback, and makes the platform current',
    () {
      final buffer = InputBuffer();
      final kind = buffer.applyValue(
        const TextEditingValue(
          text: 'autocorrected',
          selection: TextSelection.collapsed(offset: 13),
        ),
      );
      expect(kind, InputKind.value);
      expect(buffer.text, 'autocorrected');
      expect(buffer.needsEcho, isFalse);
    },
  );

  test('a local edit is what needs an echo', () {
    final buffer = InputBuffer(text: 'one');
    expect(buffer.needsEcho, isFalse, reason: 'nothing has happened');
    buffer.editedLocally(
      const TextEditingValue(
        text: 'one two',
        selection: TextSelection.collapsed(offset: 7),
      ),
    );
    expect(
      buffer.needsEcho,
      isTrue,
      reason: 'the platform still holds the note without the edit',
    );
    buffer.echoSent();
    expect(buffer.needsEcho, isFalse);
  });

  test('a composing change needs an echo of its own', () {
    // The one thing only the platform can know about the text it sent: the
    // range it is composing. Coalesced by the caller to one echo per frame.
    final buffer = InputBuffer(text: 'ciao')..composingChanged();
    expect(buffer.needsEcho, isTrue);
    buffer.echoSent();
    expect(buffer.needsEcho, isFalse);
  });

  test('deltas that change nothing report so', () {
    final buffer = InputBuffer(text: 'ciao');
    expect(buffer.applyDeltas(const <TextEditingDelta>[]), InputKind.unchanged);
    expect(
      buffer.applyDeltas(<TextEditingDelta>[
        const TextEditingDeltaNonTextUpdate(
          oldText: 'ciao',
          selection: TextSelection.collapsed(offset: 1),
          composing: TextRange.empty,
        ),
      ]),
      InputKind.unchanged,
      reason: 'a caret move is not a text change',
    );
    expect(buffer.selection.start, 1, reason: 'but the caret did move');
  });
}
