import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:niman/src/editor/context_menu_items.dart';
import 'package:niman/src/editor/editor_context_menu.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/edit/touch_selection.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The source view's selection by touch (#291): the handles of a range a
/// finger made, the toolbar over it, and the gestures that bring them — a
/// long press on a word, a tap on the caret, a handle dragged.
///
/// The view owns it, hands it the gestures and listens to it: it notifies
/// when the handles or the toolbar come or go, and the view rebuilds. It
/// selects through the view's own setter ([_select]).
final class SourceTouchSelection extends ChangeNotifier {
  /// The touch selection over the view's [_buffer] and [_selection].
  new({
    required this._buffer,
    required this._selection,
    required this._select,
    required this._offsetAt,
    required this._requestKeyboard,
    required this._caretRectAt,
    required this._followsLastClick,
    required this._clipboardItems,
    required this._spellingItems,
    required this._formats,
    required this._structure,
    required this._table,
  });

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// The caret.
  final SelectionModel Function() _selection;

  /// Selects a range, and tells whoever needs to know.
  final void Function(SelectionModel next) _select;

  /// The note offset under a global point, or null off the text.
  final int? Function(Offset global) _offsetAt;

  /// Takes the focus and asks for the keyboard.
  final VoidCallback _requestKeyboard;

  /// The caret rectangle at an offset, in global coordinates, or null while
  /// its line is not built.
  final Rect? Function(int offset) _caretRectAt;

  /// Whether a tap at a global point is the second of a double tap.
  final bool Function(Offset global) _followsLastClick;

  /// The clipboard's buttons, closing the toolbar before they act.
  final List<ContextMenuButtonItem> Function(VoidCallback dismiss)
  _clipboardItems;

  /// The spelling's buttons for the word at the caret.
  final List<ContextMenuButtonItem> Function(VoidCallback dismiss)
  _spellingItems;

  /// The toolbar's formats, for the toolbar's overflow.
  final List<FormatMenuEntry> Function() _formats;

  /// The editor's grouped menu, when it has one.
  final ContextMenuPart? Function() _structure;

  /// What can be done to the table the caret is in, or null outside one.
  final ContextMenuPart? Function() _table;

  /// The overlay the handles and the toolbar are drawn in.
  final OverlayPortalController overlay = OverlayPortalController();

  /// Ticks when the overlay should build again: its handles and toolbar hang
  /// from the selected line's paragraph, and the frame that shows them can
  /// find it detached — a rebuild (the keyboard coming up, a reveal) in the
  /// same frame (#291).
  final ValueNotifier<int> tick = ValueNotifier<int>(0);

  /// How many frames the overlay has asked to be built again, and whether
  /// one such ask is already queued.
  int _frames = 0;
  bool _scheduled = false;

  /// How many frames the overlay keeps asking ([show] resets it): enough for
  /// the keyboard's rise and a sliver's round of rebuilds, and short enough
  /// that a selection off screen stops asking.
  static const int _retryFrames = 30;

  /// Whether the selection was made by touch and shows its handles.
  bool _handles = false;

  /// Whether the touch toolbar (copy, cut, paste, select all) is up.
  bool _toolbar = false;

  /// The word the long press started on, held while the finger moves.
  (int, int)? _longPressWord;

  /// Whether the view this serves is gone.
  bool _disposed = false;

  /// Whether the handles or the toolbar are up.
  bool get isUp => _handles || _toolbar;

  @override
  void dispose() {
    _disposed = true;
    tick.dispose();
    super.dispose();
  }

  /// The handles and toolbar for the selection as it stands.
  Widget buildOverlay() {
    final selection = _selection().clampTo(_buffer().length);
    final collapsed = selection.isCollapsed;
    final start = _caretRectAt(selection.start);
    final end = _caretRectAt(selection.end);
    // A line the frame has not laid out yet has no paragraph to hang from:
    // the overlay is empty, and it asks again next frame (#291).
    if ((_handles || _toolbar) && (start == null || end == null)) {
      _retry();
    }
    // The toolbar is the context menu's phone face: the same clipboard, the
    // toolbar's formats in its overflow, the spelling after them.
    return TouchSelectionOverlay(
      start: start,
      end: end,
      showHandles: _handles && !collapsed,
      showToolbar: _toolbar,
      buttons: _clipboardItems(hide),
      formats: _toolbar ? _formats() : const <FormatMenuEntry>[],
      structure: _toolbar ? _structure() : null,
      extras: _toolbar ? _spellingItems(hide) : const <ContextMenuButtonItem>[],
      table: _toolbar ? _table() : null,
      onDismiss: hide,
      onHandleDrag: _dragHandle,
      onHandleDragEnd: () => show(toolbar: true),
    );
  }

  /// Shows the touch selection: the handles for a range, and the toolbar when
  /// [toolbar] asks for it.
  void show({required bool toolbar}) {
    _frames = 0;
    _handles = !_selection().isCollapsed;
    _toolbar = toolbar;
    notifyListeners();
    overlay.show();
    // The frame that shows the handles is the one the gesture landed in; the
    // next one has the note laid out where the gesture left it.
    _retry();
  }

  /// Asks the overlay to build again after this frame: the handles and the
  /// toolbar hang from the selected line's paragraph, and the frame that
  /// shows them can find it detached — the keyboard rising relayouts the
  /// pane and a reveal rebuilds the line — so the overlay is drawn once,
  /// empty, with nothing to build it again when the paragraph is back
  /// (#291). Bounded, so a selection that is off screen stops asking.
  void _retry() {
    if (_scheduled || _frames >= _retryFrames) return;
    _scheduled = true;
    _frames++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!_disposed && (_handles || _toolbar)) {
        tick.value++;
      }
    });
  }

  /// Takes the handles and toolbar away.
  void hide() {
    if (!_handles && !_toolbar) return;
    _handles = false;
    _toolbar = false;
    if (!_disposed) notifyListeners();
    overlay.hide();
  }

  /// A finger's tap at [global], when it means something to the touch
  /// selection: a tap on the caret brings the toolbar up (to paste), a tap
  /// anywhere else puts it and the handles away. True when the tap was
  /// taken.
  bool tap(Offset global) {
    if (_followsLastClick(global)) {
      // The second tap of a double tap: the word, not the toolbar.
      hide();
      return false;
    }
    final offset = _offsetAt(global);
    final selection = _selection();
    if (offset != null &&
        selection.isCollapsed &&
        offset == selection.extent &&
        !_toolbar) {
      show(toolbar: true);
      return true;
    }
    hide();
    return false;
  }

  /// A long press at [global]: the word under it, or — while the finger moves
  /// — the selection from the first word to the word under it now.
  void longPressAt(Offset global, {required bool start}) {
    final offset = _offsetAt(global);
    if (offset == null) return;
    final buffer = _buffer();
    final line = buffer.lineOf(offset);
    final lineStart = buffer.offsetOfLine(line);
    final text = buffer.lineAt(line);
    final (from, to) = wordRangeAt(text, offset - lineStart);
    final wordStart = lineStart + math.min<int>(from, text.length);
    final wordEnd = lineStart + math.min<int>(to, text.length);
    final word = (wordStart, wordEnd);
    if (start) {
      _longPressWord = word;
      _requestKeyboard();
      _select(SelectionModel(anchor: word.$1, extent: word.$2));
      show(toolbar: false);
      return;
    }
    final first = _longPressWord ?? word;
    final next = word.$2 >= first.$2
        ? SelectionModel(anchor: first.$1, extent: word.$2)
        : SelectionModel(anchor: first.$2, extent: word.$1);
    _select(next);
    show(toolbar: false);
  }

  /// A handle dragged to [point]: that end of the selection follows the
  /// finger, through the same hit test a tap uses.
  void _dragHandle(SelectionHandle handle, Offset point) {
    final offset = _offsetAt(point);
    if (offset == null) return;
    final selection = _selection();
    final next = handle == SelectionHandle.start
        ? SelectionModel(anchor: selection.end, extent: offset)
        : SelectionModel(anchor: selection.start, extent: offset);
    // An empty selection has no handles to hold: the dragged end stops one
    // character short of the other.
    if (next.isCollapsed) return;
    _select(next);
    _handles = true;
    _toolbar = false;
    notifyListeners();
  }
}
