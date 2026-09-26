/// The EPUB glue of a folder export (#303), split from the isolate's
/// orchestration: what a book takes from `index.md`, and one note as a
/// chapter.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/export/epub_book.dart';
import 'package:niman/src/export/export_sources.dart';
import 'package:niman/src/export/export_tree_pages.dart';
import 'package:niman/src/export/note_html.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:path/path.dart' as p;

/// What a folder's book takes from the frontmatter, and the lines to log
/// when there is none to take (#303, E3).
typedef ExportTreeFrontmatter = ({
  EpubMetadata metadata,
  List<String> warnings,
});

/// Why an exported folder has no metadata for its book (#303, E3).
enum EpubMetadataProblem {
  /// No `index.md` at the folder's root.
  missingIndex,

  /// `index.md` is there but carries no frontmatter.
  missingFrontmatter,
}

/// A folder's book: its metadata source and its chapters.
abstract final class ExportTreeBook {
  /// The problem an exported folder's metadata source has, found before the
  /// export starts: no `index.md` at [folder]'s root, or one with nothing
  /// in it (E3). Null when the folder has a source.
  ///
  /// It reads the folder's own listing and, when there is one, `index.md` —
  /// never the tree — so a caller can ask before the export does its work;
  /// the read runs off the UI isolate.
  static Future<EpubMetadataProblem?> problemOf(String folder) async {
    try {
      return await Isolate.run(() {
        File? index;
        for (final entry in Directory(folder).listSync(followLinks: false)) {
          if (entry is! File) continue;
          if (p.basename(entry.path).toLowerCase() != 'index.md') continue;
          index = entry;
          break;
        }
        final file = index;
        if (file == null) return EpubMetadataProblem.missingIndex;
        return parseFrontmatter(ExportTreePages.readNote(file.path)) == null
            ? EpubMetadataProblem.missingFrontmatter
            : null;
      });
    } on FileSystemException {
      // A folder that is not there is the export's failure to report, not
      // the pre-flight's.
      return null;
    }
  }

  /// The frontmatter a folder's book takes: `index.md`'s, when the exported
  /// folder has one at its root (#303).
  ///
  /// A folder has no frontmatter of its own, and a book's metadata belongs
  /// to the book, not to whichever note sorts first: `index.md` is the note
  /// the author writes it in.
  ///
  /// A book without one — or with one that says nothing — is not a failure,
  /// but it is silent: the package carries the folder's name and nothing
  /// else. Why travels in the answer's `warnings`, for the caller to log
  /// where its logger lives (E3).
  static ExportTreeFrontmatter frontmatter(ExportTreeWalk tree) {
    final rel = tree.notes['index.md'];
    if (rel == null || p.dirname(rel) != '.') {
      const warning =
          'the exported folder has no index.md at its root: the book carries '
          "the folder's name and no metadata";
      return (metadata: const EpubMetadata(), warnings: <String>[warning]);
    }
    final text = ExportTreePages.readNote(p.join(tree.root, rel));
    final warnings = <String>[];
    if (parseFrontmatter(text) == null) {
      warnings.add(
        "the book's index.md has no frontmatter: the package carries the "
        "folder's name and no metadata",
      );
    }
    return (metadata: epubMetadataOf(text), warnings: warnings);
  }

  /// Adds one note of [tree] to [book] as a chapter (#303).
  static Future<void> addChapter(
    EpubBook book,
    ExportTreeWalk tree,
    ExportTreeEntry entry,
  ) async {
    final rel = entry.rel;
    final noteDir = p.dirname(rel);
    final href = 'OEBPS/text/${tree.names[rel]}.xhtml';
    final text = ExportTreePages.readNote(entry.abs);
    final images = <String, String>{};
    for (final target in ExportSources.pictureTargets(text)) {
      final picture = ExportTreePages.fileIn(target, noteDir, tree.files);
      if (picture == null) continue;
      final url = await book.imageHref(
        p.posix.dirname(href),
        p.join(tree.root, picture),
      );
      if (url != null) images[target] = url;
    }
    final title = ExportTreePages.pageTitle(text, rel);
    final source = NoteHtmlSource(
      text: text,
      title: title,
      images: images,
      // A book's chapters link to each other, as the HTML zip's pages do.
      links: ExportTreePages.linkUrls(text, noteDir, tree, '.xhtml'),
    );
    final html = NoteHtml(source);
    final body = html.body();
    book.addChapter(
      href: href,
      title: title,
      body: body,
      fontFaces: html.fontFaces,
      hasSvg: html.usesSvg,
    );
  }
}
