/// The links and images of a Markdown text, rewritten where an import moved
/// what they point at: the Notion import's page ids stripped from every name
/// (#25), a folder's pages converted into notes (#1295).
///
/// Only the destination of a link is replaced, so its words stay as they
/// are. Fenced code and inline code hold no tokens, and a `](…)` in a sample
/// is not touched.
library;

import 'package:niman/src/editor/highlighting.dart';

/// [text] with the destination of each link and image replaced by what
/// [mapHref] answers for it; a destination it answers null for stays as it
/// was written.
///
/// [mapHref] is given the destination as the link writes it: without the
/// `<…>` around one that has spaces and without its title (`"note"`), both
/// of which come back around the answer.
String rewriteLinkDestinations(
  String text,
  String? Function(String href) mapHref,
) {
  final edits = <({int start, int end, String value})>[];
  var lineStart = 0;
  for (final line in HighlightDocument.fromText(text).lines) {
    final src = line.text;
    for (final token in line.tokens) {
      if (token.kind != TokenKind.link && token.kind != TokenKind.image) {
        continue;
      }
      final close = src.indexOf(']', token.start);
      if (close < 0 || close + 2 > token.end - 1) continue;
      final written = src.substring(close + 2, token.end - 1).trim();
      final destination = _Destination.parse(written);
      final mapped = mapHref(destination.url);
      if (mapped == null) continue;
      final start = lineStart + token.start;
      final end = lineStart + token.end;
      final raw = text.substring(start, end);
      final open = raw.lastIndexOf('](');
      if (open < 0) continue;
      edits.add((
        start: start,
        end: end,
        value:
            '${raw.substring(0, open + 2)}${destination.replacedBy(mapped)})',
      ));
    }
    lineStart += src.length + 1;
  }
  if (edits.isEmpty) return text;
  // Last to first, so an earlier span's offsets stay valid.
  edits.sort((a, b) => b.start.compareTo(a.start));
  var out = text;
  for (final edit in edits) {
    out = out.substring(0, edit.start) + edit.value + out.substring(edit.end);
  }
  return out;
}

/// A link's destination as written: its url and what follows it.
final class _Destination {
  new(this.url, this.after, {required this.angled});

  /// What is written between the parentheses: `url`, `<url with spaces>`,
  /// either one followed by a title.
  factory parse(String written) {
    if (written.startsWith('<')) {
      final end = written.indexOf('>');
      if (end > 0) {
        return _Destination(
          written.substring(1, end),
          written.substring(end + 1),
          angled: true,
        );
      }
    }
    final space = written.indexOf(RegExp(r'\s'));
    if (space < 0) return _Destination(written, '', angled: false);
    return _Destination(
      written.substring(0, space),
      written.substring(space),
      angled: false,
    );
  }

  /// The url alone.
  final String url;

  /// What follows it: the title, with the white space before it.
  final String after;

  /// Whether the url was written between `<` and `>`.
  final bool angled;

  /// The destination with [replacement] for its url.
  String replacedBy(String replacement) =>
      '${angled ? '<$replacement>' : replacement}$after';
}
