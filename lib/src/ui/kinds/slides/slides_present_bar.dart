import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The discreet bar over a presented slide (#534): ‹ 3 / 7 › · Overview ·
/// Notes · Exit. It shows when the mouse moves and fades when it stops.
final class SlidesPresentBar extends StatelessWidget {
  /// The bar for slide [index] of [count].
  const new({
    required this.index,
    required this.count,
    required this.onPrevious,
    required this.onNext,
    required this.onOverview,
    required this.onNotes,
    required this.onExit,
    super.key,
  });

  /// The slide on screen, from 0.
  final int index;

  /// How many slides.
  final int count;

  /// Goes back a slide.
  final VoidCallback onPrevious;

  /// Goes forward a slide.
  final VoidCallback onNext;

  /// Opens the overview.
  final VoidCallback onOverview;

  /// Switches to the presenter view.
  final VoidCallback onNotes;

  /// Stops presenting.
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget divider() => Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: scheme.outlineVariant,
    );
    return Material(
      key: const Key('slides-present-bar'),
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.9),
      elevation: 6,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: AppStrings.slidesPrevious,
              onPressed: index > 0 ? onPrevious : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '${index + 1} / $count',
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            IconButton(
              tooltip: AppStrings.slidesNext,
              onPressed: index < count - 1 ? onNext : null,
              icon: const Icon(Icons.chevron_right),
            ),
            divider(),
            TextButton.icon(
              onPressed: onOverview,
              icon: const Icon(Icons.grid_view_outlined, size: 18),
              label: Text(AppStrings.slidesOverview),
            ),
            TextButton.icon(
              key: const Key('slides-bar-notes'),
              onPressed: onNotes,
              icon: const Icon(Icons.speaker_notes_outlined, size: 18),
              label: Text(AppStrings.slidesNotes),
            ),
            divider(),
            TextButton.icon(
              key: const Key('slides-bar-exit'),
              onPressed: onExit,
              icon: const Icon(Icons.fullscreen_exit, size: 18),
              label: Text(AppStrings.slidesExit),
            ),
          ],
        ),
      ),
    );
  }
}
