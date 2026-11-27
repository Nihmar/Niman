import 'dart:async';
import 'dart:collection';

import 'package:niman/src/dictionary/dictionary_exception.dart';
import 'package:niman/src/dictionary/dictionary_index_job.dart';
import 'package:niman/src/dictionary/dictionary_result.dart';
import 'package:niman/src/dictionary/dictionary_worker.dart';
import 'package:niman/src/dictionary/installed_pack.dart';
import 'package:niman/src/dictionary/installed_packs.dart';
import 'package:niman/src/dictionary/lookup_term.dart';

/// How far the sidecar index of a pack is built: a number from 0 to 1.
typedef IndexProgress = ({String packId, double fraction});

/// What the rest of the app calls to look a word up
/// (docs/records/dictionary.md, "The engine"): a selection and a language
/// in, a [DictionaryResult] out.
///
/// It finds the pack that serves the language in the dictionaries folder
/// it was given, builds the pack's sidecar index the first time (on an
/// isolate, with progress on [indexProgress]), opens it in the worker
/// isolate, and asks the worker. No call here reads a file on the calling
/// isolate. Recent results are kept, so selecting the same word again, or
/// the panel reopening, costs nothing.
///
/// A pack that is replaced or removed on disk has to be reported with
/// [forget], which closes its files and drops what was kept of it.
final class DictionaryService {
  /// A service over the dictionaries folder `directory`
  /// (`<support>/dictionary/`), keeping the last `cacheSize` results.
  new({required this._directory, this._cacheSize = 64});

  final String _directory;
  final int _cacheSize;
  final StreamController<IndexProgress> _progress =
      StreamController<IndexProgress>.broadcast();
  final LinkedHashMap<String, DictionaryResult> _cache = LinkedHashMap();
  final Map<String, Future<void>> _opening = {};
  Future<List<InstalledPack>>? _scan;
  Future<DictionaryWorker>? _starting;
  bool _disposed = false;

  /// Reports how far each pack's index is built, while one is: the first
  /// look-up in a big pack has to wait for it, and the panel can say so.
  Stream<IndexProgress> get indexProgress => _progress.stream;

  /// The packs the folder holds, usable or not. Cached; [refresh] reads
  /// the folder again (a pack was downloaded or removed).
  Future<List<InstalledPack>> installedPacks({bool refresh = false}) {
    if (refresh || _scan == null) {
      _scan = InstalledPacks.list(_directory);
    }
    return _scan!;
  }

  /// The usable pack that serves [language], or null.
  Future<InstalledPack?> packFor(String language) async =>
      InstalledPacks.forLanguage(await installedPacks(), language);

  /// Builds the index of the pack that serves [language] and opens it, so
  /// the first look-up is as quick as the rest: for after a download.
  /// Completes without error when there is no such pack.
  Future<void> prepare(String language) async {
    final pack = await packFor(language);
    if (pack == null) return;
    try {
      await _ensureOpen(pack);
    } on DictionaryException {
      // The look-up reports it, with the pack's reason.
    }
  }

  /// Looks [selection] up in the language [language] (a code as a book or
  /// a library says it: `it`, `pt-BR`).
  ///
  /// Never throws for a pack: the result says there is none, or that it is
  /// unavailable, or that nothing was found.
  Future<DictionaryResult> lookUp(String selection, String language) async {
    if (_disposed) throw StateError('DictionaryService disposed');
    var pack = await packFor(language);
    if (pack == null) {
      // Maybe one was downloaded since the folder was read.
      final packs = await installedPacks(refresh: true);
      pack = InstalledPacks.forLanguage(packs, language);
      if (pack == null) {
        final broken = packs.where((p) => p.serves(language)).firstOrNull;
        return DictionaryResult(
          outcome: broken == null
              ? DictionaryOutcome.noPack
              : DictionaryOutcome.unavailable,
          selection: selection,
          language: language,
          packId: broken?.id,
          reason: broken?.unavailableReason,
        );
      }
    }
    final key = '${pack.id}\u{0}$language\u{0}$selection';
    final kept = _cache.remove(key);
    if (kept != null) return _cache[key] = kept;
    final candidates = LookupTerm.candidates(selection, language: language);
    if (candidates.isEmpty) {
      return DictionaryResult(
        outcome: DictionaryOutcome.notFound,
        selection: selection,
        language: language,
        packId: pack.id,
      );
    }
    try {
      await _ensureOpen(pack);
      final answer = await (await _worker()).lookUp(
        pack.id,
        candidates,
        LookupTerm.prefixBases(selection, language: language),
        LookupTerm.primaryLanguage(language),
      );
      final result = DictionaryResult(
        outcome: answer.entries.isEmpty
            ? DictionaryOutcome.notFound
            : DictionaryOutcome.found,
        selection: selection,
        language: language,
        packId: pack.id,
        matched: answer.matched,
        entries: answer.entries,
        suggestions: answer.suggestions,
      );
      _cache[key] = result;
      if (_cache.length > _cacheSize) _cache.remove(_cache.keys.first);
      return result;
    } on DictionaryException catch (error) {
      return DictionaryResult(
        outcome: DictionaryOutcome.unavailable,
        selection: selection,
        language: language,
        packId: pack.id,
        reason: error.reason,
      );
    }
  }

  /// Closes the pack [packId]'s files and forgets what was kept of it: its
  /// files were replaced or removed, or the folder changed. The next look-up
  /// reads the folder again.
  Future<void> forget(String packId) async {
    _opening.removeWhere((id, _) => id == packId);
    _scan = null;
    _cache.removeWhere((key, _) => key.startsWith('$packId\u{0}'));
    final starting = _starting;
    if (starting == null) return;
    final worker = await starting;
    if (!worker.isClosed) await worker.closePack(packId);
  }

  /// Stops the worker and ends [indexProgress].
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _cache.clear();
    _opening.clear();
    final starting = _starting;
    if (starting != null) {
      try {
        await (await starting).shutdown();
      } on DictionaryException {
        // The worker never started: there is nothing to release.
      }
    }
    await _progress.close();
  }

  Future<DictionaryWorker> _worker() async {
    final starting = _starting;
    if (starting != null) {
      final worker = await starting;
      if (!worker.isClosed) return worker;
      // The worker died: a new one has none of the packs open.
      _opening.clear();
    }
    return await (_starting = DictionaryWorker.start());
  }

  /// The pack's index built if it has none, and the pack open in the
  /// worker, once however many look-ups ask at the same time.
  Future<void> _ensureOpen(InstalledPack pack) {
    final running = _opening[pack.id];
    if (running != null) return running;
    final opening = _open(pack);
    _opening[pack.id] = opening;
    // A failure is not kept: the next look-up tries again.
    unawaited(
      opening.then<void>(
        (_) {},
        onError: (Object _) => _opening.remove(pack.id),
      ),
    );
    return opening;
  }

  Future<void> _open(InstalledPack pack) async {
    final worker = await _worker();
    if (await worker.open(pack.directory, pack.id)) return;
    await buildDictionaryIndexOnIsolate(
      directory: pack.directory,
      id: pack.id,
      onProgress: (fraction) {
        if (!_progress.isClosed) {
          _progress.add((packId: pack.id, fraction: fraction));
        }
      },
    );
    if (!await worker.open(pack.directory, pack.id)) {
      throw DictionaryException('${pack.id}: the index built is not usable');
    }
  }
}
