import 'package:flutter/material.dart';
import 'package:niman/src/ui/kinds/slides/slide_frame.dart';
import 'package:niman/src/ui/kinds/slides/slide_split.dart';

/// Every slide of the deck in a grid, one ringed (#534): pick one to go
/// there. Presenting and the presenter view both open it.
final class SlidesOverview extends StatelessWidget {
  /// The grid over [slides], [selected] ringed.
  const new({
    required this.slides,
    required this.selected,
    required this.resolveEmbed,
    required this.onPick,
    super.key,
  });

  /// The deck.
  final List<Slide> slides;

  /// The slide ringed: the one on screen, or where the arrows took it.
  final int selected;

  /// Resolves a picture's target.
  final Future<String?> Function(String target) resolveEmbed;

  /// Goes to the slide picked.
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      key: const Key('slides-overview'),
      color: scheme.surface,
      child: GridView.builder(
        padding: const EdgeInsets.all(40),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          mainAxisSpacing: 26,
          crossAxisSpacing: 22,
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
                child: Container(
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: index == selected
                          ? scheme.primary
                          : scheme.outlineVariant,
                      width: index == selected ? 3 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SlideFrame(
                      markdown: slides[index].markdown,
                      resolveEmbed: resolveEmbed,
                      live: false,
                    ),
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
