import 'package:meta/meta.dart';

/// The fence a line is inside.
@immutable
final class CodeFence {
  /// Creates a fence of [char] opened by a run of [len].
  const new(this.char, this.len);

  /// Code unit of the fence char (backtick or tilde).
  final int char;

  /// Length of the opening run.
  final int len;

  /// The fence [text] opens, or null.
  static CodeFence? openedBy(String text) {
    final info = fenceOpenInfo(text);
    return info == null ? null : CodeFence(info.$1, info.$2);
  }

  /// Whether [text] closes [fence].
  static bool closes(String text, CodeFence fence) =>
      isFenceCloseInfo(text, fence.char, fence.len);

  @override
  bool operator ==(Object other) =>
      other is CodeFence && other.char == char && other.len == len;

  @override
  int get hashCode => Object.hash(char, len);
}

/// The fence-opening run at the start of [text] (at least three backticks
/// or tildes, nothing but whitespace/language after) or null.
(int, int)? fenceOpenInfo(String text) {
  final t = text.trimLeft();
  if (t.length < 3) return null;
  final c0 = t.codeUnitAt(0);
  if (c0 != 0x60 && c0 != 0x7E) return null;
  var len = 0;
  while (len < t.length && t.codeUnitAt(len) == c0) {
    len++;
  }
  if (len < 3) return null;
  final rest = t.substring(len);
  if (rest.startsWith('`') || rest.startsWith('~')) return null;
  return (c0, len);
}

/// Whether [text] closes a fence opened with [fenceChar]/[fenceLen]: the
/// line is exactly a run of the same char, at least as long.
bool isFenceCloseInfo(String text, int fenceChar, int fenceLen) {
  final t = text.trim();
  if (t.isEmpty) return false;
  var len = 0;
  while (len < t.length && t.codeUnitAt(len) == fenceChar) {
    len++;
  }
  return len >= fenceLen && t.length == len;
}
