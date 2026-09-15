import 'package:flutter/material.dart';

/// A clip time as `m:ss` (`h:mm:ss` past the hour).
String formatClipTime(Duration time) {
  final seconds = time.inSeconds;
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$s';
  return '$m:$s';
}

/// The progress track of a voice clip: a thin bar filled to [value]
/// (0..1) with a thumb while [active]; tapping or dragging it calls
/// [onSeek] with the touched fraction.
class AudioProgressBar extends StatelessWidget {
  /// Creates the bar.
  const new({
    required this.value,
    required this.active,
    this.onSeek,
    super.key,
  });

  /// How much of the clip has played (0..1).
  final double value;

  /// Whether the clip is loaded (shows the thumb, accepts seeks).
  final bool active;

  /// Called with the touched fraction; null disables seeking.
  final ValueChanged<double>? onSeek;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void seek(double dx) => onSeek?.call((dx / width).clamp(0.0, 1.0));
        final filled = width * value.clamp(0.0, 1.0);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onSeek == null ? null : (d) => seek(d.localPosition.dx),
          onHorizontalDragUpdate: onSeek == null
              ? null
              : (d) => seek(d.localPosition.dx),
          child: SizedBox(
            height: 20,
            width: width,
            child: Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  height: 4,
                  width: filled,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (active)
                  Positioned(
                    left: filled - 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
