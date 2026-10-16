/// A tab that can be dragged, by the hand that holds it (#1080).
///
/// A mouse, a stylus or a trackpad takes the tab at once, as every tabbed
/// app does. A finger must hold it first: a swipe along an overflowing row
/// scrolls the row instead of lifting a tab out of it, as the tree's rows
/// do on a phone.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/ui/tab_drag.dart';

/// The pointers that take a tab at once: every kind but a finger.
final Set<PointerDeviceKind> _immediateKinds = {
  for (final kind in PointerDeviceKind.values)
    if (kind != PointerDeviceKind.touch) kind,
};

/// The recognizer of [TabDraggable]: a long press for a touch, a drag from
/// the first move for the rest.
///
/// It is the delayed recognizer, which takes only a touch, with an
/// immediate one beside it for every other pointer: one of the two takes
/// each pointer, so the drag the widget starts is the same either way.
final class _TabDragRecognizer extends DelayedMultiDragGestureRecognizer {
  new({super.allowedButtonsFilter})
    : _immediate = ImmediateMultiDragGestureRecognizer(
        supportedDevices: _immediateKinds,
        allowedButtonsFilter: allowedButtonsFilter,
      ),
      super(supportedDevices: {PointerDeviceKind.touch});

  final ImmediateMultiDragGestureRecognizer _immediate;

  @override
  set onStart(GestureMultiDragStartCallback? value) {
    super.onStart = value;
    _immediate.onStart = value;
  }

  @override
  set gestureSettings(DeviceGestureSettings? value) {
    super.gestureSettings = value;
    _immediate.gestureSettings = value;
  }

  @override
  void addPointer(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.touch) {
      super.addPointer(event);
    } else {
      _immediate.addPointer(event);
    }
  }

  @override
  void dispose() {
    _immediate.dispose();
    super.dispose();
  }
}

/// A [Draggable] of a [TabDrag] that a finger holds before it drags.
final class TabDraggable extends Draggable<TabDrag> {
  /// Makes [child] a tab that [data] describes once dragged, [feedback]
  /// under the pointer.
  const new({
    required super.child,
    required super.feedback,
    required super.data,
    super.childWhenDragging,
    super.dragAnchorStrategy,
    super.key,
  });

  @override
  MultiDragGestureRecognizer createRecognizer(
    GestureMultiDragStartCallback onStart,
  ) =>
      _TabDragRecognizer(allowedButtonsFilter: allowedButtonsFilter)
        ..onStart = onStart;
}
