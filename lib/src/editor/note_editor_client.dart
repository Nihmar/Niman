import 'package:copist/src/editor/composing_input.dart';
import 'package:flutter/services.dart';

/// The delta-mode IME client over a [ComposingInput] (M2a E8d) — the
/// make-or-break input piece of the on-device editor.
///
/// It is the `TextInputClient` handed to [TextInput.attach]. In delta mode
/// the platform sends a [TextEditingDelta] per edit (never the whole field);
/// this client forwards each to [ComposingInput.apply] and pushes a full
/// [ComposingInput.value] exactly when lockstep with the platform copy must
/// be re-established:
/// - [ComposingInput.apply] reports an unrecognized delta (it re-anchors to
///   the platform copy and asks for a resync);
/// - after a direct edit (reset / cut / paste / undo) the caller pushes via
///   [pushValue].
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

  /// The input model the client edits (the note's source of truth).
  final ComposingInput input;

  /// Sends a full [TextEditingValue] to the platform (the view forwards it to
  /// the [TextInputConnection]).
  final void Function(TextEditingValue value) onPushValue;

  /// Reports an IME action (e.g. the keyboard's "done"/"newline" button).
  final void Function(TextInputAction action)? onAction;

  /// Reports the platform closing the connection (the keyboard dismissed).
  final VoidCallback? onConnectionClosed;

  /// Pushes [ComposingInput.value] to the platform and clears the pending
  /// resync flag. Call after a direct edit (cut / paste / undo) or a
  /// [ComposingInput.reset].
  void pushValue() {
    onPushValue(input.value);
    input.commitDirectEdit();
  }

  // --- TextInputClient (delta mode) ---

  @override
  TextEditingValue? get currentTextEditingValue => input.value;

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> deltas) {
    var resync = false;
    for (final delta in deltas) {
      if (input.apply(delta)) resync = true;
    }
    if (resync) pushValue();
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    // Legacy (non-delta) full update: the platform sent a whole-field value
    // (an IME that does not support the delta model, or a programmatic set).
    // Re-anchor the buffer to that copy and re-sync.
    input.reset(value.text, selection: value.selection);
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
