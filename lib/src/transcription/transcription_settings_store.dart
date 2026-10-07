import 'package:niman/src/core/json_file.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/transcription/transcription_settings.dart';

/// Reads and writes [TranscriptionSettings] as `transcription.json` in the
/// model directory, through a [JsonFile] (off the UI isolate, temp write +
/// rename).
final class TranscriptionSettingsStore {
  /// A store in the directory [directory] resolves to.
  new(Future<String> Function() directory)
    : _file = JsonFile(directory, fileName);

  final JsonFile _file;

  /// The settings file's name.
  static const String fileName = 'transcription.json';

  /// The stored settings; the defaults when the file is missing or
  /// unreadable.
  Future<TranscriptionSettings> load() async {
    final clock = Stopwatch()..start();
    Object? json;
    try {
      json = await _file.read();
    } on FormatException catch (error) {
      _log.warning('settings: $fileName is not JSON ($error), defaults');
    }
    final settings = TranscriptionSettings.fromJson(json);
    _log.info(
      'settings loaded in ${clock.elapsedMilliseconds} ms: $settings'
      '${json == null ? ' (no file)' : ''}',
    );
    return settings;
  }

  /// Persists [settings].
  Future<void> save(TranscriptionSettings settings) async {
    final clock = Stopwatch()..start();
    await _file.write(settings.toJson());
    _log.info('settings saved in ${clock.elapsedMilliseconds} ms: $settings');
  }
}

const _log = AppLogger(name: 'transcription');
