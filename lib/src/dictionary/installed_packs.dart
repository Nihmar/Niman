import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/dictionary/dict_source.dart';
import 'package:niman/src/dictionary/installed_pack.dart';
import 'package:niman/src/dictionary/lookup_term.dart';
import 'package:niman/src/dictionary/stardict_ifo.dart';
import 'package:path/path.dart' as p;

/// What the dictionaries folder holds, and which pack serves a language.
///
/// The folder is `<support>/dictionary/` and is passed in: which packs are
/// installed is read from it, there being no order to keep, since one pack
/// serves one language (docs/records/dictionary.md, decision 14).
final class InstalledPacks {
  const new _();

  /// The packs in the folder [root]: every `niman-<code>` folder with a
  /// readable `.ifo`, sorted by id. One whose format this app does not read
  /// (or whose files are not all there) is listed as unavailable, so the
  /// settings can say why it is not used.
  ///
  /// Reads the disk on an isolate of its own.
  static Future<List<InstalledPack>> list(String root) =>
      Isolate.run(() => scan(root));

  /// [list]'s work, for a caller that is already off the UI isolate.
  static Future<List<InstalledPack>> scan(String root) async {
    final folder = Directory(root);
    if (!await folder.exists()) return const [];
    final packs = <InstalledPack>[];
    await for (final entity in folder.list()) {
      if (entity is! Directory) continue;
      final id = p.basename(entity.path);
      if (!_isPackId(id)) continue;
      final pack = await _read(entity.path, id);
      if (pack != null) packs.add(pack);
    }
    packs.sort((a, b) => a.id.compareTo(b.id));
    return packs;
  }

  /// The pack that serves [language] among [packs]: the first available one
  /// whose languages hold its primary subtag (`hr`, `sr` and `bs` are all
  /// served by `niman-sh`), or null.
  static InstalledPack? forLanguage(
    Iterable<InstalledPack> packs,
    String language,
  ) {
    final code = LookupTerm.primaryLanguage(language);
    for (final pack in packs) {
      if (pack.isAvailable && pack.languages.contains(code)) return pack;
    }
    return null;
  }

  static bool _isPackId(String name) =>
      RegExp(r'^niman-[a-z][a-z0-9-]*$').hasMatch(name);

  static Future<InstalledPack?> _read(String directory, String id) async {
    final ifoFile = File(p.join(directory, '$id.ifo'));
    if (!await ifoFile.exists()) return null;
    final StardictIfo? ifo;
    try {
      ifo = StardictIfo.parse(await ifoFile.readAsString());
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
    if (ifo == null) return null;
    final code = id.substring('niman-'.length);
    final reason = ifo.unsupportedReason ?? await _missingFile(directory, id);
    return InstalledPack(
      id: id,
      directory: directory,
      languages: ifo.languages.isEmpty ? [code] : ifo.languages,
      ifo: ifo,
      unavailableReason: reason,
    );
  }

  static Future<String?> _missingFile(String directory, String id) async {
    if (!await File(p.join(directory, '$id.idx')).exists()) return 'no .idx';
    if (await DictSource.pathOf(directory, id) == null) return 'no .dict';
    return null;
  }
}
