/// One annotation of a PDF or a book (#284), as its companion note holds
/// it: a heading naming the place, the passage quoted with a link back to
/// it, and what the reader said.
///
/// ```markdown
/// ## Dune, p. 34
///
/// > The passage, as the file has it.
/// > — [[Books/Dune.pdf#page=34&chars=120-180|Dune, p. 34]]
///
/// The comment.
/// ```
///
/// The heading makes the note's outline a list of its annotations; the
/// link is the way back to the file, and what marks the file where it was
/// annotated (#285); the quote is also what finds the place again if the
/// file changed. A place with nothing to quote — a page of a scanned PDF —
/// has the link on a line of its own.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/links/place_link.dart';
import 'package:niman/src/markdown/text_escape.dart';
import 'package:niman/src/reading/book_location.dart';

/// What the reader annotated, and what they said.
@immutable
final class Annotation {
  /// The annotation of [place] in the file at library-relative [path].
  const new({
    required this.path,
    required this.place,
    required this.label,
    this.quote = '',
    this.comment = '',
  });

  /// The annotated file, library-relative.
  final String path;

  /// Where in it.
  final BookLocation place;

  /// What names the place: `Dune, p. 34`, `Dune, Chapter 5`.
  final String label;

  /// The passage, as the file has it; empty when there is none.
  final String quote;

  /// What the reader said; may be empty.
  final String comment;

  /// The annotation as its note holds it, links written as [linkType]
  /// says, ending in a newline.
  String toMarkdown({required LinkType linkType}) {
    final link = placeLink(
      path: path,
      place: place,
      label: label,
      linkType: linkType,
    );
    final passage = quote.replaceAll(_blank, ' ').trim();
    final out = StringBuffer('## ${_oneLine(label)}\n\n');
    if (passage.isEmpty) {
      out.write('$link\n');
    } else {
      out
        ..write('> ${escapeMarkdownText(passage)}\n')
        ..write('> — $link\n');
    }
    final said = comment.trim();
    if (said.isNotEmpty) out.write('\n$said\n');
    return out.toString();
  }

  /// [text] on one line, its `#` escaped so a heading stays one.
  static String _oneLine(String text) =>
      escapeMarkdownText(text.replaceAll(_blank, ' ').trim());

  static final RegExp _blank = RegExp(r'\s+');
}
