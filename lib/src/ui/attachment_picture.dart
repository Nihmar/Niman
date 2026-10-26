/// A picture attachment, zoomed and panned, decoded at the size it is seen
/// at (#1194).
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:niman/src/preview/decode_bound.dart';
import 'package:niman/src/ui/attachment_unreadable.dart';

/// The most the viewer zooms in.
const double _maxZoom = 16;

/// The factor the viewer decodes a picture beyond the viewport's size by,
/// for a zoom of [scale]: the smallest power of two that is at least
/// [scale], from 1 (a picture is never decoded below the viewport's size)
/// up to the viewer's own limit, 16.
///
/// A power of two, not the zoom itself, so that a pinch settling at 3.1 and
/// one at 3.4 decode once, not twice.
int zoomDecodeScale(double scale) {
  if (!scale.isFinite || scale <= 1) return 1;
  // The log of an exact power of two lands a hair above the integer: that
  // hair is not a reason to decode twice the pixels.
  final exponent = (math.log(scale) / math.ln2 - 1e-9).ceil();
  return math.min(1 << exponent, _maxZoom.toInt());
}

/// The picture at [path], in a viewer that pans and zooms.
///
/// It is decoded at the viewport's size × the pixel ratio, not the file's,
/// and again, larger, as soon as a zoom passes a scale that needs more of
/// the file's pixels. The decode never goes past the file's own pixels,
/// so at depth it is the whole file — the one place that needs it.
final class AttachmentPicture extends StatefulWidget {
  /// Shows the picture at [path], an absolute path.
  const new({required this.path, super.key});

  /// The picture's absolute path.
  final String path;

  @override
  State<AttachmentPicture> createState() => _AttachmentPictureState();
}

final class _AttachmentPictureState extends State<AttachmentPicture> {
  final TransformationController _controller = TransformationController();

  /// The zoom the picture is decoded for, a [zoomDecodeScale]. It only
  /// rises: zooming back out keeps the decode, and the pinch that follows
  /// finds it still there.
  int _decodeScale = 1;

  @override
  void initState() {
    super.initState();
    // The transformation itself, not the gesture's end: a wheel zoom on the
    // desktop moves it without ever ending an interaction, and a pinch
    // passes each power of two once, so a picture decodes at most four
    // times on its way to the deepest zoom.
    _controller.addListener(_onTransformed);
  }

  @override
  void didUpdateWidget(AttachmentPicture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      // Another picture starts as the viewer starts: whole, at the
      // viewport's size.
      _controller.value = Matrix4.identity();
      _decodeScale = 1;
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTransformed)
      ..dispose();
    super.dispose();
  }

  void _onTransformed() {
    final scale = zoomDecodeScale(_controller.value.getMaxScaleOnAxis());
    if (scale > _decodeScale) setState(() => _decodeScale = scale);
  }

  @override
  Widget build(BuildContext context) {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.sizeOf(context);
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : size.width;
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : size.height;
        return InteractiveViewer(
          key: const Key('attachment-picture'),
          transformationController: _controller,
          minScale: 0.5,
          maxScale: _maxZoom,
          child: Center(
            child: Image(
              image: ResizeImage(
                FileImage(File(widget.path)),
                width: decodeBound(width * _decodeScale, ratio),
                height: decodeBound(height * _decodeScale, ratio),
                policy: ResizeImagePolicy.fit,
              ),
              fit: BoxFit.contain,
              // A deeper zoom decodes again: the frame it has stays up
              // until the sharper one lands.
              gaplessPlayback: true,
              errorBuilder: (context, error, stack) =>
                  const AttachmentUnreadable(),
            ),
          ),
        );
      },
    );
  }
}
