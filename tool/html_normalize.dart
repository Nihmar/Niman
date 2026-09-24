/// cmark's `normalize_html`, ported to Dart.
///
/// A "we pass the spec" claim is only meaningful relative to normalizations:
/// the suites' expected HTML and a parser's output differ in ways that are not
/// parsing differences at all — whitespace around block tags, `<br />` against
/// `<br>`, attribute order and case, and the entity form. cmark's
/// `test/normalize.py` is the reference, and this is a faithful port of it so
/// the number Niman reports is comparable with cmark's own.
///
/// Ported from `cmark`'s `test/normalize.py` (which adapted it from
/// <https://github.com/karlcow/markdown-testsuite/>). Two behaviours are
/// reproduced deliberately, including one that is arguably a bug in the
/// original:
///
/// * the percent-normalization branch tests the attribute's *value* against
///   `href`/`src` rather than its *name*, so it effectively never fires —
///   reproduced as-is, because agreeing with the reference is the point;
/// * a valueless attribute sorts as if its value were empty rather than
///   raising the way Python 3 would.
///
/// `test/unit/html_normalize_test.dart` proves the port against the reference
/// on a committed corpus.
library;

import 'dart:convert';

import 'html_entities.dart';

/// Block-level tags, as cmark's normalizer lists them. Whitespace directly
/// around one of these is insignificant.
const Set<String> _blockTags = <String>{
  'article',
  'header',
  'aside',
  'hgroup',
  'blockquote',
  'hr',
  'iframe',
  'body',
  'li',
  'map',
  'button',
  'object',
  'canvas',
  'ol',
  'caption',
  'output',
  'col',
  'p',
  'colgroup',
  'pre',
  'dd',
  'progress',
  'div',
  'section',
  'dl',
  'table',
  'td',
  'dt',
  'tbody',
  'embed',
  'textarea',
  'fieldset',
  'tfoot',
  'figcaption',
  'th',
  'figure',
  'thead',
  'footer',
  'tr',
  'form',
  'ul',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'video',
  'script',
  'style',
};

/// The normalized form of [html], per cmark's contract.
String normalizeHtml(String html) {
  final normalizer = _Normalizer();
  // CDATA is passed through verbatim: the reference works around its own
  // parser's limitations by chunking the input this way.
  final chunk = RegExp(r'<!\[CDATA\[.*?\]\]>|<[^>]*>|[^<]+', dotAll: true);
  for (final match in chunk.allMatches(html)) {
    final text = match[0]!;
    if (text.startsWith('<![CDATA')) {
      normalizer.raw(text);
    } else {
      normalizer.feed(text);
    }
  }
  return normalizer.output;
}

enum _Last { startTag, endTag, data, comment, decl, pi, ref }

final class _Normalizer {
  String output = '';
  _Last _last = _Last.startTag;
  String _lastTag = '';
  bool _inPre = false;

  void raw(String text) => output += text;

  void feed(String chunk) {
    if (chunk.startsWith('<!--')) {
      // `<!-->` is a comment with empty data, so the closing run is optional
      // rather than assumed: the reference's parser accepts the short form.
      final body = chunk.substring(4);
      _comment(
        body.endsWith('-->') ? body.substring(0, body.length - 3) : body,
      );
    } else if (chunk.startsWith('<!')) {
      // The reference's parser calls anything that is not a `DOCTYPE` a
      // *bogus comment*: `<!ELEMENT br EMPTY>` comes back as
      // `<!--ELEMENT br EMPTY-->`, not as a declaration.
      final body = chunk.substring(2);
      final data = body.endsWith('>')
          ? body.substring(0, body.length - 1)
          : body;
      if (data.toLowerCase().startsWith('doctype')) {
        _decl(data);
      } else {
        _comment(data);
      }
    } else if (chunk.startsWith('<?')) {
      _pi(chunk.substring(2, chunk.length - 1));
    } else if (chunk.startsWith('</')) {
      _endTag(chunk.substring(2, chunk.length - 1).trim().toLowerCase());
    } else if (chunk.startsWith('<')) {
      _startTag(chunk);
    } else {
      _data(chunk);
    }
  }

  void _data(String raw) {
    // The reference's parser hands entity references over separately; the
    // chunker here does not, so they are split out before the text is emitted.
    final ref = RegExp('&(#[0-9]+|#[xX][0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);');
    var position = 0;
    for (final match in ref.allMatches(raw)) {
      if (match.start > position) {
        _text(raw.substring(position, match.start));
      }
      _reference(match.group(1)!);
      position = match.end;
    }
    if (position < raw.length) _text(raw.substring(position));
  }

  void _text(String value) {
    var data = value;
    final afterTag = _last == _Last.endTag || _last == _Last.startTag;
    final afterBlockTag = afterTag && _blockTags.contains(_lastTag);
    if (afterTag && _lastTag == 'br') {
      data = data.replaceFirst(RegExp(r'^\n+'), '');
    }
    if (!_inPre) data = data.replaceAll(RegExp(r'\s+'), ' ');
    if (afterBlockTag && !_inPre) {
      data = _last == _Last.startTag
          ? data.replaceFirst(RegExp(r'^\s+'), '')
          : trimWhitespace(data);
    }
    output += data;
    _last = _Last.data;
  }

  void _endTag(String tag) {
    if (tag == 'pre') {
      _inPre = false;
    } else if (_blockTags.contains(tag)) {
      output = output.trimRight();
    }
    output += '</$tag>';
    _lastTag = tag;
    _last = _Last.endTag;
  }

  void _startTag(String chunk) {
    final attributes = <String, String?>{};
    var body = chunk.substring(1);
    var selfClosing = false;
    if (body.endsWith('>')) body = body.substring(0, body.length - 1);
    if (body.endsWith('/')) {
      selfClosing = true;
      body = body.substring(0, body.length - 1);
    }
    final nameMatch = RegExp(r'^[a-zA-Z][^\s/>]*').firstMatch(body);
    final tag = (nameMatch?[0] ?? '').toLowerCase();
    final rest = nameMatch == null ? '' : body.substring(nameMatch.end);

    final attribute = RegExp(
      r'''\s*([^\s=/>]+)(?:\s*=\s*("([^"]*)"|'([^']*)'|([^\s>]*)))?''',
    );
    for (final match in attribute.allMatches(rest)) {
      if (match.group(1) == null) continue;
      final key = match.group(1)!.toLowerCase();
      final value = match.group(3) ?? match.group(4) ?? match.group(5);
      attributes[key] = value == null ? null : _decodeReferences(value);
    }

    if (tag == 'pre') _inPre = true;
    if (_blockTags.contains(tag)) output = output.trimRight();
    output += '<$tag';
    if (attributes.isNotEmpty) {
      final keys = attributes.keys.toList()
        ..sort((a, b) {
          final byKey = a.compareTo(b);
          if (byKey != 0) return byKey;
          return (attributes[a] ?? '').compareTo(attributes[b] ?? '');
        });
      final rendered = StringBuffer();
      for (final key in keys) {
        final value = attributes[key];
        rendered.write(' $key');
        if (value == null) continue;
        if (value == 'href' || value == 'src') {
          rendered.write('="${_percentNormalize(value)}"');
        } else {
          rendered.write('="${escapeAttribute(value)}"');
        }
      }
      output += rendered.toString();
    }
    output += '>';
    _lastTag = tag;
    _last = selfClosing ? _Last.endTag : _Last.startTag;
  }

  void _comment(String data) {
    output += '<!--$data-->';
    _last = _Last.comment;
  }

  void _decl(String data) {
    output += '<!$data>';
    _last = _Last.decl;
  }

  void _pi(String data) {
    output += '<?$data>';
    _last = _Last.pi;
  }

  void _reference(String name) {
    int? code;
    if (name.startsWith('#x') || name.startsWith('#X')) {
      code = int.tryParse(name.substring(2), radix: 16);
    } else if (name.startsWith('#')) {
      code = int.tryParse(name.substring(1));
    } else {
      code = htmlNamedEntities[name];
    }
    _outputChar(code, '&$name;');
    _last = _Last.ref;
  }

  void _outputChar(int? code, String fallback) {
    if (code == null || code < 0 || code > 0x10FFFF) {
      output += fallback;
      return;
    }
    switch (code) {
      case 0x3C:
        output += '&lt;';
      case 0x3E:
        output += '&gt;';
      case 0x26:
        output += '&amp;';
      case 0x22:
        output += '&quot;';
      default:
        output += String.fromCharCode(code);
    }
  }
}

/// The reference's `html.escape(value, quote=True)`; `'` becomes `&#x27;`.
String escapeAttribute(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#x27;');

/// Whitespace trimming that matches the reference's `str.strip()`.
String trimWhitespace(String value) {
  const whitespace =
      ' \t\n\r\f\v\u00a0\u1680\u2000\u2001\u2002\u2003'
      ' \u2004\u2005\u2006\u2007\u2008\u2009\u200a\u2028\u2029\u202f'
      ' \u205f\u3000';
  var start = 0;
  var end = value.length;
  while (start < end && whitespace.contains(value[start])) {
    start++;
  }
  while (end > start && whitespace.contains(value[end - 1])) {
    end--;
  }
  return value.substring(start, end);
}

/// Decodes the character references inside an attribute value, as the
/// reference's parser does before it re-escapes it.
String _decodeReferences(String value) {
  final ref = RegExp('&(#[0-9]+|#[xX][0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);');
  return value.replaceAllMapped(ref, (match) {
    final name = match.group(1)!;
    int? code;
    if (name.startsWith('#x') || name.startsWith('#X')) {
      code = int.tryParse(name.substring(2), radix: 16);
    } else if (name.startsWith('#')) {
      code = int.tryParse(name.substring(1));
    } else {
      code = htmlNamedEntities[name];
    }
    if (code == null || code < 0 || code > 0x10FFFF) return match[0]!;
    return String.fromCharCode(code);
  });
}

/// `urllib.quote(urllib.unquote(value), safe='/')`, which the reference only
/// reaches when an attribute's *value* is literally `href` or `src`.
String _percentNormalize(String value) {
  final bytes = <int>[];
  for (var i = 0; i < value.length; i++) {
    final char = value[i];
    if (char == '%' && i + 2 < value.length) {
      final hex = int.tryParse(value.substring(i + 1, i + 3), radix: 16);
      if (hex != null) {
        bytes.add(hex);
        i += 2;
        continue;
      }
    }
    bytes.addAll(utf8.encode(char));
  }
  final decoded = utf8.decode(bytes, allowMalformed: true);
  final buffer = StringBuffer();
  for (final rune in decoded.runes) {
    final char = String.fromCharCode(rune);
    if (RegExp(r'[A-Za-z0-9_.\-~/]').hasMatch(char)) {
      buffer.write(char);
    } else {
      for (final byte in utf8.encode(char)) {
        buffer.write(
          '%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}',
        );
      }
    }
  }
  return buffer.toString();
}
