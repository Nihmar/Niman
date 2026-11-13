// A book read aloud (#1276), over an engine that speaks nothing: a
// sentence at a time with the next queued, paused and resumed on the same
// sentence, skipped by paragraph across chapters, ended at the book's end,
// and driven by the controls outside the app.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/read_aloud_text.dart';
import 'package:niman/src/ui/epub_read_aloud.dart';
import 'package:niman/src/ui/epub_read_aloud_engine.dart';

import '../fakes/fake_read_aloud_engine.dart';

void main() {
  late FakeReadAloudEngine engine;
  late EpubReadAloud reading;
  late List<int> told;

  ReadAloudParagraph paragraph(int line, List<String> sentences) => (
    line: line,
    sentences: [for (final text in sentences) (text: text, chars: null)],
  );

  // Three chapters: two paragraphs, none, one.
  final book = <int, List<ReadAloudParagraph>>{
    0: [
      paragraph(0, ['A1.', 'A2.']),
      paragraph(2, ['B.']),
    ],
    10: const [],
    20: [
      paragraph(20, ['C.']),
    ],
  };

  setUp(() {
    EpubReadAloud.lastRate = 1;
    EpubReadAloud.lastVoice = null;
    engine = FakeReadAloudEngine();
    told = [];
    reading = EpubReadAloud(
      engine: engine,
      chapterLines: const [0, 10, 20],
      lineCount: 30,
      paragraphsOf: (start, _) => book[start] ?? const [],
      title: 'A book',
      chapterTitle: (chapter) => 'Chapter ${chapter + 1}',
      channel: 'Reading aloud',
      onSpoken: told.add,
    );
  });
  tearDown(() => reading.dispose());

  List<String> texts() => [for (final s in engine.spoken) s.text];

  test('starts at the paragraph asked, the next sentence queued', () {
    expect(reading.start(1), isTrue);
    expect(reading.active, isTrue);
    expect(reading.playing, isTrue);
    expect(reading.at, (chapter: 0, paragraph: 0, sentence: 0));
    expect(texts(), ['A1.', 'A2.']);
    expect(engine.spoken.first.flush, isTrue);
    expect(engine.spoken.last.flush, isFalse);
    expect(engine.shown, (
      title: 'A book',
      chapter: 'Chapter 1',
      playing: true,
    ));
  });

  test('moves on as the engine starts each sentence, queuing the next', () {
    reading.start(0);
    engine.start(engine.spoken[0].id);
    engine.start(engine.spoken[1].id);
    expect(reading.at, (chapter: 0, paragraph: 0, sentence: 1));
    expect(texts(), ['A1.', 'A2.', 'B.']);
    expect(told, [0, 0]);
  });

  test("a chapter's end goes on into the next with any text", () {
    reading.start(2);
    engine.start(engine.spoken[0].id);
    expect(texts(), ['B.', 'C.'], reason: 'the empty chapter is passed over');
    engine.start(engine.spoken[1].id);
    expect(reading.at, (chapter: 2, paragraph: 0, sentence: 0));
    expect(engine.shown?.chapter, 'Chapter 3');
  });

  test("the book's end stops the reading and its notification", () {
    reading.start(20);
    engine.start(engine.last.id);
    engine.done(engine.last.id);
    expect(reading.active, isFalse);
    expect(engine.hides, 1);
    expect(engine.shown, isNull);
  });

  test('a pause keeps the sentence, and play says it again', () {
    reading.start(0);
    engine.start(engine.spoken[0].id);
    engine.start(engine.spoken[1].id);
    reading.pause();
    expect(reading.playing, isFalse);
    expect(engine.stops, 1);
    expect(engine.shown?.playing, isFalse);
    // Late news of what was dropped changes nothing.
    engine.start(engine.spoken[2].id);
    expect(reading.at, (chapter: 0, paragraph: 0, sentence: 1));
    reading.play();
    expect(engine.spoken[3].text, 'A2.');
    expect(engine.spoken[3].flush, isTrue);
  });

  test('next and previous go by paragraph, across chapters', () {
    reading
      ..start(0)
      ..next();
    expect(reading.at, (chapter: 0, paragraph: 1, sentence: 0));
    expect(engine.last.text, 'C.', reason: 'B. said at once, C. queued');
    reading.next();
    expect(reading.at, (chapter: 2, paragraph: 0, sentence: 0));
    reading.next();
    expect(reading.at, (chapter: 2, paragraph: 0, sentence: 0), reason: 'last');
    reading.previous();
    expect(reading.at, (chapter: 0, paragraph: 1, sentence: 0));
  });

  test('previous inside a paragraph goes back to its start', () {
    reading.start(0);
    engine.start(engine.spoken[0].id);
    engine.start(engine.spoken[1].id);
    reading.previous();
    expect(reading.at, (chapter: 0, paragraph: 0, sentence: 0));
    expect(engine.spoken[engine.spoken.length - 2].text, 'A1.');
  });

  test('a start in a chapter with nothing to read begins at the next', () {
    expect(reading.start(12), isTrue);
    expect(reading.at, (chapter: 2, paragraph: 0, sentence: 0));
  });

  test('the speed applies from the sentence being read, in range', () {
    reading
      ..start(0)
      ..setRate(1.5);
    expect(engine.last.rate, 1.5);
    expect(engine.spoken[engine.spoken.length - 2].text, 'A1.');
    reading.setRate(9);
    expect(reading.rate, EpubReadAloud.maxRate);
    expect(EpubReadAloud.lastRate, EpubReadAloud.maxRate, reason: 'kept');
  });

  test('the controls outside the app drive it', () {
    reading.start(0);
    engine.command(ReadAloudCommand.pause);
    expect(reading.playing, isFalse);
    engine.command(ReadAloudCommand.play);
    expect(reading.playing, isTrue);
    engine.command(ReadAloudCommand.next);
    expect(reading.at?.paragraph, 1);
    engine.command(ReadAloudCommand.stop);
    expect(reading.active, isFalse);
  });

  test('stop drops the reading: the bar and the notification go', () {
    reading
      ..start(0)
      ..stop();
    expect(reading.active, isFalse);
    expect(reading.at, isNull);
    expect(engine.hides, 1);
  });
}
