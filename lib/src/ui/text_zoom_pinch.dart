/// Text zoomed by a pinch (#538): two fingers spread or brought together
/// over a note or a book, or a trackpad's pinch on the desktop. Which size
/// it is, and where it is kept, is the caller's: the note text size over a
/// note, the books' over a book.
///
/// Like the palette's two-finger swipe (`PaletteSwipe`), it watches the
/// raw pointers and claims no gesture in the arena, so the scroll and the
/// taps underneath keep every finger they had. The two tell themselves
/// apart by the distance between the fingers: the swipe moves both down
/// together, a pinch changes how far apart they are.
library;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:niman/src/core/settings/library_config.dart';

/// Zooms the text of [child] as two fingers pinch over it.
final class TextZoomPinch extends StatefulWidget {
  /// Watches [child]; [scale] is the text size the pinch starts
  /// from, [onZoom] is told each step and, when the fingers lift, where it
  /// ends.
  const new({
    required this.scale,
    required this.onZoom,
    required this.child,
    this.enabled = true,
    super.key,
  });

  /// Whether a pinch zooms: off over a pane whose text zooms by a pinch
  /// of its own, a book in the note pane, so one pinch is one zoom.
  final bool enabled;

  /// The text size now.
  final double Function() scale;

  /// The size the pinch has reached; `done` when the fingers are lifted.
  final void Function(double scale, {required bool done}) onZoom;

  /// The note or the book.
  final Widget child;

  /// How much the fingers' distance has to change before it is a pinch:
  /// two fingers swiping down together stay about as far apart.
  static const double threshold = 0.12;

  /// The steps the size moves in, the settings slider's.
  static const double step = 0.05;

  /// [scale] on the steps, in range.
  static double snap(double scale) =>
      normalizeTextScale((scale / step).round() * step);

  @override
  State<TextZoomPinch> createState() => _TextZoomPinchState();
}

final class _TextZoomPinchState extends State<TextZoomPinch> {
  final Map<int, Offset> _at = {};
  double? _startDistance;
  double _startScale = 1;
  double? _shown;
  bool _pinching = false;
  bool _spent = false;

  double get _distance {
    final points = _at.values.toList();
    return (points[0] - points[1]).distance;
  }

  void _down(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    _at[event.pointer] = event.position;
    if (_at.length == 2) {
      _startDistance = _distance;
      _startScale = widget.scale();
    } else if (_at.length > 2) {
      // A third finger is another gesture.
      _finish();
      _spent = true;
    }
  }

  void _move(PointerMoveEvent event) {
    if (_spent || !_at.containsKey(event.pointer)) return;
    _at[event.pointer] = event.position;
    final start = _startDistance;
    if (_at.length != 2 || start == null || start == 0) return;
    final ratio = _distance / start;
    if (!_pinching && (ratio - 1).abs() < TextZoomPinch.threshold) return;
    _pinching = true;
    _show(_startScale * ratio);
  }

  void _up(PointerEvent event) {
    if (_at.remove(event.pointer) == null) return;
    if (_at.length < 2) _finish();
    if (_at.isEmpty) _spent = false;
  }

  /// A step the size reached, told once.
  void _show(double scale) {
    final snapped = TextZoomPinch.snap(scale);
    if (!widget.enabled || snapped == _shown) return;
    _shown = snapped;
    widget.onZoom(snapped, done: false);
  }

  void _finish() {
    final shown = _shown;
    if (_pinching && shown != null) widget.onZoom(shown, done: true);
    _pinching = false;
    _startDistance = null;
    _shown = null;
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _down,
    onPointerMove: _move,
    onPointerUp: _up,
    onPointerCancel: _up,
    // A trackpad's pinch comes as one pan-zoom, its scale given.
    onPointerPanZoomStart: (_) {
      _startScale = widget.scale();
      _pinching = true;
    },
    onPointerPanZoomUpdate: (event) {
      if (event.scale != 1) _show(_startScale * event.scale);
    },
    onPointerPanZoomEnd: (_) => _finish(),
    child: widget.child,
  );
}
