/// The pinch-and-drag surface of the full-screen diagram (#1110).
///
/// [InteractiveViewer] clamps a pan to its boundary (the child plus the
/// boundary margin) and a zoom to the scale at which that boundary still
/// covers the viewport (`max(viewport / boundary)`, both axes). A boundary
/// smaller than the viewport therefore refuses every pan and lifts the first
/// zoom to a scale the reader never asked for. So the viewer is given a
/// *scene* the size of the viewport at the lowest scale it offers, and the
/// drawing is centred in it:
///
/// * `fit` is the scale at which the drawing, with a margin, shows whole in
///   the viewport, never above 1: a small diagram is not enlarged on opening;
/// * the scene is the viewport divided by `fit`, so at `fit` it is exactly
///   the viewport (the opening matrix is the plain scale, nothing to
///   translate) and the viewer's own floor, `max(viewport / scene)`, is `fit`
///   too;
/// * `minScale` is `fit`: the whole diagram is one zoom-out away, whatever
///   its aspect ratio and the viewport's;
/// * above `fit` the scene is larger than the viewport, so a pan reaches each
///   of the scene's edges, with the drawing at least [margin] inside them.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:niman/src/diagrams/diagram_drawing.dart';
import 'package:niman/src/diagrams/diagram_painter.dart';
import 'package:niman/src/diagrams/diagram_style.dart';

/// A diagram in a viewport, opened fitted and centred, to zoom and pan.
///
/// The state is made for one viewport: the caller keys the widget by the
/// [viewport], so a rotation or a resize is a new state, fitted again.
final class DiagramFittedViewer extends StatefulWidget {
  /// Creates a viewer of [drawing] in a viewport of the given size.
  const new({
    required this.drawing,
    required this.style,
    required this.viewport,
    super.key,
  });

  /// The open space around the drawing, in its own units, that a fit and a
  /// pan to an edge keep: the drawing never touches the screen's border.
  static const double margin = 24;

  /// The highest zoom, as a multiple of the drawing's own size.
  static const double maxScale = 8;

  /// The diagram drawn.
  final DiagramDrawing drawing;

  /// How it is drawn.
  final DiagramStyle style;

  /// The space the viewer fills.
  final Size viewport;

  /// The scale at which a drawing of the given size shows whole, with its
  /// [margin], in [viewport]; at most 1.
  static double fitScale(Size drawing, Size viewport) => math.min(
    1,
    math.min(
      viewport.width / (drawing.width + 2 * margin),
      viewport.height / (drawing.height + 2 * margin),
    ),
  );

  @override
  State<DiagramFittedViewer> createState() => _DiagramFittedViewerState();
}

final class _DiagramFittedViewerState extends State<DiagramFittedViewer> {
  final TransformationController _controller = TransformationController();
  Offset _doubleTapAt = Offset.zero;

  Size get _viewport => widget.viewport;

  double get _fit =>
      DiagramFittedViewer.fitScale(widget.drawing.size, _viewport);

  /// The viewer's child: the viewport as it is at [_fit].
  Size get _scene => _viewport / _fit;

  @override
  void initState() {
    super.initState();
    _controller.value = Matrix4.diagonal3Values(_fit, _fit, _fit);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// A double tap shows the diagram at its own size where it fell and, from
  /// there or from any other zoom, shows it whole again. A diagram that is
  /// already at its own size has nothing to toggle.
  void _toggle() {
    final fit = _fit;
    final atFit = (_controller.value.getMaxScaleOnAxis() - fit).abs() < 1e-6;
    if (!atFit) {
      _controller.value = Matrix4.diagonal3Values(fit, fit, fit);
    } else if (fit < 1) {
      _zoomTo(1, _doubleTapAt);
    }
  }

  /// Sets the scale to [scale], keeping the scene point under [focal] there
  /// as far as the scene allows: the viewer refuses a pan out of it, and a
  /// matrix set from outside has to keep to the same rule.
  void _zoomTo(double scale, Offset focal) {
    final point = _controller.toScene(focal);
    final tx = (focal.dx - point.dx * scale).clamp(
      _viewport.width - _scene.width * scale,
      0.0,
    );
    final ty = (focal.dy - point.dy * scale).clamp(
      _viewport.height - _scene.height * scale,
      0.0,
    );
    _controller.value = Matrix4.translationValues(tx, ty, 0)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapAt = details.localPosition,
      onDoubleTap: _toggle,
      child: InteractiveViewer(
        transformationController: _controller,
        constrained: false,
        minScale: _fit,
        maxScale: DiagramFittedViewer.maxScale,
        child: SizedBox.fromSize(
          size: _scene,
          child: Center(
            child: SizedBox.fromSize(
              size: widget.drawing.size,
              child: CustomPaint(
                painter: DiagramPainter(
                  drawing: widget.drawing,
                  style: widget.style,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
