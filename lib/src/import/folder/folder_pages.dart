/// The conversion of the web pages of an imported folder (#1295): each page
/// read as a single one is (#1293) — the article Readability finds, else the
/// body — its pictures kept once for the whole import, and its links to the
/// other files of the folder written under a placeholder
/// (`folder_links.dart`) for the end of the import to resolve.
library;

import 'package:niman/src/capture/capture_pictures.dart'
    show maxCapturedPictures;
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/import/folder/folder_links.dart';
import 'package:niman/src/import/folder/folder_plan.dart';
import 'package:niman/src/import/html/html_convert_failures.dart';
import 'package:niman/src/import/html/html_convert_types.dart'
    show readHtmlSource;
import 'package:niman/src/import/html/html_note.dart';
import 'package:niman/src/import/html/html_page.dart';
import 'package:niman/src/import/html/html_picture_pool.dart';
import 'package:niman/src/import/html/html_picture_source.dart';
import 'package:niman/src/import/html/html_picture_store.dart';
import 'package:path/path.dart' as p;

/// A page converted: its note's text, and the heading each of its `id`s is
/// under; `linked` when its text holds placeholders to resolve.
typedef FolderPageNote = ({
  String text,
  Map<String, String> headings,
  bool linked,
});

/// Converts the pages of the folder at [source], keeping their pictures in
/// [store].
final class FolderPages {
  /// A converter for the pages of [plan].
  new({
    required this.source,
    required this.plan,
    required this.store,
    required this.step,
    required this.linkType,
    required this.folderName,
    required this.imported,
    this.stopped,
    this.progress,
  });

  /// The folder, absolute.
  final String source;

  /// The files and where they go.
  final FolderPlan plan;

  /// Where the pictures are kept.
  final HtmlPictureStore store;

  /// Awaited before each picture and between steps; throws to stop.
  final Future<void> Function() step;

  /// Asked while pictures are on their way.
  final bool Function()? stopped;

  /// Hears the name of the picture being kept.
  final void Function(String what)? progress;

  /// How the library embeds a picture.
  final LinkType linkType;

  /// The new folder's name, which a note's picture links are written from.
  final String folderName;

  /// The day the notes are imported.
  final DateTime imported;

  /// Where each picture kept is, by its address.
  final Map<String, String> _kept = {};

  /// The addresses already tried, kept or not: a picture of a site's logo is
  /// asked for once, not once a page.
  final Set<String> _tried = {};

  /// How many pictures were kept.
  int get pictures => store.length;

  /// The note of [entry]; null when the page could not be read or converted,
  /// which leaves it out. Throws [HtmlConvertStopped] when stopped.
  Future<FolderPageNote?> convert(FolderEntry entry) async {
    final file = p.joinAll([source, ...entry.source.split('/')]);
    final HtmlPage page;
    try {
      page = readHtmlPage(
        await readHtmlSource(file),
        fileName: p.basename(file),
      );
    } on HtmlConvertStopped {
      rethrow;
    } on Object {
      return null;
    }
    final base = page.baseUrl ?? Uri.file(file);
    // Each picture once, whichever `src`s name it, and the web ones a page
    // takes no more of than a capture does.
    final addressOf = <String, String>{};
    final fresh = <PictureSource>[];
    var web = 0;
    for (final src in htmlPictureSrcs(page)) {
      final picture = PictureSource.parse(src, base);
      if (picture == null) continue;
      addressOf[src] = picture.address;
      if (!_tried.add(picture.address)) continue;
      if (picture.kind == PictureKind.web && ++web > maxCapturedPictures) {
        continue;
      }
      fresh.add(picture);
    }
    if (fresh.isNotEmpty) {
      _kept.addAll(
        await keepPictures(
          store,
          fresh,
          step: step,
          stopped: stopped,
          progress: (_, what) => progress?.call(what),
        ),
      );
    }
    var linked = false;
    final HtmlNoteMade made;
    try {
      made = htmlNoteMade(
        page,
        imported: imported,
        file: Uri.file(file),
        pictures: {
          for (final entry in addressOf.entries) entry.key: ?_kept[entry.value],
        },
        linkType: linkType,
        folder: entry.targetFolder.isEmpty
            ? folderName
            : '$folderName/${entry.targetFolder}',
        pageLink: (href) {
          final link = plan.resolve(entry, href);
          if (link == null) return null;
          linked = true;
          return pagePlaceholder(link.entry.index, link.fragment, href);
        },
      );
    } on Object {
      return null;
    }
    return (text: made.text, headings: made.headings, linked: linked);
  }
}
