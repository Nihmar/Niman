/// The find keys of the open note and its find bar (issue #100 moved them
/// out of `note_view.dart`).
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/edit/source_find.dart';
import 'package:niman/src/ui/app_shortcuts.dart';

/// The find keys, for the note and its bar: Ctrl+F finds, Ctrl+H and
/// Ctrl+Alt+F replace, F3 and Shift+F3 walk the matches, Escape closes the
/// bar.
///
/// The chords come from [findInNoteKey] and its neighbours, which the
/// shortcut reference reads too, so the row and the handler agree off
/// the Control platforms (issue #381).
///
/// A key handler rather than shortcuts, so that a key it has nothing to do
/// with — Escape with the bar closed — goes on to the shell.
final class NoteFindKeys {
  /// The keys of [find], whose bar [openFind] opens.
  const new({required this.find, required this.openFind});

  /// The note's find & replace.
  final SourceFindController find;

  /// Opens the find bar, for replacing when `replace` is true.
  final void Function({bool replace}) openFind;

  /// Handles [event] for the note's focus [node]: a `Focus.onKeyEvent`.
  KeyEventResult onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    bool pressed(SingleActivator key) => key.accepts(event, keyboard);
    final replace = replaceInNoteKey();
    final ctrlH = ctrlHReplaceKey();
    if (pressed(replace) || (ctrlH != null && pressed(ctrlH))) {
      openFind(replace: true);
      return KeyEventResult.handled;
    }
    if (pressed(findInNoteKey())) {
      openFind();
      return KeyEventResult.handled;
    }
    if (!find.visible) return KeyEventResult.ignored;
    if (pressed(const SingleActivator(LogicalKeyboardKey.f3))) {
      find.nextMatch();
      return KeyEventResult.handled;
    }
    if (pressed(const SingleActivator(LogicalKeyboardKey.f3, shift: true))) {
      find.previousMatch();
      return KeyEventResult.handled;
    }
    if (pressed(const SingleActivator(LogicalKeyboardKey.escape))) {
      find.close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
