/// The link to a place in a PDF or a book (#282), as the library writes
/// links: `[[Books/Dune.pdf#page=34|Dune, p. 34]]`, or
/// `[Dune, p. 34](Books/Dune.pdf#page=34)` when it writes Markdown ones.
///
/// The file goes by its library-relative path, which always resolves; a
/// Markdown href has what would end it or read as an escape
/// percent-encoded, as Obsidian writes one (`My%20Book.pdf`).
library;

import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/reading/book_location.dart';

/// The link to [place] in the file at library-relative [path], shown as
/// [label].
String placeLink({
  required String path,
  required BookLocation place,
  required String label,
  required LinkType linkType,
}) {
  final fragment = place.toFragment();
  if (linkType == LinkType.markdown) {
    final text = label.replaceAll('[', '(').replaceAll(']', ')');
    final href = path.replaceAllMapped(
      _unsafeInHref,
      (m) => '%${m[0]!.codeUnitAt(0).toRadixString(16).toUpperCase()}',
    );
    return '[$text]($href#$fragment)';
  }
  final alias = label.replaceAll('|', '-').replaceAll(']', ')');
  return '[[$path#$fragment|$alias]]';
}

/// What a Markdown href cannot hold as written: a space or a bracket ends
/// it, a `#` begins its fragment, a `%` would read as an escape.
final RegExp _unsafeInHref = RegExp('[%\x20()<>#]');
