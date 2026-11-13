/// A book read aloud (#1276): where the voice is, and what it does next.
///
/// The book goes to the engine a sentence at a time, the next one queued
/// behind the one sounding so there is no gap between them; the engine
/// says when each begins, and that is where the reader is. A pause is a
/// stop that keeps the sentence — Android's engine has no pause — so play
/// says it again. A chapter's end goes on into the next chapter, read when
/// it is reached; the book's end stops. A control outside the app (the
/// notification, the lock screen, a headset, a call) asks the same of it.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/epub/read_aloud_text.dart';
import 'package:niman/src/ui/epub_read_aloud_engine.dart';

/// A place in what is read: the chapter, the paragraph of it and the
/// sentence of that, each an index.
typedef ReadAloudAt = ({int chapter, int paragraph, int sentence});

/// The reading of one book.
final class EpubReadAloud extends ChangeNotifier {
  /// The reading of a book whose chapters open on [chapterLines] and whose
  /// text has [lineCount] lines, read by [engine]; [paragraphsOf] gives
  /// what is spoken of lines start..end.
  new({
    required this.engine,
    required List<int> chapterLines,
    required this.lineCount,
    required this.paragraphsOf,
    required this.title,
    required this.chapterTitle,
    required this.channel,
    this.language,
    this.onSpoken,
  }) : _chapters = chapterLines.isEmpty ? const [0] : chapterLines {
    _events = engine.events.listen(_heard);
  }

  /// The engine spoken with.
  final ReadAloudEngine engine;

  /// The lines of the book.
  final int lineCount;

  /// What is spoken of the book's lines start..end, the end excluded.
  final List<ReadAloudParagraph> Function(int start, int end) paragraphsOf;

  /// The book's title, for the notification.
  final String title;

  /// The title of the chapter at an index, for the notification and the
  /// bar.
  final String Function(int chapter) chapterTitle;

  /// The notification channel's name.
  final String channel;

  /// The book's language (`dc:language`), whose default voice is used
  /// when no voice is picked.
  final String? language;

  /// Told the line of each sentence as it begins: the place to keep.
  final ValueChanged<int>? onSpoken;

  /// The pace the books were last read at, kept for the session: the next
  /// book starts at it.
  static double lastRate = 1;

  /// The voice last picked, kept for the session as [lastRate] is.
  static String? lastVoice;

  /// The paces the speed button cycles through.
  static const List<double> rates = [1, 1.25, 1.5, 2, 0.5, 0.75];

  /// The slowest and the fastest pace.
  static const double minRate = 0.5;

  /// See [minRate].
  static const double maxRate = 2;

  final List<int> _chapters;
  final Map<int, List<ReadAloudParagraph>> _read = {};
  late final StreamSubscription<ReadAloudEvent> _events;

  /// Utterance ids: every sentence handed over gets the next one; those
  /// before [_from] were dropped by a flush and are not listened to.
  int _ids = 0;
  int _from = 0;
  final Map<int, ReadAloudAt> _spoken = {};
  int? _queued;

  /// Whether a reading is on: the bar in the row's place.
  bool get active => _at != null;

  /// Whether the voice is speaking.
  bool get playing => _playing;
  bool _playing = false;

  /// The sentence being spoken, or paused on.
  ReadAloudAt? get at => _at;
  ReadAloudAt? _at;

  /// The pace, 1 the engine's normal.
  double get rate => _rate;
  double _rate = lastRate;

  /// The voice picked, or null for the language's default.
  String? get voice => _voice;
  String? _voice = lastVoice;

  /// The paragraphs of the chapter being read.
  List<ReadAloudParagraph> get paragraphs => switch (_at) {
    final at? => _paragraphs(at.chapter),
    null => const [],
  };

  /// The sentence being spoken, and its paragraph's line.
  ({int line, ReadAloudSentence sentence})? get sentence {
    final at = _at;
    if (at == null) return null;
    final paragraph = _paragraphs(at.chapter)[at.paragraph];
    return (line: paragraph.line, sentence: paragraph.sentences[at.sentence]);
  }

  List<ReadAloudParagraph> _paragraphs(int chapter) =>
      _read[chapter] ??= _readChapter(chapter);

  List<ReadAloudParagraph> _readChapter(int chapter) {
    // Two chapters are kept at most: the one read and the one next to it.
    _read.removeWhere((index, _) => (index - chapter).abs() > 1);
    final end = chapter + 1 < _chapters.length
        ? _chapters[chapter + 1]
        : lineCount;
    return paragraphsOf(_chapters[chapter], end);
  }

  int _chapterAt(int line) {
    final index = _chapters.lastIndexWhere((start) => start <= line);
    return index == -1 ? 0 : index;
  }

  /// Starts reading at the paragraph holding [line], or the first one
  /// after it; false when nothing is left to read from there.
  bool start(int line) {
    var chapter = _chapterAt(line);
    final paragraphs = _paragraphs(chapter);
    var paragraph = paragraphs.lastIndexWhere((p) => p.line <= line);
    if (paragraph == -1) paragraph = 0;
    ReadAloudAt? at = (chapter: chapter, paragraph: paragraph, sentence: 0);
    if (paragraphs.isEmpty) {
      at = _firstFrom(chapter + 1);
      if (at == null) return false;
      chapter = at.chapter;
    }
    _at = at;
    play();
    return true;
  }

  /// Speaks from the sentence it is on.
  void play() {
    final at = _at;
    if (at == null) return;
    _playing = true;
    _speak(at, flush: true);
    _show();
    notifyListeners();
  }

  /// Stops speaking, keeping the sentence.
  void pause() {
    if (!_playing) return;
    _playing = false;
    _from = _ids + 1;
    _queued = null;
    unawaited(engine.stop());
    _show();
    notifyListeners();
  }

  /// Pauses when speaking, plays when not.
  void toggle() => _playing ? pause() : play();

  /// The next paragraph; at the last, nothing.
  void next() {
    final at = _at;
    if (at == null) return;
    final next = _nextParagraph(at);
    if (next != null) _moveTo(next);
  }

  /// This paragraph's start when into it, else the paragraph before.
  void previous() {
    final at = _at;
    if (at == null) return;
    _moveTo(
      at.sentence > 0
          ? (chapter: at.chapter, paragraph: at.paragraph, sentence: 0)
          : _previousParagraph(at),
    );
  }

  /// Reads on at [rate], from the sentence it is on.
  void setRate(double rate) {
    _rate = lastRate = rate.clamp(minRate, maxRate);
    if (_playing) {
      play();
    } else {
      notifyListeners();
    }
  }

  /// Reads on in [voice], or the language's default when null.
  void setVoice(String? voice) {
    _voice = lastVoice = voice;
    if (_playing) {
      play();
    } else {
      notifyListeners();
    }
  }

  /// Stops reading: the bar and the notification go.
  void stop() {
    if (_at == null) return;
    _playing = false;
    _at = null;
    _from = _ids + 1;
    _queued = null;
    _spoken.clear();
    unawaited(engine.stop());
    unawaited(engine.hide());
    notifyListeners();
  }

  void _moveTo(ReadAloudAt at) {
    final chapter = _at?.chapter;
    _at = at;
    if (_playing) {
      _speak(at, flush: true);
    } else {
      _tell(at);
    }
    if (chapter != at.chapter) _show();
    notifyListeners();
  }

  void _speak(ReadAloudAt at, {required bool flush}) {
    final id = ++_ids;
    if (flush) {
      _from = id;
      _spoken.clear();
    }
    _spoken[id] = at;
    final paragraph = _paragraphs(at.chapter)[at.paragraph];
    unawaited(
      engine.speak(
        id,
        paragraph.sentences[at.sentence].text,
        flush: flush,
        rate: _rate,
        voice: _voice,
        language: language,
      ),
    );
    if (flush) {
      _queued = null;
      _queueAfter(at);
    }
  }

  /// Queues the sentence after [at], so the voice goes on without a gap.
  void _queueAfter(ReadAloudAt at) {
    final after = _after(at);
    if (after == null) return;
    _speak(after, flush: false);
    _queued = _ids;
  }

  void _heard(ReadAloudEvent event) {
    switch (event) {
      case ReadAloudStarted(:final id) when id >= _from && _playing:
        final at = _spoken[id];
        if (at == null) return;
        _spoken.removeWhere((key, _) => key < id);
        final chapter = _at?.chapter;
        _at = at;
        _tell(at);
        if (id == _queued) _queueAfter(at);
        if (chapter != at.chapter) _show();
        notifyListeners();
      case ReadAloudDone(:final id) when id >= _from && _playing:
        final at = _spoken[id];
        // The book's last sentence said: the reading ends.
        if (at != null && _after(at) == null) stop();
      case ReadAloudFailed(:final id) when id >= _from:
        pause();
      case ReadAloudCommanded(:final command):
        switch (command) {
          case ReadAloudCommand.play:
            play();
          case ReadAloudCommand.pause:
            pause();
          case ReadAloudCommand.next:
            next();
          case ReadAloudCommand.previous:
            previous();
          case ReadAloudCommand.stop:
            stop();
        }
      default:
        break;
    }
  }

  void _tell(ReadAloudAt at) =>
      onSpoken?.call(_paragraphs(at.chapter)[at.paragraph].line);

  void _show() {
    final at = _at;
    if (at == null) return;
    unawaited(
      engine.show(
        title: title,
        chapter: chapterTitle(at.chapter),
        playing: _playing,
        channel: channel,
      ),
    );
  }

  ReadAloudAt? _after(ReadAloudAt at) {
    final paragraph = _paragraphs(at.chapter)[at.paragraph];
    if (at.sentence + 1 < paragraph.sentences.length) {
      return (
        chapter: at.chapter,
        paragraph: at.paragraph,
        sentence: at.sentence + 1,
      );
    }
    return _nextParagraph(at);
  }

  ReadAloudAt? _nextParagraph(ReadAloudAt at) {
    if (at.paragraph + 1 < _paragraphs(at.chapter).length) {
      return (chapter: at.chapter, paragraph: at.paragraph + 1, sentence: 0);
    }
    return _firstFrom(at.chapter + 1);
  }

  /// The first paragraph of the first chapter from [chapter] on with any.
  ReadAloudAt? _firstFrom(int chapter) {
    for (var index = chapter; index < _chapters.length; index++) {
      if (_paragraphs(index).isNotEmpty) {
        return (chapter: index, paragraph: 0, sentence: 0);
      }
    }
    return null;
  }

  ReadAloudAt _previousParagraph(ReadAloudAt at) {
    if (at.paragraph > 0) {
      return (chapter: at.chapter, paragraph: at.paragraph - 1, sentence: 0);
    }
    for (var index = at.chapter - 1; index >= 0; index--) {
      final paragraphs = _paragraphs(index);
      if (paragraphs.isNotEmpty) {
        return (chapter: index, paragraph: paragraphs.length - 1, sentence: 0);
      }
    }
    return (chapter: at.chapter, paragraph: 0, sentence: 0);
  }

  @override
  void dispose() {
    stop();
    unawaited(_events.cancel());
    super.dispose();
  }
}
