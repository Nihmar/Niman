import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/edit/source_shortcuts.dart';

/// What the text system of macOS and iOS asks of a text field by name
/// (`NSStandardKeyBindingResponding`), answered with the surface's own keys
/// (#1351).
///
/// A chord the surface does not bind reaches the platform's text input as a
/// selector — `moveToBeginningOfLine:` for `⌘←`, `deleteWordBackward:` for
/// `⌥⌫`, and whatever a user's own key bindings file maps to them — and a
/// client that ignores it leaves the user's keys dead. Each selector is the
/// motion, selection or deletion the same chord is bound to in
/// [sourceShortcuts].
///
/// True when the selector was one of those, so the caller can tell a key that
/// was answered from one nobody here knows.
bool performAppleSelector(String selector, SourceKeyActions actions) {
  const modify = 'AndModifySelection:';
  final extend = selector.endsWith(modify);
  final name = extend
      ? '${selector.substring(0, selector.length - modify.length)}:'
      : selector;
  final motion = _motions[name];
  if (motion != null) {
    actions.moveBy(motion, extend: extend);
    return true;
  }
  switch (name) {
    case 'moveUp:':
      actions.moveVertically(-1, extend: extend);
    case 'moveDown:':
      actions.moveVertically(1, extend: extend);
    case 'pageUp:':
      actions.page(-1, extend: extend);
    case 'pageDown:':
      actions.page(1, extend: extend);
    case 'selectAll:':
      actions.selectAll();
    case 'deleteBackward:':
      actions.deleteBackward();
    case 'deleteForward:':
      actions.deleteForward();
    case 'deleteWordBackward:':
      actions.deleteBackward(word: true);
    case 'deleteWordForward:':
      actions.deleteForward(word: true);
    case 'deleteToBeginningOfLine:' || 'deleteToBeginningOfParagraph:':
      actions.deleteTo(CaretMotion.lineStart);
    case 'deleteToEndOfLine:' || 'deleteToEndOfParagraph:':
      actions.deleteTo(CaretMotion.lineEnd);
    case 'insertTab:':
      actions.tab(forward: true);
    case 'insertBacktab:':
      actions.tab(forward: false);
    default:
      return false;
  }
  return true;
}

/// The selectors that are one logical motion, by name without their
/// `AndModifySelection` ending.
const Map<String, CaretMotion> _motions = <String, CaretMotion>{
  'moveLeft:': CaretMotion.characterLeft,
  'moveBackward:': CaretMotion.characterLeft,
  'moveRight:': CaretMotion.characterRight,
  'moveForward:': CaretMotion.characterRight,
  'moveWordLeft:': CaretMotion.wordLeft,
  'moveWordBackward:': CaretMotion.wordLeft,
  'moveWordRight:': CaretMotion.wordRight,
  'moveWordForward:': CaretMotion.wordRight,
  // The line is the source line: a paragraph is one, and the soft-wrapped
  // row the platform means by `LeftEndOfLine` is the line's whole.
  'moveToBeginningOfLine:': CaretMotion.lineTextStart,
  'moveToLeftEndOfLine:': CaretMotion.lineTextStart,
  'moveToEndOfLine:': CaretMotion.lineEnd,
  'moveToRightEndOfLine:': CaretMotion.lineEnd,
  'moveToBeginningOfParagraph:': CaretMotion.lineStart,
  'moveParagraphBackward:': CaretMotion.lineStart,
  'moveToEndOfParagraph:': CaretMotion.lineEnd,
  'moveParagraphForward:': CaretMotion.lineEnd,
  'moveToBeginningOfDocument:': CaretMotion.documentStart,
  'moveToEndOfDocument:': CaretMotion.documentEnd,
};
