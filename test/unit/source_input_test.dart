// The surface's keyboard wiring (#245, phase 3): what arrives from the platform
// and what it does to the note.
//
// These drive `SourceInput` directly — no connection, no widget — because this
// is
// the layer that must be right about *text*, and it is the layer a device
// cannot
// be used to debug.
import 'dart:math' as math;

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
  void Function(SelectionModel) setSelection,
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
  return (
    buffer: buffer,
    input: input,
    tokens: tokens,
    carets: carets,
    setSelection: (next) => current = next,
  );
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

  // #753: the platform holds a window of a long note (#540), and its own
  // Select all is a range on that copy, which means the note — however it is
  // reported: as a selection, as an edit that changes nothing, or as a whole
  // value. The Backspace that follows empties the note, first time.
  group("the platform's Select all, then Backspace, empties the note", () {
    final text = List.generate(400, (i) => 'line $i of the note').join('\n');
    TextSelection all(TextEditingValue value) =>
        TextSelection(baseOffset: 0, extentOffset: value.text.length);
    final reports =
        <String, void Function(SourceInput input, TextEditingValue value)>{
          'as a selection': (input, value) =>
              input.updateEditingValueWithDeltas(<TextEditingDelta>[
                TextEditingDeltaNonTextUpdate(
                  oldText: value.text,
                  selection: all(value),
                  composing: TextRange.empty,
                ),
              ]),
          'as an edit of nothing': (input, value) =>
              input.updateEditingValueWithDeltas(<TextEditingDelta>[
                TextEditingDeltaInsertion(
                  oldText: value.text,
                  insertionOffset: 0,
                  textInserted: '',
                  selection: all(value),
                  composing: TextRange.empty,
                ),
              ]),
          'as a whole value': (input, value) =>
              input.updateEditingValue(value.copyWith(selection: all(value))),
        };
    for (final MapEntry(key: how, value: report) in reports.entries) {
      test(how, () {
        final surface = _wire(text, caret: text.length ~/ 2);
        final before = surface.input.currentTextEditingValue!;
        expect(before.text.length, lessThan(text.length));
        report(surface.input, before);
        expect(surface.carets.last.start, 0);
        expect(surface.carets.last.end, text.length);
        final value = surface.input.currentTextEditingValue!;
        surface.input.updateEditingValueWithDeltas(<TextEditingDelta>[
          TextEditingDeltaDeletion(
            oldText: value.text,
            deletedRange: TextRange(start: 0, end: value.text.length),
            selection: const TextSelection.collapsed(offset: 0),
            composing: TextRange.empty,
          ),
        ]);
        expect(surface.buffer.text, isEmpty);
      });
    }
  });

  // #758: a selection the app made that happens to be the whole window — the
  // caret near the note's end, selected from the window's first line down to
  // it — is that range, not the note. Checked against the plain model of an
  // edit over a selection: Backspace removes exactly the app's selection, and
  // a keystroke replaces exactly it, wherever the selection and the window
  // fall.
  test('Backspace and a keystroke act on exactly the selection', () {
    final text = List.generate(600, (i) => 'line $i of the note').join('\n');
    final random = math.Random(758);
    final selections = <SelectionModel>[];
    // The cases the issue names: the window's whole span, both directions,
    // at the note's end and at its start.
    for (final caret in <int>[text.length, 0]) {
      final surface = _wire(text, caret: caret);
      final value = surface.input.currentTextEditingValue!;
      final from = surface.input.windowStart;
      final to = from + value.text.length;
      expect(to - from, lessThan(text.length));
      final (near, far) = caret == 0 ? (from, to) : (to, from);
      selections
        ..add(SelectionModel(anchor: far, extent: near))
        ..add(SelectionModel(anchor: near, extent: far));
    }
    for (var i = 0; i < 200; i++) {
      selections.add(
        SelectionModel(
          anchor: random.nextInt(text.length + 1),
          extent: random.nextInt(text.length + 1),
        ),
      );
    }
    for (final chosen in selections) {
      if (chosen.isCollapsed) continue;
      for (final typed in <String>['', 'x']) {
        // The caret reaches the selection's extent first, as a drag or a
        // Shift move does, so the window is the one it would be there.
        final surface = _wire(text, caret: chosen.extent);
        surface.input.currentTextEditingValue;
        surface.setSelection(chosen);
        final value = surface.input.currentTextEditingValue!;
        final held = value.selection;
        if (held.isCollapsed) continue;
        surface.input.updateEditingValueWithDeltas(<TextEditingDelta>[
          TextEditingDeltaReplacement(
            oldText: value.text,
            replacementText: typed,
            replacedRange: TextRange(start: held.start, end: held.end),
            selection: TextSelection.collapsed(
              offset: held.start + typed.length,
            ),
            composing: TextRange.empty,
          ),
        ]);
        expect(
          surface.buffer.text,
          text.replaceRange(chosen.start, chosen.end, typed),
          reason: '"$typed" over $chosen',
        );
      }
    }
  });

  // The two selections out of step: the platform edits the whole of its copy
  // while the app's selection is a smaller range in it. The platform's own
  // range is what it did, and it is applied as it says.
  test("an edit of the platform's whole copy over a smaller selection", () {
    final text = List.generate(400, (i) => 'line $i of the note').join('\n');
    final surface = _wire(text, caret: text.length ~/ 2);
    final before = surface.input.currentTextEditingValue!;
    final from = surface.input.windowStart;
    final to = from + before.text.length;
    final middle = (from + to) ~/ 2;
    surface.setSelection(SelectionModel(anchor: middle, extent: middle + 10));
    final value = surface.input.currentTextEditingValue!;
    expect(surface.input.windowStart, from);
    surface.input.updateEditingValueWithDeltas(<TextEditingDelta>[
      TextEditingDeltaDeletion(
        oldText: value.text,
        deletedRange: TextRange(start: 0, end: value.text.length),
        selection: const TextSelection.collapsed(offset: 0),
        composing: TextRange.empty,
      ),
    ]);
    expect(surface.buffer.text, text.replaceRange(from, to, ''));
  });

  // The same, with the selection reported backwards (its anchor at the note's
  // end): #540's rule has to hold in both directions, or the deletion takes
  // the window's range again.
  test('a backwards select all and delete empties the note', () {
    final text = List.generate(400, (i) => 'line $i of the note').join('\n');
    final surface = _wire(text, caret: text.length);
    surface.setSelection(SelectionModel(anchor: text.length, extent: 0));
    final value = surface.input.currentTextEditingValue!;
    surface.input.updateEditingValueWithDeltas(<TextEditingDelta>[
      TextEditingDeltaDeletion(
        oldText: value.text,
        deletedRange: TextRange(start: 0, end: value.text.length),
        selection: const TextSelection.collapsed(offset: 0),
        composing: TextRange.empty,
      ),
    ]);
    expect(surface.buffer.text, isEmpty);
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

  test('a delta built on another copy is applied by its range and resyncs', () {
    // The platform's copy is not the note's (it missed a change): its range is
    // applied to the note — the note is never replaced by the platform's text,
    // which is what silently undid a local deletion — and the platform is
    // then told the note.
    final surface = _wire('ab\n');
    surface.input.updateEditingValueWithDeltas(<TextEditingDelta>[
      _insert('abXYZ\n', 2, 'c'),
    ]);
    expect(surface.buffer.text, 'abc\n');
    expect(surface.input.resyncs, 1);
  });

  test('two deltas in one update are applied once each', () {
    // An autocorrect arrives as a batch: the word replaced, then a space. The
    // earlier recovery replayed the whole batch onto the last delta's base.
    final surface = _wire('ciao mondo\n', caret: 10);
    surface.input.updateEditingValueWithDeltas(<TextEditingDelta>[
      const TextEditingDeltaReplacement(
        oldText: 'ciao mondo\n',
        replacementText: 'Mondo',
        replacedRange: TextRange(start: 5, end: 10),
        selection: TextSelection.collapsed(offset: 10),
        composing: TextRange.empty,
      ),
      _insert('ciao Mondo\n', 10, ' '),
    ]);
    expect(surface.buffer.text, 'ciao Mondo \n');
    expect(surface.input.resyncs, 0);
  });

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

  test('Enter is one line: the newline action adds nothing of its own', () {
    // The Linux embedder inserts `\n`, sends it as a delta and *then* calls
    // the newline action (`fl_text_input_handler.cc`). Inserting on the action
    // as well is one Enter becoming two lines.
    final surface = _wire('unofine\n', caret: 3);
    surface.input.updateEditingValueWithDeltas(<TextEditingDelta>[
      _insert('unofine\n', 3, '\n'),
    ]);
    surface.input.performAction(TextInputAction.newline);
    expect(surface.buffer.text, 'uno\nfine\n');
    expect(surface.carets.last.extent, 4);
  });

  test('a delta the platform computed from its own caret is left alone', () {
    // The platform is told every caret move as it happens, so its offsets are
    // the ones that count.
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
