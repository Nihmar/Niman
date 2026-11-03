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
///
/// [label] is what the link reads as, when the file's name is not it: an
/// attachment stored under its content's hash keeps the name it was
/// pasted or dropped with (#1249, #1250). A wikilink takes it as its alias,
/// an embed never — `![[p.png|300]]` is a picture's width.
Future<String> droppedLink({
  required String path,
  required String note,
  required LinkType linkType,
  required Future<String> Function(String path) wikiTarget,
  String? label,
}) async {
  final embed = droppedEmbeds(path);
  if (linkType == LinkType.markdown) {
    final shown =
        label ??
        (path.toLowerCase().endsWith('.md')
            ? p.basenameWithoutExtension(path)
            : p.basename(path));
    final text = _escapeLabel(shown);
    final href = hrefFrom(path, note: note);
    return embed ? '![$text]($href)' : '[$text]($href)';
  }
  final target = await wikiTarget(path);
  if (embed) return '![[$target]]';
  final alias = label?.replaceAll(RegExp(r'[\[\]|]'), '');
  return alias == null || alias.isEmpty || alias == target
      ? '[[$target]]'
      : '[[$target|$alias]]';
}

/// [label] as a Markdown link's text: a bracket in it escaped, so it does
/// not end the text early.
String _escapeLabel(String label) =>
    label.replaceAllMapped(RegExp(r'[\[\]]'), (m) => '\\${m[0]}');

/// Whether a drop of [path] embeds the file rather than linking it: a
/// picture the read view draws, or an audio file it plays.
bool droppedEmbeds(String path) =>
    EmbedView.imageExtensions.hasMatch(path) ||
    audioExtensions.contains(p.extension(path).toLowerCase());
