/// Our inline parser: a leaf's inline text read into [InlineNode]s as
/// `cmark-gfm` reads it (`docs/dev/block-tree.md`; `cmark`'s `inlines.c`,
/// the GFM spec 0.29).
library;

import 'package:niman/src/markdown/inline/bracket.dart';
import 'package:niman/src/markdown/inline/delimiter.dart';
import 'package:niman/src/markdown/inline/delimiter_stack.dart';
import 'package:niman/src/markdown/inline/gfm_autolinks.dart';
import 'package:niman/src/markdown/inline/inline_build.dart';
import 'package:niman/src/markdown/inline/inline_chars.dart';
import 'package:niman/src/markdown/inline/inline_node.dart';
import 'package:niman/src/markdown/inline/inline_scanners.dart';
import 'package:niman/src/markdown/inline/link_references.dart';

/// Reads one leaf's inline text.
final class InlineParser {
  /// A parser of [text], resolving references by [references] (normalized
  /// labels) and footnote references by [footnotes] (normalized labels).
  new(
    this.text, {
    this.references = const <String, LinkReference>{},
    this.footnotes = const <String>{},
    this.extendedAutolinks = true,
  });

  /// The leaf's inline text.
  final String text;

  /// The note's link reference definitions.
  final Map<String, LinkReference> references;

  /// The note's footnote labels.
  final Set<String> footnotes;

  /// Whether bare URLs and addresses are links (GFM's extended autolinks):
  /// always in the app; off for the spec's examples of plain CommonMark.
  final bool extendedAutolinks;

  int _pos = 0;
  late final InlineBuild _root = InlineBuild(
    InlineKind.root,
    start: 0,
    end: text.length,
  );
  final DelimiterStack _delimiters = DelimiterStack();
  Bracket? _brackets;

  /// How many links the parse has made ([Bracket.links]).
  int _links = 0;

  /// Whether the text was scanned to its end for a code span's closing run
  /// once, and the last start of a run of each length it saw: an opening
  /// run with no closing one after it is then known without scanning
  /// again (`cmark`'s `scanned_for_backticks`).
  bool _backticksScanned = false;
  final Map<int, int> _lastBacktickRun = <int, int>{};

  /// The text's inline nodes.
  List<InlineNode> parse() {
    while (_pos < text.length) {
      _step();
    }
    _delimiters.process(null);
    if (extendedAutolinks) GfmAutolinks.apply(_root, text);
    return <InlineNode>[
      for (var node = _root.first; node != null; node = node.next)
        node.freeze(),
    ];
  }

  void _step() {
    final char = text.codeUnitAt(_pos);
    switch (char) {
      case 0x0A || 0x0D:
        _newline();
      case 0x60:
        _codeSpan();
      case 0x5C:
        _backslash();
      case 0x26:
        _entity();
      case 0x3C:
        _angle();
      case 0x2A || 0x5F || 0x7E:
        _delimiterRun(char);
      case 0x5B:
        _openBracket(image: false, width: 1);
      case 0x21:
        if (_pos + 1 < text.length && text.codeUnitAt(_pos + 1) == 0x5B) {
          _openBracket(image: true, width: 2);
        } else {
          _text(_pos, _pos + 1);
        }
      case 0x5D:
        _closeBracket();
      default:
        var end = _pos + 1;
        while (end < text.length && !_special(text.codeUnitAt(end))) {
          end++;
        }
        _text(_pos, end);
    }
  }

  static bool _special(int char) => switch (char) {
    0x0A ||
    0x0D ||
    0x60 ||
    0x5C ||
    0x26 ||
    0x3C ||
    0x2A ||
    0x5F ||
    0x7E ||
    0x5B ||
    0x21 ||
    0x5D => true,
    _ => false,
  };

  /// A text node over `[start, end)`, reading as [literal] — the source
  /// itself when null — and the parse past it.
  InlineBuild _text(int start, int end, [String? literal]) {
    final node = InlineBuild(
      InlineKind.text,
      start: start,
      end: end,
      text: literal ?? text.substring(start, end),
    );
    _root.append(node);
    _pos = end;
    return node;
  }

  /// A line ending: hard after two spaces, soft otherwise; the spaces
  /// around it are not text.
  void _newline() {
    final at = _pos;
    var end = _pos;
    if (text.codeUnitAt(end) == 0x0D) end++;
    if (end < text.length && text.codeUnitAt(end) == 0x0A) end++;
    var start = at;
    var hard = false;
    final previous = _root.last;
    if (previous != null && previous.kind == InlineKind.text) {
      final literal = previous.text;
      var spaces = 0;
      while (spaces < literal.length &&
          literal.codeUnitAt(literal.length - 1 - spaces) == 0x20) {
        spaces++;
      }
      if (spaces > 0) {
        hard = spaces >= 2;
        previous
          ..text = literal.substring(0, literal.length - spaces)
          ..end -= spaces;
        start = at - spaces;
        if (previous.text.isEmpty && previous.start == previous.end) {
          previous.unlink();
        }
      }
    }
    _root.append(
      InlineBuild(
        hard ? InlineKind.hardBreak : InlineKind.softBreak,
        start: start,
        end: end,
      ),
    );
    _pos = _skipSpaces(end);
  }

  int _skipSpaces(int at) {
    var i = at;
    while (i < text.length &&
        (text.codeUnitAt(i) == 0x20 || text.codeUnitAt(i) == 0x09)) {
      i++;
    }
    return i;
  }

  /// A code span, or its opening backticks as text when none closes it.
  void _codeSpan() {
    final start = _pos;
    var open = start;
    while (open < text.length && text.codeUnitAt(open) == 0x60) {
      open++;
    }
    final length = open - start;
    if (_backticksScanned && (_lastBacktickRun[length] ?? -1) < open) {
      _text(start, open);
      return;
    }
    var i = open;
    while (i < text.length) {
      if (text.codeUnitAt(i) != 0x60) {
        i++;
        continue;
      }
      var run = i;
      while (run < text.length && text.codeUnitAt(run) == 0x60) {
        run++;
      }
      final seen = _lastBacktickRun[run - i];
      if (seen == null || seen < i) _lastBacktickRun[run - i] = i;
      if (run - i == length) {
        var code = text
            .substring(open, i)
            .replaceAll('\r\n', ' ')
            .replaceAll('\n', ' ')
            .replaceAll('\r', ' ');
        if (code.length >= 2 &&
            code.startsWith(' ') &&
            code.endsWith(' ') &&
            code.trim().isNotEmpty) {
          code = code.substring(1, code.length - 1);
        }
        _root.append(
          InlineBuild(InlineKind.code, start: start, end: run, text: code),
        );
        _pos = run;
        return;
      }
      i = run;
    }
    _backticksScanned = true;
    _text(start, open);
  }

  /// A backslash: an escaped punctuation character, a hard break before a
  /// line ending, or a backslash.
  void _backslash() {
    final next = _pos + 1;
    if (next < text.length) {
      final char = text.codeUnitAt(next);
      if (char == 0x0A || char == 0x0D) {
        var end = next + 1;
        if (char == 0x0D && end < text.length && text.codeUnitAt(end) == 0x0A) {
          end++;
        }
        _root.append(InlineBuild(InlineKind.hardBreak, start: _pos, end: end));
        _pos = _skipSpaces(end);
        return;
      }
      if (InlineChars.isAsciiPunctuation(char)) {
        _text(_pos, next + 1, String.fromCharCode(char));
        return;
      }
    }
    _text(_pos, next);
  }

  void _entity() {
    final reference = InlineScanners.entity(text, _pos);
    if (reference == null) {
      _text(_pos, _pos + 1);
    } else {
      _text(_pos, reference.$2, reference.$1);
    }
  }

  /// An autolink, raw HTML, or a `<`.
  void _angle() {
    final autolink = InlineScanners.autolink(text, _pos);
    if (autolink != null) {
      final (address, email, end) = autolink;
      final link = InlineBuild(InlineKind.link, start: _pos, end: end)
        ..destination = email ? 'mailto:$address' : address
        ..auto = true
        ..append(
          InlineBuild(
            InlineKind.text,
            start: _pos + 1,
            end: end - 1,
            text: address,
          ),
        );
      _root.append(link);
      _pos = end;
      return;
    }
    final html = InlineScanners.rawHtml(text, _pos);
    if (html != null) {
      _root.append(
        InlineBuild(
          InlineKind.html,
          start: _pos,
          end: html,
          text: text.substring(_pos, html),
        ),
      );
      _pos = html;
      return;
    }
    _text(_pos, _pos + 1);
  }

  /// A run of `*`, `_` or `~`: text, and a delimiter when it may open or
  /// close.
  void _delimiterRun(int char) {
    final start = _pos;
    var end = start;
    while (end < text.length && text.codeUnitAt(end) == char) {
      end++;
    }
    final count = end - start;
    final node = _text(start, end);
    // GFM's strikethrough is one or two tildes.
    if (char == 0x7E && count > 2) return;
    final before = InlineChars.before(text, start);
    final after = InlineChars.at(text, end);
    final beforeSpace = InlineChars.isWhitespace(before);
    final afterSpace = InlineChars.isWhitespace(after);
    final beforePunct = before >= 0 && InlineChars.isPunctuation(before);
    final afterPunct = after >= 0 && InlineChars.isPunctuation(after);
    final left = !afterSpace && (!afterPunct || beforeSpace || beforePunct);
    final right = !beforeSpace && (!beforePunct || afterSpace || afterPunct);
    final canOpen = char == 0x5F ? left && (!right || beforePunct) : left;
    final canClose = char == 0x5F ? right && (!left || afterPunct) : right;
    if (!canOpen && !canClose) return;
    _delimiters.push(
      Delimiter(
        node,
        char: char,
        count: count,
        canOpen: canOpen,
        canClose: canClose,
      ),
    );
  }

  void _openBracket({required bool image, required int width}) {
    final node = _text(_pos, _pos + width);
    _brackets?.bracketAfter = true;
    _brackets = Bracket(
      node,
      textStart: node.end,
      image: image,
      previousDelimiter: _delimiters.last,
      previous: _brackets,
      links: _links,
    );
  }

  /// A `]`: the link or image its bracket opened, a footnote reference, or
  /// a `]`.
  void _closeBracket() {
    final close = _pos;
    final opener = _brackets;
    if (opener == null) {
      _text(close, close + 1);
      return;
    }
    if (!opener.image && opener.links != _links) {
      _brackets = opener.previous;
      _text(close, close + 1);
      return;
    }
    final afterText = close + 1;
    final link = _inlineLink(afterText) ?? _referenceLink(opener, afterText);
    if (link == null) {
      final footnote =
          close - opener.textStart <= 1000 &&
              opener.textStart < close &&
              text.codeUnitAt(opener.textStart) == 0x5E
          ? _footnote(text.substring(opener.textStart, close))
          : null;
      _brackets = opener.previous;
      if (footnote == null) {
        _text(close, close + 1);
        return;
      }
      _pos = afterText;
      // `![^1]` is a `!` and the reference, as `cmark-gfm` reads it.
      final bang = opener.image ? 1 : 0;
      final node = InlineBuild(
        InlineKind.footnoteRef,
        start: opener.node.start + bang,
        end: afterText,
        text: footnote,
      );
      for (var after = opener.node.next; after != null;) {
        final next = after.next;
        after.unlink();
        after = next;
      }
      opener.node.insertAfter(node);
      if (opener.image) {
        opener.node
          ..text = '!'
          ..end = opener.node.start + 1;
      } else {
        opener.node.unlink();
      }
      _removeDelimitersAbove(opener.previousDelimiter);
      return;
    }
    final (destination, title, end) = link;
    _pos = end;
    final node =
        InlineBuild(
            opener.image ? InlineKind.image : InlineKind.link,
            start: opener.node.start,
            end: end,
          )
          ..destination = destination
          ..title = title
          ..wrapBetween(opener.node, null);
    opener.node.unlink();
    _delimiters.process(opener.previousDelimiter);
    _brackets = opener.previous;
    if (!opener.image) _links++;
    assert(node.parent != null, 'the link stands among the leaf inlines');
  }

  /// An inline link's `(destination "title")` at [at]: the destination and
  /// title resolved, and where it ends.
  (String, String?, int)? _inlineLink(int at) {
    if (at >= text.length || text.codeUnitAt(at) != 0x28) return null;
    final start = InlineScanners.spaceNewline(text, at + 1);
    final destination = InlineScanners.linkDestination(text, start);
    if (destination == null) return null;
    var i = InlineScanners.spaceNewline(text, destination.$2);
    String? title;
    if (i != destination.$2) {
      final read = InlineScanners.linkTitle(text, i);
      if (read != null) {
        title = InlineScanners.unescape(read.$1);
        i = InlineScanners.spaceNewline(text, read.$2);
      }
    }
    if (i >= text.length || text.codeUnitAt(i) != 0x29) return null;
    return (InlineScanners.unescape(destination.$1), title, i + 1);
  }

  /// A full, collapsed or shortcut reference link after the link text
  /// that ends at [afterText] - 1.
  (String, String?, int)? _referenceLink(Bracket opener, int afterText) {
    final label = InlineScanners.linkLabel(text, afterText);
    String? raw;
    var end = afterText;
    if (label != null && label.$1.isNotEmpty) {
      raw = label.$1;
      end = label.$2;
    } else if (!opener.bracketAfter &&
        afterText - 1 - opener.textStart <= 999) {
      // Collapsed (`[text][]`) or shortcut (`[text]`): the text is the label.
      raw = text.substring(opener.textStart, afterText - 1);
      if (label != null) end = label.$2;
    }
    if (raw == null) return null;
    final reference = references[LinkReferences.normalize(raw)];
    if (reference == null) return null;
    return (reference.destination, reference.title, end);
  }

  /// The footnote label a link text `^label` names, when the note defines
  /// it.
  String? _footnote(String linkText) {
    if (!linkText.startsWith('^') || linkText.length < 2) return null;
    final label = linkText.substring(1);
    return footnotes.contains(LinkReferences.normalize(label)) ? label : null;
  }

  void _removeDelimitersAbove(Delimiter? bottom) {
    while (_delimiters.last != null && !identical(_delimiters.last, bottom)) {
      _delimiters.remove(_delimiters.last!);
    }
  }
}
