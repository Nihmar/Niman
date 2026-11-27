/// A node of an entry's HTML: text, or an element with its attributes and
/// children.
///
/// The pack format's grammar is closed (docs/records/dictionary.md), so
/// this is not an HTML parser: it reads tags, attributes and the four
/// entities the pipeline writes, and anything it does not understand is
/// text, never an error. A pack read years from now, or one an import
/// brings, still shows its words.
final class EntryNode {
  /// An element named [tag] (lowercase) with [attributes].
  new element(String this.tag, [this.attributes = const {}])
    : text = '',
      children = [];

  /// A run of text, already decoded.
  new text(this.text) : tag = null, attributes = const {}, children = [];

  /// Reads [html]: the root is an element named `root` holding what it
  /// reads.
  factory parse(String html) {
    final root = EntryNode.element('root');
    final open = [root];
    var at = 0;
    final text = StringBuffer();
    void flush() {
      if (text.isEmpty) return;
      open.last.children.add(EntryNode.text(_decode(text.toString())));
      text.clear();
    }

    while (at < html.length) {
      final char = html[at];
      if (char != '<') {
        text.write(char);
        at++;
        continue;
      }
      if (html.startsWith('<!--', at)) {
        final end = html.indexOf('-->', at + 4);
        flush();
        at = end < 0 ? html.length : end + 3;
        continue;
      }
      final closing = at + 1 < html.length && html[at + 1] == '/';
      final nameAt = at + (closing ? 2 : 1);
      if (nameAt >= html.length || !_tagStart.hasMatch(html[nameAt])) {
        // A `<` that starts no tag is a less-than sign in the text.
        text.write(char);
        at++;
        continue;
      }
      final end = html.indexOf('>', nameAt);
      if (end < 0) {
        text.write(html.substring(at));
        break;
      }
      flush();
      var nameEnd = nameAt;
      while (nameEnd < end && !' \t\r\n/'.contains(html[nameEnd])) {
        nameEnd++;
      }
      final name = html.substring(nameAt, nameEnd).toLowerCase();
      if (closing) {
        final index = open.lastIndexWhere((node) => node.tag == name);
        if (index > 0) open.length = index;
      } else {
        final element = EntryNode.element(
          name,
          _attributes(html.substring(nameEnd, end)),
        );
        if (name == 'li') _closeOpenItem(open);
        open.last.children.add(element);
        final selfClosing = html[end - 1] == '/';
        if (!selfClosing && !_void.contains(name)) open.add(element);
      }
      at = end + 1;
    }
    flush();
    return root;
  }

  /// The elements that have no content and no end tag.
  static const Set<String> _void = {
    'br',
    'hr',
    'img',
    'wbr',
    'input',
    'meta',
    'link',
  };

  static final RegExp _tagStart = RegExp('[a-zA-Z]');
  static final RegExp _attribute = RegExp(
    r'''([^\s"'=/>]+)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'>]+)))?''',
  );
  static final RegExp _entity = RegExp('&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);');

  /// The element's name, or null for a text node.
  final String? tag;

  /// The text of a text node; empty for an element.
  final String text;

  /// An element's attributes, names lowercase.
  final Map<String, String> attributes;

  /// An element's children, in order.
  final List<EntryNode> children;

  /// Whether this is an element named [name] with the class [className] (or
  /// any class, when none is given).
  bool isElement(String name, [String? className]) =>
      tag == name &&
      (className == null ||
          (attributes['class'] ?? '')
              .split(RegExp(r'\s+'))
              .contains(className));

  /// The elements named [name] below this node, in document order, not
  /// looking inside the ones it finds.
  Iterable<EntryNode> outermost(String name, [String? className]) sync* {
    for (final child in children) {
      if (child.isElement(name, className)) {
        yield child;
      } else {
        yield* child.outermost(name, className);
      }
    }
  }

  /// All the text below this node, in document order, without tags.
  String get allText {
    if (tag == null) return text;
    final buffer = StringBuffer();
    for (final child in children) {
      if (child.tag == 'br') buffer.write(' ');
      buffer.write(child.allText);
    }
    return buffer.toString();
  }

  /// A `<li>` that opens while another is still open closes it: the list
  /// of senses, or of examples, written without its end tags.
  static void _closeOpenItem(List<EntryNode> open) {
    for (var i = open.length - 1; i > 0; i--) {
      final tag = open[i].tag;
      if (tag == 'li') {
        open.length = i;
        return;
      }
      if (tag == 'ol' || tag == 'ul') return;
    }
  }

  static Map<String, String> _attributes(String source) => {
    for (final match in _attribute.allMatches(source))
      match[1]!.toLowerCase(): _decode(match[2] ?? match[3] ?? match[4] ?? ''),
  };

  /// [text] with the entities read: the four the pipeline writes, `&apos;`,
  /// `&nbsp;` and numeric ones. An entity it does not know stays as written.
  static String _decode(String text) {
    if (!text.contains('&')) return text;
    return text.replaceAllMapped(_entity, (match) {
      final name = match[1]!;
      if (name.startsWith('#x')) {
        return _char(int.tryParse(name.substring(2), radix: 16)) ?? match[0]!;
      }
      if (name.startsWith('#')) {
        return _char(int.tryParse(name.substring(1))) ?? match[0]!;
      }
      return switch (name) {
        'amp' => '&',
        'lt' => '<',
        'gt' => '>',
        'quot' => '"',
        'apos' => "'",
        'nbsp' => ' ',
        _ => match[0]!,
      };
    });
  }

  static String? _char(int? code) =>
      code != null &&
          code > 0 &&
          code <= 0x10FFFF &&
          !(code >= 0xD800 && code <= 0xDFFF)
      ? String.fromCharCode(code)
      : null;

  @override
  String toString() =>
      tag == null ? 'EntryNode.text($text)' : 'EntryNode.element($tag)';
}
