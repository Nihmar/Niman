import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/download/download_files.dart';
import 'package:niman/src/core/download/download_state.dart';
import 'package:niman/src/core/download/downloader.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/dictionary/dictionary_catalog.dart';
import 'package:niman/src/dictionary/dictionary_disk.dart';
import 'package:niman/src/dictionary/dictionary_pack.dart';
import 'package:niman/src/dictionary/dictionary_pack_info.dart';
import 'package:niman/src/dictionary/dictionary_preparation.dart';
import 'package:niman/src/dictionary/dictionary_service.dart';

/// What dictionaries this device has, and the downloads on their way
/// (docs/records/dictionary.md, decisions 2, 14 and 17).
///
/// App-wide and long-lived (`dictionaryInstallationProvider`): a download
/// keeps running when the settings page closes, and every surface reads the
/// same state. What is installed is read from the folder, so it is true
/// whatever happened to the folder meanwhile; the catalog says what could be
/// downloaded, and is passed in, so a test downloads from a catalog of its
/// own.
///
/// A pack arrives in three steps: its archive is downloaded and checked by
/// the [Downloader] (size and SHA-256), unpacked into place atomically, and
/// indexed by the [DictionaryService], which reports how far it has got.
/// Only when all three are done does the pack count as installed.
final class DictionaryInstallation extends ChangeNotifier {
  /// The dictionaries kept in the folder `directory` resolves to, read
  /// through `service`, offering the packs of [catalog].
  ///
  /// [startDownload] and [retryDelays] are the downloader's, for a test
  /// that downloads from a server of its own. [removePack] deletes a pack's
  /// folder; a test passes one that fails, to see the failure reported.
  new({
    required this._directory,
    required this._service,
    List<DictionaryPackInfo> catalog = dictionaryPacks,
    DownloadStarter? startDownload,
    List<Duration> retryDelays = Downloader.defaultRetryDelays,
    Future<String?> Function(String root, String id)? removePack,
  }) : _removePack = removePack ?? DictionaryDisk.remove,
       packs = List.unmodifiable([
         for (final info in catalog) DictionaryPack(info),
       ]) {
    _files = DownloadFiles(_directory, packs, log: _log);
    _downloader = Downloader<DictionaryPack>(
      files: _files,
      state: stateOf,
      setState: _setState,
      onInstalled: _install,
      log: _log,
      start: startDownload,
      retryDelays: retryDelays,
    );
  }

  /// The packs the catalog offers, in its order.
  final List<DictionaryPack> packs;

  final Future<String> Function() _directory;
  final Future<DictionaryService> Function() _service;
  final Future<String?> Function(String root, String id) _removePack;
  late final DownloadFiles _files;
  late final Downloader<DictionaryPack> _downloader;

  final Map<String, DownloadState> _states = {};
  final Map<String, DictionaryPreparation> _preparing = {};
  final Map<String, Future<void>> _installing = {};
  List<InstalledDictionary> _installed = const [];
  Future<void>? _loading;
  Future<void>? _rescanning;
  bool _loaded = false;
  bool _swept = false;
  bool _disposed = false;

  /// Whether [load] has finished at least once.
  bool get loaded => _loaded;

  /// The packs in the folder, with their sizes, usable or not.
  List<InstalledDictionary> get installed => _installed;

  /// The catalog's pack [id], or null.
  DictionaryPack? packOf(String id) {
    for (final pack in packs) {
      if (pack.id == id) return pack;
    }
    return null;
  }

  /// [pack]'s download: its archive's progress, until it is unpacked.
  DownloadState stateOf(DictionaryPack pack) =>
      _states[pack.id] ?? const NotDownloaded();

  /// Where the pack [id] is on its way to being usable once downloaded, or
  /// null when it is not on that way.
  DictionaryPreparation? preparationOf(String id) => _preparing[id];

  /// Whether the folder holds the pack [id].
  bool isInstalled(String id) => _installed.any((entry) => entry.pack.id == id);

  /// Reads the folder, and the archives a download left in it; concurrent
  /// calls share one run. The first call also sweeps the hidden folders an
  /// interrupted install or removal left, and finishes the install of an
  /// archive that was downloaded but not yet unpacked.
  Future<void> load() => _loading ??= _load().whenComplete(() {
    _loading = null;
  });

  Future<void> _load() async {
    final clock = Stopwatch()..start();
    final DownloadScan scan;
    final List<InstalledDictionary> installed;
    try {
      final root = await _directory();
      scan = await _files.scan();
      installed = await DictionaryDisk.scan(root, sweep: !_swept);
      _swept = true;
    } on Object catch (error) {
      // No folder (a widget test, a platform without path_provider): the
      // page shows what the catalog offers, and the next load retries.
      _log.warning('load failed after ${clock.elapsedMilliseconds} ms: $error');
      if (_disposed) return;
      _loaded = true;
      notifyListeners();
      return;
    }
    if (_disposed) return;
    _installed = installed;
    final pending = _apply(scan);
    _loaded = true;
    _log.info(
      'loaded in ${clock.elapsedMilliseconds} ms: '
      '${installed.map((entry) => entry.pack.id).join(', ')} installed, '
      '${scan.partial.length} interrupted, ${pending.length} to unpack',
    );
    notifyListeners();
    for (final pack in pending) {
      unawaited(_finish(pack));
    }
  }

  /// Reads the folder again, nothing else: a pack removed by hand is gone
  /// from the list. Before the first [load], loads.
  Future<void> rescan() {
    if (_loading case final loading?) return loading;
    if (!_loaded) return load();
    return _rescanning ??= _rescan().whenComplete(() {
      _rescanning = null;
    });
  }

  Future<void> _rescan() async {
    final List<InstalledDictionary> installed;
    final DownloadScan scan;
    try {
      scan = await _files.scan();
      installed = await DictionaryDisk.scan(await _directory());
    } on Object catch (error) {
      _log.warning('rescan failed: $error');
      return;
    }
    if (_disposed) return;
    _installed = installed;
    _apply(scan);
    notifyListeners();
  }

  /// Sets each pack's download state from [scan] and returns those whose
  /// archive is whole but not yet unpacked. A download running, or an
  /// install under way, keeps its state.
  List<DictionaryPack> _apply(DownloadScan scan) {
    final pending = <DictionaryPack>[];
    for (final pack in packs) {
      if (stateOf(pack) is Downloading || _installing.containsKey(pack.id)) {
        continue;
      }
      final bytes = scan.installed[pack.id];
      final partial = scan.partial[pack.id];
      _states[pack.id] = switch ((bytes, partial)) {
        (final int bytes, _) => Downloaded(bytes),
        // A download cut off by the app closing: resumable from here.
        (_, final int partial) => DownloadFailed(
          'interrupted',
          received: partial,
          total: pack.bytes,
        ),
        _ when _states[pack.id] is DownloadFailed => _states[pack.id]!,
        _ => const NotDownloaded(),
      };
      if (bytes != null) pending.add(pack);
    }
    return pending;
  }

  /// Downloads [pack], resuming what is on disk; once it lands, unpacks and
  /// indexes it. Completes when the pack is usable, or the download stopped.
  Future<void> download(DictionaryPack pack) => _downloader.download(pack);

  /// Starts again the downloads a lost connection stopped.
  Future<void> resumeInterrupted() => _downloader.resumeInterrupted(packs);

  /// Stops [pack]'s download and discards its partial file.
  Future<void> cancel(DictionaryPack pack) => _downloader.cancel(pack);

  /// Removes the pack [id] from the device.
  ///
  /// Closes the pack's files first (Windows locks open files), then deletes
  /// its folder on an isolate. Returns null once it is gone, or why it
  /// could not be removed: a failure is reported, not thrown, and the pack
  /// stays as it was.
  Future<String?> remove(String id) async {
    if (packOf(id) case final pack?) await cancel(pack);
    final String? error;
    try {
      final root = await _directory();
      await (await _service()).forget(id);
      error = await _removePack(root, id);
    } on Object catch (cause) {
      _log.warning('$id not removed: $cause');
      return '$cause';
    }
    if (error != null) {
      _log.warning('$id not removed: $error');
      return error;
    }
    _log.info('$id removed');
    await _refresh(id);
    return null;
  }

  /// Takes the downloaded archive of [pack] the last two steps: unpacks it
  /// and builds its index. Runs from the downloader once the archive has
  /// checked out, and from [load] for one that was left whole.
  Future<void> _install(DictionaryPack pack) {
    final running = _installing[pack.id];
    if (running != null) return running;
    final installing = _unpackAndIndex(pack);
    _installing[pack.id] = installing;
    return installing.whenComplete(() => _installing.remove(pack.id));
  }

  /// [_install] for [load]: the failure is shown on the pack, not thrown.
  Future<void> _finish(DictionaryPack pack) async {
    try {
      await _install(pack);
    } on Object catch (error) {
      _log.warning('${pack.id}: install failed: $error');
      _setState(pack, DownloadFailed('install failed: $error'));
    }
  }

  Future<void> _unpackAndIndex(DictionaryPack pack) async {
    final clock = Stopwatch()..start();
    _prepare(pack.id, const DictionaryPreparation.unpacking());
    final root = await _directory();
    final service = await _service();
    // An older copy of the pack may be open in the worker.
    await service.forget(pack.id);
    final error = await DictionaryDisk.install(root, pack.id);
    if (error != null) {
      // A genuine archive that will not unpack would fail every start: it
      // is deleted, and the download starts over when asked.
      await _files.delete(pack);
      _prepare(pack.id, null);
      throw FormatException('could not unpack: $error');
    }
    _log.info('${pack.id}: unpacked in ${clock.elapsedMilliseconds} ms');
    _prepare(pack.id, const DictionaryPreparation.indexing(0));
    final progress = service.indexProgress.listen((report) {
      if (report.packId == pack.id) {
        _prepare(pack.id, DictionaryPreparation.indexing(report.fraction));
      }
    });
    try {
      await service.installedPacks(refresh: true);
      // The look-up reports a pack that cannot be indexed, with its reason:
      // the pack is installed either way, and the list says if it is usable.
      await service.prepare(pack.languages.first);
    } finally {
      await progress.cancel();
    }
    _log.info('${pack.id}: installed in ${clock.elapsedMilliseconds} ms');
    await _refresh(pack.id);
  }

  /// Reads the folder again for the pack [id] after it was installed or
  /// removed, and drops what said it was on its way.
  Future<void> _refresh(String id) async {
    List<InstalledDictionary>? installed;
    try {
      installed = await DictionaryDisk.scan(await _directory());
    } on Object catch (error) {
      _log.warning('scan after $id failed: $error');
    }
    if (_disposed) return;
    if (installed != null) _installed = installed;
    _preparing.remove(id);
    if (packOf(id) case final pack?) _states[pack.id] = const NotDownloaded();
    notifyListeners();
  }

  void _prepare(String id, DictionaryPreparation? preparation) {
    if (_disposed) return;
    if (preparation == null) {
      _preparing.remove(id);
    } else {
      _preparing[id] = preparation;
    }
    notifyListeners();
  }

  void _setState(DictionaryPack pack, DownloadState state) {
    if (_disposed) return;
    _states[pack.id] = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _downloader.close();
    super.dispose();
  }
}

const _log = AppLogger(name: 'dictionary');
