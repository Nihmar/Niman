/// The text a file dropped from the tree on an open note writes (#704): a
/// link to it, in the library's link format, as *Insert link* and the
/// wikilink suggester write one.
///
/// A picture or an audio file is embedded, as one added from the editor
/// is — the read view draws it in place; anything else, a note, a PDF, a
/// book, is linked.
library;

import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/links/rewrite.dart' show hrefFrom;
import 'package:niman/src/markdown/render/embed_view.dart';
import 'package:niman/src/ui/kinds/audio_parser.dart';
import 'package:path/path.dart' as p;

/// The link to the library file [path] written into the note at [note]
/// (both library-relative): a wikilink to the shortest target that names
/// it alone ([wikiTarget]), or a Markdown link relative to the note.
Future<String> droppedLink({
  required String path,
  required String note,
  required LinkType linkType,
  required Future<String> Function(String path) wikiTarget,
}) async {
  final embed = droppedEmbeds(path);
  if (linkType == LinkType.markdown) {
    final label = path.toLowerCase().endsWith('.md')
        ? p.basenameWithoutExtension(path)
        : p.basename(path);
    final href = hrefFrom(path, note: note);
    return embed ? '![$label]($href)' : '[$label]($href)';
  }
  final target = await wikiTarget(path);
  return embed ? '![[$target]]' : '[[$target]]';
}

/// Whether a drop of [path] embeds the file rather than linking it: a
/// picture the read view draws, or an audio file it plays.
bool droppedEmbeds(String path) =>
    EmbedView.imageExtensions.hasMatch(path) ||
    audioExtensions.contains(p.extension(path).toLowerCase());
