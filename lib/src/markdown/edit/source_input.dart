// The surface's connection to the platform's keyboard (#245, phase 3).
//
// This is the machinery the IME probe proved out, moved into the surface that
// needs it: a `TextInputClient` that speaks the delta model, edits the note's
// `SourceBuffer` with what arrives, and sends back only what the platform does
// not already know. `InputBuffer` holds the rules — a delta's `oldText` wins
// when
// it disagrees, a selection outside the text does not become the caret, and the
// document is not echoed per keystroke — and this file is the plumbing around
// them: one connection, attach and detach on focus, and a translation from
// `TextEditingDelta` to `SourceBuffer.replaceRange`.
//
// It is deliberately not part of the view's state. The view can be wrong about
// pixels without being wrong about text, and this is the text.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/edit/edit_history.dart';
import 'package:niman/src/markdown/edit/input_buffer.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';

/// What the surface does when the note's text changes.
typedef SourceEdited = void Function(SourceEdit edit);

/// The keyboard, wired to one note.
final class SourceInput implements TextInputClient, DeltaTextInputClient {
  /// Wires [buffer] to the platform, reporting edits and caret moves outward.
  new({
    required this.buffer,
    required this.onEdited,
    required this.text,
    required this.selection,
    required this.onSelection,
    required this.onTokenizer,
    this.onRecord,
  }) : _input = InputBuffer();

  /// The frames this surface's edits are logged under.
  static const AppLogger _log = AppLogger(name: 'edit');

  /// The note being edited.
  final SourceBuffer buffer;

  /// Called after every edit the platform asked for, so the view can repaint.
  final SourceEdited onEdited;

  /// The note's whole text, asked for only when the platform has to be told a
  /// whole value. It is a *callback* rather than a string because joining a
  /// note
  /// is O(n) and a caret move must not pay it.
  final String Function() text;

  /// Called before an edit is applied, with the text it is about to replace, so
  /// a history can undo it (and coalesce the typing, which needs to know what
  /// was there).
  final void Function(EditRecord record)? onRecord;

  /// Where the caret is now.
  final SelectionModel Function() selection;

  /// Where the caret goes when the platform moves it.
  final ValueChanged<SelectionModel> onSelection;

  /// The tokenizer the edits have to be handed to, so a keystroke re-tokenizes
  /// the edited lines and nothing else.
  final void Function(SourceEdit edit, SourceBuffer buffer) onTokenizer;

  final InputBuffer _input;
  TextInputConnection? _connection;

  /// Whether the platform currently has this surface attached.
  bool get isAttached => _connection?.attached ?? false;

  /// The size a `WHOLE` update carried last, for the perf trace and for tests.
  int lastWholeLength = 0;

  /// How many deltas have been applied through the delta model.
  int deltaCount = 0;

  /// How many arrived with an `oldText` that disagreed with the buffer.
  int recoveredDeltas = 0;

  /// Opens the connection, if it is not already open.
  void attach() {
    if (isAttached) return;
    _log.info('attach: connecting the keyboard to the note');
    _ensureSeeded();
    _input.echoSent();
    _echoScheduled = false;
    _connection =
        TextInput.attach(
            this,
            const TextInputConfiguration(
              inputType: TextInputType.multiline,
              inputAction: TextInputAction.newline,
              enableDeltaModel: true,
            ),
          )
          // `attach` opens the connection; **`show` is the request for the
          // keyboard**, and `EditableText` always makes it. Without it the log
          // shows a surface attached and a keyboard that never appears, which
          // is
          // exactly what a device reported.
          ..show()
          ..setEditingState(_value());
  }

  /// Closes the connection.
  void detach() {
    _echoTimer?.cancel();
    if (_connection != null) _log.info('detach: the surface lost focus');
    _connection?.close();
    _connection = null;
  }

  /// Tells the platform where to put the caret, when the app moved it.
  void sendSelection() {
    if (!isAttached) return;
    _input.editedLocally(_value());
    // Until the echo lands, the platform's caret is the old one: a keystroke
    // in between is placed at ours (see `updateEditingValueWithDeltas`).
    _movedSelection = true;
    // One echo per frame, however many taps, arrow keys or drags happened
    // inside
    // it: a whole `TextEditingValue` at note size is not something to send
    // twice
    // for one frame's worth of caret.
    if (_echoScheduled) return;
    _echoScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _echoScheduled = false;
      _send();
    });
  }

  bool _echoScheduled = false;
  Timer? _echoTimer;

  /// Whether *this side* moved the caret since the platform last heard about
  /// it.
  bool _movedSelection = false;

  /// The note and the caret, as the platform should hear them.
  TextEditingValue _value() {
    final caret = selection().clampTo(buffer.text.length);
    return TextEditingValue(
      text: text(),
      selection: TextSelection(
        baseOffset: caret.anchor,
        extentOffset: caret.extent,
      ),
    );
  }

  /// Sends the buffer's value when the platform's copy is behind, and nothing
  /// otherwise — the rule that keeps a keystroke from carrying the whole note.
  void _send() {
    if (!isAttached) return;
    _movedSelection = false;
    if (!_input.needsEcho) return;
    _connection!.setEditingState(_value());
    _input.echoSent();
  }

  /// A delta, short enough for a log line.
  static String _short(TextEditingDelta delta) => switch (delta) {
    TextEditingDeltaInsertion() =>
      'ins@${delta.insertionOffset}'
          '+${delta.textInserted.length} '
          '"${delta.textInserted.replaceAll('\n', '⏎')}"',
    TextEditingDeltaDeletion() =>
      'del ${delta.deletedRange.start}..${delta.deletedRange.end}',
    TextEditingDeltaReplacement() =>
      'repl ${delta.replacedRange.start}..${delta.replacedRange.end}'
          '+${delta.replacementText.length}',
    TextEditingDeltaNonTextUpdate() => 'sel ${delta.selection.start}',
    _ => 'delta',
  };

  /// Gives the buffer the note's text the first time anything needs it.
  ///
  /// A surface is built before its note is read, so its buffer starts empty
  /// while
  /// the note does not: without this the very first delta's `oldText` would be
  /// compared against nothing and every first keystroke would look like a
  /// platform
  /// that had fallen behind.
  void _ensureSeeded() {
    if (_seeded) return;
    _seeded = true;
    _input.seed(text());
  }

  bool _seeded = false;

  /// Applies one edit to the note, the tokenizer and the caret.
  void _apply(SourceEdit edit, SelectionModel caret) {
    onTokenizer(edit, buffer);
    onSelection(caret.clampTo(buffer.text.length));
    onEdited(edit);
  }

  /// The platform replaced `[start, end)` with [text].
  void _replace(int start, int end, String text, SelectionModel caret) {
    if (start < 0 || end < start || end > buffer.length) {
      // The platform's indices do not address this note: it is out of step, so
      // the whole value goes back rather than a range that would corrupt it.
      _log.warning('edit $start..$end outside the note (${buffer.length})');
      _send();
      return;
    }
    if (start == end && text.isEmpty) {
      onSelection(caret.clampTo(buffer.text.length));
      return;
    }
    onRecord?.call(
      EditRecord(
        start: start,
        removed: buffer.substring(start, end),
        inserted: text,
      ),
    );
    _apply(buffer.replaceRange(start, end, text), caret);
  }

  // -------------------------------------------------------- TextInputClient

  @override
  TextEditingValue? get currentTextEditingValue => _value();

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void updateEditingValue(TextEditingValue value) {
    _ensureSeeded();
    lastWholeLength = value.text.length;
    _log.debug('whole value: ${value.text.length} chars');
    final kind = _input.applyValue(value);
    if (kind == InputKind.unchanged) {
      _reportSelection(_caretOfValue(value));
      return;
    }
    // A whole value is the fallback path: the platform sent the entire note, so
    // the note is replaced by what it sent (whatever the reason — no delta
    // support, an autocorrect, a paste).
    final caret = _caretOfValue(value);
    onRecord?.call(
      EditRecord(start: 0, removed: buffer.text, inserted: value.text),
    );
    buffer.replaceRange(0, buffer.length, value.text);
    _apply(
      SourceEdit(
        firstLine: 0,
        removedLines: buffer.lineCount,
        insertedLines: buffer.lineCount,
        revision: buffer.revision,
      ),
      caret,
    );
  }

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> deltas) {
    if (deltas.isEmpty) return;
    _ensureSeeded();
    _log.debug(
      'deltas: ${deltas.map(_short).join(", ")} '
      '(ours ${buffer.length}, caret ${selection().extent})',
    );
    final kind = _input.applyDeltas(deltas);
    if (kind == InputKind.deltasRecovered) {
      recoveredDeltas++;
      // The platform's copy was behind: its text is the base, and the deltas
      // are
      // replayed onto it (see `InputBuffer.applyDeltas`).
      onRecord?.call(
        EditRecord(
          start: 0,
          removed: buffer.text,
          inserted: deltas.last.oldText,
        ),
      );
      buffer.replaceRange(0, buffer.length, deltas.last.oldText);
    }
    // Whether an edit landed somewhere other than where the platform put it,
    // so its copy has to be told what the note now says.
    var diverged = false;
    for (final delta in deltas) {
      deltaCount++;
      switch (delta) {
        case TextEditingDeltaInsertion() when _movedSelection:
          // The platform's caret is authoritative *unless we moved it
          // ourselves*: a tap or an arrow key moves the caret here, the
          // platform hears about it a frame later, and an insertion that lands
          // where the platform last thought the caret was is text in the wrong
          // place. When we moved it, ours is the newer truth — for the offset
          // the text goes to, not only for where the caret ends up.
          final ours = selection().clampTo(buffer.length);
          _log.debug(
            'insertion at the platform caret ${delta.insertionOffset} '
            'placed at ours ${ours.start}',
          );
          _replace(
            ours.start,
            ours.end,
            delta.textInserted,
            SelectionModel.at(ours.start + delta.textInserted.length),
          );
          diverged = true;
        case TextEditingDeltaInsertion():
          _replace(
            delta.insertionOffset,
            delta.insertionOffset,
            delta.textInserted,
            _caretOfDelta(delta),
          );
        case TextEditingDeltaDeletion():
          _replace(
            delta.deletedRange.start,
            delta.deletedRange.end,
            '',
            _caretOfDelta(delta),
          );
        case TextEditingDeltaReplacement():
          _replace(
            delta.replacedRange.start,
            delta.replacedRange.end,
            delta.replacementText,
            _caretOfDelta(delta),
          );
        case TextEditingDeltaNonTextUpdate():
          // A platform caret update while *we* hold an un-echoed one is the
          // platform's stale copy talking — the device log shows exactly this:
          // a tap
          // put the caret at 46, the first keystroke arrived as `sel 0,
          // ins@0+1`,
          // and the text went to the top of the note. Ours is the newer truth
          // until
          // the echo lands.
          if (_movedSelection) {
            _log.debug('ignored a stale caret ${delta.selection.start}');
          } else {
            _reportSelection(_caretOfDelta(delta));
          }
      }
    }
    if (diverged) {
      _input.editedLocally(_value());
      _send();
    }
  }

  /// Reports [next] when the caret really moved.
  ///
  /// A platform ping that changes nothing — a caret update with an unusable
  /// range, a repeat of where the caret already is — must not rebuild the note,
  /// and the count of what arrived is already on the probe's tally for anyone
  /// who needs it.
  void _reportSelection(SelectionModel next) {
    final current = selection();
    if (next.anchor == current.anchor && next.extent == current.extent) return;
    onSelection(next);
  }

  /// The caret a platform update carries, when it carries a usable one.
  SelectionModel _caretOfValue(TextEditingValue value) =>
      value.selection.isValid
      ? SelectionModel(
          anchor: value.selection.baseOffset,
          extent: value.selection.extentOffset,
        )
      : selection();

  /// The caret a delta carries, when it carries a usable one.
  SelectionModel _caretOfDelta(TextEditingDelta delta) =>
      delta.selection.isValid
      ? SelectionModel(
          anchor: delta.selection.baseOffset,
          extent: delta.selection.extentOffset,
        )
      : selection();

  @override
  void performAction(TextInputAction action) {
    switch (action) {
      // There is no `TextInputAction.paste`: an IME's paste arrives as the text
      // it pastes (an edit, through the deltas above), and a desktop Ctrl+V is
      // the surface's own shortcut. The clipboard is the surface's business,
      // not
      // the connection's.
      case TextInputAction.newline:
        // Nothing to insert: the line break has already arrived as text. The
        // Linux embedder inserts `\n` into its model, sends it as a delta and
        // *then* calls this action (`fl_text_input_handler.cc`), and an IME
        // commits it the same way — so inserting here as well is one Enter
        // becoming two lines. `EditableText` does nothing here for a
        // multiline field either.
        _log.debug('action: newline (already inserted by the platform)');
      case TextInputAction.done:
      case TextInputAction.go:
      case TextInputAction.send:
      case TextInputAction.search:
        detach();
      case _:
        break;
    }
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  // The rest of the client surface is not something a note-shaped field does;
  // each is a no-op rather than a decision (Flutter's own defaults, spelled out
  // because `implements` does not inherit them).
  @override
  bool onFocusReceived() => true;

  @override
  void showToolbar() {}

  @override
  void insertContent(KeyboardInsertedContent content) {
    // A hardware keyboard's rich content arrives as bytes and a MIME type, not
    // as text: a note is text, so what lands is the URI the platform offered.
    final caret = selection();
    _replace(
      caret.start,
      caret.end,
      content.uri,
      SelectionModel.at(caret.start + content.uri.length),
    );
  }

  @override
  void performSelector(String selectorName) {}

  @override
  void insertTextPlaceholder(Size size) {}

  @override
  void removeTextPlaceholder() {}

  @override
  void didChangeInputControl(
    TextInputControl? oldControl,
    TextInputControl? newControl,
  ) {}

  @override
  void connectionClosed() {
    _connection = null;
    _log.info('the platform closed the input connection');
  }

  /// The tokenizer's view of an edit: the lines that changed, and nothing else.
  ///
  /// This is what keeps a keystroke off the note's whole length — the phase's
  /// 0.507 ms incremental-edit number is this call plus the buffer's own
  /// `replaceRange`.
  static void retokenize(
    HighlightDocument tokens,
    SourceEdit edit,
    SourceBuffer buffer,
  ) {
    tokens.replaceLines(edit.firstLine, edit.removedLines, <String>[
      for (var at = 0; at < edit.insertedLines; at++)
        buffer.lineAt(edit.firstLine + at),
    ]);
  }
}
