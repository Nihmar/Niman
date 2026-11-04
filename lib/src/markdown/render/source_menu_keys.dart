import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/source_context_menu.dart';
import 'package:niman/src/markdown/render/source_touch.dart';
import 'package:niman/src/markdown/render/wikilink_suggest.dart';

/// The keys the source view's note answers on its focus, before its
/// shortcuts: the wikilink panel's while it is open, Escape, the way out of
/// a table, and the menu key.
///
/// The view hands [handle] to its `Focus`; everything else goes on to the
/// note's shortcuts.
final class SourceMenuKeys {
  /// The keys over the view's [_menu], [_touch] and [_suggest].
  new({
    required this._menu,
    required this._touch,
    required this._suggest,
    required this._selection,
    required this._placeCaret,
    required this._tableExit,
  });

  /// The desktop context menu.
  final SourceContextMenu _menu;

  /// The selection by touch.
  final SourceTouchSelection _touch;

  /// The wikilink suggester.
  final WikilinkSuggestController _suggest;

  /// The caret.
  final SelectionModel Function() _selection;

  /// Puts the caret at an offset and keeps it on screen.
  final void Function(int offset) _placeCaret;

  /// Shift+Enter or Ctrl+Enter in a table in `live`: out of it; whether the
  /// caret was in one.
  final bool Function() _tableExit;

  /// The keys the menu answers while the note has the focus: Escape closes
  /// it (or the touch selection, or collapses a selection), and the menu key
  /// or Shift+F10 opens it at the caret. Everything else
  /// goes on to the note's shortcuts.
  KeyEventResult handle(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final control = HardwareKeyboard.instance.isControlPressed;
    final alt = HardwareKeyboard.instance.isAltPressed;
    final meta = HardwareKeyboard.instance.isMetaPressed;
    // The wikilink suggester owns its keys while it is open, and only then
    // (#475); with no panel the keys fall through to the note's own table
    // exactly as they did.
    final taken = _suggest.handleKey(
      key,
      modified: shift || control || alt || meta,
    );
    if (taken != null) return taken;
    if (key == LogicalKeyboardKey.escape) {
      if (_menu.isShown) {
        _menu.hide();
        return KeyEventResult.handled;
      }
      if (_touch.isUp) {
        _touch.hide();
        return KeyEventResult.handled;
      }
      // A selection takes the first press, as it did in the legacy editor;
      // with nothing left to cancel the key goes on to the app (Zen mode).
      final selection = _selection();
      if (!selection.isCollapsed) {
        _placeCaret(selection.extent);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    // Shift+Enter and Ctrl+Enter leave a table in `live`; anywhere else they
    // go on to the platform and the app, as before.
    if ((key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) &&
        (shift || control) &&
        _tableExit()) {
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.contextMenu ||
        (key == LogicalKeyboardKey.f10 && shift)) {
      _menu.show();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
