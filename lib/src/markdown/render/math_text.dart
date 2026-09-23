/// The TeX of a display formula, read out of its block's source: shared by
/// the read view, which draws the block, and `live` mode, which draws it in
/// place of its lines while the caret is elsewhere.
library;

/// The TeX of a display block whose source is [text], its `$$` fences out —
/// a one-line `$$x$$` keeps what is between them.
String displayTexOf(String text) {
  final lines = text.split('\n');
  final body = <String>[];
  for (var at = 0; at < lines.length; at++) {
    final trimmed = lines[at].trim();
    if (trimmed.startsWith(r'$$')) {
      final inner = trimmed.replaceAll(r'$$', '').trim();
      if (inner.isNotEmpty) body.add(inner);
      continue;
    }
    body.add(lines[at]);
  }
  return body.join('\n').trim();
}
