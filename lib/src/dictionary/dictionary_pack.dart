import 'package:meta/meta.dart';
import 'package:niman/src/core/download/downloadable.dart';
import 'package:niman/src/dictionary/dictionary_pack_info.dart';

/// A dictionary pack as the downloader sees it: the catalog's
/// [DictionaryPackInfo], and the `.tar` it is published as.
///
/// The archive lands in the dictionaries folder itself, beside the pack
/// folders (`niman-it.tar` next to `niman-it/`), and is unpacked and
/// deleted once it is whole: the downloader checks its size and SHA-256
/// before it takes its final name, so a `.tar` that is there is a genuine
/// one, and the one install step left.
@immutable
final class DictionaryPack implements Downloadable {
  /// The catalog entry [info] as something to download.
  const new(this.info);

  /// What the catalog says about the pack.
  final DictionaryPackInfo info;

  /// `niman-it`: the pack's folder, and the downloader's key.
  @override
  String get id => info.id;

  @override
  Uri get uri => Uri.parse(info.url);

  @override
  int get bytes => info.bytes;

  /// `niman-it.tar`, in the dictionaries folder.
  @override
  String get fileName => info.fileName;

  @override
  String get sha256 => info.sha256;

  /// The app's language ids the pack answers for.
  List<String> get languages => info.languages;

  /// Whether the pack serves the language [code] (`it`, `hr`).
  bool serves(String code) => info.languages.contains(code);

  @override
  bool operator ==(Object other) => other is DictionaryPack && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}
