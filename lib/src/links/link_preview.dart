/// What a link points at, read for a preview card (#846): the target note's
/// text, found by the very rules following the link uses, read off the UI
/// isolate once per revision of it.
///
/// The card never navigates and never writes: it resolves the hovered link
/// the way a tap would ([LinkSource.resolveWiki], [LinkSource.resolveMarkdown],
/// and a wikilink's label-first reading), asks the library for the note's
/// text, and shows it. A link that names nothing, several notes, a file that
/// is not a note, or the note it is written in has no card.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:niman/src/links/dead_links.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/preview_reader.dart';
import 'package:niman/src/links/resolver.dart';

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

/// The beginning of a note, as a preview shows it.
final class NotePreviewText {
  /// A note's [text] — all of it, or the first [PreviewLimits.bytes] bytes of
  /// it when [truncated].
  const new({required this.text, required this.truncated});

  /// The text, its line endings `\n`.
  final String text;

  /// Whether the note goes on past [text].
  final bool truncated;
}

/// How much of a note a preview reads.
abstract final class PreviewLimits {
  /// The bytes read off the front of a note: a card shows a screenful and the
  /// heading or block it was asked for, and a novel-length note is not read
  /// whole to show them. A heading past this is not found (the card shows the
  /// top).
  static const int bytes = 256 * 1024;

  /// How many previews are kept, by note and revision.
  static const int kept = 16;
}

/// What a preview card shows.
final class LinkPreview {
  /// The preview of the note at [path].
  const new({
    required this.path,
    required this.text,
    required this.truncated,
    this.anchor,
  });

  /// The note's library-relative path.
  final String path;

  /// The note's name, `.md` dropped: the card's title.
  String get title {
    final name = path.split('/').last;
    return name.toLowerCase().endsWith('.md')
        ? name.substring(0, name.length - 3)
        : name;
  }

  /// The beginning of the note.
  final String text;

  /// Whether the note goes on past [text].
  final bool truncated;

  /// The heading path (`A#B`) or block id (`^id`) the link names, for the card
  /// to scroll to; null for the note as a whole.
  final String? anchor;
}

/// The preview of what [link] points at, written in the note at
/// library-relative [from], or null when it points at nothing a card can show:
/// the link is resolved by [source], the note's beginning read by [previews].
Future<LinkPreview?> previewOfLink(
  LinkSource source,
  PreviewSource previews,
  PreviewLink link, {
  required String? from,
}) async {
  final (path, anchor) = await _target(source, link, from);
  if (path == null) return null;
  // A card shows a note: a picture, a book or any other file is not text.
  if (!path.toLowerCase().endsWith('.md')) return null;
  // The note the link is written in is the page already on screen.
  if (path == from) return null;
  final read = await previews.previewText(path);
  if (read == null) return null;
  return LinkPreview(
    path: path,
    text: read.text,
    truncated: read.truncated,
    anchor: anchor,
  );
}

/// The one note [link] names — its library-relative path and the `#anchor` —
/// or `(null, null)`.
Future<(String?, String?)> _target(
  LinkSource source,
  PreviewLink link,
  String? from,
) async {
  if (!link.wiki) {
    final resolved = await source.resolveMarkdown(link.text, from: from);
    return resolved is ResolvedNote
        ? (resolved.note.path, resolved.heading)
        : (null, null);
  }
  final ref = parseWikiRef(link.text);
  if (ref.target.isEmpty) return (null, null);
  var resolved = await source.resolveWiki(ref.target, from: from);
  var anchor = ref.fragment;
  if (resolved is! ResolvedNote) {
    // A label-first link, `[[a label|filename#heading]]`, is the note named
    // by its alias when the first part is none — as following reads it.
    final aliased = aliasTarget(ref.alias);
    if (aliased != null) {
      final swapped = await source.resolveWiki(aliased, from: from);
      if (swapped is ResolvedNote) {
        resolved = swapped;
        final hash = ref.alias!.indexOf('#');
        final fragment = hash == -1
            ? ''
            : ref.alias!.substring(hash + 1).trim();
        anchor = fragment.isEmpty ? null : fragment;
      }
    }
  }
  return resolved is ResolvedNote
      ? (resolved.note.path, anchor ?? resolved.heading)
      : (null, null);
}
