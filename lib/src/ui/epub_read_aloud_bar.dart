/// The player of a book read aloud (#1276), in the book's row's place while
/// it reads: where the voice is, stop, the paragraph before and after,
/// play and pause, the speed and the voice.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/action_sheet.dart' show menuAnchorOf;
import 'package:niman/src/ui/epub_read_aloud.dart';

import 'package:niman/src/ui/strings.dart';

/// The player's bar over [reading].
final class EpubReadAloudBar extends StatelessWidget {
  /// The bar of [reading]; [voiceName] says what it reads with.
  const new({
    required this.reading,
    required this.voiceName,
    required this.onVoice,
    super.key,
  });

  /// The reading.
  final EpubReadAloud reading;

  /// The language and the voice, as the bar says them while it plays.
  final String voiceName;

  /// Opens the voice and speed sheet, from the button's place.
  final ValueChanged<Rect?> onVoice;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: reading,
    builder: (context, _) {
      final theme = Theme.of(context);
      final colors = theme.colorScheme;
      final at = reading.at;
      final count = reading.paragraphs.length;
      final where = at == null
          ? ''
          : AppStrings.readAloudWhere(
              reading.chapterTitle(at.chapter),
              at.paragraph + 1,
              count,
            );
      final fill = at == null || count == 0 ? 0.0 : (at.paragraph + 1) / count;
      final next =
          EpubReadAloud.rates[(EpubReadAloud.rates.indexOf(reading.rate) + 1) %
              EpubReadAloud.rates.length];
      return SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Semantics(
              container: true,
              label: AppStrings.readAloud,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            where,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          reading.playing
                              ? voiceName
                              : AppStrings.readAloudPaused,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                    child: LinearProgressIndicator(
                      value: fill,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        key: const Key('read-aloud-stop'),
                        tooltip: AppStrings.readAloudStop,
                        icon: const Icon(Icons.close),
                        onPressed: reading.stop,
                      ),
                      IconButton(
                        key: const Key('read-aloud-previous'),
                        tooltip: AppStrings.readAloudPrevious,
                        icon: const Icon(Icons.skip_previous_outlined),
                        onPressed: reading.previous,
                      ),
                      IconButton.filled(
                        key: const Key('read-aloud-play'),
                        tooltip: reading.playing
                            ? AppStrings.readAloudPause
                            : AppStrings.readAloudResume,
                        iconSize: 28,
                        constraints: const BoxConstraints.tightFor(
                          width: 56,
                          height: 56,
                        ),
                        icon: Icon(
                          reading.playing ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: reading.toggle,
                      ),
                      IconButton(
                        key: const Key('read-aloud-next'),
                        tooltip: AppStrings.readAloudNext,
                        icon: const Icon(Icons.skip_next_outlined),
                        onPressed: reading.next,
                      ),
                      Tooltip(
                        message: AppStrings.readAloudSpeed(
                          AppStrings.readAloudRate(next),
                        ),
                        child: OutlinedButton(
                          key: const Key('read-aloud-speed'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(56, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () => reading.setRate(next),
                          child: Text(
                            AppStrings.readAloudRate(reading.rate),
                            semanticsLabel: AppStrings.readAloudSpeed(
                              AppStrings.readAloudRate(reading.rate),
                            ),
                          ),
                        ),
                      ),
                      Builder(
                        builder: (context) => IconButton(
                          key: const Key('read-aloud-voice'),
                          tooltip: AppStrings.readAloudVoice,
                          icon: const Icon(Icons.record_voice_over_outlined),
                          onPressed: () => onVoice(menuAnchorOf(context)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
