/// Display styles for the source editor's highlighting (M2a E7).
///
/// [tokenStyle] maps a [TokenKind] to a [TextStyle] *override* for the row
/// painter; [TokenKind.plain] maps to null (the base row style shows). The
/// overrides change only color / weight / decoration / font-style — never
/// font size or line height — so a row keeps its constant height (the
/// virtualized view lays out every row at a fixed pixel height). Colors are
/// fixed (not theme-aware) for now; a themed palette is a follow-up.
library;

import 'package:copist/src/editor/highlighting.dart';
import 'package:flutter/widgets.dart';

/// Grey used for markers, list markers, rules, frontmatter and fence lines.
const Color _dim = Color(0xFF7A7A7A);
const Color _code = Color(0xFF0E7C7B);
const Color _codeMuted = Color(0xFF5C6B73);
const Color _link = Color(0xFF1A5FB4);
const Color _image = Color(0xFF7B1FA2);
const Color _wikilink = Color(0xFF6A3AB2);
const Color _task = Color(0xFF2E7D32);
const Color _quote = Color(0xFF6B7280);
const Color _math = Color(0xFFAD1457);
const Color _tag = Color(0xFF00838F);

/// The style of the heading *text* — the region after a `#…` marker, which
/// the tokenizer leaves unmarked: bold, at the base row size.
const TextStyle headingStyle = TextStyle(fontWeight: FontWeight.bold);

/// The [TextStyle] override for each [TokenKind] (null for plain).
const Map<TokenKind, TextStyle?> _styles = {
  TokenKind.plain: null,
  TokenKind.headingMarker: TextStyle(color: _dim),
  TokenKind.bold: TextStyle(fontWeight: FontWeight.bold),
  TokenKind.italic: TextStyle(fontStyle: FontStyle.italic),
  TokenKind.strike: TextStyle(decoration: TextDecoration.lineThrough),
  TokenKind.codeInline: TextStyle(color: _code),
  TokenKind.codeFence: TextStyle(color: _codeMuted),
  TokenKind.codeLanguage: TextStyle(
    color: _codeMuted,
    fontStyle: FontStyle.italic,
  ),
  TokenKind.link: TextStyle(color: _link, decoration: TextDecoration.underline),
  TokenKind.image: TextStyle(color: _image),
  TokenKind.wikilink: TextStyle(color: _wikilink),
  TokenKind.listMarker: TextStyle(color: _dim),
  TokenKind.taskBox: TextStyle(color: _task),
  TokenKind.blockquote: TextStyle(color: _quote, fontStyle: FontStyle.italic),
  TokenKind.horizontalRule: TextStyle(color: _dim),
  TokenKind.mathInline: TextStyle(color: _math),
  TokenKind.mathBlock: TextStyle(color: _math, fontStyle: FontStyle.italic),
  TokenKind.tag: TextStyle(color: _tag),
  TokenKind.frontmatter: TextStyle(color: _dim),
};

/// The [TextStyle] override for a [kind], or null for [TokenKind.plain] (use
/// the base row style).
TextStyle? tokenStyle(TokenKind kind) => _styles[kind];
