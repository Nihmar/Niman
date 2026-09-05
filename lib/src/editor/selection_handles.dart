import 'dart:math' as math;

import 'package:copist/src/editor/caret_geometry.dart';
import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/selection_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// The standard Android selection UI — the two drag handles and the
/// copy/cut/paste/select-all toolbar — over the virtualized editor, driven
/// through [SelectionOverlay]: the framework's own mechanism for selection
/// handles on widgets that do not use a `RenderEditable` (its docs point
/// custom widgets here).
///
/// The handles are anchored (via the layer links) at the selection's
/// endpoints, which the editor converts to viewport-local offsets in
/// [update]. Dragging a handle maps the pointer through the editor's own
/// hit test (the same mapping the tap/long-press gestures use) and moves
/// the selection live — no IME push per move (a full-text push at novel
/// length is a platform round trip, M2a on-device round 3); the drag end
/// commits the final selection through `commitSelection`.
final class SelectionHandles {
  /// Creates the handles over [input], with the toolbar actions from
  /// [delegate] and the IME push on drag end from `commitSelection`.
  SelectionHandles({
    required this.input,
    required this.delegate,
    required this.commitSelection,
  });

  /// The buffer the handles move the selection in.
  final ComposingInput input;

  /// The toolbar actions + the platform delegate channel.
  final NoteSelectionDelegate delegate;

  /// Pushes the final selection to the IME on a handle-drag end.
  final void Function() commitSelection;

  /// The layer link the start handle follows: the editor anchors it to the
  /// `startAnchor` target (the start endpoint, moved on every update — the
  /// same layer-link mechanism the platform handles use).
  final LayerLink startHandleLayerLink = LayerLink();

  /// The layer link the end handle follows (the [endAnchor] target).
  final LayerLink endHandleLayerLink = LayerLink();

  /// The layer link the toolbar follows (the scroll viewport: the toolbar
  /// anchors are viewport-local).
  final LayerLink toolbarLayerLink = LayerLink();

  /// The clipboard status the toolbar's paste button tracks (and is
  /// listened to, so a clipboard change re-builds the toolbar).
  final ClipboardStatusNotifier _clipboardStatus = ClipboardStatusNotifier();

  SelectionOverlay? _overlay;
  BuildContext? _context;
  RenderBox? _viewport;
  List<TextSelectionPoint> _endpoints = const <TextSelectionPoint>[];
  Offset? _startAnchor;
  Offset? _endAnchor;
  double _rowHeight = 0;
  bool _shown = false;
  bool _showPending = false;
  bool _dragging = false;
  int Function(Offset)? _pointerToOffset;
  TextSelection _dragStartSelection = const TextSelection(
    baseOffset: 0,
    extentOffset: 0,
  );

  /// Whether the handles/toolbar are currently shown (the editor logs the
  /// show/hide transitions).
  bool get shown => _shown;

  /// The viewport-local position of the start endpoint's layer target
  /// (`null` while the selection UI is hidden).
  ///
  /// The editor places the start handle's `CompositedTransformTarget` (the
  /// link leader — the widget equivalent of the zero-size leader layer a
  /// `RenderEditable` paints at each endpoint) at this position.
  Offset? get startAnchor => _startAnchor;

  /// The viewport-local position of the end endpoint's layer target
  /// (`null` while the selection UI is hidden).
  Offset? get endAnchor => _endAnchor;

  /// Shows, moves, or hides the selection UI for [selection].
  ///
  /// [context] is the anchor context (it must have an [Overlay] ancestor);
  /// [viewport] is the render box the endpoint offsets are relative to (the
  /// scroll viewport); [geometry] and [scrollOffset] compute the endpoint
  /// offsets; [offsetAtPointer] maps a global pointer position to a buffer
  /// offset (the handle drag mapping).
  void update({
    required BuildContext context,
    required RenderBox viewport,
    required TextSelection selection,
    required CaretGeometry geometry,
    required double scrollOffset,
    required int Function(Offset globalPointer) offsetAtPointer,
  }) {
    _context = context;
    _viewport = viewport;
    _rowHeight = geometry.rowHeight;
    _pointerToOffset = offsetAtPointer;
    if (!selection.isValid || selection.isCollapsed) {
      _hideOverlay();
      return;
    }
    _endpoints = _endpointsFor(selection, geometry, scrollOffset);
    // The leaders clamp to the viewport (the same way the `LeaderLayer`s
    // a `RenderEditable` paints clamp to its size): off-screen endpoints
    // pin their handles to the edge.
    final size = viewport.size;
    _startAnchor = _clampPoint(_endpoints[0].point, size);
    _endAnchor = _clampPoint(_endpoints[1].point, size);
    _overlay ??= _createOverlay(context, geometry);
    _overlay!
      ..selectionEndpoints = _endpoints
      ..markNeedsBuild();
    if (!_shown) {
      _shown = true;
      _show();
    }
  }

  static Offset _clampPoint(Offset point, Size size) {
    return Offset(
      point.dx.clamp(0, size.width).toDouble(),
      point.dy.clamp(0, size.height).toDouble(),
    );
  }

  /// Hides the handles and the toolbar (the selection persists in the
  /// buffer — this is the UI only).
  void hide() => _hideOverlay();

  /// Releases the overlay (the editor's dispose).
  void dispose() {
    _overlay?.dispose();
    _overlay = null;
    _shown = false;
    _context = null;
    _viewport = null;
    _pointerToOffset = null;
    _clipboardStatus.removeListener(_onClipboardStatus);
  }

  /// The viewport-local offset of buffer [offset] (the anchor point of one
  /// selection handle).
  TextSelectionPoint _pointFor(
    int offset,
    CaretGeometry geometry,
    double scrollOffset,
  ) {
    final (row, col) = geometry.rowModel.offsetToRowColumn(offset);
    return TextSelectionPoint(
      Offset(
        geometry.leftPadding + col * geometry.charWidth,
        row * geometry.rowHeight - scrollOffset,
      ),
      TextDirection.ltr,
    );
  }

  List<TextSelectionPoint> _endpointsFor(
    TextSelection selection,
    CaretGeometry geometry,
    double scrollOffset,
  ) {
    return <TextSelectionPoint>[
      _pointFor(selection.start, geometry, scrollOffset),
      _pointFor(selection.end, geometry, scrollOffset),
    ];
  }

  SelectionOverlay _createOverlay(
    BuildContext context,
    CaretGeometry geometry,
  ) {
    _clipboardStatus.addListener(_onClipboardStatus);
    return SelectionOverlay(
      context: context,
      startHandleType: TextSelectionHandleType.left,
      lineHeightAtStart: geometry.rowHeight,
      onStartHandleDragStart: _dragStart,
      onStartHandleDragUpdate: _dragUpdateStart,
      onStartHandleDragEnd: _dragEnd,
      endHandleType: TextSelectionHandleType.right,
      lineHeightAtEnd: geometry.rowHeight,
      onEndHandleDragStart: _dragStart,
      onEndHandleDragUpdate: _dragUpdateEnd,
      onEndHandleDragEnd: _dragEnd,
      selectionEndpoints: _endpoints,
      selectionControls: materialTextSelectionControls,
      // Required (not deprecated): the framework routes the toolbar's
      // state (paste enabled, …) through the delegate.
      selectionDelegate: delegate,
      clipboardStatus: _clipboardStatus,
      startHandleLayerLink: startHandleLayerLink,
      endHandleLayerLink: endHandleLayerLink,
      toolbarLayerLink: toolbarLayerLink,
    );
  }

  /// The clipboard changed: re-build the toolbar (its paste button follows
  /// the clipboard status).
  void _onClipboardStatus() {
    _overlay?.markNeedsBuild();
  }

  /// Shows the handles + toolbar, deferring to a post-frame callback when
  /// called during build (the overlay needs a laid-out tree).
  void _show() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (!_showPending) {
        _showPending = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPending = false;
          _showNow();
        });
      }
      return;
    }
    _showNow();
  }

  void _showNow() {
    final overlay = _overlay;
    final context = _context;
    if (overlay == null || context == null) return;
    overlay
      ..showHandles()
      ..showToolbar(context: context, contextMenuBuilder: _toolbarBuilder);
  }

  /// The standard Material toolbar (the framework's own text fields use the
  /// same widget): copy/cut/paste/select all, anchored above the selection
  /// (below when it does not fit there).
  Widget _toolbarBuilder(BuildContext context) {
    final viewport = _viewport;
    if (viewport == null) return const SizedBox.shrink();
    return AdaptiveTextSelectionToolbar.editable(
      clipboardStatus: _clipboardStatus.value,
      // The toolbar cause: the delegate's cause contract hides the toolbar
      // after copy/cut/paste (the [NoteSelectionDelegate] implements it).
      onCopy: () => delegate.copySelection(SelectionChangedCause.toolbar),
      onCut: () => delegate.cutSelection(SelectionChangedCause.toolbar),
      onPaste: () => delegate.pasteText(SelectionChangedCause.toolbar),
      onSelectAll: () => delegate.selectAll(SelectionChangedCause.toolbar),
      onLookUp: null,
      onSearchWeb: null,
      onShare: null,
      onLiveTextInput: null,
      anchors: TextSelectionToolbarAnchors.fromSelection(
        renderBox: viewport,
        startGlyphHeight: _rowHeight,
        endGlyphHeight: _rowHeight,
        selectionEndpoints: _endpoints,
      ),
    );
  }

  void _hideOverlay() {
    if (!_shown) return;
    _shown = false;
    _startAnchor = null;
    _endAnchor = null;
    _overlay?.hide();
  }

  void _dragStart(DragStartDetails details) {
    _dragging = true;
    _dragStartSelection = input.selection;
  }

  /// The left handle (the selection's start side) moves to the pointer; the
  /// other side stays put.
  void _dragUpdateStart(DragUpdateDetails details) {
    if (!_dragging) return;
    final offset = _pointerToOffset!(details.globalPosition);
    final fixed = _dragStartSelection.end;
    input.setSelection(
      TextSelection(
        baseOffset: math.min(fixed, offset),
        extentOffset: math.max(fixed, offset),
      ),
    );
  }

  /// The right handle (the selection's end side) moves to the pointer; the
  /// other side stays put.
  void _dragUpdateEnd(DragUpdateDetails details) {
    if (!_dragging) return;
    final offset = _pointerToOffset!(details.globalPosition);
    final fixed = _dragStartSelection.start;
    input.setSelection(
      TextSelection(
        baseOffset: math.min(fixed, offset),
        extentOffset: math.max(fixed, offset),
      ),
    );
  }

  /// The handle drag ends: commit the final selection to the IME (the moves
  /// did not push — see the class docs).
  void _dragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    commitSelection();
  }
}
