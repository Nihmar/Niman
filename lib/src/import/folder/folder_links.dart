/// The links between the files of an imported folder (#1295), rewritten to
/// the notes the files became.
///
/// A page is converted before the pages it links to are, so its links are
/// written under a placeholder ([pagePlaceholder]) and pointed at their
/// notes once every page is done ([resolvePageLinks]): which note, and —
/// when the link ends in `#id` — the heading the `id` lands in, which only
/// the target's conversion knows. A Markdown file's links are rewritten after
/// the pages ([markdownLinkRewriter]), the same way.
///
/// A destination is written as the book conversions write theirs
/// (`import/book/book_render.dart`): relative to the note it is in,
/// percent-encoded segment by segment, and `#Heading` for a heading, which
/// the app reads back by its slug. Plain Markdown links, whatever the
/// library's link type: that decides how a picture is embedded, not how one
/// note links another.
library;

import 'package:niman/src/core/percent.dart';
import 'package:niman/src/import/book/book_render.dart'
    show bookEncoded, bookHref;
import 'package:niman/src/import/folder/folder_plan.dart';
import 'package:path/path.dart' as p;

const String _scheme = 'niman-page:';

/// What each page's `id`s are headed by, by file index: null for a file that
/// was not converted.
typedef PageHeadings = List<Map<String, String>?>;

/// The placeholder destination of a link to the file [index]: its fragment,
/// and the link as the page wrote it ([href], which stays when the file is
/// not converted after all).
String pagePlaceholder(int index, String fragment, String href) =>
    '$_scheme$index:${Uri.encodeComponent(fragment)}:'
    '${Uri.encodeComponent(href)}';

/// A link written under [pagePlaceholder]: the index, the fragment and the
/// href, the last two percent-encoded.
final RegExp pagePlaceholderPattern = RegExp(
  '\\(<$_scheme(\\d+):([^:>]*):([^>]*)>\\)',
);

/// [text], the note of [here], with each placeholder replaced by the
/// destination of the note it stands for. A link to a page that was not
/// converted after all ([headings] has none for it) is written back as the
/// page wrote it.
String resolvePageLinks(
  String text, {
  required FolderPlan plan,
  required FolderEntry here,
  required PageHeadings headings,
}) => text.replaceAllMapped(pagePlaceholderPattern, (match) {
  final target = plan.entries[int.parse(match[1]!)];
  if (target.isPage && headings[target.index] == null) {
    return '(<${percentDecoded(match[3]!)}>)';
  }
  return '(${destination(here, target, percentDecoded(match[2]!), headings)})';
});

/// A rewriter for the links of the Markdown file [here], for
/// `rewriteLinkDestinations`: a link to a page that was converted points at
/// its note; any other stays as it was written, which includes a link to
/// another Markdown file, whose place in the folder is the one it had.
String? Function(String href) markdownLinkRewriter(
  FolderPlan plan,
  FolderEntry here,
  PageHeadings headings,
) => (href) {
  final link = plan.resolve(here, href);
  if (link == null ||
      !link.entry.isPage ||
      headings[link.entry.index] == null) {
    return null;
  }
  return destination(here, link.entry, link.fragment, headings);
};

/// How the note of [here] writes a link to [target], whose `#[fragment]` is
/// the place in it the link names.
///
/// A page's fragment is an `id`: it becomes the heading the `id` is under,
/// and goes when the page has no such `id`. A Markdown file's is already a
/// heading's, and is written as it was.
String destination(
  FolderEntry here,
  FolderEntry target,
  String fragment,
  PageHeadings headings,
) {
  final String anchor;
  if (fragment.isEmpty) {
    anchor = '';
  } else if (target.isPage) {
    final heading = headings[target.index]?[fragment];
    anchor = heading == null ? '' : '#${bookEncoded(heading)}';
  } else {
    anchor = '#$fragment';
  }
  if (target.index == here.index) {
    return anchor.isEmpty ? bookHref(p.posix.basename(target.target)) : anchor;
  }
  return '${bookHref(target.target, from: here.targetFolder)}$anchor';
}
