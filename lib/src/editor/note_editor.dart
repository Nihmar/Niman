import 'package:copist/src/core/logging.dart';
import 'package:copist/src/editor/caret_geometry.dart';
import 'package:copist/src/editor/caret_painter.dart';
import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/editor_gestures.dart';
import 'package:copist/src/editor/hit_test.dart';
import 'package:copist/src/editor/note_editor_client.dart';
import 'package:copist/src/editor/row_model.dart';
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
  late RowModel _rows;
  late CaretGeometry _caretGeometry;
  late HitTest _hitTest;
  late final EditorGestures _gestures;
  late final ScrollController _scrollController;
  TextInputConnection? _connection;
  int _lastRevision = -1;
  int _appliedColumns = -1;
  bool _rebuildingColumns = false;

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

  /// A drag begins a selection anchored at the drag start.
  void _handlePanStart(DragStartDetails details) {
    _focusEditor();
    final changed = _gestures.dragStartAt(
      _textX(details.localPosition.dx),
      details.localPosition.dy + _scrollOffset,
    );
    _logGesture('dragStart', details.localPosition, changed);
    if (changed) _pushSelection();
  }

  /// A drag move extends the selection to the pointer.
  void _handlePanUpdate(DragUpdateDetails details) =>
      _handleDragMove('drag', details.localPosition);

  /// The drag ends: the selection collapses to its caret (the E8a
  /// drag-select contract; a persistent selection is a later sub-step).
  void _handlePanEnd(DragEndDetails details) => _handleDragMove('dragEnd',
      null);

  /// Shared drag-move path (long-press drag and plain drag): extends the
  /// selection to the pointer when `local` is given, collapses it on the
  /// `dragEnd` tag, and pushes the change to the IME.
  void _handleDragMove(String tag, Offset? local) {
    final changed = local == null
        ? _gestures.dragEnd()
        : _gestures.dragTo(
            _textX(local.dx),
            local.dy + _scrollOffset,
          );
    _logGesture(tag, local, changed);
    if (changed) _pushSelection();
  }

  /// The gesture diagnostic: the pointer position, the resulting caret or
  /// selection, and whether it changed (an unchanged gesture means the
  /// pointer stayed inside one character cell).
  void _logGesture(String tag, Offset? local, bool changed) {
    final selection = _input.selection;
    final where = local == null
        ? '-'
        : '(${local.dx.toStringAsFixed(1)}, ${local.dy.toStringAsFixed(1)})';
    _log.debug(
      '$tag: $where -> ${_describeSelection(selection)}'
      '${changed ? '' : ' (unchanged)'}',
    );
  }

  static String _describeSelection(TextSelection selection) =>
      selection.isCollapsed
          ? 'caret ${selection.baseOffset}'
          : 'selection ${selection.start}..${selection.end}';

  void _focusEditor() {
    if (!widget.focusNode.hasFocus) {
      widget.focusNode.requestFocus();
    }
  }

  /// Pushes the current value to the IME after a gesture-driven selection
  /// change. The platform's copy must match ours, or the next keystroke
  /// edits the stale platform selection instead of the caret the user sees
  /// (the M2a on-device round-2 data-loss bug).
  void _pushSelection() => _pushValue(_input.value);

  /// Forwards a value to the platform (a resync from the client, or a
  /// gesture-driven selection change).
  void _pushValue(TextEditingValue value) {
    final clock = Stopwatch()..start();
    _connection?.setEditingState(value);
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
      // on-device round-2 keyboard complaint).
      final connection = TextInput.attach(
        _client,
        const TextInputConfiguration(inputType: TextInputType.multiline),
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
    widget.focusNode.removeListener(_onFocusChanged);
    _input.removeListener(_onChange);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Re-wraps the model at the grid width that fits [maxWidth], one frame
  /// later (a model swap during build is not legal, and the width is only
  /// known from the layout). Runs once on first layout and on resizes; the
  /// common path (width unchanged) is a comparison.
  void _applyColumnsIfChanged(double maxWidth) {
    if (!maxWidth.isFinite || _rebuildingColumns) return;
    final columns = _fitColumns(maxWidth);
    if (columns == _appliedColumns) return;
    _rebuildingColumns = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rebuildingColumns = false;
      if (!mounted) return;
      setState(() {
        _rows = RowModel(_input.buffer, columns: columns);
        _appliedColumns = columns;
        _caretGeometry = _geometryFor(_rows);
        _hitTest = _hitTestFor(_rows);
      });
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
        return Focus(
          focusNode: widget.focusNode,
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: _handleTapUp,
                onLongPressStart: _handleLongPressStart,
                onLongPressMoveUpdate: _handleLongPressMoveUpdate,
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: VirtualizedTextView(
                  model: _rows,
                  scrollController: _scrollController,
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
