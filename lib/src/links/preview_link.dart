import 'package:flutter/foundation.dart' show immutable;

/// A link as the preview is asked about it: the text it was written with.
@immutable
final class PreviewLink {
  /// A wikilink whose inside (`target#heading|alias`) is [text].
  const new wiki(this.text) : wiki = true;

  /// A Markdown link whose destination is [text].
  const new markdown(this.text) : wiki = false;

  /// Whether it is a wikilink; else a Markdown link.
  final bool wiki;

  /// What is between a wikilink's brackets, or a Markdown link's parentheses.
  final String text;

  @override
  bool operator ==(Object other) =>
      other is PreviewLink && other.wiki == wiki && other.text == text;

  @override
  int get hashCode => Object.hash(wiki, text);
}
