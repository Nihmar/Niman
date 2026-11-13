// An engine that speaks nothing: it keeps what it was asked, and a test
// says when an utterance starts and ends.
import 'dart:async';

import 'package:niman/src/ui/epub_read_aloud_engine.dart';

/// A spoken utterance, as the engine was handed it.
typedef FakeUtterance = ({int id, String text, bool flush, double rate});

/// The read-aloud engine of a test.
final class FakeReadAloudEngine implements ReadAloudEngine {
  /// An engine whose language has a voice unless [available] is false.
  new({this.available = true, this.voiceNames = const ['a', 'b']});

  /// Whether the book's language has a voice.
  final bool available;

  /// The voices it lists.
  final List<String> voiceNames;

  final StreamController<ReadAloudEvent> _events =
      StreamController<ReadAloudEvent>.broadcast(sync: true);

  /// Everything handed over, in order.
  final List<FakeUtterance> spoken = [];

  /// How many times it was stopped, opened its settings, and hidden.
  int stops = 0;
  int settings = 0;
  int hides = 0;

  /// The notification's last state, null while hidden.
  ({String title, String chapter, bool playing})? shown;

  @override
  Stream<ReadAloudEvent> get events => _events.stream;

  /// Says [id] began to sound.
  void start(int id) => _events.add(ReadAloudStarted(id));

  /// Says [id] was spoken to its end.
  void done(int id) => _events.add(ReadAloudDone(id));

  /// A control outside the app asks [command].
  void command(ReadAloudCommand command) =>
      _events.add(ReadAloudCommanded(command));

  /// The last utterance handed over.
  FakeUtterance get last => spoken.last;

  @override
  Future<void> speak(
    int id,
    String text, {
    required bool flush,
    required double rate,
    String? voice,
    String? language,
  }) async => spoken.add((id: id, text: text, flush: flush, rate: rate));

  @override
  Future<void> stop() async => stops++;

  @override
  Future<ReadAloudVoices> voices(String? language) async => (
    languageName: 'English',
    available: available,
    voices: [for (final name in voiceNames) (name: name, network: false)],
  );

  @override
  Future<void> sample(
    String voice,
    String text, {
    required double rate,
  }) async {}

  @override
  Future<void> openSettings() async => settings++;

  @override
  Future<void> show({
    required String title,
    required String chapter,
    required bool playing,
    required String channel,
  }) async => shown = (title: title, chapter: chapter, playing: playing);

  @override
  Future<void> hide() async {
    hides++;
    shown = null;
  }
}
