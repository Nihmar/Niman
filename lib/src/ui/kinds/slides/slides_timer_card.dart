import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The presenter view's timer (#534): the time the talk has run, its pause
/// and restart, and the clock on the wall.
final class SlidesTimerCard extends StatelessWidget {
  /// Shows [elapsed].
  const new({
    required this.elapsed,
    required this.paused,
    required this.onPause,
    required this.onRestart,
    this.label,
    super.key,
  });

  /// The time the talk has run.
  final Duration elapsed;

  /// Whether the timer is paused.
  final bool paused;

  /// Pauses the timer, or starts it again.
  final VoidCallback onPause;

  /// Puts the timer back to zero.
  final VoidCallback onRestart;

  /// The style of the card's caption.
  final TextStyle? label;

  static String _clock(Duration time) {
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = time.inHours;
    final rest = '${two(time.inMinutes % 60)}:${two(time.inSeconds % 60)}';
    return hours > 0 ? '$hours:$rest' : rest;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = TimeOfDay.now();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.slidesElapsed.toUpperCase(), style: label),
            Row(
              children: [
                Text(
                  _clock(elapsed),
                  key: const Key('slides-elapsed'),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                IconButton.outlined(
                  tooltip: paused
                      ? AppStrings.slidesPresent
                      : AppStrings.slidesPause,
                  onPressed: onPause,
                  icon: Icon(paused ? Icons.play_arrow_outlined : Icons.pause),
                ),
                const SizedBox(width: 6),
                IconButton.outlined(
                  tooltip: AppStrings.slidesRestart,
                  onPressed: onRestart,
                  icon: const Icon(Icons.restart_alt),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  now.format(context),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
