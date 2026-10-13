/// Which of a note's links name nothing (#847): what the editor and the read
/// view draw muted, before the link is clicked.
///
/// Resolution happens against the library's index, in one batch for all of a
/// note's links ([LinkSource.deadAmong]), and never in the drawing: the
/// drawing only asks a [DeadLinks] — a set of the targets that resolved to
/// nothing — which is cheap to ask and cheap to compare. A link the set does
/// not know about (typed since the last resolution) is drawn live until the
/// next one says otherwise.
///
/// Dead is judged at the level of the note, as Obsidian does: a link to a
/// note that exists is live whether or not its `#heading` or `#^block` is
/// there.
library;

import 'package:flutter/foundation.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';

/// The targets of a note's links that resolve to nothing.
@immutable
final class DeadLinks {
  /// Creates the set: the wiki [wiki] targets and the Markdown [href]s that
  /// name nothing, each as written in the note.
  const new({this.wiki = const <String>{}, this.href = const <String>{}});

  /// No link is dead.
  static const DeadLinks none = DeadLinks();

  /// The wiki targets (`[[target#heading|alias]]`'s `target`, trimmed) that
  /// resolve to nothing.
  final Set<String> wiki;

  /// The Markdown hrefs (`[text](href)`'s `href`, trimmed) that name a file
  /// the library does not hold.
  final Set<String> href;

  /// Whether no link is dead.
  bool get isEmpty => wiki.isEmpty && href.isEmpty;

  /// Whether the wikilink [ref] is dead.
  ///
  /// A link with no target names the note it is in; a link whose target is
  /// not dead is live. A label-first link — `[[a label|filename]]`, which
  /// following reads as the note `filename` when `a label` is none — is dead
  /// only if the aliased part names nothing either.
  bool wikiIsDead(WikiRef ref) {
    if (wiki.isEmpty || ref.target.isEmpty || !wiki.contains(ref.target)) {
      return false;
    }
    final aliased = aliasTarget(ref.alias);
    return aliased == null || wiki.contains(aliased);
  }

  /// Whether the Markdown link to [destination] is dead.
  bool hrefIsDead(String destination) =>
      href.isNotEmpty && href.contains(normalizedHref(destination));

  @override
  bool operator ==(Object other) =>
      other is DeadLinks &&
      setEquals(other.wiki, wiki) &&
      setEquals(other.href, href);

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(wiki), href.length);
}

/// The part of a wikilink's [alias] that may be a note, as following a link
/// reads it: before a `#`, trimmed; null when there is nothing there.
String? aliasTarget(String? alias) {
  if (alias == null) return null;
  final hash = alias.indexOf('#');
  final target = (hash == -1 ? alias : alias.substring(0, hash)).trim();
  return target.isEmpty ? null : target;
}

/// A Markdown destination as the set keeps it: trimmed, and without the angle
/// brackets that may enclose it (`<a b.md>`).
String normalizedHref(String destination) {
  final trimmed = destination.trim();
  if (trimmed.length >= 2 && trimmed.startsWith('<') && trimmed.endsWith('>')) {
    return trimmed.substring(1, trimmed.length - 1).trim();
  }
  return trimmed;
}

/// The queries that decide whether [links] are dead, written in the note at
/// library-relative [from] (null when it is outside a library).
///
/// A wikilink asks for its target, and for the part of its alias that following
/// the link would try as one; a Markdown link asks for its href. Embeds are not
/// asked: they are shown, not followed. Each query is made once.
Set<LinkQuery> deadLinkQueries(Iterable<ParsedLink> links, String? from) {
  final out = <LinkQuery>{};
  for (final link in links) {
    switch (link) {
      case WikiLink(:final ref):
        if (ref.target.isNotEmpty) {
          out.add((target: ref.target, from: from, markdown: false));
          final aliased = aliasTarget(ref.alias);
          if (aliased != null) {
            out.add((target: aliased, from: from, markdown: false));
          }
        }
      case MarkdownLink(:final href):
        final written = normalizedHref(href);
        if (written.isNotEmpty) {
          out.add((target: written, from: from, markdown: true));
        }
    }
  }
  return out;
}

/// The [links] that name nothing in the library [source] reads, as one
/// batched resolution.
Future<DeadLinks> resolveDeadLinks(
  LinkSource source,
  Iterable<ParsedLink> links, {
  required String? from,
}) async {
  final queries = deadLinkQueries(links, from);
  if (queries.isEmpty) return DeadLinks.none;
  final dead = await source.deadAmong(queries);
  if (dead.isEmpty) return DeadLinks.none;
  return DeadLinks(
    wiki: {
      for (final query in dead)
        if (!query.markdown) query.target,
    },
    href: {
      for (final query in dead)
        if (query.markdown) query.target,
    },
  );
}
