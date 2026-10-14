/// The question a link asks the resolver: what it targets, as the index
/// asks it when it writes a note's edges and as a move asks it to know which
/// links followed a file that moved (#919).
///
/// One function for both, so the links a move rewrites are the links the
/// index drew an edge for.
library;

import 'package:niman/src/links/link_path.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';

/// The target text of [link] to resolve by, or null for a link that never
/// resolves to an indexed note (external URL, anchor, no extension).
String? linkTargetOf(ParsedLink link) => switch (link) {
  final WikiLink w when w.ref.target.isNotEmpty => w.ref.target,
  final MarkdownLink m
      when !LinkPaths.hasScheme(m.href) &&
          !m.href.trim().startsWith('#') &&
          LinkPaths.markdownTarget(m.href) != null =>
    m.href,
  _ => null,
};

/// [link] as the resolver is asked about it, written in the note at
/// library-relative [from] (a `..` walks from its folder, #491), or null
/// for a link that never resolves.
LinkQuery? linkQueryOf(ParsedLink link, String from) {
  final target = linkTargetOf(link);
  return target == null
      ? null
      : (target: target, from: from, markdown: link is MarkdownLink);
}
