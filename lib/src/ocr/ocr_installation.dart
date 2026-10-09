import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/download/download_files.dart';
import 'package:niman/src/core/download/download_state.dart';
import 'package:niman/src/core/download/downloadable.dart';
import 'package:niman/src/core/download/downloader.dart';
import 'package:niman/src/core/json_file.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/ocr/ocr_engine_build.dart';
import 'package:niman/src/ocr/ocr_engine_locator.dart';
import 'package:niman/src/ocr/ocr_language.dart';
import 'package:niman/src/ocr/ocr_language_catalog.dart';
import 'package:niman/src/ocr/ocr_settings.dart';
import 'package:path/path.dart' as p;

/// What text recognition has on this device: the engine, the languages
/// of each quality, and the settings (docs/records/ocr.md).
///
/// App-wide and long-lived (`ocrInstallationProvider`): a download keeps
/// running when the settings page closes, and the page and the Recognize
/// command read the same state. Nothing ships in the package: the engine
/// (unless the package bundles one, or Linux has the distribution's) and
/// every language are downloaded through one [Downloader], each file
/// checked against the SHA-256 the catalog pins.
final class OcrInstallation extends ChangeNotifier {
  /// The OCR data kept in the directory [directory] resolves to.
  ///
  /// [build] is the engine this process would download (none where no
  /// build is published); `findInstalled` looks for one already on the
  /// device, on a worker isolate in the app; `probe` opens a freshly
  /// downloaded engine and answers its version, or null when this device
  /// will not load it.
  new({
    required Future<String> Function() directory,
    required this.build,
    required this._findInstalled,
    required this._probe,
    DownloadStarter? startDownload,
    List<Duration> retryDelays = Downloader.defaultRetryDelays,
  }) : _directory = directory,
       _settingsFile = JsonFile(directory, settingsFileName),
       _catalog = {
         ?build?.id: ?build,
         for (final language in ocrLanguages)
           for (final quality in OcrQuality.values)
             ?language.file(quality)?.id: ?language.file(quality),
       } {
    _files = DownloadFiles(directory, _catalog.values, log: _log);
    _downloader = Downloader<Downloadable>(
      files: _files,
      state: stateOf,
      setState: _set,
      onInstalled: _verify,
      log: _log,
      start: startDownload,
      retryDelays: retryDelays,
    );
  }

  /// The settings file's name.
  static const String settingsFileName = 'ocr.json';

  /// The engine this device downloads, or null where none is published.
  final OcrEngineBuild? build;

  final Future<String> Function() _directory;
  final Future<OcrEngineLibrary?> Function() _findInstalled;
  final Future<String?> Function(String path) _probe;
  final JsonFile _settingsFile;

  /// Everything this device may download, by id.
  final Map<String, Downloadable> _catalog;
  late final DownloadFiles _files;
  late final Downloader<Downloadable> _downloader;

  final Map<String, DownloadState> _states = {};
  OcrSettings _settings = const OcrSettings();
  OcrEngineLibrary? _installed;
  String? _dir;
  Future<void>? _loading;
  Future<void>? _rescanning;
  bool _loaded = false;
  bool _disposed = false;

  /// Whether [load] has finished at least once.
  bool get loaded => _loaded;

  /// The stored settings.
  OcrSettings get settings => _settings;

  /// [item]'s state: the engine's or a language file's.
  DownloadState stateOf(Downloadable item) =>
      _states[item.id] ?? const NotDownloaded();

  /// The engine a recognition opens: the bundled or distribution one, else
  /// the downloaded one once it is on disk; null when it must be
  /// downloaded first.
  OcrEngineLibrary? get engine {
    if (_installed case final installed?) return installed;
    final build = this.build;
    final dir = _dir;
    if (build == null || dir == null) return null;
    if (stateOf(build) is! Downloaded) return null;
    return (
      name: p.join(dir, build.fileName),
      source: OcrEngineSource.downloaded,
      version: OcrEngineBuild.version,
    );
  }

  /// Whether this device has no engine and none to download.
  bool get unavailable => _installed == null && build == null;

  /// The languages of [quality] on disk, by name.
  List<OcrLanguageFile> installed(OcrQuality quality) => [
    for (final language in ocrLanguages)
      if (language.file(quality) case final file?
          when stateOf(file) is Downloaded)
        file,
  ]..sort((a, b) => a.language.native.compareTo(b.language.native));

  /// Bytes taken by the languages of [quality].
  int installedBytes(OcrQuality quality) => [
    for (final file in installed(quality))
      if (stateOf(file) case Downloaded(:final bytes)) bytes,
  ].fold(0, (sum, bytes) => sum + bytes);

  /// The folder Tesseract loads the languages of [quality] from; null
  /// before [load].
  String? datapath(OcrQuality quality) =>
      _dir == null ? null : p.join(_dir!, quality.name);

  /// What reading [languages] at the current quality still needs: the
  /// engine when there is none, and each language not on disk.
  List<Downloadable> missingFor(Iterable<OcrLanguage> languages) => [
    if (engine == null) ?build,
    for (final language in languages)
      if (language.file(_settings.quality) case final file?
          when stateOf(file) is! Downloaded)
        file,
  ];

  /// The default language for the app speaking [app].
  OcrLanguage defaultLanguage([AppLanguage? app]) =>
      _settings.defaultLanguage(app ?? AppLanguages.resolved);

  /// The second language, if any, for the app speaking [app].
  OcrLanguage? alsoLanguage([AppLanguage? app]) =>
      _settings.alsoLanguage(app ?? AppLanguages.resolved);

  /// Reads the settings, scans the downloads and looks for an engine
  /// already on the device; concurrent calls share one run.
  Future<void> load() => _loading ??= _load().whenComplete(() {
    _loading = null;
  });

  Future<void> _load() async {
    final clock = Stopwatch()..start();
    final OcrSettings settings;
    final DownloadScan scan;
    final String dir;
    try {
      dir = await _directory();
      settings = await _readSettings();
      scan = await _files.scan();
      _installed = await _findInstalled();
    } on Object catch (error) {
      // No directory (a widget test, a platform without path_provider):
      // the page shows everything as downloadable; the next load retries.
      _log.warning('load failed after ${clock.elapsedMilliseconds} ms: $error');
      if (_disposed) return;
      _loaded = true;
      notifyListeners();
      return;
    }
    if (_disposed) return;
    _dir = dir;
    _settings = settings;
    _apply(scan);
    _loaded = true;
    final found = switch ((_installed, engine)) {
      ((:final source, :final version, name: _)?, _) =>
        '${source.name} $version',
      (null, _?) => 'downloaded',
      _ => 'none',
    };
    _log.info(
      'loaded in ${clock.elapsedMilliseconds} ms: engine $found, '
      '${scan.installed.length} files, ${scan.partial.length} interrupted, '
      '$settings',
    );
    notifyListeners();
  }

  /// Scans the downloads again, nothing else: a file deleted since [load]
  /// (a storage cleanup, a sync tool, a hand) is missing again, so the
  /// recognition that needs it downloads it rather than failing to open
  /// it. Before the first [load], loads; concurrent calls share one run.
  Future<void> rescan() {
    if (_loading case final loading?) return loading;
    if (_dir == null) return load();
    return _rescanning ??= _rescan().whenComplete(() {
      _rescanning = null;
    });
  }

  Future<void> _rescan() async {
    final DownloadScan scan;
    try {
      scan = await _files.scan();
    } on Object catch (error) {
      _log.warning('rescan failed: $error');
      return;
    }
    if (_disposed) return;
    _apply(scan);
    notifyListeners();
  }

  /// Sets every catalog item's state from [scan]: on disk, cut off
  /// part-way, or not there — a file gone since the last scan included.
  /// A download running keeps its state, and so does an earlier failure
  /// that left nothing on disk.
  void _apply(DownloadScan scan) {
    for (final item in _catalog.values) {
      if (stateOf(item) is Downloading) continue;
      final bytes = scan.installed[item.id];
      final partial = scan.partial[item.id];
      _states[item.id] = switch ((bytes, partial)) {
        (final int bytes, _) => Downloaded(bytes),
        // A download cut off by the app closing: resumable from here.
        (_, final int partial) => DownloadFailed(
          'interrupted',
          received: partial,
          total: item.bytes,
        ),
        _ when _states[item.id] is DownloadFailed => _states[item.id]!,
        _ => const NotDownloaded(),
      };
    }
  }

  Future<OcrSettings> _readSettings() async {
    try {
      return OcrSettings.fromJson(await _settingsFile.read());
    } on FormatException catch (error) {
      _log.warning('settings: $settingsFileName is not JSON ($error)');
      return const OcrSettings();
    }
  }

  /// Downloads [item] (the engine or a language file), resuming what is on
  /// disk.
  Future<void> download(Downloadable item) => _downloader.download(item);

  /// Downloads everything in [items] together.
  Future<void> downloadAll(Iterable<Downloadable> items) =>
      Future.wait(items.map(download));

  /// Starts again the downloads a lost connection stopped.
  Future<void> resumeInterrupted() =>
      _downloader.resumeInterrupted(_catalog.values);

  /// Stops [item]'s download and discards its partial file.
  Future<void> cancel(Downloadable item) => _downloader.cancel(item);

  /// Opens the engine as soon as it lands: a library this device refuses
  /// is found here, from the settings page, rather than by the first
  /// recognition. Languages need no check: their SHA-256 already passed.
  Future<void> _verify(Downloadable item) async {
    final build = this.build;
    final dir = _dir;
    if (build == null || item != build || dir == null) return;
    final path = p.join(dir, build.fileName);
    final version = await _probe(path);
    if (version != null) {
      _log.info('engine ${build.target} loads: Tesseract $version');
      return;
    }
    _log.warning('engine ${build.target} does not load on this device');
    // Failed first: the probe may have loaded the library, and Windows
    // then refuses the delete until the app exits (#607), as [delete]
    // says; the next launch deletes it.
    _set(build, const DownloadFailed('does not load on this device'));
    try {
      await _files.delete(build);
    } on FileSystemException catch (error) {
      _log.warning('${build.id} not deleted: ${error.osError ?? error}');
    }
  }

  /// Deletes [item]'s file.
  ///
  /// Windows locks a library this process has loaded (the check after the
  /// download does) until the app exits: that delete fails, the engine
  /// stays listed, and the next launch can delete it.
  Future<void> delete(Downloadable item) async {
    await cancel(item);
    try {
      await _files.delete(item);
    } on FileSystemException catch (error) {
      _log.warning('${item.id} not deleted: ${error.osError ?? error}');
      return;
    }
    _set(item, const NotDownloaded());
  }

  /// Uses [quality] models from now on.
  Future<void> setQuality(OcrQuality quality) =>
      _save(_settings.withQuality(quality));

  /// Makes [language] the default.
  Future<void> setLanguage(OcrLanguage language) =>
      _save(_settings.withLanguage(language.code));

  /// Reads [language] too (null: only the default).
  Future<void> setAlso(OcrLanguage? language) =>
      _save(_settings.withAlso(language?.code));

  Future<void> _save(OcrSettings settings) async {
    if (settings == _settings) return;
    _settings = settings;
    notifyListeners();
    await _settingsFile.write(settings.toJson());
    _log.info('settings saved: $settings');
  }

  void _set(Downloadable item, DownloadState state) {
    if (_disposed) return;
    _states[item.id] = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _downloader.close();
    super.dispose();
  }
}

const _log = AppLogger(name: 'ocr');
