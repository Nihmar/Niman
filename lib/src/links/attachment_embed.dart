/// The embed link of a file copied into the library's attachments folder
/// (issue #56): images and captured pictures share one syntax, chosen by
/// the library's link setting — a wikilink embed by default, a Markdown
/// image link when the library writes Markdown links.
///
/// A Markdown link is written from the note's folder (#1282), as a dropped
/// file's is (#704): other Markdown tools, the Markdown export and a
/// browser opening an HTML export all read an href from there, and a path
/// from the library root breaks for every note outside it. Niman reads
/// both, the root first (`resolveEmbedPath`).
library;

import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/links/rewrite.dart' show hrefFrom;

/// The note text embedding the attachment at library-relative
/// [relativePath] in the note at library-relative [note]:
/// `![[assets/a1b2.png]]` for wikilink libraries, `![label](../assets/a1b2.png)`
/// for Markdown ones, from a note one folder down.
String attachmentEmbed({
  required String relativePath,
  required String label,
  required LinkType linkType,
  required String note,
}) {
  if (linkType == LinkType.markdown) {
    return '![$label](${hrefFrom(relativePath, note: note)})';
  }
  return '![[$relativePath]]';
}
