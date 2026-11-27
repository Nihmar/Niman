import 'dart:convert';
import 'dart:typed_data';

/// The text of an entry's bytes in the `.dict`, by the `.ifo`'s
/// `sametypesequence`.
///
/// A pack of ours is `h` (HTML) and the bytes are the HTML. StarDict allows
/// other types, and a pack an import brings later may use them: the bytes
/// are then each field of the sequence, a lowercase type ending in a zero
/// byte and an uppercase one led by its size, the last field running to
/// the end. The first `h` field is read, else the first `m` (plain text).
final class EntryPayload {
  const new _();

  /// The text of [bytes] under [sameTypeSequence] (null when each entry
  /// names its own types), or an empty string when it holds no text.
  static String text(Uint8List bytes, String? sameTypeSequence) {
    if (sameTypeSequence != null && sameTypeSequence.length == 1) {
      return _isText(sameTypeSequence) ? _decode(bytes) : '';
    }
    final fields = _fields(bytes, sameTypeSequence);
    for (final type in ['h', 'm']) {
      for (final (kind, text) in fields) {
        if (kind == type) return text;
      }
    }
    return '';
  }

  static bool _isText(String type) =>
      type.codeUnitAt(0) >= 0x61 && type.codeUnitAt(0) <= 0x7A;

  static String _decode(Uint8List bytes) =>
      utf8.decode(bytes, allowMalformed: true);

  /// The text fields of [bytes], each with its type.
  static List<(String, String)> _fields(Uint8List bytes, String? sequence) {
    final fields = <(String, String)>[];
    final view = ByteData.sublistView(bytes);
    var at = 0;
    var index = 0;
    while (at < bytes.length) {
      final String type;
      var last = false;
      if (sequence == null) {
        type = String.fromCharCode(bytes[at++]);
      } else if (index < sequence.length) {
        type = sequence[index++];
        last = index == sequence.length;
      } else {
        break;
      }
      if (_isText(type)) {
        var end = at;
        if (last) {
          end = bytes.length;
        } else {
          while (end < bytes.length && bytes[end] != 0) {
            end++;
          }
        }
        fields.add((type, _decode(Uint8List.sublistView(bytes, at, end))));
        at = last ? end : end + 1;
      } else {
        var size = bytes.length - at;
        if (!last) {
          if (at + 4 > bytes.length) break;
          size = view.getUint32(at);
          at += 4;
        }
        at = at + size > bytes.length ? bytes.length : at + size;
      }
    }
    return fields;
  }
}
