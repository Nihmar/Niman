import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/preview/aspect_image.dart';

/// The inline syntax for `![[…]]` embeds in the preview: the note's own
/// link style for files inside the library. Images render inline; other
/// binaries and dead targets render as muted text. The element carries the
/// raw target and the display text (the `|alias` form).
final class EmbedInlineSyntax extends md.InlineSyntax {
  /// Creates the syntax.
  new() : super(r'!\[\[[^\[\]\n]*\]\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final raw = match.group(0)!;
    final ref = parseWikiRef(raw.substring(3, raw.length - 2));
    // `![[]]` / `![[|]]` / `![[#]]` carry nothing to resolve. This must
    // render as plain text, not `return false`: the package's tryMatch
    // swallows a false onMatch without advancing the position, which is an
    // infinite loop on the UI isolate (app freeze, 2026-09-12).
    if (ref.target.isEmpty && ref.heading == null && ref.alias == null) {
      parser.addNode(md.Text(raw));
      return true;
    }
    final display = ref.alias ?? ref.target;
    final element = md.Element.text('embed', display)
      ..attributes['target'] = ref.target
      ..attributes['alias'] = ref.alias ?? '';
    parser.addNode(element);
    return true;
  }
}

/// Renders an `![[…]]` embed: an image target renders inline (fit width), a
/// non-image target (epub, pdf, …) renders as muted path text. The caller
/// resolves the target to an absolute file via [onResolve] (async — the
/// index-backed fallback needs a query); the placeholder shows until the
/// resolution lands, and on failure.
final class EmbedBuilder extends MarkdownElementBuilder {
  /// Creates a builder resolving embeds via [onResolve].
  new({required this.onResolve});

  /// Resolves an embed target to an absolute file path, or null.
  final Future<String?> Function(String target) onResolve;

  /// Image extensions an embed renders inline.
  static final RegExp _imageExt = RegExp(
    r'\.(png|jpe?g|gif|webp|bmp)$',
    caseSensitive: false,
  );

  /// Embeds are block-level (the package drops a paragraph whose only
  /// child is a single widget — a bare `![[img.png]]` line vanished).
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final target = element.attributes['target'] ?? element.textContent;
    final alias = element.attributes['alias'] ?? '';
    final display = alias.isNotEmpty ? alias : (element.textContent);
    return _EmbedView(target: target, display: display, onResolve: onResolve);
  }
}

/// The stateful embed body: resolves once, then renders the image inline
/// or the muted placeholder (binary, missing, or failed decode).
final class _EmbedView extends StatefulWidget {
  const new({
    required this.target,
    required this.display,
    required this.onResolve,
  });

  final String target;
  final String display;
  final Future<String?> Function(String target) onResolve;

  @override
  State<_EmbedView> createState() => _EmbedViewState();
}

final class _EmbedViewState extends State<_EmbedView> {
  String? _path;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    String? path;
    try {
      path = await widget.onResolve(widget.target);
    } on Object {
      path = null;
    }
    if (mounted && path != _path) setState(() => _path = path);
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;
    if (path == null || !EmbedBuilder._imageExt.hasMatch(widget.target)) {
      return _placeholder(context);
    }
    return AspectImage(
      provider: FileImage(File(path)),
      fit: BoxFit.fitWidth,
      errorBuilder: (context, error, stack) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      '![[${widget.display}]]',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      softWrap: true,
    );
  }
}

/// The inline syntax for `[[…]]` wikilinks in the preview (T-M3-07).
///
/// The pattern mirrors the editor tokenizer (`[^\[\]\n]*` inside, no nested
/// brackets); `![[…]]` embeds are left untouched (negative lookbehind), so
/// only real wikilinks become clickable. The element carries the parsed
/// pieces so the builder can render the display text and hand the target to
/// the caller.
final class WikilinkInlineSyntax extends md.InlineSyntax {
  /// Creates the syntax.
  new() : super(r'(?<!!)\[\[[^\[\]\n]*\]\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final raw = match.group(0)!;
    final ref = parseWikiRef(raw.substring(2, raw.length - 2));
    // `[[]]` / `[[|]]` / `[[#]]` carry nothing to show or resolve. This
    // must render as plain text, not `return false`: the package's
    // tryMatch swallows a false onMatch without advancing the position,
    // which is an infinite loop on the UI isolate (app freeze, 2026-09-12).
    if (ref.target.isEmpty && ref.heading == null && ref.alias == null) {
      parser.addNode(md.Text(raw));
      return true;
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
  new({required this.onWikiRef, required this.recognizers});

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
