import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/kinds/slides/slide_frame.dart';
import 'package:niman/src/ui/kinds/slides/slide_split.dart';
import 'package:niman/src/ui/kinds/slides/slide_stage.dart';

/// Every slide of the deck in a grid, one ringed (#534): pick one to go
/// there. Presenting and the presenter view both open it.
final class SlidesOverview extends StatelessWidget {
  /// The grid over [slides], [selected] ringed.
  const new({
    required this.slides,
    required this.selected,
    required this.resolveEmbed,
    required this.mathCache,
    required this.onPick,
    super.key,
  });

  /// The deck.
  final List<Slide> slides;

  /// The slide ringed: the one on screen, or where the arrows took it.
  final int selected;

  /// Resolves a picture's target.
  final Future<String?> Function(String target) resolveEmbed;

  /// The deck's formulas, typeset once for every slide drawn (#672).
  final MathCache mathCache;

  /// Goes to the slide picked.
  final ValueChanged<int> onPick;

  static const double _padding = 40;
  static const double _gap = 22;

  /// How many slides a row holds on a screen [width] wide: what the
  /// arrows step by to go up or down one.
  static int columnsFor(double width) =>
      math.max(1, ((width - 2 * _padding) / (280 + _gap)).ceil());

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      key: const Key('slides-overview'),
      color: scheme.surface,
      child: GridView.builder(
        padding: const EdgeInsets.all(_padding),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnsFor(MediaQuery.sizeOf(context).width),
          mainAxisSpacing: 26,
          crossAxisSpacing: _gap,
          childAspectRatio: 16 / 11,
        ),
        itemCount: slides.length,
        itemBuilder: (context, index) => InkWell(
          key: Key('overview-slide-$index'),
          onTap: () => onPick(index),
          borderRadius: BorderRadius.circular(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: SlideStage(
                  radius: 6,
                  ringWidth: index == selected ? 3 : null,
                  child: SlideFrame(
                    markdown: slides[index].markdown,
                    resolveEmbed: resolveEmbed,
                    mathCache: mathCache,
                    live: false,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${index + 1}',
                style: TextStyle(
                  color: index == selected
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
