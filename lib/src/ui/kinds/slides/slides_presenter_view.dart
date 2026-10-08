import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/kinds/slides/slide_frame.dart';
import 'package:niman/src/ui/kinds/slides/slide_split.dart';
import 'package:niman/src/ui/kinds/slides/slides_parts.dart';
import 'package:niman/src/ui/strings.dart';

/// The presenter view (#534): the slide on screen, the next one, the
/// speaker notes, the time the talk has run and the clock — what the
/// speaker needs and the audience does not see.
final class SlidesPresenterView extends StatefulWidget {
  /// The view at slide [index] of [slides].
  const new({
    required this.slides,
    required this.index,
    required this.resolveEmbed,
    required this.elapsed,
    required this.paused,
    required this.onGo,
    required this.onOverview,
    required this.onSlideOnly,
    required this.onExit,
    required this.onPause,
    required this.onRestart,
    super.key,
  });

  /// The deck.
  final List<Slide> slides;

  /// The slide on screen.
  final int index;

  /// Resolves a picture's target.
  final Future<String?> Function(String target) resolveEmbed;

  /// The time the talk has run, read on every tick.
  final Duration Function() elapsed;

  /// Whether the timer is paused.
  final bool paused;

  /// Goes to a slide.
  final ValueChanged<int> onGo;

  /// Opens the overview.
  final VoidCallback onOverview;

  /// Back to the slide alone.
  final VoidCallback onSlideOnly;

  /// Stops presenting.
  final VoidCallback onExit;

  /// Pauses the timer, or starts it again.
  final VoidCallback onPause;

  /// Puts the timer back to zero.
  final VoidCallback onRestart;

  @override
  State<SlidesPresenterView> createState() => _SlidesPresenterViewState();
}

final class _SlidesPresenterViewState extends State<SlidesPresenterView> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

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
    final count = widget.slides.length;
    final index = widget.index;
    final slide = widget.slides[index];
    final next = index + 1 < count ? widget.slides[index + 1] : null;
    final now = TimeOfDay.now();
    final label = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      letterSpacing: 0.6,
    );
    return ColoredBox(
      key: const Key('slides-presenter'),
      color: scheme.surface,
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Text(
                  '${index + 1} / $count',
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: widget.onOverview,
                  icon: const Icon(Icons.grid_view_outlined, size: 18),
                  label: Text(AppStrings.slidesOverview),
                ),
                TextButton.icon(
                  key: const Key('slides-slide-only'),
                  onPressed: widget.onSlideOnly,
                  icon: const Icon(Icons.slideshow_outlined, size: 18),
                  label: Text(AppStrings.slidesSlideOnly),
                ),
                const SizedBox(width: 4),
                OutlinedButton.icon(
                  onPressed: widget.onExit,
                  icon: const Icon(Icons.fullscreen_exit, size: 18),
                  label: Text(AppStrings.slidesExit),
                ),
                const SizedBox(width: 14),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.slidesNow.toUpperCase(), style: label),
                        const SizedBox(height: 8),
                        _framed(context, slide, current: true),
                        const SizedBox(height: 18),
                        Expanded(
                          child: slide.notes == null
                              ? const SizedBox.shrink()
                              : SpeakerNotes(notes: slide.notes!, large: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          next == null
                              ? AppStrings.slidesNext.toUpperCase()
                              : '${AppStrings.slidesNext.toUpperCase()} · '
                                    '${index + 2}',
                          style: label,
                        ),
                        const SizedBox(height: 8),
                        if (next == null)
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: scheme.outlineVariant,
                                ),
                              ),
                            ),
                          )
                        else
                          _framed(context, next, current: false),
                        const SizedBox(height: 26),
                        _timer(context, label, now),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: index > 0
                                  ? () => widget.onGo(index - 1)
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                              label: Text(AppStrings.slidesPrevious),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              key: const Key('slides-presenter-next'),
                              onPressed: next == null
                                  ? null
                                  : () => widget.onGo(index + 1),
                              icon: const Icon(Icons.chevron_right),
                              label: Text(AppStrings.slidesNext),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _framed(BuildContext context, Slide slide, {required bool current}) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: current ? scheme.primary : scheme.outlineVariant,
            width: current ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SlideFrame(
            key: ValueKey(slide),
            markdown: slide.markdown,
            resolveEmbed: widget.resolveEmbed,
            live: false,
          ),
        ),
      ),
    );
  }

  Widget _timer(BuildContext context, TextStyle? label, TimeOfDay now) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
                  _clock(widget.elapsed()),
                  key: const Key('slides-elapsed'),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                IconButton.outlined(
                  tooltip: widget.paused
                      ? AppStrings.slidesPresent
                      : AppStrings.slidesPause,
                  onPressed: widget.onPause,
                  icon: Icon(
                    widget.paused ? Icons.play_arrow_outlined : Icons.pause,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.outlined(
                  tooltip: AppStrings.slidesRestart,
                  onPressed: widget.onRestart,
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
