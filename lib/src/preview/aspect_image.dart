// An image that reserves its box before the bytes arrive (T-PP-22).
//
// The preview lays out only the blocks the viewport shows and reports each
// block's height to the scroll map. An image that paints late used to grow
// its block after the neighbours were measured, which moved the map's
// target under the reader (the side-by-side preview "staying behind").
// Reserving the box as soon as the provider's dimensions are known keeps
// the block's height stable, so the mapping stays put.

import 'package:flutter/material.dart';
import 'package:niman/src/preview/decode_bound.dart';
import 'package:niman/src/preview/decode_width_probe.dart';

/// An [Image] that holds its aspect ratio from the first decoded frame on.
///
/// While the dimensions are unknown it reserves a small placeholder box —
/// never nothing, so the blocks below it move by at most the difference
/// between the placeholder and the real box, and only once. A provider
/// that fails renders [errorBuilder]'s widget (an empty box by default).
///
/// The picture is decoded at the size it is drawn at, not the file's
/// (#1194): the box is bounded by the width it is given and by the height
/// cap, so [provider] is wrapped in a `ResizeImage` fitting both (see
/// [decodeBound]), and decoded again only when a bound moves past a
/// [decodeStep].
final class AspectImage extends StatefulWidget {
  /// Creates the image over [provider].
  const new({
    required this.provider,
    this.fit = BoxFit.contain,
    this.errorBuilder,
    this.maxHeight,
    super.key,
  });

  /// The image to show.
  final ImageProvider provider;

  /// How the image fills its reserved box (the box itself always keeps the
  /// provider's aspect ratio).
  final BoxFit fit;

  /// The failed-decode widget; an empty box when null.
  final ImageErrorWidgetBuilder? errorBuilder;

  /// The tallest the image may be drawn; null asks the screen (see
  /// [heightCapFor]).
  final double? maxHeight;

  @override
  State<AspectImage> createState() => _AspectImageState();
}

final class _AspectImageState extends State<AspectImage> {
  /// The width the image was last laid out in, in decode steps' worth of
  /// physical pixels ([decodeBound]); null before its first layout.
  int? _widthBound;

  /// The layout's width, from [DecodeWidthProbe]: a new bound rebuilds
  /// after the frame, since layout is no place to build.
  void _onWidth(int bound) {
    if (bound == _widthBound) return;
    _widthBound = bound;
    // The first layout is the placeholder's: the decode starts right after
    // the frame that laid it out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final cap = widget.maxHeight ?? heightCapFor(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final width = _widthBound;
    return DecodeWidthProbe(
      ratio: ratio,
      // An unbounded width (a horizontal scroller) is drawn no wider than
      // the window.
      fallback: MediaQuery.sizeOf(context).width,
      onWidth: _onWidth,
      child: _AspectImageBody(
        provider: widget.provider,
        // `fit` keeps the picture's ratio inside both bounds, which are the
        // box [_AspectImageBodyState.build] draws it in, so the decoded
        // picture has the ratio of the file. Nothing is decoded before the
        // width is known: a guess would be a decode thrown away.
        resized: width == null
            ? null
            : ResizeImage(
                widget.provider,
                width: width,
                height: decodeBound(cap, ratio),
                policy: ResizeImagePolicy.fit,
              ),
        fit: widget.fit,
        errorBuilder: widget.errorBuilder,
        heightCap: cap,
      ),
    );
  }
}

/// What [AspectImage] draws: it resolves the picture, learns its ratio and
/// holds it.
final class _AspectImageBody extends StatefulWidget {
  const new({
    required this.provider,
    required this.resized,
    required this.fit,
    required this.errorBuilder,
    required this.heightCap,
  });

  /// The picture as the caller gave it: what says it is another picture.
  final ImageProvider provider;

  /// [provider] bounded to the size it is drawn at: what is decoded. Null
  /// until the width is known.
  final ImageProvider? resized;

  /// [AspectImage.fit].
  final BoxFit fit;

  /// [AspectImage.errorBuilder].
  final ImageErrorWidgetBuilder? errorBuilder;

  /// The tallest the box may be.
  final double heightCap;

  @override
  State<_AspectImageBody> createState() => _AspectImageBodyState();
}

final class _AspectImageBodyState extends State<_AspectImageBody> {
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
  void didUpdateWidget(_AspectImageBody oldWidget) {
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
    } else if (oldWidget.resized != widget.resized) {
      // The same picture, decoded at another size: the ratio and the
      // failure stand (the block keeps its height, and the picture keeps
      // drawing from the frame it has until the new one lands), and only
      // the stream followed moves.
      _resolve();
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
    final resized = widget.resized;
    if (resized == null) return;
    final stream = resized.resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener(
      (info, _) {
        final height = info.image.height.toDouble();
        // The ratio of the first decode stands for this picture: a smaller
        // decode rounds its sides, and would move the box by a fraction of
        // a pixel — and with it the height the scroll map was told.
        if (!mounted || height <= 0 || _aspectRatio != null) return;
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
    final resized = widget.resized;
    // Before the first layout says how wide the picture is drawn, the
    // placeholder's box stands alone.
    if (resized == null) return const SizedBox(height: 96);
    final image = Image(
      image: resized,
      fit: widget.fit,
      // A new decode size keeps the old frame up until the new one lands.
      gaplessPlayback: true,
      errorBuilder: widget.errorBuilder,
    );
    final ratio = _aspectRatio;
    if (ratio == null || !ratio.isFinite || ratio <= 0) {
      // Dimensions not in yet: the image still mounts (and decodes) inside
      // a small box, which keeps the block from collapsing; the reserved
      // aspect replaces the box as soon as the first frame arrives.
      return SizedBox(height: 96, child: image);
    }
    // A portrait figure at the pane's full width is a screen and a half of
    // one picture, and the prose around it disappears (device report,
    // 2026-09-10). Past the cap the box takes the height and derives the
    // width from the ratio, so the figure only ever gets smaller, never
    // stretched — and it stays on the left, where the text starts.
    return Align(
      alignment: Alignment.centerLeft,
      // Only the width is the pane's; the height is the picture's, so the
      // block around it is exactly as tall as what it draws.
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.heightCap),
        child: AspectRatio(aspectRatio: ratio, child: image),
      ),
    );
  }
}

/// How tall an image may be drawn in [context]: half the window, and no
/// more than [maxImageHeight] of it. Half a phone screen and half a
/// desktop pane are both about one comfortable figure.
double heightCapFor(BuildContext context) {
  final height = MediaQuery.sizeOf(context).height;
  final half = height > 0 ? height / 2 : maxImageHeight;
  return half < maxImageHeight ? half : maxImageHeight;
}

/// The tallest an image is ever drawn, however big the window.
const double maxImageHeight = 480;
