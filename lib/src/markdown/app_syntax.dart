/// The app's own inline constructs, by the rules the app has always read
/// them with: display math, inline math, wikilinks and embeds, tags
/// (`docs/dev/block-tree.md`, phase 4).
///
/// Our inline parser asks for one where a `$`, a `[[`, a `![[` or a `#`
/// stands ([AppSyntax.at]), in this order, which is the priority: `$$`
/// before `$`, or the opening pair would be an empty formula. A code span,
/// an autolink or raw HTML the parser read first holds what looks like one
/// — so the emphasis algorithm never reads a `_` inside a formula (7 530
/// `_` runs in one note, 17 of them emphasis).
///
/// They were a masker's once: the constructs set aside before
/// `package:markdown` read a block, put back after.
library;

import 'package:niman/src/editor/math_rule.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/extension_span.dart';

/// The app's inline constructs.
abstract final class AppSyntax {
  /// The app's own construct that starts exactly at [at] of [text] —
  /// display math, inline math, a wikilink or an embed, a tag, in that
  /// order — or null.
  static ExtensionSpan? at(String text, int at) =>
      _displayMath(text, at) ??
      _inlineMath(text, at) ??
      _wikiLink(text, at) ??
      _tag(text, at);

  /// `$$…$$` inside a block.
  ///
  /// The block scanner lifts a display block into a block of its own, so this
  /// catches the one that shares its line with prose. It runs before the single
  /// `$` rule because otherwise the opening pair would be read as an empty
  /// inline span and the tex would be read as prose.
  static ExtensionSpan? _displayMath(String text, int at) {
    if (at + 1 >= text.length) return null;
    if (text.codeUnitAt(at) != 0x24 || text.codeUnitAt(at + 1) != 0x24) {
      return null;
    }
    final close = text.indexOf(r'$$', at + 2);
    if (close < 0) return null;
    return ExtensionSpan(
      kind: ExtensionKind.displayMath,
      start: at,
      end: close + 2,
      text: text.substring(at, close + 2),
    );
  }

  /// `$…$`, by the app's own predicate.
  static ExtensionSpan? _inlineMath(String text, int at) {
    final end = inlineMathAt(text, at);
    if (end == null) return null;
    return ExtensionSpan(
      kind: ExtensionKind.inlineMath,
      start: at,
      end: end,
      text: text.substring(at, end),
    );
  }

  /// `[[…]]` and `![[…]]`, by the single parse rule the indexer, the editor's
  /// Ctrl+click and the preview all share.
  static ExtensionSpan? _wikiLink(String text, int at) {
    final embed = text.codeUnitAt(at) == 0x21;
    final open = embed ? at + 1 : at;
    if (open + 1 >= text.length) return null;
    if (text.codeUnitAt(open) != 0x5B || text.codeUnitAt(open + 1) != 0x5B) {
      return null;
    }
    if (at > 0 && text.codeUnitAt(at - 1) == 0x5C) return null; // escaped
    final close = _wikiClose(text, open + 2);
    if (close < 0) return null;
    final inner = text.substring(open + 2, close);
    final ref = parseWikiRef(inner);
    // `[[]]`, `[[|]]` and `[[#]]` carry nothing to show or resolve, so they are
    // not links — the same rule `links/parser.dart` applies.
    if (ref.target.isEmpty && ref.heading == null && ref.alias == null) {
      return null;
    }
    return ExtensionSpan(
      kind: embed ? ExtensionKind.embed : ExtensionKind.wikilink,
      start: at,
      end: close + 2,
      text: text.substring(at, close + 2),
    );
  }

  /// The `]]` that closes a wikilink opened at [from], or -1.
  ///
  /// Brackets may not nest: the first `]`/`[` inside means this is not a
  /// wikilink, which is the rule the tokenizer has always used.
  static int _wikiClose(String text, int from) {
    for (var at = from; at < text.length; at++) {
      final char = text.codeUnitAt(at);
      if (char == 0x5B) return -1;
      if (char == 0x5D) {
        if (at + 1 < text.length && text.codeUnitAt(at + 1) == 0x5D) return at;
        return -1;
      }
      if (char == 0x0A) return -1;
    }
    return -1;
  }

  /// `#tag`, as the index and the tag panel read it.
  ///
  /// A tag's characters are unicode letters and digits plus the `_`, `/` and
  /// `-` it has always allowed — the class the editor's own `#tag` pattern
  /// scans — so `#città` and `#идея` are one tag each, and the frontmatter's
  /// YAML, which keeps the whole word, agrees with them.
  static ExtensionSpan? _tag(String text, int at) {
    if (text.codeUnitAt(at) != 0x23) return null;
    // A tag is not preceded by a word character: `a#b` is prose.
    if (at > 0 && _wordBefore(text, at)) return null;
    if (at > 0 && text.codeUnitAt(at - 1) == 0x5C) return null; // escaped
    final body = _tagBody.matchAsPrefix(text, at + 1);
    if (body == null) return null;
    return ExtensionSpan(
      kind: ExtensionKind.tag,
      start: at,
      end: body.end,
      text: text.substring(at, body.end),
    );
  }

  /// Whether the character that ends just before [at] is a word character.
  ///
  /// The character is asked, not its last code unit: a letter outside the BMP
  /// is one character in two units, and the surrogate alone is not a letter.
  static bool _wordBefore(String text, int at) {
    var start = at - 1;
    final unit = text.codeUnitAt(start);
    if (start > 0 && unit >= 0xDC00 && unit <= 0xDFFF) start--;
    return _word.hasMatch(text.substring(start, at));
  }

  /// Whether [text] has a `#` a tag could start at — one followed by a
  /// tag's character — so a reader after tags may skip parsing text that
  /// has none: a heading's own hashes are followed by a space (#581).
  static bool mayHoldTag(String text) => _tagStart.hasMatch(text);

  /// The characters a tag is made of: a unicode letter or digit, or `_`, `/`
  /// or `-`. The editor's `#tag` pattern is the same class.
  static const String _tagChars = r'[\p{L}\p{N}_/-]';

  static final RegExp _tagBody = RegExp('$_tagChars+', unicode: true);

  static final RegExp _tagStart = RegExp('#$_tagChars', unicode: true);

  /// Whether a character is a word character: a letter, a digit or `_`.
  static final RegExp _word = RegExp(r'^[\p{L}\p{N}_]$', unicode: true);
}
