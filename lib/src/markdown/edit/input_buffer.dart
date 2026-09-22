// The surface's text input: what the app and the platform agree the note says
// (#245, phase 3 — the rules a device run established).
//
// The IME probe answered the questions the design could only argue
// (`docs/dev/unified-surface.md` §10.4, spike 2;
// `lib/src/editor/text_input_probe.dart`):
//
// * `enableDeltaModel: true` delivers **deltas** on Android with Gboard — one
//   per character, at the right offsets, with the selection tracking them;
// * at a 921 600-character buffer, the delta path carries **one character** and
//   the whole-value fallback carries **921 601 characters** — the entire note
//   across the platform channel, per keystroke;
// * and the echo race is real **only at size**: echoing the document per
//   keystroke means the IME builds its next delta from a copy that predates it,
//   which showed up as four deltas whose `oldText` was one keystroke behind the
//   buffer — and as none at all in the small-buffer runs.
//
// So this file is the policy those three facts imply, and nothing else: the
// buffer, what the platform has been told, and when it has to be told again. It
// is pure Dart — no `TextInputConnection`, no widget — because the policy is
// what has to be testable on its own, and the surface that owns a connection
// can be wrong about pixels without being wrong about text.
import 'package:flutter/services.dart';

/// What changed in a buffer by one platform update, for a caller that has to
/// decide whether to echo and what to log.
enum InputKind {
  /// The platform sent deltas and they applied cleanly.
  deltas,

  /// The platform sent deltas whose `oldText` disagreed with the buffer: the
  /// platform's copy was behind, so its text became the base (see
  /// [InputBuffer.applyDeltas]).
  deltasRecovered,

  /// The platform sent the whole value (the fallback path, or an IME that does
  /// not do deltas).
  value,

  /// Deltas arrived that changed nothing (a selection-only update).
  unchanged,
}

/// The note's text and selection, and what the platform's copy of them holds.
final class InputBuffer {
  /// Creates a buffer over [text], with the caret at [caret] (0 by default).
  new({String text = '', int caret = 0})
    : _value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: caret),
      ),
      _platformText = text;

  TextEditingValue _value;

  /// What the platform's copy holds, as far as this side knows: the text at the
  /// last value it was handed, moved forward by every delta it sent. A local
  /// edit is what makes the two disagree, and [needsEcho] is that disagreement.
  String _platformText;

  /// Whether the composing range the platform's copy carries is out of date.
  bool _composingStale = false;

  /// The buffer as it stands.
  TextEditingValue get value => _value;

  /// The text as it stands.
  String get text => _value.text;

  /// The selection as it stands.
  TextSelection get selection => _value.selection;

  /// Whether the platform has to be told what the buffer now says.
  ///
  /// Echoing **everything** per keystroke is what §8.7.1 warns about and what
  /// the device run measured at 921 KB; echoing nothing leaves the IME's
  /// composing range (and the platform's copy of a local edit) stale. So this
  /// is
  /// true for a local edit and for a composing change, and false after a
  /// platform update that the platform already knows about.
  bool get needsEcho => _composingStale || _value.text != _platformText;

  /// Applies the platform's whole value — the fallback path, and what an IME
  /// that does not do deltas sends.
  InputKind applyValue(TextEditingValue incoming) {
    final changed = incoming.text != _value.text;
    _value = _withSelectionKeptIfInvalid(incoming);
    // The platform sent this, so its copy is current by definition — including
    // the composing range, which is the one thing only it can know.
    _platformText = _value.text;
    _composingStale = false;
    return changed ? InputKind.value : InputKind.unchanged;
  }

  /// Applies the platform's [deltas], in the order they arrived.
  ///
  /// **A delta's `oldText` is authoritative when it disagrees with the
  /// buffer.**
  /// The platform computes a delta against its own copy, and at note size that
  /// copy can be a keystroke behind the app's (a 921 KB `setEditingState` is
  /// not instant): applying such a delta to the app's text writes the wrong
  /// bytes.
  /// The device run produced exactly that, four times, all at ~921 600
  /// characters — so the platform's text becomes the base, and the caller is
  /// told with [InputKind.deltasRecovered].
  InputKind applyDeltas(List<TextEditingDelta> deltas) {
    if (deltas.isEmpty) return InputKind.unchanged;
    var current = _value;
    var recovered = false;
    for (final delta in deltas) {
      if (delta.oldText != current.text) {
        recovered = true;
        current = TextEditingValue(
          text: delta.oldText,
          selection: delta.selection,
          composing: delta.composing,
        );
      }
      current = delta.apply(current);
    }
    final changed = current.text != _value.text;
    _value = _withSelectionKeptIfInvalid(current);
    // The deltas came from the platform's copy, so it is current — unless this
    // side had a composing range it has not told it about.
    _platformText = _value.text;
    return changed || recovered
        ? (recovered ? InputKind.deltasRecovered : InputKind.deltas)
        : InputKind.unchanged;
  }

  /// The app changed the text itself: a toolbar button, a command, an undo.
  ///
  /// This is the case that needs an echo — the platform's copy is now behind —
  /// and the case that has to send the whole value, because there is no delta
  /// that describes it.
  void editedLocally(TextEditingValue next) {
    _value = next;
    // Deliberately not `_platformText = next.text`: that is what makes
    // [needsEcho] true, and the platform's copy really is behind until the echo
    // is sent.
    _composingStale = false;
  }

  /// Sets the note's text without changing what the platform has been told.
  ///
  /// What a surface that was built before its note was read needs: the buffer
  /// starts empty, the note arrives, and the first delta's `oldText` has to be
  /// compared against the note and not against nothing.
  void seed(String text) {
    _value = TextEditingValue(
      text: text,
      selection: _value.selection.isValid
          ? _value.selection
          : const TextSelection.collapsed(offset: 0),
    );
  }

  /// Records that the platform has been handed the buffer's value.
  void echoSent() {
    _platformText = _value.text;
    _composingStale = false;
  }

  /// Records that the composing range changed and the platform has not been
  /// told.
  void composingChanged() => _composingStale = true;

  /// [incoming] with this buffer's selection when the incoming one is not in
  /// its text.
  ///
  /// The platform sends `-1..-1` (and `-1..0`) in its non-text updates — the
  /// device run logged nine of them — and adopting that as the caret leaves
  /// the surface with a selection it cannot paint or scroll to.
  TextEditingValue _withSelectionKeptIfInvalid(TextEditingValue incoming) {
    final selection = incoming.selection;
    final valid =
        selection.isValid &&
        selection.start <= incoming.text.length &&
        selection.end <= incoming.text.length;
    if (valid) return incoming;
    return TextEditingValue(
      text: incoming.text,
      selection: TextSelection.collapsed(
        offset: _value.selection.isValid
            ? _value.selection.start.clamp(0, incoming.text.length)
            : 0,
      ),
      composing: incoming.composing,
    );
  }
}
