/// What the notes of a converted book say (#1138): each note's lines with
/// the book's pictures and links pointing at the library's files, and
/// `index.md`, the book's metadata and contents.
///
/// - **Pictures** point at their copy in the book's folder, relative to the
///   note: the folder moves whole, and a folder exported as a book takes the
///   pictures inside it along.
/// - **A link into the book** points at the note it lands in, relative to
///   the note it is written in, and at its heading when it lands on one
///   (`02%20Part/01%20Arrival.md#The%20Storm`). A link out of the book is
///   left as written.
/// - **`index.md`** carries the keys a folder's book export reads back
///   (`epubMetadataOf`): a converted book exported again keeps its title,
///   authors, series, identifier and cover.
library;

import 'package:niman/src/epub/epub_book.dart';
import 'package:niman/src/epub/epub_convert_plan.dart';
import 'package:niman/src/epub/epub_info.dart';
import 'package:niman/src/frontmatter/yaml_scalar.dart';
import 'package:path/path.dart' as p;

/// The text of [note], one of [written] — the notes of [plan] that have
/// text. [pictureAt] answers where picture `n` was written, relative to
/// the folder the notes' paths are relative to; null when it was not.
String renderNote(
  EpubPlan plan,
  EpubPlannedNote note,
  List<EpubPlannedNote> written, {
  required String? Function(int picture) pictureAt,
}) {
  final body = noteBody(plan, note);
  final titled = body.startsWith('#') ? body : '# ${note.title}\n\n$body';
  final from = noteFolderOf(note.path);
  return titled
      .replaceAllMapped(_picture, (match) {
        final at = pictureAt(int.parse(match.group(1)!));
        return at == null ? '' : _href(at, from: from);
      })
      .replaceAllMapped(_link, (match) {
        final index = int.parse(match.group(1)!);
        return _linkTarget(plan, note, written, index) ?? '#';
      });
}

/// [note]'s lines, without the blank lines and the chapters' rules at its
/// edges; empty when it holds no text.
String noteBody(EpubPlan plan, EpubPlannedNote note) {
  var start = note.start;
  var end = note.end;
  bool edge(String line) => line.trim().isEmpty || line.trim() == '---';
  while (start < end && edge(plan.lines[start])) {
    start++;
  }
  while (end > start && edge(plan.lines[end - 1])) {
    end--;
  }
  return plan.lines.sublist(start, end).join('\n');
}

/// Where link [index] of the book goes, written in [note].
String? _linkTarget(
  EpubPlan plan,
  EpubPlannedNote note,
  List<EpubPlannedNote> written,
  int index,
) {
  final line = plan.lineOfTarget(plan.book.links[index]);
  if (line == null) return null;
  final target = plan.noteAt(line, written);
  if (target == null) return null;
  final heading = line > target.start ? _headingAt(plan, line) : null;
  final anchor = heading == null ? '' : '#${Uri.encodeComponent(heading)}';
  if (identical(target, note) || target.path == note.path) {
    return anchor.isEmpty ? _href(p.posix.basename(note.path)) : anchor;
  }
  return '${_href(target.path, from: noteFolderOf(note.path))}$anchor';
}

/// The heading on [line] of the book, or null when it is not one.
String? _headingAt(EpubPlan plan, int line) {
  final match = _heading.firstMatch(plan.lines[line]);
  return match?.group(1)?.trim();
}

/// [path] relative to the folder [from] (both `/`-separated, relative to the
/// same folder), each segment percent-encoded: a link's target.
String _href(String path, {String from = ''}) {
  final relative = from.isEmpty ? path : p.posix.relative(path, from: from);
  return relative.split('/').map(Uri.encodeComponent).join('/');
}

/// `index.md` of [plan]: the book's metadata as frontmatter, then its title,
/// its authors, its cover and its contents as links to the notes. [cover]
/// is where the cover picture was written, relative to the book's folder.
String renderIndex(
  EpubPlan plan,
  List<EpubPlannedNote> written, {
  required EpubConvertWords words,
  String? cover,
}) {
  final info = plan.book.info;
  final out = StringBuffer('---\n')
    ..write(_frontmatter(info, title: plan.title, cover: cover))
    ..write('---\n\n# ${plan.title}\n');
  if (info.authors.isNotEmpty) out.write('\n*${info.authors.join(', ')}*\n');
  if (cover != null) out.write('\n![${plan.title}](${_href(cover)})\n');
  out.write('\n## ${words.contents}\n\n');
  if (plan.contents.isEmpty) {
    for (final note in written) {
      out.write('- [${_text(note.title)}](${_href(note.path)})\n');
    }
  } else {
    for (final entry in plan.contents) {
      final target = plan.noteAt(entry.line, written);
      if (target == null) continue;
      final heading = entry.line > target.start
          ? _headingAt(plan, entry.line)
          : null;
      final anchor = heading == null ? '' : '#${Uri.encodeComponent(heading)}';
      final link = '[${_text(entry.title)}](${_href(target.path)}$anchor)';
      out.write('${'  ' * entry.depth}- $link\n');
    }
  }
  return out.toString();
}

String _frontmatter(EpubInfo info, {required String title, String? cover}) {
  final out = StringBuffer();
  void one(String key, String? value) {
    if (value == null || value.trim().isEmpty) return;
    out.write('$key: ${yamlString(value)}\n');
  }

  void many(String key, List<String> values) {
    if (values.isEmpty) return;
    out.write('$key:\n');
    for (final value in values) {
      out.write('  - ${yamlString(value)}\n');
    }
  }

  one('title', title);
  many('author', info.authors);
  one('language', info.language);
  one('publisher', info.publisher);
  one('published', info.published);
  one('isbn', info.isbn);
  one('identifier', info.identifier);
  one('series', info.series);
  one('series_index', info.seriesIndex);
  one('rights', info.rights);
  one('description', info.description);
  many('tags', info.subjects);
  one('cover', cover);
  return out.toString();
}

/// [text] as a link's words: the brackets that would end them escaped.
String _text(String text) =>
    text.replaceAllMapped(RegExp(r'[\[\]\\]'), (m) => '\\${m.group(0)}');

final RegExp _picture = RegExp('$epubPictureScheme:(\\d+)');
final RegExp _link = RegExp('$epubLinkScheme:(\\d+)');
final RegExp _heading = RegExp(r'^#{1,6}\s+(.+?)\s*#*\s*$');
