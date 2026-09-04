import 'package:copist/src/editor/line_buffer.dart';
import 'package:flutter/services.dart'
    show
        TextEditingDelta,
        TextEditingDeltaDeletion,
        TextEditingDeltaInsertion,
        TextEditingDeltaNonTextUpdate,
        TextEditingDeltaReplacement,
        TextEditingValue,
        TextRange,
        TextSelection;

/// The pure-Dart core of the editor's text-input client (M2a E4).
///
/// It owns a [LineBuffer] as the source of truth for the note text, plus the
/// two IME regions that Flutter's [TextEditingValue] carries over it: the
/// [TextSelection] (a collapsed selection is the caret) and the
/// `composing` [TextRange] (the span the input method is still deciding).
///
/// ## How edits arrive
///
/// In delta mode the platform never resends the whole field; it sends
/// [TextEditingDelta]s. Every delta carries the **full** `oldText` and the
/// platform applies edits against that copy (last-write-wins, because the
/// platform link is async). The editor therefore stays correct under one
/// invariant:
///
/// > **Lockstep.** Every edit to the buffer flows through the IME as a delta,
/// > so the platform's `oldText` is always exactly the current buffer text.
///
/// `apply` trusts that invariant and applies the delta's incremental edit to
/// the buffer in O(change), never re-reading the O(n) full text. A programmatic
/// change (loading a note, undo, an outline jump) breaks lockstep, so it must
/// go through [reset] (which also re-anchors the IME). The O(1) length assert
/// in [apply] catches a missed resync in debug builds.
///
/// This is the state machine E8's `DeltaTextInputClient` wraps: it receives
/// the platform's deltas in `updateEditingValueWithDeltas`, forwards each to
/// [apply], and reads [composing]/[selection] to paint the row.
final class ComposingInput {
  /// Creates an input client over [text] with a collapsed caret and no
  /// active composition (a fresh client is never mid-composition; the
  /// composing region only ever comes from [apply]).
  ComposingInput(
    String text, {
    TextSelection? selection,
  }) : _buffer = LineBuffer.fromText(text),
       _selection = selection ?? const TextSelection.collapsed(offset: 0),
       _composing = TextRange.empty;

  final LineBuffer _buffer;
  final List<void Function()> _listeners = <void Function()>[];
  TextSelection _selection;
  TextRange _composing;
  int _revision = 0;

  /// Whether a direct edit ([reset], [deleteSelection], [replaceSelection]) is
  /// awaiting [commitDirectEdit] — i.e. the IME may still be out of lockstep
  /// with the buffer. [apply] re-anchors when this is set, so a forgotten
  /// [commitDirectEdit] loses the pending edit instead of silently corrupting
  /// the text (the same-length case the length assert below cannot catch).
  bool _needsImeSync = false;

  /// The buffer this client edits (the note's source of truth).
  LineBuffer get buffer => _buffer;

  /// The full text. O(text length) — for saving, tests and IME sync.
  String get text => _buffer.text;

  /// The full text length in UTF-16 code units (O(1)).
  int get textLength => _buffer.textLength;

  /// The number of logical lines.
  int get lineCount => _buffer.lineCount;

  /// The current selection; a collapsed selection is the caret.
  TextSelection get selection => _selection;

  /// The span the input method is still composing; [TextRange.empty] when
  /// nothing is being composed (the text is committed).
  TextRange get composing => _composing;

  /// Whether a composition is in progress.
  bool get isComposing => _composing.isValid;

  /// The caret as a full-text offset, or null when the selection is not a
  /// single caret (a range is selected, or there is no caret).
  int? get caret {
    final s = _selection;
    return (s.isValid && s.isCollapsed) ? s.baseOffset : null;
  }

  /// The logical line the caret is on, or null when there is no caret.
  int? get caretLine {
    final c = caret;
    return c == null ? null : _buffer.locationOf(c).$1;
  }

  /// A counter that advances only when the text changes (not on selection or
  /// composing-only updates) — the change signal autosave and the preview
  /// re-parse subscribe to.
  int get revision => _revision;

  /// The current editing state as Flutter's [TextEditingValue] — for sending
  /// to the IME (on focus, after [reset]). Materializes [text] (O(n)), so it
  /// is not for the per-keystroke path.
  TextEditingValue get value => TextEditingValue(
    text: _buffer.text,
    selection: _selection,
    composing: _composing,
  );

  /// Applies a platform [delta] to the buffer, selection and composing region.
  ///
  /// Returns `true` when the client must push a full [value] update to re-sync
  /// the IME (an unrecognized delta type), otherwise `false`.
  ///
  /// See the class docs for the lockstep invariant this relies on.
  bool apply(TextEditingDelta delta) {
    if (_needsImeSync) {
      // A direct edit (reset/cut/paste) was not followed by
      // [commitDirectEdit], so the IME's copy may be stale and this delta's
      // offsets are relative to it, not to the buffer. Re-anchor the buffer to
      // the platform's copy (delta.oldText) so the delta applies on the right
      // base: the pending direct edit is lost, but the delta (the latest
      // input) is preserved and lockstep is restored — the difference between
      // a lost paste and a silently corrupting text.
      _buffer.replace(0, _buffer.textLength, delta.oldText);
      _needsImeSync = false;
    }
    assert(
      delta.oldText.length == _buffer.textLength,
      'input client is out of lockstep with the IME; programmatic edits must '
      'go through reset',
    );
    switch (delta) {
      case TextEditingDeltaInsertion():
        _buffer.insert(delta.insertionOffset, delta.textInserted);
      case TextEditingDeltaDeletion():
        _buffer.delete(delta.deletedRange.start, delta.deletedRange.end);
      case TextEditingDeltaReplacement():
        _buffer.replace(
          delta.replacedRange.start,
          delta.replacedRange.end,
          delta.replacementText,
        );
      case TextEditingDeltaNonTextUpdate():
        _setMeta(delta);
        return false;
      default:
        // An unrecognized delta type (a future Flutter addition) cannot be
        // applied incrementally. Don't drop it silently (lost input): apply
        // the metadata, re-anchor to the platform's last known-good copy, and
        // tell the client to push a full [value] update so lockstep is
        // restored. The one edit this delta carried is lost; later input is
        // correct.
        assert(false, 'unhandled delta: ${delta.runtimeType}');
        _buffer.replace(0, _buffer.textLength, delta.oldText);
        _revision++;
        _setMeta(delta);
        return true;
    }
    _revision++;
    _setMeta(delta);
    return false;
  }

  /// Re-anchors the client to [text] after a programmatic change (loading a
  /// note, undo, an outline jump). The caller must also send [value] to the
  /// IME (e.g. via `setEditingState`) so the platform copy re-syncs.
  void reset(
    String text, {
    TextSelection? selection,
  }) {
    _buffer.replace(0, _buffer.textLength, text);
    _selection = selection ?? const TextSelection.collapsed(offset: 0);
    _composing = TextRange.empty;
    _revision++;
    _needsImeSync = true;
    _notify();
  }

  /// The view has pushed [value] to the IME after a direct edit ([reset],
  /// [deleteSelection], [replaceSelection]), so the IME is back in lockstep
  /// with the buffer. Clears the pending [apply] re-anchor. Call it every time
  /// you push [value] following one of those methods.
  void commitDirectEdit() {
    _needsImeSync = false;
  }

  /// Programmatically sets the selection (a collapsed selection is the caret).
  /// No text change; the caller tells the IME via a selection update.
  void setSelection(TextSelection selection) {
    _selection = selection;
    _notify();
  }

  /// Sets the caret to the start of logical line [line] — the contract's
  /// "set caret to line N" for scroll sync and outline jumps.
  void setCaretAtLine(int line) {
    setSelection(TextSelection.collapsed(offset: _buffer.offsetOf(line, 0)));
  }

  /// Whether a (non-caret) range is selected.
  bool get hasSelection => _selection.isValid && !_selection.isCollapsed;

  /// The selected text (empty when nothing is selected). O(selection length).
  String get selectionText {
    final s = _selection;
    if (!s.isValid || s.isCollapsed) return '';
    return _buffer.substring(s.start, s.end);
  }

  /// Moves the selection's focus to [offset], keeping the anchor — the model
  /// half of a drag-select (the view drives one call per pointer move).
  void extendSelectionTo(int offset) {
    final base = _selection.isValid ? _selection.baseOffset : 0;
    _selection = TextSelection(
      baseOffset: base,
      extentOffset: offset.clamp(0, textLength),
    );
    _notify();
  }

  /// Collapses the selection to its focus (the caret) — ends a drag-select.
  void collapseSelection() {
    final focus = _selection.isValid ? _selection.extentOffset : 0;
    _selection = TextSelection.collapsed(offset: focus);
    _notify();
  }

  /// Deletes the current selection and collapses the caret to where it began,
  /// returning the removed text (the source for the clipboard on a cut).
  ///
  /// No-op (returns `''`) when nothing is selected. This mutates the buffer
  /// directly, so it breaks delta lockstep: the caller must re-sync the IME
  /// with a full [value] update (as Flutter does after a local paste/cut).
  String deleteSelection() {
    final s = _selection;
    if (!s.isValid || s.isCollapsed) return '';
    final removed = _buffer.substring(s.start, s.end);
    _buffer.delete(s.start, s.end);
    _selection = TextSelection.collapsed(offset: s.start);
    _composing = TextRange.empty;
    _revision++;
    _needsImeSync = true;
    _notify();
    return removed;
  }

  /// Replaces the current selection with [text] (a paste / replace), or
  /// inserts it at the caret when nothing is selected (at offset zero when
  /// there is no caret), leaving the caret after the inserted text.
  ///
  /// Like [deleteSelection], this mutates the buffer directly and breaks
  /// delta lockstep; the caller re-syncs the IME with a full [value] update.
  void replaceSelection(String text) {
    final s = _selection;
    final start = s.isValid ? s.start : 0;
    final end = s.isValid ? s.end : 0;
    _buffer.replace(start, end, text);
    _selection = TextSelection.collapsed(offset: start + text.length);
    _composing = TextRange.empty;
    _revision++;
    _needsImeSync = true;
    _notify();
  }

  /// Subscribes [listener] to every change (text, selection or composing).
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  /// Unsubscribes [listener].
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  /// Copies the delta's selection + composing onto the client.
  void _setMeta(TextEditingDelta delta) {
    _selection = delta.selection;
    _composing = delta.composing;
    _notify();
  }

  void _notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }
}
