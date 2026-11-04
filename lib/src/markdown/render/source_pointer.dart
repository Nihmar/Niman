import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/source_touch.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// A link the pointer is on with the opening modifier held (#846): its kind
/// (a wikilink or a Markdown link), as written (`[[…]]`, `[…](…)`), the target
/// a reference link resolved to when its source spells none, and where the
/// pointer is (global).
typedef SourceLinkHover = ({
  TokenKind kind,
  String raw,
  String? href,
  Offset position,
});

/// The source view's pointer: the mouse's press, drag and hover over the
/// note, the taps a click counts, and the cursor it shows (#505, #725).
///
/// The view owns it, wraps the note in [listen] and hands it the gestures
/// its detector sees; it places the caret, selects and asks the rest of the
/// view through the narrow callbacks it is handed.
final class SourcePointer {
  /// The pointer over the view's [_buffer] and [_selection].
  new({
    required this._buffer,
    required this._selection,
    required this._live,
    required this._mounted,
    required this._touch,
    required this._offsetAt,
    required this._onScrollbar,
    required this._hoverTable,
    required this._leaveTable,
    required this._taskBoxAt,
    required this._overTaskBox,
    required this._toggleTaskAt,
    required this._linkAt,
    required this._openLink,
    required this._linkHover,
    required this._requestKeyboard,
    required this._secondaryClick,
    required this._placeCaret,
    required this._extendTo,
    required this._select,
    required this._inCell,
    required this._holdSync,
  });

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// The caret.
  final SelectionModel Function() _selection;

  /// Whether the view draws `live`.
  final bool Function() _live;

  /// Whether the view is still mounted.
  final bool Function() _mounted;

  /// The selection by touch, which a finger's taps and long presses drive.
  final SourceTouchSelection _touch;

  /// The note offset a global point falls on, or null outside the text.
  final int? Function(Offset global) _offsetAt;

  /// Whether a global point is on the scrollbar's track (#1106).
  final bool Function(Offset global) _onScrollbar;

  /// Follows the mouse over the note's tables, with the offset under it.
  final void Function(int? offset, Offset global) _hoverTable;

  /// The mouse is off the table it was on.
  final VoidCallback _leaveTable;

  /// Whether a drawn task box is under a global point.
  final bool Function(Offset global) _taskBoxAt;

  /// Whether a drawn task box is under a global point, the offset under it
  /// already asked.
  final bool Function(int? offset, Offset global) _overTaskBox;

  /// Ticks the task box under a global point; whether there was one.
  final bool Function(Offset global) _toggleTaskAt;

  /// The link at an offset — its kind, its text as written, and a Markdown
  /// link's resolved target — or null.
  final (TokenKind, String, String?)? Function(int offset) _linkAt;

  /// Opens a link token, or null on a surface that follows no link.
  final void Function(TokenKind kind, String raw, String? href)? Function()
  _openLink;

  /// Told which link the pointer is on with the modifier held, or null on
  /// a surface that does not ask.
  final void Function(SourceLinkHover? hover)? Function() _linkHover;

  /// Asks for the focus and the keyboard.
  final VoidCallback _requestKeyboard;

  /// A right click at a global point.
  final void Function(Offset global) _secondaryClick;

  /// Puts the caret at an offset and keeps it on screen.
  final void Function(int offset) _placeCaret;

  /// Extends the selection to an offset.
  final void Function(int offset) _extendTo;

  /// Selects `[start, end)`, the wikilink panel left as it is.
  final void Function(int start, int end) _select;

  /// Where the caret goes from an offset in a table's room: the nearer
  /// cell's text.
  final int Function(int offset) _inCell;

  /// Holds the platform's copy of the selection while a drag runs, or lets
  /// it go.
  final void Function({required bool hold}) _holdSync;

  /// The pointer over the note: the text's, or the hand's over a task box a
  /// click ticks (#505). A notifier, not state, so crossing a box repaints the
  /// pointer alone and never rebuilds the note.
  final ValueNotifier<MouseCursor> cursor = ValueNotifier<MouseCursor>(
    SystemMouseCursors.text,
  );

  /// A press on a control `live` draws over the note — a fold arrow, a
  /// diagram and its buttons — so the pointer going down under it places no
  /// caret: the control answers the tap itself.
  bool _controlPress = false;

  /// The mouse press that went down opened a link ([_openLinkAt]), so the
  /// click it ends as is spent: placing the caret where it was let go would
  /// take the caret, and the view, back from wherever the link led — an
  /// anchor in the same note is lines away.
  bool _pressOpenedLink = false;

  /// The kind of the pointer that last went down: a long press or a tap by a
  /// finger is a touch gesture, by a mouse it is not.
  PointerDeviceKind? _lastPointerKind;

  /// Where the mouse last was over the note, or null when it left: the
  /// opening modifier going down re-asks the cursor about it (#725).
  Offset? _hoverPosition;

  /// How many taps have landed inside [_clickWindow], and when and where the
  /// last did.
  int _clicks = 0;
  DateTime? _lastClick;
  Offset? _lastClickAt;

  /// How long two taps may be apart and still be one gesture.
  static const Duration _clickWindow = Duration(milliseconds: 400);

  /// The offset a mouse drag started from, or null when no drag is running.
  int? _dragAnchor;

  /// Where a mouse press put the caret, for the click it ends as to keep:
  /// typewriter mode scrolls the caret's row to the middle as the button
  /// goes down, and the release, read again where the pointer is, landed
  /// a row further on (#544).
  int? _pressOffset;

  /// Whether the mouse went down on the scrollbar's strip (#1106): the drag
  /// belongs to the scrollbar, so the note takes no caret and no selection
  /// from it.
  bool _pressOnScrollbar = false;

  /// The link the pointer is on with the opening modifier held, as last told
  /// to [_linkHover]: a pointer moving along one link tells once.
  String? _hoveredLink;

  /// A press went down on a control `live` draws over the note — a fold
  /// arrow — which answers the tap itself.
  void controlPressed() => _controlPress = true;

  /// Whether a tap at [position], at [now], is the next of the last one's
  /// gesture: near it in time *and* in place. Two quick taps on different
  /// words are two carets, not a double click — counting time alone selected
  /// a word under the second tap and the next keystroke replaced it.
  bool followsLastClick(Offset position, DateTime now) {
    final last = _lastClick;
    final lastAt = _lastClickAt;
    return last != null &&
        lastAt != null &&
        now.difference(last) <= _clickWindow &&
        (position - lastAt).distance <= kDoubleTapSlop;
  }

  /// A tap the note's detector saw end.
  ///
  /// The keyboard is asked for on the *tap*: a drag the scroll view wins is
  /// someone reading, not someone about to type.
  void tapUp(TapUpDetails details) {
    // A mouse tap on the scrollbar's strip is the scrollbar's, not the
    // text's: no caret, no keyboard. A finger is the text's anywhere (#1106).
    if (details.kind == PointerDeviceKind.mouse &&
        _onScrollbar(details.globalPosition)) {
      _lastClick = null;
      return;
    }
    // A task box is ticked where it is drawn, and a tick is neither a caret
    // nor a reason to raise the keyboard; nor the first of a double click.
    if (_toggleTaskAt(details.globalPosition)) {
      _lastClick = null;
      return;
    }
    // The press opened a link: it placed the caret it meant to, and the
    // link may have moved it since.
    if (_pressOpenedLink) {
      _pressOpenedLink = false;
      _pressOffset = null;
      _lastClick = null;
      return;
    }
    _requestKeyboard();
    if (details.kind != PointerDeviceKind.mouse &&
        _touch.tap(details.globalPosition)) {
      return;
    }
    _tapUp(details.globalPosition);
  }

  /// A tap: one places the caret, two take the word under it, three take the
  /// line.
  ///
  /// The two- and three-tap selections come up with the touch handles and
  /// menu, as a long press does: on a phone a word the finger selected is a
  /// selection the finger can act on, whatever picked it (#291). A mouse's
  /// second click is a double click and keeps its menu for the right button,
  /// so the overlay is the finger's alone.
  ///
  /// Counted here rather than with `onDoubleTap`, because a triple click is a
  /// *third* tap and not a second double one, and because the count has to
  /// survive
  /// the caret moving between taps — which is exactly what happens.
  void _tapUp(Offset position) {
    final finger = _lastPointerKind != PointerDeviceKind.mouse;
    final offset = (finger ? null : _pressOffset) ?? _offsetAt(position);
    _pressOffset = null;
    if (offset == null) return;
    final now = DateTime.now();
    _clicks = followsLastClick(position, now) ? _clicks + 1 : 1;
    _lastClick = now;
    _lastClickAt = position;
    final buffer = _buffer();
    switch (_clicks) {
      case 1:
        // A Shift+click extended the selection as it went down.
        if (!finger && HardwareKeyboard.instance.isShiftPressed) break;
        // A click on a table's room puts the caret in the nearer cell.
        _placeCaret(_inCell(offset));
      case 2:
        // A word never crosses a line: the line's text, not the note's.
        final line = buffer.lineOf(offset);
        final lineStart = buffer.offsetOfLine(line);
        final text = buffer.lineAt(line);
        final (start, end) = wordRangeAt(text, offset - lineStart);
        _select(
          lineStart + math.min(start, text.length),
          lineStart + math.min(end, text.length),
        );
        if (finger) _touch.show(toolbar: true);
      default:
        final line = buffer.lineOf(offset);
        _select(
          buffer.offsetOfLine(line),
          buffer.offsetOfLine(line) + buffer.lineLengthAt(line),
        );
        _clicks = 0;
        if (finger) _touch.show(toolbar: true);
    }
  }

  /// A long press by a finger at [global]: [start] takes the word under it,
  /// a move extends by words. A mouse has its drag instead.
  void longPressAt(Offset global, {required bool start}) {
    if (_lastPointerKind == PointerDeviceKind.mouse) return;
    _touch.longPressAt(global, start: start);
  }

  /// A finger's long press let go: the toolbar comes up.
  void longPressEnd() {
    if (_lastPointerKind == PointerDeviceKind.mouse) return;
    _touch.show(toolbar: true);
  }

  /// The mouse left the note: the table's handles go, the cursor is the
  /// text's again, and no link is hovered.
  void exit() {
    _leaveTable();
    _hoverPosition = null;
    cursor.value = SystemMouseCursors.text;
    _reportLinkHover(null, Offset.zero);
  }

  /// [child] with mouse dragging selecting text.
  ///
  /// Mouse only, deliberately: on a phone a vertical drag on the text *scrolls*
  /// the note, and stealing that gesture to select would break the way people
  /// read. Selection by touch belongs to the platform's own handles, which is a
  /// separate piece of work.
  Widget listen(Widget child) => Listener(
    onPointerHover: (event) {
      // The scrollbar's strip belongs to the scrollbar: the pointer keeps the
      // arrow there, and neither the table nor the cursor is asked (#1106).
      if (_onScrollbar(event.position)) {
        _hoverPosition = null;
        _leaveTable();
        _reportLinkHover(null, Offset.zero);
        if (cursor.value != SystemMouseCursors.basic) {
          cursor.value = SystemMouseCursors.basic;
        }
        return;
      }
      // The offset under the pointer is one question, asked once and shared:
      // both the table and the cursor read it (#505). Outside `live` there is
      // no box and no table, and neither the offset nor the note is touched —
      // unless the opening modifier is down, when the cursor asks about the
      // link under the pointer (#725).
      _hoverPosition = event.position;
      final offset = _live() || linkModifier()
          ? _offsetAt(event.position)
          : null;
      _hoverTable(offset, event.position);
      _hoverCursorAt(offset, event.position);
    },
    onPointerDown: (event) {
      _lastPointerKind = event.kind;
      _pressOffset = null;
      _pressOpenedLink = false;
      if (event.kind == PointerDeviceKind.mouse &&
          _onScrollbar(event.position)) {
        // The scrollbar takes the drag; the note takes nothing (#1106).
        _pressOnScrollbar = true;
        _hoverPosition = null;
        return;
      }
      _pressOnScrollbar = false;
      _trackMouse(event);
      // A mouse asks for the keyboard as it goes down, which is where a click
      // starts a drag; a finger asks on the tap (`onTapUp`), so a finger that
      // only scrolls the note does not bring the keyboard up.
      if (event.kind != PointerDeviceKind.mouse) return;
      _touch.hide();
      _requestKeyboard();
      if (_controlPress) {
        _controlPress = false;
        return;
      }
      if (event.buttons == kSecondaryMouseButton) {
        _secondaryClick(event.position);
        return;
      }
      if (event.buttons != kPrimaryMouseButton) return;
      // A press on a task box ticks it when it is let go (`_tapUp`): it
      // neither places a caret nor starts a selection.
      if (_taskBoxAt(event.position)) return;
      final offset = _pressOffset = _offsetAt(event.position);
      if (offset == null) return;
      if (_openLinkAt(offset)) {
        _pressOpenedLink = true;
        return;
      }
      // Shift+click extends the selection from its anchor to the click, and
      // a drag from there goes on extending it (#546).
      if (HardwareKeyboard.instance.isShiftPressed) {
        _dragAnchor = _selection().anchor;
        _extendTo(offset);
      } else {
        _dragAnchor = offset;
        _placeCaret(offset);
      }
      // The platform needs the selection the drag ends with, not every one on
      // the way: a whole note per mouse move is what a drag must not cost.
      _holdSync(hold: true);
    },
    onPointerMove: (event) {
      if (_pressOnScrollbar) return;
      _trackMouse(event);
      final anchor = _dragAnchor;
      if (anchor == null) return;
      if (event.kind != PointerDeviceKind.mouse) return;
      final offset = _offsetAt(event.position);
      if (offset == null) return;
      _select(anchor, offset);
    },
    onPointerUp: (event) {
      if (_pressOnScrollbar) {
        _pressOnScrollbar = false;
        return;
      }
      _trackMouse(event);
      _endDrag();
    },
    onPointerCancel: (_) {
      _pressOnScrollbar = false;
      _endDrag();
    },
    child: child,
  );

  /// Keeps [_hoverPosition] where the mouse is while a button is down too:
  /// a press and a drag send no hover, and the modifier going down after a
  /// drag asked the cursor about where the drag began — the hand over plain
  /// text, where a click opens nothing (#787).
  void _trackMouse(PointerEvent event) {
    if (event.kind == PointerDeviceKind.mouse) _hoverPosition = event.position;
  }

  /// A Ctrl+click (Cmd on a Mac) on a link at [offset]: the caret goes there
  /// and the link opens, the legacy editor's T-M3-07. True when it did.
  bool _openLinkAt(int offset) {
    final open = _openLink();
    if (open == null) return false;
    if (!linkModifier()) return false;
    final link = _linkAt(offset);
    if (link == null) return false;
    _placeCaret(offset);
    open(link.$1, link.$2, link.$3);
    return true;
  }

  void _endDrag() {
    _dragAnchor = null;
    _holdSync(hold: false);
  }

  /// A pointer went down on a diagram `live` draws (#530). A mouse's
  /// primary button would place the caret under it as it goes down — in the
  /// block, revealing its source and taking the diagram, and the button the
  /// pointer is on, away before it is let go; the diagram answers the click
  /// instead.
  void diagramDown(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.mouse) return;
    if (event.buttons != kPrimaryMouseButton) return;
    _controlPress = true;
  }

  /// Whether the opening modifier is held: Control, or Command on a Mac.
  static bool linkModifier() {
    final keyboard = HardwareKeyboard.instance;
    return defaultTargetPlatform == TargetPlatform.macOS
        ? keyboard.isMetaPressed
        : keyboard.isControlPressed;
  }

  /// The modifier went down or up while the pointer sat still: the cursor
  /// answers it where it is, without a move to wait for (#725).
  bool modifierChanged(KeyEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.controlLeft &&
        event.logicalKey != LogicalKeyboardKey.controlRight &&
        event.logicalKey != LogicalKeyboardKey.metaLeft &&
        event.logicalKey != LogicalKeyboardKey.metaRight) {
      return false;
    }
    final point = _hoverPosition;
    if (point != null && _mounted()) {
      final offset = _live() || linkModifier() ? _offsetAt(point) : null;
      _hoverCursorAt(offset, point);
    }
    return false;
  }

  /// Points the mouse's cursor at what is under it: the hand over a drawn task
  /// box, which a click ticks, or over a link the opening modifier would open
  /// (#505, #725), the text's everywhere else.
  ///
  /// [offset] is the offset under the pointer, computed once by the hover
  /// handler and shared with the table's hover.
  void _hoverCursorAt(int? offset, Offset global) {
    final next = _overTaskBox(offset, global) || _overLink(offset)
        ? SystemMouseCursors.click
        : SystemMouseCursors.text;
    if (cursor.value != next) cursor.value = next;
    _reportLinkHover(offset, global);
  }

  /// Tells [_linkHover] which link the pointer is on — only with the
  /// modifier down, which is the intent to open it — or that it is on none.
  /// Asked of the same line [_overLink] reads, so a hover costs no scan of
  /// the note.
  void _reportLinkHover(int? offset, Offset global) {
    final report = _linkHover();
    if (report == null) return;
    final link = offset != null && linkModifier() ? _linkAt(offset) : null;
    final key = link == null ? null : '${link.$1.name}|${link.$2}';
    if (key == _hoveredLink) return;
    _hoveredLink = key;
    report(
      link == null
          ? null
          : (kind: link.$1, raw: link.$2, href: link.$3, position: global),
    );
  }

  /// Whether the opening modifier over [offset] would open a link: the very
  /// predicate the Ctrl+click runs ([_openLinkAt]), so the hand and the click
  /// cannot disagree (#725). [_linkAt] reads the one line the offset is on.
  bool _overLink(int? offset) {
    if (offset == null || _openLink() == null) return false;
    if (!linkModifier()) return false;
    return _linkAt(offset) != null;
  }

  /// Lets the cursor go.
  void dispose() => cursor.dispose();
}
