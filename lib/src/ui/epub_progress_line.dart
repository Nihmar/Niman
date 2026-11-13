/// A book's progress line (#1275): how far into the chapter, how far into
/// the book, or the reading time left, a tap moving to the next view.
///
/// One button, labelled with what it shows and, as its hint, what a tap
/// shows next, so TalkBack and a keyboard reach it as any other. On a
/// phone it is a line over the book's row, as wide as the pane; on a
/// tablet and a desktop it sits in the row, beside the book's name, and a
/// pointer resting on it shows the three measures at once.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/epub/epub_progress.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/markdown/render/scroll_anchor.dart';
import 'package:niman/src/ui/strings.dart';

/// Where the reader is, as the line shows it: the chapter's title and the
/// measures.
typedef EpubProgressHere = ({String title, EpubProgressAt at});

/// Where the reader of [document] is, its [progress] measured with the
/// top of the view at [top], or at the book's end when [atEnd].
EpubProgressHere epubProgressHere(
  EpubDocument document,
  EpubProgress progress,
  ScrollAnchor? top, {
  bool atEnd = false,
}) {
  final line = atEnd ? progress.counts.lines : top?.line ?? 0;
  final at = atEnd ? progress.at(line) : progress.at(line, top?.fraction ?? 0);
  final entry = document.entryAt(line);
  return (
    title: entry == -1
        ? AppStrings.epubConvertChapterName.replaceAll('{n}', '${at.chapter}')
        : document.contents[entry].title,
    at: at,
  );
}

/// Keeps [view] as what the books' progress line shows in [session]'s
/// library, the rest of their look as it was.
Future<void> keepEpubProgressView(
  LibrarySession session,
  EpubProgressView view,
) async {
  final look = await session.librarySettings.epubLook;
  await session.librarySettings.setEpubLook(look.copyWith(progress: view));
}

/// Shows [view] on every open book at once, before it is kept.
void showEpubProgressView(EpubProgressView view) => EpubLooks.apply(
  EpubLooks.look.copyWith(progress: view),
  theme: EpubLooks.theme,
);

/// The progress line of a book.
final class EpubProgressLine extends StatelessWidget {
  /// The line over [progress], following [here].
  const new({
    required this.progress,
    required this.here,
    required this.view,
    this.onView,
    this.inline = false,
    super.key,
  });

  /// The book's progress, for the ticks of its chapters.
  final EpubProgress progress;

  /// Where the reader is, as the book scrolls.
  final ValueListenable<EpubProgressHere> here;

  /// What the line shows.
  final EpubProgressView view;

  /// Moves to another view; null leaves the line as it is.
  final ValueChanged<EpubProgressView>? onView;

  /// Whether the line sits in the book's row, as on a tablet and a desktop,
  /// rather than over it, as on a phone.
  final bool inline;

  /// The height of the line over the row, a thumb's.
  static const double height = 44;

  /// The width of the track in the row.
  static const double trackWidth = 96;

  /// What [view] says at [here].
  static String label(EpubProgressHere here, EpubProgressView view) {
    final at = here.at;
    return switch (view) {
      EpubProgressView.chapter => '${here.title} · ${_percent(at.inChapter)}%',
      EpubProgressView.book => AppStrings.epubProgressBook(
        _percent(at.inBook),
        at.chapter,
        at.chapters,
      ),
      EpubProgressView.time => AppStrings.epubProgressTime(
        _time(at.chapterMinutes),
        _time(at.bookMinutes),
      ),
    };
  }

  /// A fraction as a whole percentage, 100 only at the very end.
  static int _percent(double fraction) =>
      (fraction * 100).floor().clamp(0, 100);

  static String _time(int minutes) =>
      AppStrings.readingTimeValue(minutes ~/ 60, minutes % 60);

  /// What a tap shows next.
  static String _hint(EpubProgressView view) => switch (view.next) {
    EpubProgressView.chapter => AppStrings.epubProgressShowChapter,
    EpubProgressView.book => AppStrings.epubProgressShowBook,
    EpubProgressView.time => AppStrings.epubProgressShowTime,
  };

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: here,
    builder: (context, here, _) {
      final text = label(here, view);
      final at = here.at;
      final fill = view == EpubProgressView.book ? at.inBook : at.inChapter;
      final ticks = view == EpubProgressView.book
          ? progress.chapterTicks
          : const <double>[];
      final onView = this.onView;
      final line = Semantics(
        container: true,
        button: true,
        label: text,
        hint: _hint(view),
        excludeSemantics: true,
        onTap: onView == null ? null : () => onView(view.next),
        child: InkWell(
          key: const Key('epub-progress'),
          borderRadius: BorderRadius.circular(8),
          onTap: onView == null ? null : () => onView(view.next),
          child: inline
              ? _inline(context, text, fill, ticks)
              : _over(context, text, fill, ticks),
        ),
      );
      return Tooltip(
        message: [for (final view in EpubProgressView.values) label(here, view)]
            .join('\n'),
        excludeFromSemantics: true,
        child: line,
      );
    },
  );

  Widget _over(
    BuildContext context,
    String text,
    double fill,
    List<double> ticks,
  ) => SizedBox(
    height: height,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(child: _text(context, text)),
              const SizedBox(width: 8),
              _dots(context),
            ],
          ),
          const SizedBox(height: 6),
          _track(context, fill, ticks),
        ],
      ),
    ),
  );

  Widget _inline(
    BuildContext context,
    String text,
    double fill,
    List<double> ticks,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: _text(context, text)),
        const SizedBox(width: 10),
        SizedBox(width: trackWidth, child: _track(context, fill, ticks)),
        const SizedBox(width: 8),
        _dots(context),
      ],
    ),
  );

  Widget _text(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  /// The three views, the one shown filled.
  Widget _dots(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final each in EpubProgressView.values)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: each == view ? colors.primary : colors.outlineVariant,
            ),
          ),
      ],
    );
  }

  /// How far, a tick at every chapter's start on the book's.
  Widget _track(BuildContext context, double fill, List<double> ticks) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(color: colors.surfaceContainerHighest),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: box.maxWidth * fill.clamp(0, 1),
                child: ColoredBox(color: colors.primary),
              ),
              for (final tick in ticks)
                Positioned(
                  left: box.maxWidth * tick,
                  top: 0,
                  bottom: 0,
                  width: 1,
                  child: ColoredBox(color: colors.surface),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
