/// GFM's extended autolinks — `www.` addresses, `http://`, `https://` and
/// `ftp://` URLs, and email addresses written bare — found in the text
/// nodes outside links (the GFM spec 0.29, §6.9; `cmark-gfm`'s
/// `extensions/autolink.c`).
library;

import 'package:niman/src/markdown/inline/inline_build.dart';

/// Turns the bare URLs and addresses in a parse's text into links.
abstract final class GfmAutolinks {
  /// Links the extended autolinks in the text nodes under [root], whose
  /// offsets are in [source].
  static void apply(InlineBuild root, String source) {
    // The containers to visit, without recursion: emphasis nests as deep
    // as a note writes it.
    final containers = <InlineBuild>[root];
    final texts = <InlineBuild>[];
    while (containers.isNotEmpty) {
      final container = containers.removeLast();
      _consolidate(container);
      for (var node = container.first; node != null; node = node.next) {
        switch (node.kind) {
          case InlineKind.text:
            texts.add(node);
          case InlineKind.emphasis ||
              InlineKind.strong ||
              InlineKind.strikethrough:
            containers.add(node);
          case InlineKind.root ||
              InlineKind.link ||
              InlineKind.image ||
              InlineKind.code ||
              InlineKind.html ||
              InlineKind.softBreak ||
              InlineKind.hardBreak ||
              InlineKind.footnoteRef:
            break;
        }
      }
    }
    for (final text in texts) {
      _split(text, source);
    }
  }

  /// Joins the adjacent text nodes among [root]'s children that are their
  /// source as written: a delimiter run that made no emphasis is text of
  /// its own until here, and an address may run through it (`a_b@c.d`). An
  /// escape or a character reference stays a node of its own, so that
  /// every node's offsets still map to the source one to one.
  static void _consolidate(InlineBuild root) {
    bool asWritten(InlineBuild node) =>
        node.kind == InlineKind.text &&
        node.end - node.start == node.text.length;
    for (var node = root.first; node != null; node = node.next) {
      if (!asWritten(node) || node.next == null || !asWritten(node.next!)) {
        continue;
      }
      // One buffer for the run: joining two at a time copies the run once
      // per node, which is quadratic in a run of single-character nodes.
      final joined = StringBuffer(node.text);
      while (node.next != null && asWritten(node.next!)) {
        final next = node.next!;
        joined.write(next.text);
        node.end = next.end;
        next.unlink();
      }
      node.text = joined.toString();
    }
  }

  /// [node] split around the autolinks in its text.
  static void _split(InlineBuild node, String source) {
    final text = node.text;
    // Offsets map one to one only when the node is its source as written.
    final exact =
        node.end - node.start == text.length &&
        source.substring(node.start, node.end) == text;
    var from = 0;
    var anchor = node;
    var i = 0;
    while (i < text.length) {
      final found = _at(text, i);
      if (found == null) {
        i++;
        continue;
      }
      final (start, end, href) = found;
      // An address found by its `@` starts before it: not inside a link
      // already found.
      if (start < from) {
        i++;
        continue;
      }
      if (start > from) {
        anchor = _insert(anchor, node, text, from, start, exact);
      }
      final link =
          InlineBuild(
              InlineKind.link,
              start: exact ? node.start + start : node.start,
              end: exact ? node.start + end : node.end,
            )
            ..destination = href
            ..auto = true;
      link.append(
        InlineBuild(
          InlineKind.text,
          start: link.start,
          end: link.end,
          text: text.substring(start, end),
        ),
      );
      anchor.insertAfter(link);
      anchor = link;
      from = end;
      i = end;
    }
    if (from == 0) return;
    if (from < text.length) {
      _insert(anchor, node, text, from, text.length, exact);
    }
    node.unlink();
  }

  static InlineBuild _insert(
    InlineBuild after,
    InlineBuild node,
    String text,
    int from,
    int to,
    bool exact,
  ) {
    final piece = InlineBuild(
      InlineKind.text,
      start: exact ? node.start + from : node.start,
      end: exact ? node.start + to : node.end,
      text: text.substring(from, to),
    );
    after.insertAfter(piece);
    return piece;
  }

  /// The autolink starting at or around [at] in [text]: its range and
  /// destination, or null. An email address is found by its `@`, and
  /// starts before it.
  static (int, int, String)? _at(String text, int at) {
    final char = text.codeUnitAt(at);
    if (char == 0x40) return _email(text, at);
    if (char == 0x77 || char == 0x57) {
      if (!_boundary(text, at) || !text.startsWith('www.', at)) return null;
      final domain = _domain(text, at, short: false);
      if (domain == 0) return null;
      final end = _delimit(text, at, _run(text, at + domain));
      return (at, end, 'http://${text.substring(at, end)}');
    }
    // A URL's scheme is the letters before its `://`: one with a letter
    // before it is another word's (`cmark-gfm` rewinds over letters).
    if (at > 0 && _isAlpha(text.codeUnitAt(at - 1))) return null;
    for (final scheme in const <String>['http://', 'https://', 'ftp://']) {
      if (text.length - at >= scheme.length &&
          text.substring(at, at + scheme.length).toLowerCase() == scheme) {
        final domain = _domain(text, at + scheme.length, short: true);
        if (domain == 0) return null;
        final end = _delimit(text, at, _run(text, at + scheme.length + domain));
        return (at, end, text.substring(at, end));
      }
    }
    return null;
  }

  /// Whether an autolink may start at [at]: at the start, after white
  /// space, or after `*`, `_`, `~` or `(`.
  static bool _boundary(String text, int at) {
    if (at == 0) return true;
    final before = text.codeUnitAt(at - 1);
    return _isSpace(before) ||
        before == 0x2A ||
        before == 0x5F ||
        before == 0x7E ||
        before == 0x28;
  }

  /// How long the valid domain at [at] is, or 0: alphanumerics, `-` and
  /// `_` in parts between periods, no `_` in the last two parts, and — but
  /// for a URL's [short] one — a period.
  static int _domain(String text, int at, {required bool short}) {
    if (at >= text.length || _isSpace(text.codeUnitAt(at))) return 0;
    var periods = 0;
    var underscoreLast = 0;
    var underscorePrevious = 0;
    // The first character is not asked about, as `cmark-gfm`'s
    // `check_domain` does not: `http://🍄.ga/` is a link.
    var i = at + 1;
    for (; i < text.length; i++) {
      final char = text.codeUnitAt(i);
      if (char == 0x5C && i + 2 < text.length) {
        i++;
        continue;
      }
      if (char == 0x5F) {
        underscoreLast++;
      } else if (char == 0x2E) {
        underscorePrevious = underscoreLast;
        underscoreLast = 0;
        periods++;
      } else if (!_isAlphanumeric(char) && char != 0x2D) {
        break;
      }
    }
    if (underscorePrevious > 0 || underscoreLast > 0) return 0;
    if (!short && periods == 0) return 0;
    return i - at;
  }

  /// Where the link from [at] runs to: up to white space or `<`.
  static int _run(String text, int at) {
    var i = at;
    while (i < text.length &&
        !_isSpace(text.codeUnitAt(i)) &&
        text.codeUnitAt(i) != 0x3C) {
      i++;
    }
    return i;
  }

  /// [end], the end of the link from [start], less the punctuation that
  /// ends a sentence, an unbalanced `)` and an entity-like `&…;`.
  static int _delimit(String text, int start, int end) {
    var to = end;
    // The parentheses in the link, counted once: a run of `)` taking one
    // off at a time counted the link again for each.
    var opening = -1;
    var closing = -1;
    while (to > start) {
      final last = text.codeUnitAt(to - 1);
      if ('?!.,:*_~\'"'.codeUnits.contains(last)) {
        to--;
      } else if (last == 0x3B) {
        var back = to - 2;
        while (back > start && _isAlpha(text.codeUnitAt(back))) {
          back--;
        }
        if (back < to - 2 && text.codeUnitAt(back) == 0x26) {
          to = back;
        } else {
          to--;
        }
      } else if (last == 0x29) {
        if (opening < 0) {
          opening = 0;
          closing = 0;
          for (var i = start; i < to; i++) {
            final char = text.codeUnitAt(i);
            if (char == 0x28) opening++;
            if (char == 0x29) closing++;
          }
        }
        if (closing <= opening) break;
        to--;
        closing--;
      } else {
        break;
      }
    }
    return to;
  }

  /// The email address around the `@` at [at]: letters, digits and `.+-_`
  /// before it; a domain with a period after it, whose last character is
  /// no `-` or `_`; a period at its end left out.
  static (int, int, String)? _email(String text, int at) {
    var start = at;
    while (start > 0) {
      final char = text.codeUnitAt(start - 1);
      if (_isAlphanumeric(char) || '.+-_'.codeUnits.contains(char)) {
        start--;
      } else {
        break;
      }
    }
    if (start == at) return null;
    var end = at + 1;
    var periods = 0;
    while (end < text.length) {
      final char = text.codeUnitAt(end);
      if (_isAlphanumeric(char) || char == 0x2D || char == 0x5F) {
        end++;
      } else if (char == 0x2E &&
          end + 1 < text.length &&
          _isAlphanumeric(text.codeUnitAt(end + 1))) {
        periods++;
        end++;
      } else {
        break;
      }
    }
    if (end == at + 1 || periods == 0) return null;
    final last = text.codeUnitAt(end - 1);
    if (last == 0x2D || last == 0x5F) return null;
    // Written with its scheme, `mailto:` or `xmpp:` — an XMPP address with
    // one `/resource` after it — the link is the whole of it.
    for (final scheme in const <String>['mailto:', 'xmpp:']) {
      final from = start - scheme.length;
      if (from >= 0 &&
          text.substring(from, start).toLowerCase() == scheme &&
          (from == 0 || !_isAlphanumeric(text.codeUnitAt(from - 1)))) {
        start -= scheme.length;
        if (scheme == 'xmpp:' &&
            end < text.length &&
            text.codeUnitAt(end) == 0x2F) {
          var resource = end + 1;
          while (resource < text.length &&
              (_isAlphanumeric(text.codeUnitAt(resource)) ||
                  text.codeUnitAt(resource) == 0x40 ||
                  (text.codeUnitAt(resource) == 0x2E &&
                      resource + 1 < text.length &&
                      _isAlphanumeric(text.codeUnitAt(resource + 1))))) {
            resource++;
          }
          if (resource > end + 1) end = resource;
        }
        return (start, end, text.substring(start, end));
      }
    }
    return (start, end, 'mailto:${text.substring(start, end)}');
  }

  static bool _isSpace(int char) =>
      char == 0x20 || char == 0x09 || char == 0x0A || char == 0x0D;

  static bool _isAlpha(int char) =>
      (char >= 0x41 && char <= 0x5A) || (char >= 0x61 && char <= 0x7A);

  static bool _isAlphanumeric(int char) =>
      _isAlpha(char) || (char >= 0x30 && char <= 0x39);
}
