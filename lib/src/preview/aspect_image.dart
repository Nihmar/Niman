// An image that reserves its box before the bytes arrive (T-PP-22).
//
// The preview lays out only the blocks the viewport shows and reports each
// block's height to the scroll map. An image that paints late used to grow
// its block after the neighbours were measured, which moved the map's
// target under the reader (the side-by-side preview "staying behind").
// Reserving the box as soon as the provider's dimensions are known keeps
// the block's height stable, so the mapping stays put.

import 'package:flutter/material.dart';

/// An [Image] that holds its aspect ratio from the first decoded frame on.
///
/// While the dimensions are unknown it reserves a small placeholder box —
/// never nothing, so the blocks below it move by at most the difference
/// between the placeholder and the real box, and only once. A provider
/// that fails renders [errorBuilder]'s widget (an empty box by default).
final class AspectImage extends StatefulWidget {
  /// Creates the image over [provider].
  const new({
    required this.provider,
    this.fit = BoxFit.contain,
    this.errorBuilder,
    super.key,
  });

  /// The image to show.
  final ImageProvider provider;

  /// How the image fills its reserved box (the box itself always keeps the
  /// provider's aspect ratio).
  final BoxFit fit;

  /// The failed-decode widget; an empty box when null.
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  State<AspectImage> createState() => _AspectImageState();
}

final class _AspectImageState extends State<AspectImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  double? _aspectRatio;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(AspectImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider != widget.provider) {
      _detach();
      _aspectRatio = null;
      _failed = false;
      // The configuration comes from the inherited tree: resolve after the
      // frame, where reading it is legal.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resolve();
      });
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  void _detach() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _listener = null;
    _stream = null;
  }

  void _resolve() {
    _detach();
    final stream = widget.provider.resolve(
      createLocalImageConfiguration(context),
    );
    final listener = ImageStreamListener(
      (info, _) {
        final height = info.image.height.toDouble();
        if (!mounted || height <= 0) return;
        setState(() => _aspectRatio = info.image.width.toDouble() / height);
      },
      onError: (error, stackTrace) {
        if (mounted) setState(() => _failed = true);
      },
    );
    _listener = listener;
    _stream = stream;
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return widget.errorBuilder?.call(context, 'image failed', null) ??
          const SizedBox.shrink();
    }
    final image = Image(
      image: widget.provider,
      fit: widget.fit,
      errorBuilder: widget.errorBuilder,
    );
    final ratio = _aspectRatio;
    if (ratio == null || !ratio.isFinite || ratio <= 0) {
      // Dimensions not in yet: the image still mounts (and decodes) inside
      // a small box, which keeps the block from collapsing; the reserved
      // aspect replaces the box as soon as the first frame arrives.
      return SizedBox(height: 96, child: image);
    }
    return AspectRatio(aspectRatio: ratio, child: image);
  }
}
