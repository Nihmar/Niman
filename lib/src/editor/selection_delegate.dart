import 'dart:async' show unawaited;

import 'package:copist/src/editor/composing_input.dart';
import 'package:flutter/services.dart';

/// The [TextSelectionDelegate] behind the standard selection UI (the
/// `SelectionOverlay` handles + toolbar, see `selection_handles.dart`): the
/// framework's own channel for the toolbar actions (copy / cut / paste /
/// select all), wired onto the [ComposingInput] buffer.
///
/// Clipboard writes go through the platform [Clipboard]. Text edits (cut,
/// paste) mutate the buffer directly and report back through `onCut` /
/// `onPaste` so the view can re-sync the IME with a full value push (a
/// direct edit breaks the delta lockstep the IME bridge relies on).
final class NoteSelectionDelegate with TextSelectionDelegate {
  /// Creates the delegate over [input].
  ///
  /// `onSelectAll` selects the whole buffer and commits the selection to the
  /// IME; `onCut` deletes the selection and pushes the new value to the IME
  /// (after [cutSelection] has copied it to the clipboard); `onPaste`
  /// replaces the selection with its argument and pushes the new value;
  /// `onBringIntoView` scrolls so the position is visible; `onHide` hides
  /// the selection UI (handles + toolbar).
  NoteSelectionDelegate({
    required this.input,
    required this.onSelectAll,
    required this.onCut,
    required this.onPaste,
    required this.onBringIntoView,
    required this.onHide,
  });

  /// The buffer behind the toolbar actions.
  final ComposingInput input;

  /// Selects the whole buffer and commits the selection to the IME.
  final VoidCallback onSelectAll;

  /// Deletes the selection and pushes the new value to the IME (the copy to
  /// the clipboard happens in [cutSelection], before this callback).
  final VoidCallback onCut;

  /// Replaces the selection with [onPaste]'s argument and pushes the new
  /// value to the IME.
  final Future<void> Function(String text) onPaste;

  /// Scrolls so the position is visible.
  final void Function(TextPosition position) onBringIntoView;

  /// Hides the selection UI (handles + toolbar).
  final VoidCallback onHide;

  /// The toolbar's view of the field: the selection + composing are real,
  /// the text is empty (the copy/cut text comes from the buffer's
  /// `selectionText`, not from here). Never materializes the buffer — the
  /// selection UI must stay cheap on a 931 KB note (M2a fix P1).
  @override
  TextEditingValue get textEditingValue => TextEditingValue(
    selection: input.selection,
    composing: input.composing,
  );

  @override
  void userUpdateTextEditingValue(
    TextEditingValue value,
    SelectionChangedCause cause,
  ) {
    // The platform's full-value update channel: only the selection matters
    // here (the text is always ours). No IME push — the drag end commits.
    input.setSelection(value.selection);
  }

  @override
  void hideToolbar([bool hideHandles = true]) => onHide();

  @override
  void bringIntoView(TextPosition position) => onBringIntoView(position);

  @override
  bool get copyEnabled => input.hasSelection;

  @override
  bool get cutEnabled => input.hasSelection;

  @override
  void cutSelection(SelectionChangedCause cause) {
    if (!input.hasSelection) return;
    unawaited(Clipboard.setData(ClipboardData(text: input.selectionText)));
    onCut();
    // The cause contract: a toolbar cut hides the toolbar (the selection
    // collapses too, which hides the handles).
    if (cause == SelectionChangedCause.toolbar) onHide();
  }

  @override
  Future<void> pasteText(SelectionChangedCause cause) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    await onPaste(text);
    if (cause == SelectionChangedCause.toolbar) onHide();
  }

  @override
  void selectAll(SelectionChangedCause cause) => onSelectAll();

  @override
  void copySelection(SelectionChangedCause cause) {
    if (!input.hasSelection) return;
    unawaited(Clipboard.setData(ClipboardData(text: input.selectionText)));
    // The cause contract: a toolbar copy hides the toolbar (the selection
    // stays in the buffer).
    if (cause == SelectionChangedCause.toolbar) onHide();
  }
}
