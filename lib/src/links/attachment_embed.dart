/// The embed link of a file copied into the library's attachments folder
/// (issue #56): images and voice-note clips share one syntax, chosen by
/// the library's link setting — a wikilink embed by default, a Markdown
/// image link when the library writes Markdown links.
library;

import 'package:niman/src/core/settings/library_settings.dart' show LinkType;

/// The note text embedding the attachment at library-relative
/// [relativePath]: `![[assets/a1b2.wav]]` for wikilink libraries,
/// `![label](assets/a1b2.png)` for Markdown ones.
String attachmentEmbed({
  required String relativePath,
  required String label,
  required LinkType linkType,
}) {
  if (linkType == LinkType.markdown) return '![$label]($relativePath)';
  return '![[$relativePath]]';
}
