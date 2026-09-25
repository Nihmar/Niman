/// A single-line text that scrolls itself when the room it is given is
/// too narrow, so a note's whole name can be read without opening it
/// (issue #287).
///
/// It measures the line with a [TextPainter] and, only when it does not
/// fit, reveals the rest by sliding left, resting a moment at each end
/// and coming back. It makes a few passes and then rests at the start,
/// rather than moving for as long as the title lives: a title that never
/// stops walking pulls the eye off the note. A line that fits, or a
/// system set to reduce motion, is drawn plain with an ellipsis. Nothing
/// is scrollable by hand: the movement is the widget's, and a title is
/// not a thing to drag.
library;

import 'package:flutter/material.dart';

/// A [Text] that marquees when it overflows its width.
final class MarqueeText extends StatefulWidget {
  /// Creates the title for [text].
  ///
  /// [velocity] is in logical pixels per second while moving; [pause] is
  /// how long the line rests at each end; [gap] is the least blank run
  /// kept before the line comes back, so the last word does not touch the
  /// first; [passes] is how many times it makes the trip (0 = forever).
  const new({
    required this.text,
    this.style,
    this.maxLines = 1,
    this.velocity = 30,
    this.pause = const Duration(milliseconds: 1200),
    this.gap = 24,
    this.passes = 3,
    super.key,
  });

  /// What to draw.
  final String text;

  /// The face; null takes the ambient [DefaultTextStyle].
  final TextStyle? style;

  /// How many lines to keep before truncating. Only one line marquees;
  /// more than one is drawn as an ordinary ellipsized [Text].
  final int maxLines;

  /// How fast the line travels while moving, in logical pixels a second.
  final double velocity;

  /// How long the line rests at each end.
  final Duration pause;

  /// The blank run kept past the end of the line before it comes back.
  final double gap;

  /// How many trips the line makes before it rests; 0 repeats forever.
  final int passes;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

final class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  /// How far the line has to move to reveal its end.
  double _distance = 0;

  /// How long one pass (left, then back) takes, the two pauses apart.
  int _travelMs = 1000;

  /// How many passes have completed for the current distance.
  int _passes = 0;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onStatus);
  }

  /// Makes the next pass while [MarqueeText.passes] allows it, else rests.
  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _passes++;
    if (widget.passes != 0 && _passes >= widget.passes) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MarqueeText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _stop();
    }
  }

  /// Starts or stops the movement without touching state during a build.
  void _schedule({double? distance}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (distance == null) {
        _stop();
      } else {
        _configure(distance);
      }
    });
  }

  void _stop() {
    if (_controller.isAnimating) _controller.stop();
    _controller.value = 0;
    // Forgotten, so an overflow at the same width configures afresh.
    _distance = 0;
  }

  void _configure(double distance) {
    final travel = (distance / widget.velocity * 1000).round().clamp(
      200,
      20000,
    );
    if (_distance == distance && _travelMs == travel) return;
    _distance = distance;
    _travelMs = travel;
    _passes = 0;
    _controller
      ..stop()
      ..value = 0
      ..duration = Duration(
        milliseconds: 2 * widget.pause.inMilliseconds + 2 * travel,
      )
      ..forward(from: 0);
  }

  /// The line's offset within the cycle [t] (0..1): rest, reveal, rest,
  /// return.
  double _offsetAt(double t) {
    final pause = widget.pause.inMilliseconds.toDouble();
    final travel = _travelMs.toDouble();
    final position = t * (2 * pause + 2 * travel);
    if (position < pause) return 0;
    if (position < pause + travel) {
      return _distance * (position - pause) / travel;
    }
    if (position < 2 * pause + travel) return _distance;
    return _distance * (1 - (position - 2 * pause - travel) / travel);
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    final reduced = MediaQuery.disableAnimationsOf(context);
    // More than one line has no one line to scroll; draw it as before.
    if (widget.maxLines != 1) {
      _schedule();
      return Text(
        widget.text,
        style: style,
        maxLines: widget.maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: 1,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final textWidth = painter.width;
        final overflows = maxWidth.isFinite && textWidth > maxWidth;
        if (reduced || !overflows) {
          _schedule();
          return Text(
            widget.text,
            style: style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          );
        }
        _schedule(distance: textWidth - maxWidth + widget.gap);
        return SizedBox(
          height: painter.height,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: double.infinity,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Transform.translate(
                  key: const Key('marquee-offset'),
                  offset: Offset(-_offsetAt(_controller.value), 0),
                  child: child,
                ),
                child: Text(
                  widget.text,
                  style: style,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
