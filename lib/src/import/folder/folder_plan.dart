/// Where each file of an imported folder lands, and which file a link of
/// one of them points at (#1295).
///
/// The layout is kept: `site/a/b.html` is `a/b.md` in the new folder, named
/// after the page's file and not its title, so the links between the files
/// map one to one and two pages never take one name. A Markdown file keeps
/// its name; a page whose note would take a name already taken in its folder
/// (`b.md` beside `b.html`, `b.html` beside `b.htm`) is numbered, `b_2.md`,
/// as the Notion import numbers its own.
///
/// Pure: paths in, paths out.
library;

import 'package:niman/src/core/percent.dart';
import 'package:niman/src/import/folder/folder_scan.dart';
import 'package:niman/src/links/link_path.dart';
import 'package:path/path.dart' as p;

/// One file of the folder: what it was, and the note it becomes.
final class FolderEntry {
  /// The [index]th file, [source] in the folder and [target] in the new one,
  /// both relative and `/`-separated.
  const new(this.index, this.source, this.target, {required this.isPage});

  /// Its place in [FolderPlan.entries].
  final int index;

  /// Where it was, relative to the folder.
  final String source;

  /// Where it lands, relative to the new folder.
  final String target;

  /// Whether it is a web page, converted; a Markdown file is copied.
  final bool isPage;

  /// The folder it lands in, relative to the new folder; '' for the top.
  String get targetFolder => _folderOf(target);

  /// The folder it was in, relative to the folder; '' for the top.
  String get sourceFolder => _folderOf(source);
}

/// A link that lands on a file of the folder: which, and the fragment after
/// its `#` as the link wrote it ('' when it has none).
typedef FolderLink = ({FolderEntry entry, String fragment});

/// The plan of one import: every file and where it goes.
final class FolderPlan {
  /// The plan of [scan]'s files.
  new(FolderScan scan) {
    final used = <String, Set<String>>{};
    String unique(String folder, String name) {
      final taken = used.putIfAbsent(folder, () => {});
      final stem = p.posix.withoutExtension(name);
      final extension = p.posix.extension(name);
      var candidate = name;
      for (var n = 2; !taken.add(candidate.toLowerCase()); n++) {
        candidate = '${stem}_$n$extension';
      }
      return folder.isEmpty ? candidate : '$folder/$candidate';
    }

    // Markdown files first: they keep their names, and a page gives way.
    final markdown = <FolderEntry>[];
    for (final source in scan.markdown) {
      markdown.add(
        FolderEntry(
          0,
          source,
          unique(_folderOf(source), p.posix.basename(source)),
          isPage: false,
        ),
      );
    }
    final pages = <FolderEntry>[];
    for (final source in scan.pages) {
      final stem = p.posix.basenameWithoutExtension(source);
      pages.add(
        FolderEntry(
          0,
          source,
          unique(_folderOf(source), '$stem.md'),
          isPage: true,
        ),
      );
    }
    // Pages are converted first, and the Markdown after them: its links to a
    // page need the headings the page's conversion found.
    entries = [
      for (final (index, entry) in [...pages, ...markdown].indexed)
        FolderEntry(index, entry.source, entry.target, isPage: entry.isPage),
    ];
    for (final entry in entries) {
      _bySource[entry.source] = entry;
      _byLower.putIfAbsent(entry.source.toLowerCase(), () => entry);
    }
  }

  /// Every file: the pages, then the Markdown files.
  late final List<FolderEntry> entries;

  final Map<String, FolderEntry> _bySource = {};
  final Map<String, FolderEntry> _byLower = {};

  /// The pages.
  Iterable<FolderEntry> get pages => entries.where((entry) => entry.isPage);

  /// The Markdown files.
  Iterable<FolderEntry> get markdown => entries.where((entry) => !entry.isPage);

  /// The file the link [href], written in [from], points at; null for a link
  /// that points at none of the folder's files: one to the web, to a place in
  /// [from] itself, to something outside the folder, or to a file that is not
  /// imported (a PDF, a picture).
  ///
  /// The link is read as a browser reads one: relative to the file it is in,
  /// percent-decoded, a backslash a slash, its query dropped; one that begins
  /// with `/` is relative to the folder, which is taken to be the site's top.
  /// A folder (`docs/`) is the page that is its `index`.
  FolderLink? resolve(FolderEntry from, String href) {
    final text = href.trim();
    if (text.isEmpty ||
        text.startsWith('#') ||
        text.startsWith('//') ||
        LinkPaths.hasScheme(text)) {
      return null;
    }
    final hash = text.indexOf('#');
    var path = hash < 0 ? text : text.substring(0, hash);
    final fragment = hash < 0 ? '' : text.substring(hash + 1);
    final query = path.indexOf('?');
    if (query >= 0) path = path.substring(0, query);
    if (path.isEmpty) return null;
    final decoded = percentDecoded(path).replaceAll(r'\', '/');
    final joined = decoded.startsWith('/')
        ? decoded.substring(1)
        : p.posix.join(from.sourceFolder, decoded);
    final normal = p.posix.normalize(joined);
    if (normal == '.' || normal == '..' || normal.startsWith('../')) {
      return null;
    }
    var entry = _find(normal);
    if (entry == null && (decoded.endsWith('/') || !_hasExtension(normal))) {
      for (final index in const ['index.html', 'index.htm', 'index.xhtml']) {
        entry ??= _find('$normal/$index');
      }
    }
    return entry == null ? null : (entry: entry, fragment: fragment);
  }

  FolderEntry? _find(String source) =>
      _bySource[source] ?? _byLower[source.toLowerCase()];

  static bool _hasExtension(String path) => p.posix.extension(path).isNotEmpty;
}

String _folderOf(String path) {
  final folder = p.posix.dirname(path);
  return folder == '.' ? '' : folder;
}
