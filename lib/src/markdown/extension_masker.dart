/// Sets a block's own constructs aside before the Markdown package sees it.
///
/// The package knows CommonMark and GFM. It has never heard of `$…$`,
/// `[[wikilinks]]` or `#tags`, and — worse than not knowing them — it will read
/// their contents as whatever CommonMark construct the characters resemble. The
/// corpus says how much that matters: `Geometria 1.md` has **7 530 `_`
/// delimiter runs, of which only 17 are real emphasis** once its `$…$` is
/// masked. That is a 443× over-read of the emphasis algorithm, and the emphasis
/// inside a formula would be wrong in both directions.
///
/// So the block is masked first, and the order is the correctness argument:
///
/// 1. **code spans**, because a `$` or a `[[` inside backticks is neither;
/// 2. **display math** (`$$…$$` within the block), before single `$`, or the
///    opening pair would be read as an empty inline span;
/// 3. **inline math** (`$…$`), by the app's own rule — `math_rule.dart`, the
///    same predicate the editor highlight uses, so the two cannot drift;
/// 4. **wikilinks and embeds**, by `links/parser.dart`'s single parse rule;
/// 5. **tags**.
///
/// Each span is replaced by a run of placeholders **of the same length**, so
/// every offset in the masked text is the offset it was in the source. That is
/// what lets the block layer parse masked text and put the answer back without
/// a translation table — and it is the reason this is masking rather than
/// removal.
library;

import 'package:niman/src/editor/math_rule.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/extension_span.dart';
import 'package:niman/src/markdown/masked_block.dart';

/// Masks the constructs the Markdown package must not interpret.
final class ExtensionMasker {
  /// Creates a masker.
  const new();

  /// The character a masked span is replaced by.
  ///
  /// A private-use code point, so it cannot collide with anything a note
  /// contains and is plain text to the parser: no Markdown construct is built
  /// from it, and a run of them reads as one word.
  static const String placeholder = '\uE000';

  /// Masks [text], returning what to parse and what was set aside.
  MaskedBlock mask(String text) {
    final spans = <ExtensionSpan>[];
    var at = 0;
    while (at < text.length) {
      final span = _spanAt(text, at);
      if (span == null) {
        at++;
        continue;
      }
      spans.add(span);
      at = span.end;
    }
    if (spans.isEmpty) return MaskedBlock(text: text, spans: spans);
    return MaskedBlock(text: _maskedText(text, spans), spans: spans);
  }

  /// The span that starts exactly at [at], or null.
  ///
  /// The order is the priority order: the first that matches wins, which is why
  /// a code span hides everything inside it.
  ExtensionSpan? _spanAt(String text, int at) =>
      _codeSpan(text, at) ??
      _displayMath(text, at) ??
      _inlineMath(text, at) ??
      _wikiLink(text, at) ??
      _tag(text, at);

  /// A code span, by the CommonMark rule that a run of N backticks closes at
  /// the next run of exactly N.
  ExtensionSpan? _codeSpan(String text, int at) {
    if (text.codeUnitAt(at) != 0x60) return null;
    var run = 0;
    while (at + run < text.length && text.codeUnitAt(at + run) == 0x60) {
      run++;
    }
    var closing = at + run;
    while (closing < text.length) {
      if (text.codeUnitAt(closing) != 0x60) {
        closing++;
        continue;
      }
      var candidate = 0;
      while (closing + candidate < text.length &&
          text.codeUnitAt(closing + candidate) == 0x60) {
        candidate++;
      }
      if (candidate == run) {
        return ExtensionSpan(
          kind: ExtensionKind.codeSpan,
          start: at,
          end: closing + run,
          text: text.substring(at, closing + run),
        );
      }
      closing += candidate;
    }
    return null;
  }

  /// `$$…$$` inside a block.
  ///
  /// The block scanner lifts a display block into a block of its own, so this
  /// catches the one that shares its line with prose. It runs before the single
  /// `$` rule because otherwise the opening pair would be read as an empty
  /// inline span and the tex would be read as prose.
  ExtensionSpan? _displayMath(String text, int at) {
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
  ExtensionSpan? _inlineMath(String text, int at) {
    if (text.codeUnitAt(at) != 0x24) return null;
    final span = findInlineMath(text, at);
    if (span == null || span.$1 != at) return null;
    return ExtensionSpan(
      kind: ExtensionKind.inlineMath,
      start: at,
      end: span.$2,
      text: text.substring(at, span.$2),
    );
  }

  /// `[[…]]` and `![[…]]`, by the single parse rule the indexer, the editor's
  /// Ctrl+click and the preview all share.
  ExtensionSpan? _wikiLink(String text, int at) {
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
  ExtensionSpan? _tag(String text, int at) {
    if (text.codeUnitAt(at) != 0x23) return null;
    // A tag is not preceded by a word character: `a#b` is prose.
    if (at > 0 && _isWord(text.codeUnitAt(at - 1))) return null;
    if (at > 0 && text.codeUnitAt(at - 1) == 0x5C) return null; // escaped
    var end = at + 1;
    while (end < text.length && _isTagChar(text.codeUnitAt(end))) {
      end++;
    }
    if (end == at + 1) return null;
    return ExtensionSpan(
      kind: ExtensionKind.tag,
      start: at,
      end: end,
      text: text.substring(at, end),
    );
  }

  /// [text] with every span's characters replaced by placeholders.
  static String _maskedText(String text, List<ExtensionSpan> spans) {
    const placeholder = ExtensionMasker.placeholder;
    final buffer = StringBuffer();
    var at = 0;
    for (final span in spans) {
      if (span.start > at) buffer.write(text.substring(at, span.start));
      buffer.write(placeholder * span.length);
      at = span.end;
    }
    if (at < text.length) buffer.write(text.substring(at));
    return buffer.toString();
  }

  static bool _isWord(int char) =>
      (char >= 0x30 && char <= 0x39) ||
      (char >= 0x41 && char <= 0x5A) ||
      (char >= 0x61 && char <= 0x7A) ||
      char == 0x5F;

  static bool _isTagChar(int char) =>
      _isWord(char) || char == 0x2F || char == 0x2D;
}
