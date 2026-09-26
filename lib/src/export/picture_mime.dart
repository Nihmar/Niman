/// The picture types an export carries (#24, #303): one table for a page
/// and a book, so both agree on what a `.svg` is (S3).
///
/// The read view's inline embeds carry no SVG (`EmbedView.imageExtensions`):
/// Flutter has no decoder for it. An export has one — a browser draws a
/// `data:` URI, an EPUB reader draws a container entry — so the export's own
/// list is a superset, and it lives here alone (E8).
library;

/// The media type of each picture type an export carries, lower case with
/// the dot.
const Map<String, String> pictureTypes = <String, String>{
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.webp': 'image/webp',
  '.bmp': 'image/bmp',
  '.svg': 'image/svg+xml',
};

/// The media type of the picture at [extension] (lower case, with the dot),
/// or null when it is not one an export carries.
String? pictureMime(String extension) => pictureTypes[extension];

/// [pictureTypes]' extensions as the pattern an embed's target is matched
/// against, case-insensitively.
final RegExp pictureExtension = RegExp(
  '\\.(${pictureTypes.keys.map((extension) => extension.substring(1)).join('|')})\$',
  caseSensitive: false,
);
