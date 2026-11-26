/// XHTML, as the HTML parser has to be given it.
///
/// An XHTML document is XML: `<title/>` is an empty title, `<a id="p1"/>` an
/// empty anchor, `<span/>` an empty span. The HTML parser the converter uses
/// ignores the slash of every element that is not void — as every browser
/// reading HTML does — so `<title/>` opens a title that holds the rest of the
/// document, and `<a id="p1"/>Text` makes `Text` the anchor's. A book that
/// writes them is read as its author meant by writing each out as the pair it
/// is first (#1304).
library;

/// [source], XHTML, with every self-closed element that is not void written
/// as an empty pair: `<span class="x"/>` is `<span class="x"></span>`.
///
/// Void elements (`<br/>`, `<img …/>`, `<meta …/>`) keep their slash: they
/// have no end tag, and a pair would give them a second. What is not a start
/// tag — text, comments, CDATA sections, processing instructions, the
/// doctype — is left untouched, and so is a quoted attribute value that
/// holds a `/>`.
String expandSelfClosed(String source) {
  // The common case: a document that writes none of them.
  if (!source.contains('/>')) return source;
  final out = StringBuffer();
  var written = 0;
  var at = 0;
  while (true) {
    final open = source.indexOf('<', at);
    if (open < 0 || open + 1 >= source.length) break;
    final skipTo = switch (source.codeUnitAt(open + 1)) {
      // `<!--`, `<![CDATA[`, `<!DOCTYPE`: a comment and a CDATA section
      // run to their own end, which may hold anything.
      0x21 /* ! */ when source.startsWith('<!--', open) => _end(
        source,
        '-->',
        open + 4,
      ),
      0x21 when source.startsWith('<![CDATA[', open) => _end(
        source,
        ']]>',
        open + 9,
      ),
      0x21 => _end(source, '>', open + 2),
      0x3F /* ? */ => _end(source, '?>', open + 2),
      0x2F /* / */ => _end(source, '>', open + 2),
      final c when !_isLetter(c) => open + 1,
      _ => 0,
    };
    if (skipTo != 0) {
      if (skipTo < 0) break;
      at = skipTo;
      continue;
    }
    final close = _startTagEnd(source, open + 1);
    if (close < 0) break;
    at = close + 1;
    if (source.codeUnitAt(close - 1) != 0x2F /* / */ ) continue;
    final name = _tagName(source, open + 1);
    if (_voidElements.contains(name.toLowerCase())) continue;
    out
      ..write(source.substring(written, close - 1))
      ..write('></')
      ..write(name)
      ..write('>');
    written = close + 1;
  }
  if (written == 0) return source;
  return (out..write(source.substring(written))).toString();
}

/// The index just past the next [terminator] from [from], or -1 when there is
/// none.
int _end(String source, String terminator, int from) {
  final found = source.indexOf(terminator, from);
  return found < 0 ? -1 : found + terminator.length;
}

/// The index of the `>` that ends the start tag whose name begins at [from],
/// or -1 when it never ends. A quoted attribute value is skipped whole: it
/// may hold a `>`.
int _startTagEnd(String source, int from) {
  for (var i = from; i < source.length; i++) {
    final c = source.codeUnitAt(i);
    if (c == 0x3E /* > */ ) return i;
    if (c == 0x22 /* " */ || c == 0x27 /* ' */ ) {
      final closing = source.indexOf(String.fromCharCode(c), i + 1);
      if (closing < 0) return -1;
      i = closing;
    }
  }
  return -1;
}

/// The name of the tag whose name begins at [from].
String _tagName(String source, int from) {
  var end = from;
  while (end < source.length) {
    final c = source.codeUnitAt(end);
    if (c == 0x2F || c == 0x3E || _isSpace(c)) break;
    end++;
  }
  return source.substring(from, end);
}

bool _isLetter(int c) => (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A);

bool _isSpace(int c) =>
    c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D || c == 0x0C;

/// The elements that never have content, in HTML: a slash after one is
/// always right, whatever the parser does with it.
const Set<String> _voidElements = {
  'area',
  'base',
  'basefont',
  'bgsound',
  'br',
  'col',
  'command',
  'embed',
  'frame',
  'hr',
  'image',
  'img',
  'input',
  'keygen',
  'link',
  'meta',
  'param',
  'source',
  'track',
  'wbr',
};
