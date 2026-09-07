import 'package:copist/src/links/parser.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

/// The inline syntax for `[[…]]` wikilinks in the preview (T-M3-07).
///
/// The pattern mirrors the editor tokenizer (`[^\[\]\n]*` inside, no nested
/// brackets); `![[…]]` embeds are left untouched (negative lookbehind), so
/// only real wikilinks become clickable. The element carries the parsed
/// pieces so the builder can render the display text and hand the target to
/// the caller.
final class WikilinkInlineSyntax extends md.InlineSyntax {
  /// Creates the syntax.
  WikilinkInlineSyntax() : super(r'(?<!!)\[\[[^\[\]\n]*\]\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final raw = match.group(0)!;
    final ref = parseWikiRef(raw.substring(2, raw.length - 2));
    // `[[]]` / `[[|]]` / `[[#]]` carry nothing to show or resolve.
    if (ref.target.isEmpty && ref.heading == null && ref.alias == null) {
      return false;
    }
    final display = ref.alias ?? ref.heading ?? ref.target;
    final element = md.Element.text('wikilink', display)
      ..attributes['target'] = ref.target
      ..attributes['heading'] = ref.heading ?? ''
      ..attributes['alias'] = ref.alias ?? '';
    parser.addNode(element);
    return true;
  }
}

/// Renders a wikilink element as a tap-able inline link (T-M3-07):
/// the display text with the link style, tapping reports the parsed ref.
final class WikilinkBuilder extends MarkdownElementBuilder {
  /// Creates a builder reporting [onWikiRef]; [recognizers] receives every
  /// gesture recognizer the preview must dispose.
  WikilinkBuilder({
    required this.onWikiRef,
    required this.recognizers,
  });

  /// Called with the parsed ref (and its display text) on tap.
  final void Function(WikiRef ref, String display) onWikiRef;

  /// The preview's recognizer registry (disposed with the preview).
  final List<GestureRecognizer> recognizers;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final target = element.attributes['target'] ?? '';
    final heading = element.attributes['heading'] ?? '';
    final alias = element.attributes['alias'] ?? '';
    final display = element.textContent;
    final recognizer = TapGestureRecognizer()
      ..onTap = () => onWikiRef(
        WikiRef(
          target: target,
          heading: heading.isEmpty ? null : heading,
          alias: alias.isEmpty ? null : alias,
        ),
        display,
      );
    recognizers.add(recognizer);
    final theme = Theme.of(context);
    final style = (parentStyle ?? preferredStyle ?? const TextStyle()).copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: theme.colorScheme.primary,
    );
    return Text.rich(
      TextSpan(text: display, style: style, recognizer: recognizer),
      softWrap: true,
    );
  }
}
