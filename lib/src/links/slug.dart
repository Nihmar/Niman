/// The shared heading slug (design.md: links/slug.dart).
///
/// One implementation, used by every consumer of `[[note#Some Heading]]`
/// anchors: the link parser (anchor targets), the outline/editor (anchor
/// sources) and the preview — so the same heading has the same slug
/// everywhere and a `#`-anchor lands.
library;

final RegExp _kept = RegExp(r'^[\p{L}\p{N}_]$', unicode: true);

/// The heading slug: [heading] normalized to a link-safe, case-insensitive,
/// unicode-preserving form, so `[[note#A Heading]]` matches the heading
/// `## A Heading` (and `## a  heading!` too).
///
/// Rules: lowercase; every run of characters that is not a letter, digit or
/// `_` collapses to a single `-`; the slug never starts or ends with `-`;
/// an empty slug (nothing left after normalization) is the empty string.
/// Unicode letters and digits are kept (`日本語` → `日本語`), so anchors work
/// for any script the editor can type.
String headingSlug(String heading) {
  final buffer = StringBuffer();
  var lastDash = false;
  for (final rune in heading.toLowerCase().runes) {
    if (_kept.hasMatch(String.fromCharCode(rune))) {
      buffer.write(String.fromCharCode(rune));
      lastDash = false;
    } else if (!lastDash) {
      buffer.write('-');
      lastDash = true;
    }
  }
  var slug = buffer.toString();
  if (slug.startsWith('-')) slug = slug.substring(1);
  if (slug.endsWith('-')) slug = slug.substring(0, slug.length - 1);
  return slug;
}
