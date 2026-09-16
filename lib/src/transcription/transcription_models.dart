import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/transcription/model_downloader.dart';
import 'package:niman/src/transcription/model_files.dart';
import 'package:niman/src/transcription/model_state.dart';
import 'package:niman/src/transcription/transcription_model.dart';
import 'package:niman/src/transcription/transcription_settings.dart';
import 'package:niman/src/transcription/transcription_settings_store.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

export 'package:niman/src/transcription/model_downloader.dart'
    show ModelDownloadStarter;

/// The transcription models of this installation: what is downloaded,
/// what is downloading, and the default model and language.
///
/// App-wide and long-lived ([transcriptionModelsProvider]): a download
/// keeps running when its page closes, and the settings rows and the
/// audio note read the same state. The downloads themselves, with their
/// retries and resumes, run in [ModelDownloader].
final class TranscriptionModels extends ChangeNotifier {
  /// Models kept in the directory [directory] resolves to.
  new({
    required Future<String> Function() directory,
    bool? phone,
    ModelDownloadStarter? startDownload,
    List<Duration> retryDelays = ModelDownloader.defaultRetryDelays,
  }) : _files = ModelFiles(directory),
       _store = TranscriptionSettingsStore(directory),
       phone = phone ?? Platform.isAndroid {
    _downloader = ModelDownloader(
      files: _files,
      state: stateOf,
      setState: _set,
      onInstalled: (model) async {
        if (defaultModel == null) await setDefault(model);
      },
      start: startDownload,
      retryDelays: retryDelays,
    );
  }

  final ModelFiles _files;
  final TranscriptionSettingsStore _store;
  late final ModelDownloader _downloader;

  /// Whether this is a phone: fewer models, and "slow" warnings.
  final bool phone;

  final Map<String, ModelState> _states = {};
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
    final ModelScan scan;
    try {
      settings = await _store.load();
      scan = await _files.scan();
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
      if (stateOf(model) is ModelDownloading) continue;
      final bytes = scan.installed[model.id];
      final partial = scan.partial[model.id];
      _states[model.id] = switch ((bytes, partial)) {
        (final int bytes, _) => ModelInstalled(bytes),
        // A download cut off by the app closing: resumable from here.
        (_, final int partial) => ModelFailed(
          'interrupted',
          received: partial,
          total: model.bytes,
        ),
        _ when _states[model.id] is ModelFailed => _states[model.id]!,
        _ => const ModelAbsent(),
      };
    }
    _loaded = true;
    _log.info(
      'loaded in ${clock.elapsedMilliseconds} ms: '
      '${installed.length} installed ($installedBytes b), '
      '${scan.partial.length} interrupted, '
      'default ${defaultModel?.id ?? '-'}',
    );
    notifyListeners();
  }

  /// Downloads [model], resuming what is on disk; the first model to
  /// arrive becomes the default when none is set.
  Future<void> download(TranscriptionModel model) =>
      _downloader.download(model);

  /// Starts again the downloads a lost connection stopped; the app calls
  /// it when it returns to the foreground.
  Future<void> resumeInterrupted() => _downloader.resumeInterrupted(models);

  /// Stops [model]'s download and discards its partial file.
  Future<void> cancel(TranscriptionModel model) => _downloader.cancel(model);

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
    _downloader.close();
    super.dispose();
  }
}

const _log = AppLogger(name: 'transcription');

/// The installation's transcription models, shared by the settings, the
/// models page and the audio notes.
final transcriptionModelsProvider = Provider<TranscriptionModels>((ref) {
  final models = TranscriptionModels(directory: WhisperController.getModelDir);
  unawaited(models.load());
  // Back in the foreground: pick up the downloads the freeze cut off.
  final observer = _ResumeObserver(() => unawaited(models.resumeInterrupted()));
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() {
    WidgetsBinding.instance.removeObserver(observer);
    models.dispose();
  });
  return models;
});

/// Calls [onResume] whenever the app returns to the foreground.
///
/// A plain observer rather than `AppLifecycleListener`, which asserts on
/// the order of lifecycle states and so fails on the shortcuts platforms
/// and tests take (paused straight to resumed).
final class _ResumeObserver with WidgetsBindingObserver {
  new(this.onResume);

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}
