import 'package:copist/src/core/logging.dart';
import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/ime_bridge.dart';
import 'package:flutter/services.dart';

/// The delta-mode IME client over a [ComposingInput] (M2a E8d) — the
/// make-or-break input piece of the on-device editor.
///
/// It is the `TextInputClient` handed to [TextInput.attach]. In delta mode
/// the platform sends a [TextEditingDelta] per edit (never the whole field);
/// this client forwards each to [ComposingInput.apply] (translating the
/// platform's window-local offsets by the window start) and pushes exactly
/// when lockstep with the platform copy must be re-established:
/// - [ComposingInput.apply] reports an unrecognized delta (it re-anchors to
///   the platform copy and asks for a resync);
/// - after a direct edit (reset / cut / paste / undo) the caller pushes via
///   [pushValue];
/// - the caret crossed the edge of the window the platform holds (re-center
///   = one KB-sized push, M2a fix P2).
///
/// The platform never holds the full buffer: it holds the caret's
/// [ImeWindow] (KB, clamped to line boundaries), so a keystroke on the 931 KB
/// note ships a KB-sized delta, not a 931 KB oldText.
///
/// The client does not own the [TextInputConnection]; the view does. It
/// reports the push, the IME action, and the connection close through
/// callbacks, which is what keeps this class headless-verifiable (the tests
/// drive [updateEditingValueWithDeltas] and observe [onPushValue] + the
/// buffer).
final class NoteEditorClient with DeltaTextInputClient {
  /// Creates a client over [input]. [onPushValue] is called with the value to
  /// send to the platform (the view forwards it to the connection);
  /// [onAction] reports an IME action; [onConnectionClosed] reports the
  /// platform closing the connection.
  NoteEditorClient({
    required this.input,
    required this.onPushValue,
    this.onAction,
    this.onConnectionClosed,
  });

  /// The IME diagnostics.
  static const AppLogger _log = AppLogger(name: 'editor');

  /// The input model the client edits (the note's source of truth).
  final ComposingInput input;

  /// Sends the [TextEditingValue] to push to the platform (the view forwards
  /// it to the [TextInputConnection]). Window-sized since M2a fix P2.
  final void Function(TextEditingValue value) onPushValue;

  /// Reports an IME action (e.g. the keyboard's "done"/"newline" button).
  final void Function(TextInputAction action)? onAction;

  /// Reports the platform closing the connection (the keyboard dismissed).
  final VoidCallback? onConnectionClosed;

  /// The buffer offset the platform's copy starts at (the last pushed
  /// window's start). Incoming deltas are window-local relative to it.
  int _windowStart = 0;

  /// The length of the platform's copy as it stands now (the pushed window
  /// text, plus/minus the deltas applied since). The legacy (non-delta)
  /// full-update path re-anchors the window region with it.
  int _platformLength = 0;

  /// Pushes the caret's [ImeWindow] to the platform and clears the pending
  /// resync flag. Call after a direct edit (cut / paste / undo) or a
  /// [ComposingInput.reset] — and on focus attach.
  void pushValue() {
    final window = ImeWindow.around(input);
    _windowStart = window.windowStart;
    _platformLength = window.windowText.length;
    onPushValue(window.asValue());
    input.commitDirectEdit();
  }

  // --- TextInputClient (delta mode) ---

  /// The platform's resync pull: the caret's [ImeWindow] (KB, never the full
  /// buffer — M2a fix P2).
  @override
  TextEditingValue? get currentTextEditingValue {
    final window = ImeWindow.around(input);
    _windowStart = window.windowStart;
    _platformLength = window.windowText.length;
    return window.asValue();
  }

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> deltas) {
    final anchor = _windowStart;
    var resync = false;
    for (final delta in deltas) {
      _log.debug('ime delta: ${_describeDelta(delta)}');
      if (input.apply(delta, anchor: anchor)) resync = true;
      _platformLength += _lengthDelta(delta);
    }
    if (resync) {
      pushValue();
      return;
    }
    // Re-center when the caret crossed the window's edge (the platform copy
    // would no longer hold the caret's line breaks): one KB-sized push, then
    // lockstep on the new window (M2a fix P2).
    if (ImeWindow.around(input).windowStart != anchor) pushValue();
  }

  /// The platform-copy length change a [delta] carries (the window text
  /// grows/shrinks with every edit the platform makes inside it).
  static int _lengthDelta(TextEditingDelta delta) => switch (delta) {
    TextEditingDeltaInsertion(:final textInserted) => textInserted.length,
    TextEditingDeltaDeletion(:final deletedRange) =>
        deletedRange.start - deletedRange.end,
    TextEditingDeltaReplacement(
      :final replacedRange,
      :final replacementText
    ) =>
        replacementText.length + replacedRange.start - replacedRange.end,
    _ => 0,
  };

  /// The delta in one line: the kind, the edit, and the platform's oldText
  /// size (the cost question at novel length: how big the text the IME ships
  /// back with every keystroke is).
  static String _describeDelta(TextEditingDelta delta) {
    final old = delta.oldText.length;
    final deltaDescription = switch (delta) {
      TextEditingDeltaInsertion(:final insertionOffset, :final textInserted) =>
          'insertion @ $insertionOffset "${_short(textInserted)}"',
      TextEditingDeltaDeletion(:final deletedRange) =>
          'deletion ${deletedRange.start}..${deletedRange.end}',
      TextEditingDeltaReplacement(
        :final replacedRange, :final replacementText
      ) =>
          'replacement ${replacedRange.start}..${replacedRange.end} '
          '"${_short(replacementText)}"',
      TextEditingDeltaNonTextUpdate() =>
          'nonText selection ${delta.selection.start}..'
          '${delta.selection.end} composing ${delta.composing.start}..'
          '${delta.composing.end}',
      _ => delta.runtimeType.toString(),
    };
    return '$deltaDescription (oldText $old)';
  }

  static String _short(String s) {
    final flat = s.replaceAll('\n', r'\n');
    return flat.length <= 40 ? flat : '${flat.substring(0, 40)}…';
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    // Legacy (non-delta) full update: the platform sent its whole-field copy
    // (an IME without the delta model) — which is the window (M2a fix P2),
    // not the buffer. Re-anchor the window region to that copy, take the
    // platform's selection, and re-sync. No window was ever pushed (a
    // programmatic set, or a platform that started from its own state): the
    // value is the whole field, full reset.
    if (_windowStart == 0 && _platformLength == 0) {
      input.reset(value.text, selection: value.selection);
    } else {
      final start = _windowStart;
      input.replaceRegion(
        start,
        start + _platformLength,
        value.text,
        selection: translateSelection(value.selection, start),
      );
    }
    _platformLength = value.text.length;
    pushValue();
  }

  @override
  void performAction(TextInputAction action) {
    onAction?.call(action);
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void connectionClosed() {
    onConnectionClosed?.call();
  }

  // --- TextInputClient members this editor does not use ---

  @override
  void insertContent(KeyboardInsertedContent content) {}

  @override
  bool onFocusReceived() => false;

  @override
  void didChangeInputControl(
    TextInputControl? oldControl,
    TextInputControl? newControl,
  ) {}

  @override
  void showToolbar() {}

  @override
  void insertTextPlaceholder(Size size) {}

  @override
  void removeTextPlaceholder() {}

  @override
  void performSelector(String selectorName) {}
}
