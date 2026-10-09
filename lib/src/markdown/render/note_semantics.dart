import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';

/// The note as a text field to the platform's accessibility: what
/// `RenderEditable` tells it about a `TextField`, which the `Semantics`
/// widget has no way to say — the selection inside the value above all.
final class NoteSemantics extends SingleChildRenderObjectWidget {
  /// The note's [value] and [selection] as the platform reads them, and the
  /// actions its accessibility can take on them.
  const new({
    required this.value,
    required this.selection,
    required this.focused,
    required this.onTap,
    required this.onSetSelection,
    required this.onMove,
    required this.onCopy,
    required this.onCut,
    required this.onPaste,
    super.key,
    super.child,
  });

  /// The text the field holds: the note around the caret.
  final String value;

  /// The selection inside [value].
  final TextSelection selection;

  /// Whether the note has the keyboard's focus.
  final bool focused;

  /// A tap on the field.
  final VoidCallback onTap;

  /// The platform setting the selection.
  final ValueChanged<TextSelection> onSetSelection;

  /// The platform moving the caret by a character or a word.
  final void Function(CaretMotion motion, {required bool extend}) onMove;

  /// Copying the selection, or null with nothing selected.
  final VoidCallback? onCopy;

  /// Cutting the selection, or null with nothing selected.
  final VoidCallback? onCut;

  /// Pasting at the caret.
  final VoidCallback onPaste;

  @override
  RenderProxyBox createRenderObject(BuildContext context) =>
      _RenderNoteSemantics(this);

  @override
  void updateRenderObject(BuildContext context, RenderProxyBox renderObject) {
    // The render object is always the one [createRenderObject] made.
    (renderObject as _RenderNoteSemantics).semantics = this;
  }
}

final class _RenderNoteSemantics extends RenderProxyBox {
  new(this._semantics);

  NoteSemantics _semantics;

  // A setter the widget pairs with, as every render object's are.
  // ignore: avoid_setters_without_getters
  set semantics(NoteSemantics value) {
    _semantics = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    final note = _semantics;
    MoveCursorHandler move(CaretMotion motion) =>
        (extend) => note.onMove(motion, extend: extend);
    // Named first: a closure written in the cascade would swallow the rest of
    // it into its body.
    final characterRight = move(CaretMotion.characterRight);
    final characterLeft = move(CaretMotion.characterLeft);
    final wordRight = move(CaretMotion.wordRight);
    final wordLeft = move(CaretMotion.wordLeft);
    config
      ..isSemanticBoundary = true
      ..isTextField = true
      ..isMultiline = true
      ..isFocused = note.focused
      ..isEnabled = true
      ..value = note.value
      // The note is written left to right, as every line of it is laid out.
      ..textDirection = TextDirection.ltr
      ..textSelection = note.selection
      ..onTap = note.onTap
      ..onSetSelection = note.onSetSelection
      ..onPaste = note.onPaste
      ..onMoveCursorForwardByCharacter = characterRight
      ..onMoveCursorBackwardByCharacter = characterLeft
      ..onMoveCursorForwardByWord = wordRight
      ..onMoveCursorBackwardByWord = wordLeft;
    if (note.onCopy != null) config.onCopy = note.onCopy;
    if (note.onCut != null) config.onCut = note.onCut;
  }
}
