import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/kinds/slides/slide_split.dart';
import 'package:niman/src/ui/kinds/slides/slide_stage.dart';
import 'package:niman/src/ui/kinds/slides/slide_thumbnail.dart';
import 'package:niman/src/ui/kinds/slides/speaker_notes.dart';

/// The slide view on a wide window (#534): the slide on screen large, its
/// speaker notes under it, and the deck as a row of thumbnails.
final class SlidesWideLayout extends StatelessWidget {
  /// Lays out [slides], the one at [index] on screen.
  const new({
    required this.slides,
    required this.index,
    required this.strip,
    required this.frame,
    required this.onGo,
    super.key,
  });

  /// The deck.
  final List<Slide> slides;

  /// The slide on screen.
  final int index;

  /// The thumbnail row's scroll, which the view keeps on the slide.
  final ScrollController strip;

  /// Draws a slide: live answers taps, a thumbnail does not.
  final Widget Function(Slide slide, {required bool live}) frame;

  /// Goes to a slide.
  final ValueChanged<int> onGo;

  /// The space between two thumbnails.
  static const double thumbGap = 10;

  @override
  Widget build(BuildContext context) {
    final slide = slides[index];
    final notes = slide.notes;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
            child: LayoutBuilder(
              builder: (context, box) {
                // A pane shorter than the notes gives them all of it, the
                // slide none, rather than a negative size.
                final notesHeight = math.min<double>(120, box.maxHeight);
                final room = box.maxHeight - (notes == null ? 0 : notesHeight);
                final width = math.min(box.maxWidth, room * 16 / 9);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: width,
                      height: width * 9 / 16,
                      child: SlideStage(child: frame(slide, live: true)),
                    ),
                    if (notes != null)
                      SizedBox(
                        width: width,
                        height: notesHeight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SpeakerNotes(notes: notes),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        SizedBox(
          height: 116,
          child: Row(
            children: [
              Expanded(
                child: ListView.separated(
                  key: const Key('slides-strip'),
                  controller: strip,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: slides.length,
                  separatorBuilder: (_, _) => const SizedBox(width: thumbGap),
                  itemBuilder: (context, i) => SlideThumbnail(
                    key: Key('slide-thumb-$i'),
                    number: i + 1,
                    selected: i == index,
                    onTap: () => onGo(i),
                    child: frame(slides[i], live: false),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${index + 1} / ${slides.length}',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
