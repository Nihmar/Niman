/// Which formats are on at the caret, for the toolbar's pressed state (#246).
///
/// The toolbar is a property *of the caret*, not of the note: `**bold**` is lit
/// while the caret is inside the bold run and dark one word later. So what the
/// answer is read from is what the reveal already reads — the line's own
/// tokens, which the styler produced for the colours — and not a second
/// reading of the text.
///
/// Two granularities, as the reveal has two:
///
/// * a **structural** mark — a heading's hashes, a list's marker, a quote's
///   `>`, a fence — is the shape of the *line*, so its button is lit wherever
///   the caret is on that line;
/// * an **inline** run — bold, italic, code, a link — is the shape of the text
///   the caret is *in*, so its button is lit while the caret's run of
///   non-whitespace overlaps it. Overlap and not containment, which is the one
///   place this differs from the reveal: a phrase in bold is one run of many
///   words, and the button has to say "you are writing in bold" while the caret
///   is in the middle of it, whereas the reveal only shows the markers of the
///   word being edited.
///
/// What is *not* reported, and why: `image`, `indent`, `outdent` and `tools`
/// are actions rather than states, and the legacy WYSIWYG's own answer keeps
/// them dark too (`QuillEditorCommands.isActive`). `underline` and
/// `superscript` are the `<u>`/`<sup>` tags, which the engine reads as runs of
/// their own and lights like any other inline format.
library;

import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/toolbar_item.dart';

/// The formats on at a caret whose line reads [text], has [tokens], and whose
/// run of non-whitespace is [run].
///
/// [run] is the caret's own run on that line, in the line's coordinates — the
/// same `(start, end)` the reveal compares a marker against (`runAround` in
/// `caret_motion.dart`).
Set<ToolbarItem> activeFormatsOf({
  required String text,
  required List<Token> tokens,
  required (int, int) run,
}) {
  final active = <ToolbarItem>{};
  for (final token in tokens) {
    switch (token.kind) {
      // The line's shape.
      case TokenKind.headingMarker:
        active.add(ToolbarItem.heading);
      case TokenKind.listMarker:
        active.add(
          _orderedMarker(text, token)
              ? ToolbarItem.orderedList
              : ToolbarItem.list,
        );
      case TokenKind.taskBox:
        active.add(ToolbarItem.list);
      case TokenKind.blockquote:
        active.add(ToolbarItem.quote);
      case TokenKind.codeFence || TokenKind.codeBlock || TokenKind.codeLanguage:
        active.add(ToolbarItem.code);
      // The caret's own text.
      case TokenKind.bold || TokenKind.italic || TokenKind.strike:
      case TokenKind.underline || TokenKind.superscript:
      case TokenKind.codeInline:
      case TokenKind.link || TokenKind.wikilink:
        if (token.start < run.$2 && token.end > run.$1) {
          active.add(_itemOf(token.kind));
        }
      case TokenKind.plain:
      case TokenKind.image:
      case TokenKind.horizontalRule:
      case TokenKind.mathInline:
      case TokenKind.mathBlock:
      case TokenKind.tag:
      case TokenKind.frontmatter:
      // The toolbar has no subscript.
      case TokenKind.subscript:
        break;
    }
    // The constructs around the caret's text are on too: in `<u>**x**</u>`
    // the stretch is one bold token, and the underline is its outer one.
    if (token.start < run.$2 && token.end > run.$1) {
      for (final kind in token.outer) {
        if (_inline.contains(kind)) active.add(_itemOf(kind));
      }
    }
  }
  return active;
}

/// The inline kinds a toolbar button stands for.
const Set<TokenKind> _inline = <TokenKind>{
  TokenKind.bold,
  TokenKind.italic,
  TokenKind.strike,
  TokenKind.underline,
  TokenKind.superscript,
  TokenKind.codeInline,
  TokenKind.link,
  TokenKind.wikilink,
};

/// The toolbar button an inline token kind belongs to.
ToolbarItem _itemOf(TokenKind kind) => switch (kind) {
  TokenKind.italic => ToolbarItem.italic,
  TokenKind.strike => ToolbarItem.strikethrough,
  TokenKind.underline => ToolbarItem.underline,
  TokenKind.superscript => ToolbarItem.superscript,
  TokenKind.codeInline => ToolbarItem.code,
  TokenKind.link || TokenKind.wikilink => ToolbarItem.link,
  // Bold is the only one left of the kinds this is called with, and naming it
  // as the fallback is what keeps the mapping total.
  _ => ToolbarItem.bold,
};

/// Whether a list marker marks an ordered item: `1.` and `1)` do, `-` does not.
bool _orderedMarker(String text, Token token) {
  for (var at = token.start; at < token.end && at < text.length; at++) {
    final char = text.codeUnitAt(at);
    if (char == 0x20 || char == 0x09) continue;
    return char >= 0x30 && char <= 0x39;
  }
  return false;
}
