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

/// A buffer [TextSelection] translated by [delta] (a negative delta maps
/// buffer offsets into window-local ones for the windowed IME, M2a fix P2;
/// a positive one the reverse).
TextSelection translateSelection(TextSelection selection, int delta) {
  if (!selection.isValid) return selection;
  return TextSelection(
    baseOffset: selection.baseOffset + delta,
    extentOffset: selection.extentOffset + delta,
    affinity: selection.affinity,
    isDirectional: selection.isDirectional,
  );
}

/// A buffer [TextRange] (the composing region) translated by [delta].
TextRange translateRange(TextRange range, int delta) {
  if (!range.isValid) return range;
  return TextRange(start: range.start + delta, end: range.end + delta);
}

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
/// the buffer in O(change), never re-reading the O(n) full text. A
/// programmatic change (loading a note via [reset], or cut/paste/undo/redo)
/// breaks lockstep and sets the resync flag, so [apply] re-anchors to the
/// platform copy rather than corrupting; the O(1) length assert in [apply]
/// catches a missed resync in debug builds.
///
/// This is the state machine E8's `DeltaTextInputClient` wraps: it receives
/// the platform's deltas in `updateEditingValueWithDeltas`, forwards each to
/// [apply], and reads [composing]/[selection] to paint the row.
final class ComposingInput {
  /// Creates an input client over [text] with a collapsed caret and no
  /// active composition (a fresh client is never mid-composition; the
  /// composing region only ever comes from [apply]).
  ///
  /// [maxHistory] bounds the undo stack (E-U): once it is exceeded the
  /// oldest entry is dropped, so a long session never grows the stack
  /// without bound.
  ComposingInput(
    String text, {
    TextSelection? selection,
    this.maxHistory = 200,
  }) : _buffer = LineBuffer.fromText(text),
       _selection = selection ?? const TextSelection.collapsed(offset: 0),
       _composing = TextRange.empty;

  final LineBuffer _buffer;
  final List<void Function()> _listeners = <void Function()>[];
  TextSelection _selection;
  TextRange _composing;
  int _revision = 0;

  /// The undo-stack depth bound (oldest entries dropped first) — E-U.
  final int maxHistory;

  final List<_UndoEntry> _undo = <_UndoEntry>[];
  final List<_UndoEntry> _redo = <_UndoEntry>[];

  /// Whether a direct edit ([reset], [deleteSelection], [replaceSelection],
  /// [undo], [redo]) is awaiting [commitDirectEdit] — i.e. the IME may still
  /// be out of lockstep
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

  /// The current editing state as Flutter's [TextEditingValue] — the full
  /// buffer, for the legacy (non-windowed) IME path and tests. Materializes
  /// [text] (O(n)), so it is not for the per-keystroke path (the windowed
  /// client pushes window-sized values instead, M2a fix P2).
  TextEditingValue get value => TextEditingValue(
    text: _buffer.text,
    selection: _selection,
    composing: _composing,
  );

  /// Applies a platform [delta] to the buffer, selection and composing region.
  ///
  /// [anchor] is the buffer offset the platform's copy starts at: in full
  /// mode it is 0 and the platform's `oldText` is the whole buffer; in the
  /// windowed IME (M2a fix P2) it is the window start (see `ImeWindow`)
  /// and every offset in the delta is window-local. The delta's offsets are
  /// translated by `+anchor` before touching the buffer.
  ///
  /// Returns `true` when the client must push a value update to re-sync the
  /// IME (an unrecognized delta type), otherwise `false`.
  ///
  /// See the class docs for the lockstep invariant this relies on (with the
  /// window: the platform's `oldText` is exactly the window text).
  bool apply(TextEditingDelta delta, {int anchor = 0}) {
    final selectionBefore = _selection;
    if (_needsImeSync) {
      // A direct edit (reset/cut/paste/undo) was not followed by
      // [commitDirectEdit], so the IME's copy may be stale and this delta's
      // offsets are relative to it, not to the buffer. Re-anchor the window
      // region to the platform's copy (delta.oldText) so the delta applies on
      // the right base: the pending direct edit inside the window is lost, but
      // the delta (the latest input) is preserved and lockstep is restored —
      // the difference between a lost paste and a silently corrupting text.
      // The region may have shrunk below the platform copy (a forgotten push
      // after a delete); the replace then extends to the buffer end — the
      // degenerate case loses the direct edit, it does not corrupt.
      final regionEnd =
          (anchor + delta.oldText.length).clamp(0, _buffer.textLength);
      _buffer.replace(anchor.clamp(0, _buffer.textLength), regionEnd,
          delta.oldText);
      _needsImeSync = false;
    }
    assert(
      anchor >= 0 && anchor + delta.oldText.length <= _buffer.textLength,
      'input client is out of lockstep with the IME; the window '
      '[$anchor, ${anchor + delta.oldText.length}) exceeds the buffer '
      '(${_buffer.textLength} chars); programmatic edits must go through '
      'reset',
    );
    var start = 0;
    var oldText = '';
    var newText = '';
    var needsValueResync = false;
    switch (delta) {
      case TextEditingDeltaInsertion():
        start = delta.insertionOffset + anchor;
        newText = delta.textInserted;
        _buffer.insert(start, newText);
      case TextEditingDeltaDeletion():
        start = delta.deletedRange.start + anchor;
        final end = delta.deletedRange.end + anchor;
        oldText = _buffer.substring(start, end);
        newText = '';
        _buffer.delete(start, end);
      case TextEditingDeltaReplacement():
        start = delta.replacedRange.start + anchor;
        final end = delta.replacedRange.end + anchor;
        oldText = _buffer.substring(start, end);
        newText = delta.replacementText;
        _buffer.replace(start, end, newText);
      case TextEditingDeltaNonTextUpdate():
        // A selection/composing change with no text edit — not undoable.
        _setMeta(delta, anchor);
        return false;
      default:
        // An unrecognized delta type (a future Flutter addition) cannot be
        // applied incrementally. Don't drop it silently (lost input): apply
        // the metadata, re-anchor to the platform's last known-good copy, and
        // tell the client to push a value update so lockstep is restored. The
        // one edit this delta carried is lost; later input is correct.
        assert(false, 'unhandled delta: ${delta.runtimeType}');
        start = 0;
        oldText = _buffer.text;
        newText = delta.oldText;
        _buffer.replace(0, _buffer.textLength, newText);
        needsValueResync = true;
    }
    _revision++;
    _recordEdit(
      start: start,
      oldText: oldText,
      newText: newText,
      selectionBefore: selectionBefore,
      selectionAfter: translateSelection(delta.selection, anchor),
    );
    _setMeta(delta, anchor);
    return needsValueResync;
  }

  /// Re-anchors the client to [text] after a programmatic change (loading a
  /// note, an outline jump). The caller must also send [value] to the IME
  /// (e.g. via `setEditingState`) so the platform copy re-syncs.
  ///
  /// Loading a fresh document clears the undo/redo history ([undo]/[redo]
  /// are per-document, not across loads).
  void reset(
    String text, {
    TextSelection? selection,
  }) {
    _buffer.replace(0, _buffer.textLength, text);
    _selection = selection ?? const TextSelection.collapsed(offset: 0);
    _composing = TextRange.empty;
    _revision++;
    _needsImeSync = true;
    _undo.clear();
    _redo.clear();
    _notify();
  }

  /// The view has pushed [value] to the IME after a direct edit ([reset],
  /// [deleteSelection], [replaceSelection]), so the IME is back in lockstep
  /// with the buffer. Clears the pending [apply] re-anchor. Call it every time
  /// you push [value] following one of those methods.
  void commitDirectEdit() {
    _needsImeSync = false;
  }

  /// Programmatically sets the selection (a collapsed selection is the
  /// caret). No text change; the caller tells the IME via a selection
  /// update. No-op (and no notification) when the selection is unchanged.
  void setSelection(TextSelection selection) {
    if (_selection == selection) return;
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

  /// Selects the word at [offset] (a run of non-whitespace characters) — or
  /// the nearest word when [offset] is on whitespace — the long-press
  /// selection contract. The anchor is the word end closest to [offset], so
  /// a following [extendSelectionTo] (a drag) extends from there.
  ///
  /// A long-press on a line gap or blank line lands on the nearest word
  /// (left first, then right), never on the line breaks between lines: a
  /// "\n\n" selection is invisible (a line break is not a glyph) and read on
  /// device as "selected from the end of the line to the next" (M2a
  /// on-device round 3).
  ///
  /// Reads characters through [LineBuffer.locationOf] + [LineBuffer.lineAt]
  /// only — O(word), never a full-buffer [text] join (M2a fix P1). It is
  /// gesture-driven (rare), not per-frame.
  void selectWordAt(int offset) {
    final length = textLength;
    final clamped = offset.clamp(0, length);
    var probe = -1;
    if (clamped < length && !_isSpace(_codeAt(clamped))) {
      probe = clamped;
    } else if (clamped > 0 && !_isSpace(_codeAt(clamped - 1))) {
      probe = clamped - 1;
    } else {
      // The offset is on a whitespace run: the nearest word on the pressed
      // line first (left, then right), so an in-line gap press never lands
      // lines away (round-5 S4). A blank/all-space line keeps the tested
      // fallback below (nearest line above, then below — never the "\n\n"
      // itself, M2a on-device round 3).
      final (pressLine, _) = _buffer.locationOf(clamped);
      final lineStart = _buffer.offsetOf(pressLine, 0);
      final lineEnd = lineStart + _buffer.lineLength(pressLine);
      var i = clamped - 1;
      while (i >= lineStart && _isSpace(_codeAt(i))) {
        i--;
      }
      if (i >= lineStart) {
        probe = i;
      } else {
        i = clamped;
        while (i < lineEnd && _isSpace(_codeAt(i))) {
          i++;
        }
        if (i < lineEnd) {
          probe = i;
        } else {
          // No word on this line: fall back to the nearest line above,
          // then below (a press just below a line lands on the line's
          // last word).
          i = clamped - 1;
          while (i >= 0 && _isSpace(_codeAt(i))) {
            i--;
          }
          if (i >= 0) {
            probe = i;
          } else {
            i = clamped;
            while (i < length && _isSpace(_codeAt(i))) {
              i++;
            }
            if (i < length) probe = i;
          }
        }
      }
    }
    var start = 0;
    var end = 0;
    if (probe >= 0) {
      start = probe;
      while (start > 0 && !_isSpace(_codeAt(start - 1))) {
        start--;
      }
      end = probe + 1;
      while (end < length && !_isSpace(_codeAt(end))) {
        end++;
      }
    } else {
      // No word anywhere in the buffer (all whitespace): the run around the
      // offset is all there is.
      start = clamped;
      while (start > 0 && _isSpace(_codeAt(start - 1))) {
        start--;
      }
      end = clamped;
      while (end < length && _isSpace(_codeAt(end))) {
        end++;
      }
      if (start == end) return; // empty buffer: nothing to select.
    }
    final t = clamped.clamp(start, end);
    final base = (t - start).abs() <= (end - t).abs() ? start : end;
    setSelection(
      TextSelection(
        baseOffset: base,
        extentOffset: base == start ? end : start,
      ),
    );
  }

  /// The UTF-16 code unit at full-text [offset] — character access without
  /// materializing the whole buffer (the [selectWordAt] O(word) rewrite,
  /// M2a fix P1).
  ///
  /// A line's trailing line break is at full-text offset
  /// `_lineStarts[line] + lineLength(line)`, which [LineBuffer.locationOf]
  /// maps to `(line, lineLength(line))` — `col == lineLength` is the line
  /// break itself (a real 0x0A), not a past-end column.
  int _codeAt(int offset) {
    final (line, col) = _buffer.locationOf(offset);
    if (col == _buffer.lineLength(line)) return 0x0A;
    return _buffer.lineAt(line).codeUnitAt(col);
  }

  /// A word-boundary whitespace: space, tab, newline, plus the Unicode
  /// spaces prose uses (no-break variants — the notes carry the French
  /// narrow no-break space).
  static bool _isSpace(int unit) =>
      unit == 0x20 ||
      unit == 0x09 ||
      unit == 0x0A ||
      unit == 0xA0 ||
      unit == 0x2007 ||
      unit == 0x2009 ||
      unit == 0x200A ||
      unit == 0x202F;

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
    final collapsed = TextSelection.collapsed(offset: s.start);
    _buffer.delete(s.start, s.end);
    _selection = collapsed;
    _composing = TextRange.empty;
    _revision++;
    _needsImeSync = true;
    _recordEdit(
      start: s.start,
      oldText: removed,
      newText: '',
      selectionBefore: s,
      selectionAfter: collapsed,
    );
    _notify();
    return removed;
  }

  /// Replaces the buffer region [start, end) with [text] (a direct edit —
  /// breaks delta lockstep: the caller re-syncs with a push +
  /// [commitDirectEdit]), undoable, and takes [selection] (or a caret at
  /// [start]). The undoable region-replace the legacy (non-delta) IME path
  /// uses when the platform sends back its whole-field copy — the window,
  /// not the buffer (M2a fix P2).
  void replaceRegion(
    int start,
    int end,
    String text, {
    TextSelection? selection,
  }) {
    final selectionBefore = _selection;
    final oldText = _buffer.substring(start, end);
    _buffer.replace(start, end, text);
    _selection = selection ??
        TextSelection.collapsed(offset: start.clamp(0, _buffer.textLength));
    _composing = TextRange.empty;
    _revision++;
    _needsImeSync = true;
    _recordEdit(
      start: start,
      oldText: oldText,
      newText: text,
      selectionBefore: selectionBefore,
      selectionAfter: _selection,
    );
    _notify();
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
    final oldText = _buffer.substring(start, end);
    final collapsed = TextSelection.collapsed(offset: start + text.length);
    _buffer.replace(start, end, text);
    _selection = collapsed;
    _composing = TextRange.empty;
    _revision++;
    _needsImeSync = true;
    _recordEdit(
      start: start,
      oldText: oldText,
      newText: text,
      selectionBefore: s,
      selectionAfter: collapsed,
    );
    _notify();
  }

  /// Whether [undo] is available (there is an edit to take back).
  bool get canUndo => _undo.isNotEmpty;

  /// Whether [redo] is available (an edit was undone and not yet re-applied).
  bool get canRedo => _redo.isNotEmpty;

  /// Undoes the last edit, restoring the buffer **and the caret** to the state
  /// before it (E-U). A sequence of edits (typing, IME deltas, cut, paste)
  /// can be undone one at a time to recover the exact prior buffer + caret.
  ///
  /// Undo is a direct buffer edit: it breaks delta lockstep, so it sets the
  /// resync flag — the caller must push [value] and call [commitDirectEdit]
  /// (as it does after any direct edit), so the next delta re-anchors and no
  /// input is lost.
  void undo() {
    final entry = _undo.removeLast();
    // The buffer currently holds `newText` at [start, start + newText.length);
    // undo puts `oldText` back.
    _buffer.replace(
      entry.start,
      entry.start + entry.newText.length,
      entry.oldText,
    );
    _selection = entry.selectionBefore;
    _composing = TextRange.empty;
    _revision++;
    _needsImeSync = true;
    _redo.add(entry);
    _notify();
  }

  /// Re-applies the last undone edit, restoring the buffer + caret to the
  /// state after it (E-U). Like [undo], a direct edit that sets the resync
  /// flag; the caller pushes [value] + calls [commitDirectEdit].
  void redo() {
    final entry = _redo.removeLast();
    // After [undo] the buffer holds `oldText` at [start, start +
    // oldText.length); redo puts `newText` back.
    _buffer.replace(
      entry.start,
      entry.start + entry.oldText.length,
      entry.newText,
    );
    _selection = entry.selectionAfter;
    _composing = TextRange.empty;
    _revision++;
    _needsImeSync = true;
    _undo.add(entry);
    _notify();
  }

  /// Records a completed edit on the undo stack (clearing the redo branch) and
  /// drops the oldest entry past [maxHistory] (the stack is bounded).
  void _recordEdit({
    required int start,
    required String oldText,
    required String newText,
    required TextSelection selectionBefore,
    required TextSelection selectionAfter,
  }) {
    _undo.add(
      _UndoEntry(
        start: start,
        oldText: oldText,
        newText: newText,
        selectionBefore: selectionBefore,
        selectionAfter: selectionAfter,
      ),
    );
    if (_undo.length > maxHistory) {
      _undo.removeAt(0);
    }
    _redo.clear();
  }

  /// Subscribes [listener] to every change (text, selection or composing).
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  /// Unsubscribes [listener].
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  /// Copies the delta's selection + composing onto the client, translated
  /// from the platform's window-local offsets into buffer offsets by
  /// [anchor].
  void _setMeta(TextEditingDelta delta, int anchor) {
    _selection = translateSelection(delta.selection, anchor);
    _composing = translateRange(delta.composing, anchor);
    _notify();
  }

  void _notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }
}

/// One undoable edit (E-U): the text region `[start, start + oldText.length)`
/// was replaced with [newText]. Undo replaces `[start, start +
/// newText.length)` with [oldText]; redo does the reverse. The selection is
/// stored so undo/redo restore the caret, not just the text.
class _UndoEntry {
  const _UndoEntry({
    required this.start,
    required this.oldText,
    required this.newText,
    required this.selectionBefore,
    required this.selectionAfter,
  });

  /// The start of the edited region (stable across undo/redo: it is where the
  /// edit was made, and both old and new text occupy offsets from it).
  final int start;

  /// The text that was there before the edit (empty for an insertion).
  final String oldText;

  /// The text the edit inserted (empty for a deletion).
  final String newText;

  /// The selection before the edit (restored by [ComposingInput.undo]).
  final TextSelection selectionBefore;

  /// The selection after the edit (restored by [ComposingInput.redo]).
  final TextSelection selectionAfter;
}
