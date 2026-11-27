/// Where the bare URLs of a text are, so that the app's own syntax is not
/// read inside one: a tag's `#` or a formula's `$` in an address belongs to
/// the address (`https://x.com/#top`, `https://x/$a/$b`), and the parser
/// would cut the link there before the autolink pass sees it.
library;

import 'package:niman/src/markdown/inline/gfm_autolinks.dart';

/// The bare URLs of a text, found a stretch at a time as they are asked
/// about, each stretch once.
final class BareUrls {
  /// The URLs of [text].
  new(this.text);

  /// The text parsed.
  final String text;

  // The stretch last read: a run of characters between white space (and
  // `<`, where an autolink ends), and the URLs in it.
  int _from = 0;
  int _to = 0;
  List<(int, int)> _urls = const <(int, int)>[];

  /// Whether position [at] is inside a bare URL, past its first character.
  ///
  /// Read once per stretch: a text asked about at every `#` and `$` of a
  /// long run stays linear.
  bool holds(int at) {
    if (at < _from || at >= _to) _read(at);
    for (final (start, end) in _urls) {
      if (start < at && at < end) return true;
    }
    return false;
  }

  void _read(int at) {
    var from = at;
    while (from > 0 && !_breaks(text.codeUnitAt(from - 1))) {
      from--;
    }
    var to = at;
    while (to < text.length && !_breaks(text.codeUnitAt(to))) {
      to++;
    }
    final urls = <(int, int)>[];
    var i = from;
    while (i < to) {
      final found = GfmAutolinks.urlAt(text, i);
      if (found == null) {
        i++;
      } else {
        urls.add(found);
        i = found.$2;
      }
    }
    _from = from;
    _to = to;
    _urls = urls;
  }

  /// What ends a stretch: white space, and `<`, which ends a link.
  static bool _breaks(int char) =>
      char == 0x20 ||
      char == 0x09 ||
      char == 0x0A ||
      char == 0x0D ||
      char == 0x3C;
}
