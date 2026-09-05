import 'package:copist/src/core/logging.dart';
import 'package:copist/src/editor/caret_geometry.dart';
import 'package:copist/src/editor/caret_painter.dart';
import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/editor_gestures.dart';
import 'package:copist/src/editor/hit_test.dart';
import 'package:copist/src/editor/note_editor_client.dart';
import 'package:copist/src/editor/row_model.dart';
import 'package:copist/src/editor/selection_delegate.dart';
import 'package:copist/src/editor/selection_handles.dart';
import 'package:copist/src/editor/virtualized_text_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The interactive line editor (M2a E8d): a virtualized text view over a
/// [ComposingInput], driven by the platform IME through [NoteEditorClient].
///
/// [initialText] is the note content. [onTextChanged] fires with the full
/// buffer text after every *text* edit (autosave subscribes to it; selection
/// and composing-only changes do not fire it). The [focusNode] shows/hides
/// the IME and lets the owner save on focus loss.
///
/// The view owns the [TextInputConnection] (attached on focus); the client
/// reports the values it must push back through [NoteEditorClient.onPushValue].
final class NoteEditor extends StatefulWidget {
  /// Creates the editor over [initialText].
  ///
  /// [input] is a test seam: when given, it is used as the buffer instead of
  /// creating one from [initialText], so a test can drive
  /// [ComposingInput.apply] directly.
  const NoteEditor({
    required this.initialText,
    required this.focusNode,
    required this.onTextChanged,
    this.columns = 80,
    this.input,
    super.key,
  });

  /// The note content the editor starts with (ignored when [input] is given).
  final String initialText;

  /// The focus node; the IME shows on focus and hides on blur.
  final FocusNode focusNode;

  /// Fires with the full buffer text after every text edit.
  final ValueChanged<String> onTextChanged;

  /// The maximum monospace grid width in characters (the visual-row wrap
  /// width). The editor derives the actual width from the viewport — the
  /// wider wrap would clip rows and park the caret off-screen (M2a
  /// on-device round 2) — so this caps it, e.g. at 80 on a wide desktop
  /// window.
  final int columns;

  /// The buffer to edit, or null to create one from [initialText].
  @visibleForTesting
  final ComposingInput? input;

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

final class _NoteEditorState extends State<NoteEditor> {
  static const AppLogger _log = AppLogger(name: 'editor');

  late final ComposingInput _input;
  late final NoteEditorClient _client;
  late final double _charWidth;
  late final double _caretHeight;
  late RowModel _rows;
  late CaretGeometry _caretGeometry;
  late HitTest _hitTest;
  late final EditorGestures _gestures;
  late final ScrollController _scrollController;
  late final SelectionHandles _handles;

  /// The anchor of the selection handles/toolbar: the scroll viewport box
  /// (the endpoint offsets and the toolbar are relative to it).
  final GlobalKey _viewportKey = GlobalKey();
  TextInputConnection? _connection;
  int _lastRevision = -1;
  int _appliedColumns = -1;
  bool _rebuildingColumns = false;

  /// The columns the previous layout also asked for. A width change must
  /// hold for two consecutive layouts before a re-wrap: the app resume and
  /// the keyboard in/out transiently relayout at odd widths, and a re-wrap
  /// moves every row — the caret jumped into the middle of a word on screen
  /// (M2a on-device round 3).
  int? _pendingColumns;

  /// Whether the initial `widget.columns` → viewport-fit re-wrap already
  /// happened (it is applied immediately; only later width changes are
  /// debounced).
  bool _didInitialColumnsFit = false;

  /// The last selection pushed to the IME (the gesture pushes skip an
  /// unchanged selection — the platform already holds it).
  TextSelection? _lastPushedSelection;

  @override
  void initState() {
    super.initState();
    _input = widget.input ?? ComposingInput(widget.initialText);
    _client = NoteEditorClient(
      input: _input,
      onPushValue: _pushValue,
      onAction: _onAction,
      onConnectionClosed: _onConnectionClosed,
    );
    final initClock = Stopwatch()..start();
    _charWidth = VirtualizedTextView.measureCharWidth();
    _caretHeight = VirtualizedTextView.measureCaretHeight();
    _rows = RowModel(_input.buffer, columns: widget.columns);
    _appliedColumns = widget.columns;
    _log.debug(
      'editor ready: ${_input.textLength} chars, ${_rows.rowCount} rows, '
      'columns $_appliedColumns, in '
      '${_ms(initClock.elapsedMicroseconds)} ms',
    );
    _caretGeometry = _geometryFor(_rows);
    _hitTest = _hitTestFor(_rows);
    _gestures = EditorGestures(hitTest: _hitTest, input: _input);
    _scrollController = ScrollController();
    _handles = SelectionHandles(
      input: _input,
      delegate: NoteSelectionDelegate(
        input: _input,
        onSelectAll: _selectAll,
        onCut: _cutSelection,
        onPaste: _pasteText,
        onBringIntoView: _bringIntoView,
        onHide: _hideSelectionUi,
      ),
      commitSelection: _pushSelection,
    );
    _lastRevision = _input.revision;
    _input.addListener(_onChange);
    widget.focusNode.addListener(_onFocusChanged);
    _scrollController.addListener(_onScroll);
  }

  CaretGeometry _geometryFor(RowModel rows) => CaretGeometry(
    rowModel: rows,
    charWidth: _charWidth,
    rowHeight: VirtualizedTextView.rowHeight,
    leftPadding: VirtualizedTextView.leftPadding,
    caretHeight: _caretHeight,
  );

  HitTest _hitTestFor(RowModel rows) => HitTest(
    rows: rows,
    rowHeight: VirtualizedTextView.rowHeight,
    charWidth: _charWidth,
  );

  void _onScroll() {
    if (mounted) setState(() {});
  }

  /// Scrolls so the caret's row is visible (the caret scroll sync): if the
  /// row is above the viewport, scroll it to the top; if below, to the
  /// bottom. No-op when the row is already visible.
  void _syncCaretScroll() {
    final caret = _input.caret;
    if (caret == null || !_scrollController.hasClients) return;
    final row = _rows.offsetToRowColumn(caret).$1;
    const rowHeight = VirtualizedTextView.rowHeight;
    final rowTop = row * rowHeight;
    final rowBottom = (row + 1) * rowHeight;
    final pos = _scrollController.position;
    final scrollClock = Stopwatch()..start();
    if (rowTop < pos.pixels) {
      pos.jumpTo(rowTop);
      _log.debug(
        'caret scroll: row $row to top in '
        '${_ms(scrollClock.elapsedMicroseconds)} ms',
      );
    } else if (rowBottom > pos.pixels + pos.viewportDimension) {
      pos.jumpTo(rowBottom - pos.viewportDimension);
      _log.debug(
        'caret scroll: row $row to bottom in '
        '${_ms(scrollClock.elapsedMicroseconds)} ms',
      );
    }
  }

  double get _scrollOffset =>
      _scrollController.hasClients ? _scrollController.offset : 0;

  /// The pointer's x relative to the text start (the [HitTest] contract is
  /// "x from the first glyph", so the row's left inset is subtracted).
  double _textX(double localX) => localX - VirtualizedTextView.leftPadding;

  /// A tap (no drag) places the caret at the tapped position.
  void _handleTapUp(TapUpDetails details) {
    _focusEditor();
    final changed = _gestures.tapAt(
      _textX(details.localPosition.dx),
      details.localPosition.dy + _scrollOffset,
    );
    _logGesture('tap', details.localPosition, changed);
    if (changed) _pushSelection();
  }

  /// A long-press selects the word under the pointer (the long-press
  /// contract); the selection persists after release (a tap clears it), and
  /// a drag extending it arrives as long-press pan updates.
  void _handleLongPressStart(LongPressStartDetails details) {
    _focusEditor();
    final changed = _gestures.longPressAt(
      _textX(details.localPosition.dx),
      details.localPosition.dy + _scrollOffset,
    );
    _logGesture('longPress', details.localPosition, changed);
    if (changed) _pushSelection();
  }

  /// Extends the long-press selection to the pointer (the anchor stays at
  /// the long-press end).
  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) =>
      _handleDragMove('longPressDrag', details.localPosition);

  /// A drag begins a selection anchored at the drag start. No IME push
  /// here: the drag end pushes the final selection (a full-text push at
  /// novel length is a platform round trip — pushing at pointer-move rate
  /// froze the app, M2a on-device round 3).
  void _handlePanStart(DragStartDetails details) {
    _focusEditor();
    final changed = _gestures.dragStartAt(
      _textX(details.localPosition.dx),
      details.localPosition.dy + _scrollOffset,
    );
    _logGesture('dragStart', details.localPosition, changed);
  }

  /// A drag move extends the selection to the pointer (no IME push — see
  /// [_handlePanStart]).
  void _handlePanUpdate(DragUpdateDetails details) =>
      _handleDragMove('drag', details.localPosition);

  /// The drag ends: the selection collapses to its caret (the E8a
  /// drag-select contract; a persistent selection is a later sub-step), and
  /// the final selection is pushed to the IME.
  void _handlePanEnd(DragEndDetails details) => _handleDragEnd('dragEnd');

  /// A long-press drag ends (the finger lifts): the long-press selection
  /// persists (no collapse), but its moves did not push — land the final
  /// selection so the next keystroke edits it.
  void _handleLongPressEnd(LongPressEndDetails details) {
    _pushSelection();
  }

  /// The drag-end path: collapse the drag selection to its caret and push
  /// the change to the IME.
  void _handleDragEnd(String tag) {
    final changed = _gestures.dragEnd();
    _logGesture(tag, null, changed);
    if (changed) _pushSelection();
  }

  /// The plain-drag move path: extends the selection to the pointer (no IME
  /// push — see [_handlePanStart]).
  void _handleDragMove(String tag, Offset local) {
    final changed = _gestures.dragTo(
      _textX(local.dx),
      local.dy + _scrollOffset,
    );
    _logGesture(tag, local, changed);
  }

  /// The gesture diagnostic: the pointer position (with the scroll offset —
  /// the mapping the hit test used), the resulting caret or selection (with
  /// its visual row/column), and whether it changed.
  void _logGesture(String tag, Offset? local, bool changed) {
    final selection = _input.selection;
    final where = local == null
        ? '-'
        : '(${local.dx.toStringAsFixed(1)}, ${local.dy.toStringAsFixed(1)}) '
          'scroll ${_scrollOffset.toStringAsFixed(1)}';
    _log.debug(
      '$tag: $where -> ${_describeSelection(selection)}'
      '${changed ? '' : ' (unchanged)'}',
    );
  }

  String _describeSelection(TextSelection selection) {
    if (!selection.isValid) return 'none';
    final (row, col) = _rows.offsetToRowColumn(
      selection.isCollapsed ? selection.baseOffset : selection.start,
    );
    return selection.isCollapsed
        ? 'caret ${selection.baseOffset} (row $row col $col)'
        : 'selection ${selection.start}..${selection.end} '
          '(row $row col $col)';
  }

  void _focusEditor() {
    if (!widget.focusNode.hasFocus) {
      widget.focusNode.requestFocus();
    }
  }

  /// Pushes the current value to the IME after a gesture-driven selection
  /// change. The platform's copy must match ours, or the next keystroke
  /// edits the stale platform selection instead of the caret the user sees
  /// (the M2a on-device round-2 data-loss bug). Skips an unchanged
  /// selection (the platform already holds it — a full-text push is a
  /// platform round trip at novel length).
  void _pushSelection() {
    final selection = _input.selection;
    if (selection == _lastPushedSelection) return;
    _pushValue(_input.value);
  }

  /// The standard selection toolbar actions (the [NoteSelectionDelegate]
  /// wiring): select-all commits the selection to the IME; cut and paste
  /// mutate the buffer directly and re-sync it with a full value push (the
  /// lockstep discipline).
  void _selectAll() {
    _input.setSelection(
      TextSelection(baseOffset: 0, extentOffset: _input.textLength),
    );
    _pushSelection();
  }

  void _cutSelection() {
    _input
      ..deleteSelection()
      ..commitDirectEdit();
    _pushValue(_input.value);
    // The cut cause contract: the (collapsed) selection is scrolled into
    // view.
    _syncCaretScroll();
  }

  Future<void> _pasteText(String text) async {
    _input
      ..replaceSelection(text)
      ..commitDirectEdit();
    _pushValue(_input.value);
  }

  /// The toolbar's bring-into-view: scrolls so the position's row is
  /// visible (no selection change — the platform contract for the toolbar
  /// path).
  void _bringIntoView(TextPosition position) {
    if (!_scrollController.hasClients) return;
    final row = _rows.offsetToRowColumn(position.offset).$1;
    const rowHeight = VirtualizedTextView.rowHeight;
    final rowTop = row * rowHeight;
    final rowBottom = rowTop + rowHeight;
    final pos = _scrollController.position;
    if (rowTop < pos.pixels) {
      pos.jumpTo(rowTop);
    } else if (rowBottom > pos.pixels + pos.viewportDimension) {
      pos.jumpTo(rowBottom - pos.viewportDimension);
    }
  }

  void _hideSelectionUi() => _handles.hide();

  /// Syncs the standard selection handles/toolbar ([SelectionHandles]) with
  /// the current selection + geometry; the call site is build (idempotent,
  /// and the overlay show is deferred to a post-frame inside).
  void _updateSelectionUi() {
    final context = _viewportKey.currentContext;
    final viewport = context?.findRenderObject() as RenderBox?;
    if (context == null || viewport == null) return;
    final wasShown = _handles.shown;
    _handles.update(
      context: context,
      viewport: viewport,
      selection: _input.selection,
      geometry: _caretGeometry,
      scrollOffset: _scrollOffset,
      offsetAtPointer: _offsetAtPointer,
    );
    if (_handles.shown != wasShown) {
      _log.info(
        'selection ui ${_handles.shown ? 'shown' : 'hidden'} '
        '(selection: ${_input.selection})',
      );
    }
  }

  /// Maps a global pointer position to a buffer offset (the handle-drag
  /// mapping): global → viewport-local → content (with the scroll offset) →
  /// the same hit test the tap/long-press gestures use.
  int _offsetAtPointer(Offset global) {
    final context = _viewportKey.currentContext;
    if (context == null) return 0;
    final box = context.findRenderObject()! as RenderBox;
    final local = box.globalToLocal(global);
    return _hitTest.offsetAt(_textX(local.dx), local.dy + _scrollOffset);
  }

  /// Forwards a value to the platform (a resync from the client, the
  /// focus-attach sync, or a gesture-driven selection change).
  void _pushValue(TextEditingValue value) {
    final clock = Stopwatch()..start();
    _connection?.setEditingState(value);
    _lastPushedSelection = value.selection;
    _log.debug(
      'ime push: ${value.text.length} chars, '
      '${_describeSelection(value.selection)} in '
      '${_ms(clock.elapsedMicroseconds)} ms',
    );
  }

  void _onAction(TextInputAction action) {
    // IME-action handling (newline / done) is a later sub-step.
  }

  void _onConnectionClosed() {
    // The platform dismissed the keyboard; the connection is already closed.
  }

  void _onFocusChanged() {
    if (widget.focusNode.hasFocus) {
      // multiline: the default (TextInputType.text) is a single-line field,
      // whose keyboard offers a checkmark (done) instead of Enter (the M2a
      // on-device round-2 keyboard complaint). No suggestion pipeline: on
      // the 931K note every push drove the IME's suggestion strip, which
      // blocked the Android main thread ~2 s per push (M2a round 3) — flip
      // `enableSuggestions` back if the trade is not wanted.
      final connection = TextInput.attach(
        _client,
        const TextInputConfiguration(
          inputType: TextInputType.multiline,
          enableSuggestions: false,
        ),
      );
      _connection = connection;
      final clock = Stopwatch()..start();
      connection
        ..setEditingState(_input.value)
        ..show();
      _log.info(
        'ime focus: attached, pushed ${_input.textLength} chars in '
        '${_ms(clock.elapsedMicroseconds)} ms',
      );
    } else {
      _log.info('ime focus: connection closed');
      _connection?.close();
      _connection = null;
      // Blur hides the selection UI (the selection persists in the buffer).
      _handles.hide();
    }
    if (mounted) setState(() {});
  }

  void _onChange() {
    final clock = Stopwatch()..start();
    _rows.sync();
    final foldMs = _ms(clock.elapsedMicroseconds);
    final revision = _input.revision;
    final textChanged = revision != _lastRevision;
    _lastRevision = revision;
    if (!mounted) return;
    _syncCaretScroll();
    setState(() {});
    if (textChanged) {
      _log.debug(
        'keystroke: fold $foldMs ms, '
        '${_ms(clock.elapsedMicroseconds)} ms total, '
        '${_input.textLength} chars, ${_rows.rowCount} rows',
      );
      widget.onTextChanged(_input.text);
    }
  }

  /// Formats [microseconds] as a milliseconds string (2 decimals), for the
  /// [AppLogger] performance diagnostics.
  static String _ms(int microseconds) =>
      (microseconds / 1000).toStringAsFixed(2);

  @override
  void dispose() {
    _connection?.close();
    _handles.dispose();
    widget.focusNode.removeListener(_onFocusChanged);
    _input.removeListener(_onChange);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Re-wraps the model at the grid width that fits [maxWidth] — but only
  /// when the new width is stable (held for two consecutive layouts): the
  /// app resume and the keyboard in/out transiently relayout at odd widths,
  /// and a re-wrap moves every row (the caret jumped into the middle of a
  /// word on screen, M2a on-device round 3). The initial `widget.columns`
  /// → viewport fit is applied immediately (it is the one expected
  /// re-wrap, before any interaction).
  void _applyColumnsIfChanged(double maxWidth) {
    if (!maxWidth.isFinite || _rebuildingColumns) return;
    final columns = _fitColumns(maxWidth);
    if (columns == _appliedColumns) {
      _pendingColumns = null;
      return;
    }
    if (!_didInitialColumnsFit) {
      _didInitialColumnsFit = true;
      _scheduleColumnsRebuild(columns);
      return;
    }
    if (_pendingColumns == columns) {
      _scheduleColumnsRebuild(columns);
    } else {
      _pendingColumns = columns;
    }
  }

  /// Re-wraps to [columns] after the current frame (a model swap during
  /// build is not legal), keeping the caret visible — the caret's row moves
  /// with the re-wrap.
  void _scheduleColumnsRebuild(int columns) {
    _pendingColumns = null;
    _rebuildingColumns = true;
    final previous = _appliedColumns;
    final clock = Stopwatch()..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rebuildingColumns = false;
      if (!mounted) return;
      setState(() {
        _rows = RowModel(_input.buffer, columns: columns);
        _appliedColumns = columns;
        _caretGeometry = _geometryFor(_rows);
        _hitTest = _hitTestFor(_rows);
      });
      _log.info(
        'columns: $previous -> $columns (re-wrap '
        '${_ms(clock.elapsedMicroseconds)} ms)',
      );
      _syncCaretScroll();
    });
  }

  /// The wrap width for a `maxWidth`-px viewport: what is visible, capped by
  /// `widget.columns` (the 80-column design width on wide windows).
  int _fitColumns(double maxWidth) {
    final fit = ((maxWidth - VirtualizedTextView.leftPadding) / _charWidth)
        .floor();
    return fit.clamp(1, widget.columns);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _applyColumnsIfChanged(constraints.maxWidth);
        final caret = _input.caret;
        // The caret is steady (no blink yet); it shows only while the editor
        // is focused and the IME is not mid-composition (the underline takes
        // over).
        final caretVisible =
            caret != null && widget.focusNode.hasFocus && !_input.isComposing;
        final theme = Theme.of(context);
        // The theme's caret color (falling back to the scheme's primary, as
        // MaterialApp does) so the caret is visible on light and dark themes
        // alike.
        final caretColor =
            theme.textSelectionTheme.cursorColor ?? theme.colorScheme.primary;
        _updateSelectionUi();
        final startAnchor = _handles.startAnchor;
        final endAnchor = _handles.endAnchor;
        return Focus(
          focusNode: widget.focusNode,
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: _handleTapUp,
                onLongPressStart: _handleLongPressStart,
                onLongPressMoveUpdate: _handleLongPressMoveUpdate,
                onLongPressEnd: _handleLongPressEnd,
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: CompositedTransformTarget(
                  key: _viewportKey,
                  link: _handles.toolbarLayerLink,
                  child: VirtualizedTextView(
                    model: _rows,
                    scrollController: _scrollController,
                  ),
                ),
              ),
              // The handle links' leaders, at the selection's endpoints
              // (the zero-size `LeaderLayer`s a `RenderEditable` paints,
              // as widgets): the handles follow these.
              if (startAnchor != null)
                Positioned(
                  left: startAnchor.dx,
                  top: startAnchor.dy,
                  child: CompositedTransformTarget(
                    link: _handles.startHandleLayerLink,
                    // 1×1 (a zero-size box paints nothing, which would leave
                    // the link unlinked and the handle hidden):
                    child: const SizedBox(width: 1, height: 1),
                  ),
                ),
              if (endAnchor != null)
                Positioned(
                  left: endAnchor.dx,
                  top: endAnchor.dy,
                  child: CompositedTransformTarget(
                    link: _handles.endHandleLayerLink,
                    child: const SizedBox(width: 1, height: 1),
                  ),
                ),
              IgnorePointer(
                child: CustomPaint(
                  painter: CaretPainter(
                    geometry: _caretGeometry,
                    caretOffset: caret ?? 0,
                    composing: _input.composing,
                    caretVisible: caretVisible,
                    selection: _input.selection,
                    caretColor: caretColor,
                    scrollOffset: _scrollOffset,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
