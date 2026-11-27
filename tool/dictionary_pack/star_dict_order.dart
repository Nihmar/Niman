// The order StarDict keeps its index in (docs/records/dictionary.md, "The pack
// format, version 1"): the other StarDict tools binary-search a pack's `.idx`
// and `.syn`, so a key out of this order is a key they cannot find.
import 'dart:typed_data';

/// glib's `g_ascii_strcasecmp` over UTF-8 [a] and [b] (ASCII letters
/// folded, every other byte as it is, a prefix before its extensions), then
/// `strcmp` when that finds them equal.
int compareStarDictKeys(Uint8List a, Uint8List b) {
  final shortest = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < shortest; i++) {
    final x = _fold(a[i]);
    final y = _fold(b[i]);
    if (x != y) return x - y;
  }
  if (a.length != b.length) return a.length - b.length;
  return compareBytes(a, b);
}

/// `strcmp`: the bytes as unsigned numbers, a prefix first.
int compareBytes(Uint8List a, Uint8List b) {
  final shortest = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < shortest; i++) {
    if (a[i] != b[i]) return a[i] - b[i];
  }
  return a.length - b.length;
}

int _fold(int byte) => byte >= 0x41 && byte <= 0x5a ? byte + 0x20 : byte;
