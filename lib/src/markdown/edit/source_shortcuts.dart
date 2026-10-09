import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';

/// What the source view's own keys do: the logical motions, the table's
/// Tab and Down, the clipboard, deleting and undo — the actions
/// [sourceShortcuts] binds.
final class SourceKeyActions {
  /// The view's own actions, one per kind of key.
  const new({
    required this.moveVertically,
    required this.moveBy,
    required this.downOutOfTable,
    required this.page,
    required this.tab,
    required this.copy,
    required this.cut,
    required this.paste,
    required this.selectAll,
    required this.deleteBackward,
    required this.deleteForward,
    required this.undo,
    required this.redo,
  });

  /// Moves the caret a number of visual rows up (negative) or down.
  final void Function(int rows, {bool extend}) moveVertically;

  /// Moves the caret by a logical motion.
  final void Function(CaretMotion motion, {bool extend}) moveBy;

  /// Down from a table's last row in `live`; whether it was that.
  final bool Function() downOutOfTable;

  /// Moves the caret a page up (negative) or down.
  final void Function(int direction, {bool extend}) page;

  /// Tab: the next cell of a table in `live`, an indent elsewhere.
  final void Function({required bool forward}) tab;

  /// Copies the selection.
  final VoidCallback copy;

  /// Cuts the selection.
  final VoidCallback cut;

  /// Pastes at the caret.
  final VoidCallback paste;

  /// Selects the whole note.
  final VoidCallback selectAll;

  /// Deletes before the caret: a character, or a word.
  final void Function({bool word}) deleteBackward;

  /// Deletes after the caret: a character, or a word.
  final void Function({bool word}) deleteForward;

  /// Undoes the last edit.
  final VoidCallback undo;

  /// Redoes the last undone edit.
  final VoidCallback redo;
}

/// The keys the surface answers itself.
///
/// The *logical* motions and undo/redo, which are this surface's own
/// business. What the shell binds — the remappable command table, the
/// toolbar, find — is dispatched to it by the shell, not captured here, so a
/// user's rebinding wins.
Map<ShortcutActivator, VoidCallback> sourceShortcuts(
  SourceKeyActions actions,
) => <ShortcutActivator, VoidCallback>{
  const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
      actions.moveVertically(-1),
  const SingleActivator(LogicalKeyboardKey.arrowDown): () {
    if (!actions.downOutOfTable()) actions.moveVertically(1);
  },
  const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): () =>
      actions.moveVertically(-1, extend: true),
  const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): () =>
      actions.moveVertically(1, extend: true),
  const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
      actions.moveBy(CaretMotion.characterLeft),
  const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
      actions.moveBy(CaretMotion.characterRight),
  const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): () =>
      actions.moveBy(CaretMotion.characterLeft, extend: true),
  const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): () =>
      actions.moveBy(CaretMotion.characterRight, extend: true),
  const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): () =>
      actions.moveBy(CaretMotion.wordLeft),
  const SingleActivator(LogicalKeyboardKey.arrowRight, control: true): () =>
      actions.moveBy(CaretMotion.wordRight),
  const SingleActivator(
    LogicalKeyboardKey.arrowLeft,
    control: true,
    shift: true,
  ): () =>
      actions.moveBy(CaretMotion.wordLeft, extend: true),
  const SingleActivator(
    LogicalKeyboardKey.arrowRight,
    control: true,
    shift: true,
  ): () =>
      actions.moveBy(CaretMotion.wordRight, extend: true),
  const SingleActivator(LogicalKeyboardKey.home): () =>
      actions.moveBy(CaretMotion.lineTextStart),
  const SingleActivator(LogicalKeyboardKey.end): () =>
      actions.moveBy(CaretMotion.lineEnd),
  const SingleActivator(LogicalKeyboardKey.home, shift: true): () =>
      actions.moveBy(CaretMotion.lineTextStart, extend: true),
  const SingleActivator(LogicalKeyboardKey.end, shift: true): () =>
      actions.moveBy(CaretMotion.lineEnd, extend: true),
  const SingleActivator(LogicalKeyboardKey.home, control: true): () =>
      actions.moveBy(CaretMotion.documentStart),
  const SingleActivator(LogicalKeyboardKey.end, control: true): () =>
      actions.moveBy(CaretMotion.documentEnd),
  const SingleActivator(
    LogicalKeyboardKey.home,
    control: true,
    shift: true,
  ): () =>
      actions.moveBy(CaretMotion.documentStart, extend: true),
  const SingleActivator(
    LogicalKeyboardKey.end,
    control: true,
    shift: true,
  ): () =>
      actions.moveBy(CaretMotion.documentEnd, extend: true),
  const SingleActivator(LogicalKeyboardKey.pageUp): () => actions.page(-1),
  const SingleActivator(LogicalKeyboardKey.pageDown): () => actions.page(1),
  const SingleActivator(LogicalKeyboardKey.pageUp, shift: true): () =>
      actions.page(-1, extend: true),
  const SingleActivator(LogicalKeyboardKey.pageDown, shift: true): () =>
      actions.page(1, extend: true),
  // Tab is the note's: left to the app it moves the focus away, and the
  // keyboard with it.
  // In a table in `live` it goes from cell to cell instead (#261).
  const SingleActivator(LogicalKeyboardKey.tab): () =>
      actions.tab(forward: true),
  const SingleActivator(LogicalKeyboardKey.tab, shift: true): () =>
      actions.tab(forward: false),
  const SingleActivator(LogicalKeyboardKey.keyC, control: true): actions.copy,
  const SingleActivator(LogicalKeyboardKey.keyC, meta: true): actions.copy,
  const SingleActivator(LogicalKeyboardKey.keyX, control: true): actions.cut,
  const SingleActivator(LogicalKeyboardKey.keyX, meta: true): actions.cut,
  const SingleActivator(LogicalKeyboardKey.keyV, control: true): actions.paste,
  const SingleActivator(LogicalKeyboardKey.keyV, meta: true): actions.paste,
  const SingleActivator(LogicalKeyboardKey.keyA, control: true):
      actions.selectAll,
  const SingleActivator(LogicalKeyboardKey.keyA, meta: true): actions.selectAll,
  // Backspace and Delete *are* bound: no embedder edits the text for them
  // (Linux says so in its source, and Android's hardware key reaches the
  // framework first), so a surface that leaves them to the platform is one
  // that cannot delete. Handling the key stops it here, so it is never
  // applied twice.
  const SingleActivator(LogicalKeyboardKey.backspace): actions.deleteBackward,
  const SingleActivator(LogicalKeyboardKey.backspace, shift: true):
      actions.deleteBackward,
  const SingleActivator(LogicalKeyboardKey.backspace, control: true): () =>
      actions.deleteBackward(word: true),
  const SingleActivator(LogicalKeyboardKey.backspace, alt: true): () =>
      actions.deleteBackward(word: true),
  const SingleActivator(LogicalKeyboardKey.delete): actions.deleteForward,
  const SingleActivator(LogicalKeyboardKey.delete, control: true): () =>
      actions.deleteForward(word: true),
  const SingleActivator(LogicalKeyboardKey.delete, alt: true): () =>
      actions.deleteForward(word: true),
  // Enter is deliberately *not* bound here. The platform already sends the
  // line break as text — an IME commits it, and the Linux embedder inserts
  // it and then calls the newline action, which inserts nothing (see
  // `SourceInput.performAction`) — so the delta is the only source.
  const SingleActivator(LogicalKeyboardKey.keyZ, control: true): actions.undo,
  const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): actions.undo,
  const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
      actions.redo,
  const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
      actions.redo,
  const SingleActivator(LogicalKeyboardKey.keyY, control: true): actions.redo,
};
