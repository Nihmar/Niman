import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/transcription/model_download.dart';
import 'package:niman/src/transcription/model_files.dart';
import 'package:niman/src/transcription/model_state.dart';
import 'package:niman/src/transcription/transcription_model.dart';
import 'package:niman/src/transcription/transcription_settings.dart';
import 'package:niman/src/transcription/transcription_settings_store.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

/// Starts a download; [ModelDownload.start] in the app, a fake in tests.
typedef ModelDownloadStarter = Future<ModelDownload> Function({
  required Uri uri,
  required String target,
  required void Function(int received) onProgress,
  void Function(int? total, int elapsedMs)? onHeaders,
});

/// The transcription models of this installation: what is downloaded,
/// what is downloading, and the default model and language.
///
/// App-wide and long-lived ([transcriptionModelsProvider]): a download
/// keeps running when its page closes, and the settings rows and the
/// audio note read the same state.
final class TranscriptionModels extends ChangeNotifier {
  /// Models kept in the directory [directory] resolves to.
  new({
    required Future<String> Function() directory,
    bool? phone,
    ModelDownloadStarter? startDownload,
  }) : _files = ModelFiles(directory),
       _store = TranscriptionSettingsStore(directory),
       phone = phone ?? Platform.isAndroid,
       _startDownload = startDownload ?? ModelDownload.start;

  final ModelFiles _files;
  final TranscriptionSettingsStore _store;
  final ModelDownloadStarter _startDownload;

  /// Whether this is a phone: fewer models, and "slow" warnings.
  final bool phone;

  final Map<String, ModelState> _states = {};
  final Map<String, ModelDownload> _downloads = {};
  TranscriptionSettings _settings = const TranscriptionSettings();
  Future<void>? _loading;
  bool _disposed = false;

  /// The models this device offers, smallest first.
  List<TranscriptionModel> get models =>
      offeredTranscriptionModels(phone: phone);

  /// Whether [load] has finished at least once.
  bool get loaded => _loaded;
  bool _loaded = false;

  /// The stored settings.
  TranscriptionSettings get settings => _settings;

  /// [model]'s state.
  ModelState stateOf(TranscriptionModel model) =>
      _states[model.id] ?? const ModelAbsent();

  /// The downloaded models, smallest first.
  List<TranscriptionModel> get installed => [
    for (final model in models)
      if (stateOf(model) is ModelInstalled) model,
  ];

  /// Bytes taken by the downloaded models.
  int get installedBytes => [
    for (final model in models)
      if (stateOf(model) case ModelInstalled(:final bytes)) bytes,
  ].fold(0, (sum, bytes) => sum + bytes);

  /// The default model, when it is chosen and downloaded.
  TranscriptionModel? get defaultModel {
    final model = transcriptionModelById(_settings.modelId);
    return model != null && stateOf(model) is ModelInstalled ? model : null;
  }

  /// Reads the settings and scans the model directory; concurrent calls
  /// share one run.
  Future<void> load() => _loading ??= _load().whenComplete(() {
    _loading = null;
  });

  Future<void> _load() async {
    final clock = Stopwatch()..start();
    final TranscriptionSettings settings;
    final Map<String, int> sizes;
    try {
      settings = await _store.load();
      sizes = await _files.installed(active: _downloads.keys.toSet());
    } on Object catch (error) {
      // No model directory (a platform without path_provider, a widget
      // test): the page shows every model as downloadable instead of
      // failing, and the next load tries again.
      _log.warning('load failed after ${clock.elapsedMilliseconds} ms: $error');
      if (_disposed) return;
      _loaded = true;
      notifyListeners();
      return;
    }
    if (_disposed) return;
    _settings = settings;
    for (final model in transcriptionModels) {
      if (_downloads.containsKey(model.id)) continue;
      final bytes = sizes[model.id];
      if (bytes != null) {
        _states[model.id] = ModelInstalled(bytes);
      } else if (_states[model.id] is! ModelFailed) {
        _states[model.id] = const ModelAbsent();
      }
    }
    _loaded = true;
    _log.info(
      'loaded in ${clock.elapsedMilliseconds} ms: '
      '${installed.length} installed ($installedBytes b), '
      'default ${defaultModel?.id ?? '-'}',
    );
    notifyListeners();
  }

  /// Downloads [model]; the first model to arrive becomes the default
  /// when none is set.
  Future<void> download(TranscriptionModel model) async {
    // Downloading covers the moment the isolate is still spawning, before
    // _downloads has the entry: a second tap must not start a second one.
    if (stateOf(model) case ModelDownloading() || ModelInstalled()) return;
    final clock = Stopwatch()..start();
    var total = model.bytes;
    var nextLog = 10;
    _set(model, ModelDownloading(received: 0, total: total));
    _log.info('download ${model.id}: start ${model.uri}');
    final ModelDownload download;
    try {
      download = await _startDownload(
        uri: model.uri,
        target: await _files.pathOf(model),
        onHeaders: (announced, ms) {
          if (announced != null) total = announced;
          _log.info(
            'download ${model.id}: headers after $ms ms, '
            '${announced ?? 'unknown'} b',
          );
        },
        onProgress: (received) {
          if (stateOf(model) is! ModelDownloading) return;
          _set(model, ModelDownloading(received: received, total: total));
          final percent = total <= 0 ? 0 : received * 100 ~/ total;
          if (percent >= nextLog) {
            _log.debug(
              'download ${model.id}: $percent% $received b '
              'at ${clock.elapsedMilliseconds} ms',
            );
            nextLog = (percent ~/ 10 + 1) * 10;
          }
        },
      );
    } on Object catch (error) {
      _log.warning('download ${model.id}: could not start ($error)');
      _set(model, ModelFailed(error.toString()));
      return;
    }
    _downloads[model.id] = download;
    try {
      final bytes = await download.done;
      final seconds = clock.elapsedMilliseconds / 1000;
      _log.info(
        'download ${model.id}: done, $bytes b in '
        '${clock.elapsedMilliseconds} ms '
        '(${seconds == 0 ? '-' : (bytes / 1048576 / seconds).toStringAsFixed(1)} MB/s)',
      );
      _downloads.remove(model.id);
      _set(model, ModelInstalled(bytes));
      if (defaultModel == null) await setDefault(model);
    } on ModelDownloadCancelled {
      _log.info(
        'download ${model.id}: cancelled after ${clock.elapsedMilliseconds} ms',
      );
      _downloads.remove(model.id);
      _set(model, const ModelAbsent());
    } on ModelDownloadException catch (error) {
      _log.warning(
        'download ${model.id}: failed after '
        '${clock.elapsedMilliseconds} ms (${error.reason})',
      );
      _downloads.remove(model.id);
      _set(model, ModelFailed(error.reason));
    }
  }

  /// Stops [model]'s download.
  Future<void> cancel(TranscriptionModel model) async {
    final download = _downloads[model.id];
    if (download == null) return;
    await download.cancel();
  }

  /// Deletes [model]'s file. When it was the default, the smallest model
  /// still downloaded takes over (or none).
  Future<void> delete(TranscriptionModel model) async {
    await cancel(model);
    await _files.delete(model);
    _set(model, const ModelAbsent());
    if (_settings.modelId == model.id) {
      final next = installed.isEmpty ? null : installed.first;
      await _save(_settings.withModel(next?.id));
    }
  }

  /// Makes [model] the default.
  Future<void> setDefault(TranscriptionModel model) =>
      _save(_settings.withModel(model.id));

  /// Sets the recordings' language: [TranscriptionSettings.followApp],
  /// [TranscriptionSettings.detect] or an app language id.
  Future<void> setLanguage(String language) =>
      _save(_settings.withLanguage(language));

  Future<void> _save(TranscriptionSettings settings) async {
    if (settings == _settings) return;
    _settings = settings;
    notifyListeners();
    await _store.save(settings);
  }

  void _set(TranscriptionModel model, ModelState state) {
    if (_disposed) return;
    _states[model.id] = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final download in _downloads.values) {
      unawaited(download.cancel());
    }
    _downloads.clear();
    super.dispose();
  }
}

const _log = AppLogger(name: 'transcription');

/// The installation's transcription models, shared by the settings, the
/// models page and the audio notes.
final transcriptionModelsProvider = Provider<TranscriptionModels>((ref) {
  final models = TranscriptionModels(directory: WhisperController.getModelDir);
  unawaited(models.load());
  ref.onDispose(models.dispose);
  return models;
});
