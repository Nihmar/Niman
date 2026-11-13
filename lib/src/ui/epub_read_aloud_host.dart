/// What the book's pane holds of a reading aloud (#1276): it starts one —
/// asking first when the device has no voice for the book's language —
/// marks the sentence spoken, follows it until the reader scrolls away by
/// hand, and brings the view back on *Back to the voice*. The pane only
/// wires it in.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/epub/read_aloud_text.dart';
import 'package:niman/src/markdown/render/mark_highlight.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/range_highlight.dart';
import 'package:niman/src/ui/epub_read_aloud.dart';
import 'package:niman/src/ui/epub_read_aloud_bar.dart';
import 'package:niman/src/ui/epub_read_aloud_engine.dart';
import 'package:niman/src/ui/epub_read_aloud_sheet.dart';
import 'package:niman/src/ui/strings.dart';

/// The reading aloud of one book on screen.
final class EpubReadAloudHost extends ChangeNotifier {
  /// Reads [document] with [engine], off the blocks of the view [view]
  /// gives, telling [onSpoken] each paragraph's line as the voice reaches
  /// it.
  new({
    required this.engine,
    required this.document,
    required this.view,
    required this.onSpoken,
  });

  /// The engine.
  final ReadAloudEngine engine;

  /// The book.
  final EpubDocument document;

  /// The book's read view, once drawn.
  final MarkdownReadViewState? Function() view;

  /// Told the line the voice has reached: the place to keep.
  final ValueChanged<int> onSpoken;

  EpubReadAloud? _reading;
  ReadAloudVoices? _voices;
  int? _followed;

  /// The reading, while one is on.
  EpubReadAloud? get reading => _reading;

  /// Whether a reading is on: the player in the row's place.
  bool get active => _reading?.active ?? false;

  /// Whether the reader has scrolled away from the voice by hand.
  bool get away => _away;
  bool _away = false;

  /// Reads from the paragraph at [line]; first, when the device has no
  /// voice for the book's language, says so, and reads on only if asked.
  Future<void> start(BuildContext context, int line) async {
    final voices = _voices ??= await engine.voices(document.language);
    if (!voices.available && document.language != null) {
      if (!context.mounted) return;
      final read = await showReadAloudNoVoice(
        context,
        engine,
        voices.languageName,
      );
      if (!read) return;
    }
    final reading = _reading ??= EpubReadAloud(
      engine: engine,
      chapterLines: [for (final chapter in document.chapters) chapter.line],
      lineCount: document.counts.lines,
      paragraphsOf: (start, end) =>
          readAloudParagraphs(view()?.readBlocks(start, end) ?? const []),
      title: document.title,
      chapterTitle: _chapterTitle,
      channel: AppStrings.readAloudChannel,
      language: available ? document.language : null,
      onSpoken: onSpoken,
    )..addListener(_follow);
    _away = false;
    _followed = null;
    if (!reading.start(line)) return;
    notifyListeners();
  }

  /// Whether the book's language has a voice on the device.
  bool get available => _voices?.available ?? false;

  String _chapterTitle(int chapter) {
    final line = document.chapters.isEmpty
        ? 0
        : document.chapters[chapter].line;
    final entry = document.entryAt(line);
    return entry == -1
        ? AppStrings.epubConvertChapterName.replaceAll('{n}', '${chapter + 1}')
        : document.contents[entry].title;
  }

  /// The sentence spoken, as the view marks it.
  List<BlockMark> get marks => switch (_reading?.sentence) {
    final spoken? when active => [
      (
        line: spoken.line,
        chars: spoken.sentence.chars,
        highlight: HighlightColour.yellow,
      ),
    ],
    _ => const [],
  };

  /// The view was moved by hand: it stops following the voice.
  void scrolledByHand() {
    if (!active || _away) return;
    _away = true;
    notifyListeners();
  }

  /// Brings the view back to the voice, and follows it again.
  void back() {
    _away = false;
    _followed = null;
    _follow();
  }

  void _follow() {
    final spoken = _reading?.sentence;
    if (active && !_away && spoken != null && spoken.line != _followed) {
      _followed = spoken.line;
      view()?.showAnchor((line: spoken.line, fraction: 0));
    }
    notifyListeners();
  }

  /// The player's bar, in the row's place.
  Widget bar(BuildContext context) {
    final reading = _reading!;
    final voices = _voices;
    final language = voices?.languageName ?? '';
    return EpubReadAloudBar(
      reading: reading,
      voiceName: language.isEmpty
          ? AppStrings.readAloudDeviceVoice
          : '$language · ${AppStrings.readAloudDeviceVoice}',
      onVoice: (anchor) => unawaited(
        showReadAloudVoiceSheet(
          context,
          reading: reading,
          voices:
              voices ??
              (languageName: language, available: false, voices: const []),
          anchor: anchor,
        ),
      ),
    );
  }

  /// [book] with *Back to the voice* over it once the reader has scrolled
  /// away, and its drags heard.
  Widget around(Widget book) => NotificationListener<ScrollStartNotification>(
    onNotification: (notification) {
      if (notification.dragDetails != null) scrolledByHand();
      return false;
    },
    child: Stack(
      children: [
        book,
        if (active && _away)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: FilledButton.icon(
                key: const Key('read-aloud-back'),
                icon: const Icon(Icons.arrow_downward),
                label: Text(AppStrings.readAloudBackToVoice),
                onPressed: back,
              ),
            ),
          ),
      ],
    ),
  );

  @override
  void dispose() {
    _reading?.removeListener(_follow);
    _reading?.dispose();
    _reading = null;
    super.dispose();
  }
}
