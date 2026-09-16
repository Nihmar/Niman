import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/transcription/transcription_settings.dart';
import 'package:path/path.dart' as p;

/// Reads and writes [TranscriptionSettings] as `transcription.json` in the
/// model directory.
///
/// Both run off the UI isolate (every open is a FUSE round trip on
/// Android). A write goes to a temp name and is renamed into place, so a
/// crash mid-write leaves the previous file, never half of one.
final class TranscriptionSettingsStore {
  /// A store in the directory [directory] resolves to.
  new(this.directory);

  /// Resolves the model directory (`WhisperController.getModelDir` in the
  /// app, a temp folder in tests).
  final Future<String> Function() directory;

  /// The settings file's name.
  static const String fileName = 'transcription.json';

  /// The stored settings; the defaults when the file is missing or
  /// unreadable.
  Future<TranscriptionSettings> load() async {
    final clock = Stopwatch()..start();
    final path = p.join(await directory(), fileName);
    final text = await Isolate.run(() => _read(path));
    var settings = const TranscriptionSettings();
    if (text != null) {
      try {
        settings = TranscriptionSettings.fromJson(jsonDecode(text));
      } on FormatException catch (error) {
        _log.warning('settings: $fileName is not JSON ($error), defaults');
      }
    }
    _log.info(
      'settings loaded in ${clock.elapsedMilliseconds} ms: $settings'
      '${text == null ? ' (no file)' : ''}',
    );
    return settings;
  }

  /// Persists [settings].
  Future<void> save(TranscriptionSettings settings) async {
    final clock = Stopwatch()..start();
    final dir = await directory();
    final text = jsonEncode(settings.toJson());
    await Isolate.run(() => _write(dir, text));
    _log.info('settings saved in ${clock.elapsedMilliseconds} ms: $settings');
  }
}

const _log = AppLogger(name: 'transcription');

Future<String?> _read(String path) async {
  final file = File(path);
  if (!file.existsSync()) return null;
  try {
    return await file.readAsString();
  } on FileSystemException {
    return null;
  }
}

Future<void> _write(String dir, String text) async {
  await Directory(dir).create(recursive: true);
  final target = p.join(dir, TranscriptionSettingsStore.fileName);
  final temp = '$target.niman-tmp-${DateTime.now().microsecondsSinceEpoch}';
  await File(temp).writeAsString(text, flush: true);
  await File(temp).rename(target);
}
