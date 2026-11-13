/// The voice a book is read aloud with (#1276): the system's
/// text-to-speech engine, on Android for now.
///
/// Android's `TextToSpeech`, the engine TalkBack speaks with, through the
/// `niman/read_aloud` channel (`ReadAloudBridge.kt`); a media notification
/// and the lock screen's controls come with it, under a foreground service
/// of type `mediaPlayback`. The other platforms have an engine too
/// (AVSpeechSynthesizer, the Windows speech API, speech-dispatcher) and
/// may get read aloud later: until then there is no engine there, and the
/// control does not show (`docs/user/platforms.md`).
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:niman/src/ui/strings.dart';

/// What the engine says happened.
sealed class ReadAloudEvent {
  const new();
}

/// The utterance [id] has begun to sound.
final class ReadAloudStarted extends ReadAloudEvent {
  /// See [ReadAloudStarted].
  const new(this.id);

  /// The utterance.
  final int id;
}

/// The utterance [id] has been spoken to its end.
final class ReadAloudDone extends ReadAloudEvent {
  /// See [ReadAloudDone].
  const new(this.id);

  /// The utterance.
  final int id;
}

/// The utterance [id] could not be spoken.
final class ReadAloudFailed extends ReadAloudEvent {
  /// See [ReadAloudFailed].
  const new(this.id);

  /// The utterance.
  final int id;
}

/// A control outside the app asked for something: the notification's, the
/// lock screen's, a headset's — or the system, pausing for a call, another
/// app's audio or headphones unplugged.
final class ReadAloudCommanded extends ReadAloudEvent {
  /// See [ReadAloudCommanded].
  const new(this.command);

  /// What was asked.
  final ReadAloudCommand command;
}

/// What a control outside the app asks of the reading.
enum ReadAloudCommand {
  /// Go on.
  play,

  /// Stop where it is, keeping the sentence.
  pause,

  /// The next paragraph.
  next,

  /// The paragraph before, or this one's start.
  previous,

  /// Stop reading altogether.
  stop;

  /// The command named [name]; null for one this build does not know.
  static ReadAloudCommand? fromName(Object? name) {
    for (final command in values) {
      if (command.name == name) return command;
    }
    return null;
  }
}

/// A voice of the device: its engine's name for it, and whether it needs
/// the network.
typedef ReadAloudVoice = ({String name, bool network});

/// The voices for a language: its name in the interface's language, whether
/// the device can speak it, and its voices.
typedef ReadAloudVoices = ({
  String languageName,
  bool available,
  List<ReadAloudVoice> voices,
});

/// The engine a book is read with.
abstract interface class ReadAloudEngine {
  /// The engine of this platform, or null where there is none yet.
  static final ReadAloudEngine? platform = Platform.isAndroid
      ? AndroidReadAloudEngine()
      : null;

  /// What happens, as it happens.
  Stream<ReadAloudEvent> get events;

  /// Speaks [text] as utterance [id], after what is queued, or in its
  /// place when [flush]: at [rate] (1 is normal), in [voice] or the
  /// [language]'s default when null.
  Future<void> speak(
    int id,
    String text, {
    required bool flush,
    required double rate,
    String? voice,
    String? language,
  });

  /// Stops speaking, the queue dropped.
  Future<void> stop();

  /// The device's voices for [language] (a BCP 47 tag, the book's), or for
  /// its default language when null.
  Future<ReadAloudVoices> voices(String? language);

  /// Speaks [text] in [voice] at [rate], as a sample of it.
  Future<void> sample(String voice, String text, {required double rate});

  /// Opens the system's text-to-speech settings, where a voice is
  /// installed.
  Future<void> openSettings();

  /// Shows the reading outside the app, or updates it: the notification
  /// and the lock screen's controls, under [channel] the first time.
  Future<void> show({
    required String title,
    required String chapter,
    required bool playing,
    required String channel,
  });

  /// Takes the reading's notification and controls away.
  Future<void> hide();
}

/// The engine on Android, over `niman/read_aloud`.
final class AndroidReadAloudEngine implements ReadAloudEngine {
  /// Listens on the channel for what the bridge tells.
  new([this._channel = const MethodChannel('niman/read_aloud')]) {
    _channel.setMethodCallHandler(_heard);
  }

  final MethodChannel _channel;
  final StreamController<ReadAloudEvent> _events =
      StreamController<ReadAloudEvent>.broadcast();

  @override
  Stream<ReadAloudEvent> get events => _events.stream;

  Future<void> _heard(MethodCall call) async {
    final args = call.arguments;
    final id = args is Map ? args['id'] : null;
    final event = switch (call.method) {
      'started' when id is int => ReadAloudStarted(id),
      'done' when id is int => ReadAloudDone(id),
      'failed' when id is int => ReadAloudFailed(id),
      'command' => switch (ReadAloudCommand.fromName(
        args is Map ? args['name'] : null,
      )) {
        final command? => ReadAloudCommanded(command),
        null => null,
      },
      _ => null,
    };
    if (event != null) _events.add(event);
  }

  @override
  Future<void> speak(
    int id,
    String text, {
    required bool flush,
    required double rate,
    String? voice,
    String? language,
  }) => _channel.invokeMethod<void>('speak', {
    'id': id,
    'text': text,
    'flush': flush,
    'rate': rate,
    'voice': voice,
    'language': language,
  });

  @override
  Future<void> stop() => _channel.invokeMethod<void>('stop');

  @override
  Future<ReadAloudVoices> voices(String? language) async {
    final answer = await _channel.invokeMapMethod<String, Object?>('voices', {
      'language': language,
    });
    final voices = answer?['voices'];
    return (
      languageName: answer?['languageName'] as String? ?? language ?? '',
      available: answer?['available'] == true,
      voices: [
        if (voices is List)
          for (final voice in voices)
            if (voice is Map && voice['name'] is String)
              (
                name: voice['name'] as String,
                network: voice['network'] == true,
              ),
      ],
    );
  }

  @override
  Future<void> sample(String voice, String text, {required double rate}) =>
      _channel.invokeMethod<void>('sample', {
        'voice': voice,
        'text': text,
        'rate': rate,
      });

  @override
  Future<void> openSettings() => _channel.invokeMethod<void>('openSettings');

  @override
  Future<void> show({
    required String title,
    required String chapter,
    required bool playing,
    required String channel,
  }) => _channel.invokeMethod<void>('show', {
    'title': title,
    'chapter': chapter,
    'playing': playing,
    'channel': channel,
    'labels': {
      'previous': AppStrings.readAloudPrevious,
      'play': AppStrings.readAloudResume,
      'pause': AppStrings.readAloudPause,
      'next': AppStrings.readAloudNext,
      'stop': AppStrings.readAloudStop,
    },
  });

  @override
  Future<void> hide() => _channel.invokeMethod<void>('hide');
}
