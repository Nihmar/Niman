/// The links of an imported page (#1293) that point into the page itself.
///
/// A page's `#id` names an element; a note has headings. The converter
/// writes such a link under a placeholder ([anchorTarget]), because the
/// line of each `id` is known only once the page is converted;
/// [resolveAnchorLinks] then points each one at the heading it lands in:
/// the one on its line, else the last one before it, else the note's own
/// title. An `id` the page does not have stays as it was written.
///
/// The destination is written as the EPUB conversion writes its own: the
/// heading's text, percent-encoded (`#The%20Storm`), which the app reads
/// back by the heading's slug.
library;

import 'package:niman/src/core/percent.dart';

/// The placeholder destination of a link to the page's own element [id].
String anchorTarget(String id) => '$_scheme${Uri.encodeComponent(id)}';

const String _scheme = 'niman-anchor:';

/// A link written under [anchorTarget]: `(<niman-anchor:id>)`, the id
/// percent-encoded in group 1.
final RegExp anchorPlaceholder = RegExp('\\(<$_scheme([^>]*)>\\)');
final RegExp _heading = RegExp(r'^#{1,6}[ \t]+(.+?)(?:[ \t]+#+)?[ \t]*$');
final RegExp _fence = RegExp(r'^\s*(```|~~~)');

/// [markdown] with each placeholder destination replaced by the heading it
/// lands in; [anchors] says on which line of [markdown] each `id` is, and
/// [title] is the note's own heading, written as it stands in the note.
String resolveAnchorLinks(
  String markdown,
  Map<String, int> anchors, {
  required String title,
}) {
  if (!markdown.contains(_scheme)) return markdown;
  final headings = markdownHeadings(markdown.split('\n'));
  return markdown.replaceAllMapped(anchorPlaceholder, (match) {
    final id = percentDecoded(match[1]!);
    final line = anchors[id];
    if (line == null) return '(#${_encoded(id)})';
    return '(#${_encoded(headingAtOrBefore(headings, line) ?? title)})';
  });
}

/// A heading of a text: the line it is on and its words.
typedef MarkdownHeading = ({int line, String text});

/// The headings of [lines] with their lines, in order, those inside a code
/// fence left out.
List<MarkdownHeading> markdownHeadings(List<String> lines) {
  final found = <MarkdownHeading>[];
  var fenced = false;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_fence.hasMatch(line)) {
      fenced = !fenced;
    } else if (!fenced) {
      final match = _heading.firstMatch(line);
      if (match != null) found.add((line: i, text: match[1]!.trim()));
    }
  }
  return found;
}

/// The text of the last of [headings] at or before [line], or null.
String? headingAtOrBefore(List<MarkdownHeading> headings, int line) =>
    headingBefore(headings, line)?.text;

/// The last of [headings] at or before [line], or null.
MarkdownHeading? headingBefore(List<MarkdownHeading> headings, int line) {
  var low = 0;
  var high = headings.length;
  while (low < high) {
    final middle = (low + high) ~/ 2;
    if (headings[middle].line <= line) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  return low == 0 ? null : headings[low - 1];
}

/// [text] as a destination: everything but letters, digits and `-_.!~*'`
/// escaped, the parentheses too, which a destination written bare would
/// end on.
String _encoded(String text) =>
    Uri.encodeComponent(text).replaceAll('(', '%28').replaceAll(')', '%29');
