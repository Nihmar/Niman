import 'dart:io';

import 'package:niman/src/dictionary/dict_source.dart';
import 'package:niman/src/dictionary/dictionary_credit.dart';
import 'package:niman/src/dictionary/dictionary_entry.dart';
import 'package:niman/src/dictionary/dictionary_entry_parser.dart';
import 'package:niman/src/dictionary/dictionary_exception.dart';
import 'package:niman/src/dictionary/dictionary_index.dart';
import 'package:niman/src/dictionary/entry_payload.dart';
import 'package:niman/src/dictionary/stardict_ifo.dart';
import 'package:path/path.dart' as p;

/// What a look-up found: the candidate that matched (null when none did),
/// the entries it leads to, and the nearest keys when it led nowhere.
typedef PackAnswer = ({
  String? matched,
  List<DictionaryEntry> entries,
  List<String> suggestions,
});

/// One pack, open in the worker isolate: its `.ifo`, its data file and its
/// sidecar index, answering look-ups from them.
///
/// One look-up at a time: the files have a single position each, and the
/// worker handles its messages in turn.
final class DictionaryWorkerPack {
  const new _(this._id, this._ifo, this._credit, this._dict, this._index);

  /// The most entries a form shared by several lemmas shows.
  static const int maxEntries = 8;

  /// How many nearest keys a look-up that found nothing offers.
  static const int suggestionLimit = 6;

  /// The shortest prefix the nearest keys are looked for under, so *did you
  /// mean* does not offer every word that starts with the same two letters.
  static const int _minPrefix = 3;

  /// Opens the pack [id] in [directory].
  ///
  /// Null when its sidecar index is absent or stale: it has to be built
  /// first, and then this called again. Throws [DictionaryException] for a
  /// pack that cannot be read at all.
  static Future<DictionaryWorkerPack?> open(String directory, String id) async {
    final ifoFile = File(p.join(directory, '$id.ifo'));
    if (!await ifoFile.exists()) throw DictionaryException('$id has no .ifo');
    final ifo = StardictIfo.parse(await ifoFile.readAsString());
    if (ifo == null) throw DictionaryException('$id has no readable .ifo');
    final unsupported = ifo.unsupportedReason;
    if (unsupported != null) throw DictionaryException('$id: $unsupported');
    final dict = await DictSource.open(directory, id);
    if (dict == null) throw DictionaryException('$id has no .dict');
    final DictionaryIndex? index;
    try {
      index = await DictionaryIndex.open(directory, id);
    } on Object {
      await dict.close();
      rethrow;
    }
    if (index == null) {
      await dict.close();
      return null;
    }
    return DictionaryWorkerPack._(
      id,
      ifo,
      DictionaryCredit.fromIfo(ifo),
      dict,
      index,
    );
  }

  final String _id;
  final StardictIfo _ifo;
  final DictionaryCredit _credit;
  final DictSource _dict;
  final DictionaryIndex _index;

  /// Tries [candidates] in order against the index and reads the entries of
  /// the first that is a key.
  ///
  /// When none is, [prefixBases] are the spellings the nearest keys are
  /// looked for under, by their prefix. [language] is the one the look-up is
  /// for, recorded on each entry.
  Future<PackAnswer> lookUp(
    List<String> candidates,
    List<String> prefixBases,
    String language,
  ) async {
    for (final candidate in candidates) {
      final hits = await _index.find(candidate);
      if (hits.isEmpty) continue;
      // The headwords before the forms, each in the pack's own order.
      final entries = {
        for (final hit in hits)
          if (!hit.isSyn) hit.entry,
        for (final hit in hits)
          if (hit.isSyn) hit.entry,
      }.take(maxEntries);
      return (
        matched: candidate,
        entries: [
          for (final entry in entries) await _read(entry, candidate, language),
        ],
        suggestions: const <String>[],
      );
    }
    return (
      matched: null,
      entries: const <DictionaryEntry>[],
      suggestions: await _suggestions(prefixBases),
    );
  }

  Future<DictionaryEntry> _read(
    int entry,
    String matched,
    String language,
  ) async {
    final place = await _index.entry(entry);
    final bytes = await _dict.read(place.offset, place.size);
    return DictionaryEntryParser.parse(
      EntryPayload.text(bytes, _ifo.sameTypeSequence),
      language: language,
      matched: matched,
      credit: _credit,
    );
  }

  /// The nearest keys to a word that is not one: those that start with its
  /// longest prefix that starts any, in each of [bases]' spellings.
  Future<List<String>> _suggestions(List<String> bases) async {
    final lengths = [for (final base in bases) base.runes.length];
    if (lengths.isEmpty) return const [];
    final longest = lengths.reduce((a, b) => a > b ? a : b);
    final shortest = longest < _minPrefix ? longest : _minPrefix;
    final found = <String>[];
    for (var length = longest; length >= shortest; length--) {
      for (final base in bases) {
        if (base.runes.length < length) continue;
        final prefix = String.fromCharCodes(base.runes.take(length));
        for (final key in await _index.keysWithPrefix(
          prefix,
          suggestionLimit,
        )) {
          if (!found.contains(key) && found.length < suggestionLimit) {
            found.add(key);
          }
        }
      }
      if (found.isNotEmpty) break;
    }
    return found;
  }

  /// The pack's id.
  String get id => _id;

  /// Releases the pack's files.
  Future<void> close() async {
    await _index.close();
    await _dict.close();
  }
}
