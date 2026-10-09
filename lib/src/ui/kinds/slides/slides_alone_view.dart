import 'package:flutter/material.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/kinds/slides/slide_frame.dart';
import 'package:niman/src/ui/kinds/slides/slide_split.dart';
import 'package:niman/src/ui/kinds/slides/slides_present_bar.dart';
import 'package:niman/src/ui/kinds/slides/slides_tap_hint.dart';

/// The slide alone on the whole screen (#534), as the audience sees it:
/// taps, swipes and the mouse's bar move it; B's blackout hides it.
final class SlidesAloneView extends StatelessWidget {
  /// Shows [slide], number [index] of [count].
  const new({
    required this.slide,
    required this.index,
    required this.count,
    required this.resolveEmbed,
    required this.mathCache,
    required this.black,
    required this.bar,
    required this.touch,
    required this.hint,
    required this.onTapUp,
    required this.onGo,
    required this.onExit,
    required this.onPoke,
    required this.onOverview,
    required this.onNotes,
    super.key,
  });

  /// The slide on screen.
  final Slide slide;

  /// Its place in the deck, from 0.
  final int index;

  /// How many slides.
  final int count;

  /// Resolves a picture's target.
  final Future<String?> Function(String target) resolveEmbed;

  /// The deck's formulas, typeset once for every slide drawn (#672).
  final MathCache mathCache;

  /// Whether the screen is blacked out.
  final bool black;

  /// Whether the mouse's bar shows.
  final bool bar;

  /// A touch screen: the count in a corner instead of the bar.
  final bool touch;

  /// Whether the tap hint shows.
  final bool hint;

  /// A tap on the slide.
  final GestureTapUpCallback onTapUp;

  /// Goes to a slide.
  final ValueChanged<int> onGo;

  /// Stops presenting.
  final VoidCallback onExit;

  /// The mouse moved.
  final VoidCallback onPoke;

  /// Opens the overview.
  final VoidCallback onOverview;

  /// Opens the presenter view.
  final VoidCallback onNotes;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: bar ? MouseCursor.defer : SystemMouseCursors.none,
      onHover: (_) => onPoke(),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const Key('slides-present'),
              behavior: HitTestBehavior.opaque,
              onTapUp: onTapUp,
              onHorizontalDragEnd: (details) {
                final speed = details.primaryVelocity ?? 0;
                if (speed < -300) onGo(index + 1);
                if (speed > 300) onGo(index - 1);
              },
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) > 300) onExit();
              },
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: SlideFrame(
                    key: ValueKey(index),
                    markdown: slide.markdown,
                    resolveEmbed: resolveEmbed,
                    mathCache: mathCache,
                    live: false,
                  ),
                ),
              ),
            ),
          ),
          if (black)
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  key: Key('slides-black'),
                  color: Colors.black,
                ),
              ),
            ),
          if (touch)
            Positioned(
              right: 14,
              bottom: 10,
              child: Text(
                '${index + 1} / $count',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            )
          else
            Positioned(
              left: 0,
              right: 0,
              bottom: 22,
              child: IgnorePointer(
                ignoring: !bar,
                child: AnimatedOpacity(
                  opacity: bar ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Center(
                    child: SlidesPresentBar(
                      index: index,
                      count: count,
                      onPrevious: () => onGo(index - 1),
                      onNext: () => onGo(index + 1),
                      onOverview: onOverview,
                      onNotes: onNotes,
                      onExit: onExit,
                    ),
                  ),
                ),
              ),
            ),
          if (hint) const Positioned.fill(child: SlidesTapHint()),
        ],
      ),
    );
  }
}
