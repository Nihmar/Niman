/// The words a task's link is shown by, as a chip in the list and as plain
/// text everywhere else (#1152).
///
/// One rule for both, so a task reads the same on a row, in a notification,
/// on the Home tile and in the widget: the alias when one is written; else
/// the note's name, and the heading or block after it (`Repairs › Boiler`).
/// Plain text never shows `[[…]]`: on a lock screen it is syntax with
/// nothing to explain it.
library;

import 'package:niman/src/links/link_path.dart';
import 'package:niman/src/links/link_query.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/task_link.dart';

/// Between a note's name and the heading in a link's label.
const String taskLinkLevels = ' › ';

/// The label of [link] with the note called [name]: its alias, else [name]
/// and the anchor's heading levels or block id after it.
String taskLinkLabel(TaskLink link, String name) {
  final anchor = headingPathOf(link.anchor).join(taskLinkLevels);
  return link.alias ?? (anchor.isEmpty ? name : '$name$taskLinkLevels$anchor');
}

/// The note [link] names, as written: the path of a Markdown link, the
/// target of a wikilink.
String writtenNoteOf(TaskLink link) {
  if (link.link is MarkdownLink) {
    return LinkPaths.markdownTarget(link.target)?.path ?? link.target;
  }
  return link.target;
}

/// The name of the note at [path], its folder and its `.md` taken off.
String noteNameOf(String path) {
  final name = path.substring(path.lastIndexOf('/') + 1);
  return name.toLowerCase().endsWith('.md')
      ? name.substring(0, name.length - 3)
      : name;
}

/// [description] as plain text: [taskDisplayText] (or, with [markers],
/// [withoutKeyValueTags], which keeps `+project`, `@context` and `#tag`),
/// each link that names a note shown by its label instead of its syntax.
///
/// The tags are taken off first, over the text with its links whole, so an
/// alias that reads like a tag (`[[Plan|my +work]]`) is shown as written.
String taskPlainText(String description, {bool markers = false}) {
  final prose = markers
      ? withoutKeyValueTags(description)
      : taskDisplayText(description);
  if (!prose.contains('[')) return prose;
  final links = parseLinks(prose, includeEmbeds: true).toList();
  var out = prose;
  for (final link in links.reversed) {
    final target = linkTargetOf(link);
    if (target == null) continue;
    final task = TaskLink(
      link: link,
      result: UnresolvedNote(target: target),
    );
    out = out.replaceRange(
      link.start,
      link.end,
      taskLinkLabel(task, noteNameOf(writtenNoteOf(task))),
    );
  }
  return out;
}
