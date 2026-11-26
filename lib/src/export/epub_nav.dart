/// An EPUB's navigation document (#303, #1308): the contents a reader
/// shows, one entry per chapter in spine order, nested by the folders the
/// chapters were in.
///
/// A folder is an entry with its chapters in a list under it. When the
/// folder's first chapter is its own page (`00 Part One.md`, as a converted
/// book names it) that page is the folder's entry; otherwise the entry is a
/// heading with no target of its own.
library;

import 'package:niman/src/export/epub_package.dart';
import 'package:niman/src/export/html_text.dart';
import 'package:path/path.dart' as p;

/// The navigation document of a book titled [title], in [language].
String epubNavXhtml({
  required List<EpubChapterEntry> chapters,
  required String title,
  required String language,
}) {
  final entries = StringBuffer();
  _write(entries, _nest(chapters).children, 3);
  return '<?xml version="1.0" encoding="utf-8"?>\n'
      '<!DOCTYPE html>\n'
      '<html xmlns="http://www.w3.org/1999/xhtml" '
      'xmlns:epub="http://www.idpf.org/2007/ops" '
      'xml:lang="${escapeAttribute(language)}" '
      'lang="${escapeAttribute(language)}">\n'
      '<head>\n'
      '  <meta charset="utf-8" />\n'
      '  <title>${escapeHtml(title)}</title>\n'
      '</head>\n'
      '<body>\n'
      '  <nav epub:type="toc" id="toc">\n'
      '    <h1>${escapeHtml(title)}</h1>\n'
      '    <ol>\n$entries'
      '    </ol>\n'
      '  </nav>\n'
      '</body>\n'
      '</html>\n';
}

/// One folder of the nav: its name, the page that opens it when it has one,
/// and what it holds — [EpubChapterEntry]s and [_Level]s, in spine order.
final class _Level {
  new(this.name);

  final String name;
  EpubChapterEntry? opening;
  final List<Object> children = <Object>[];
}

/// The chapters of [chapters] as the folders they were in: a level for each
/// folder, made when its first chapter comes (a folder's chapters are
/// together in the spine, so one pass keeps their order).
_Level _nest(List<EpubChapterEntry> chapters) {
  final root = _Level('');
  final levels = <String, _Level>{};
  for (final chapter in chapters) {
    var parent = root;
    var path = '';
    if (chapter.folder.isNotEmpty) {
      for (final name in chapter.folder.split('/')) {
        path = path.isEmpty ? name : '$path/$name';
        var level = levels[path];
        if (level == null) {
          level = levels[path] = _Level(name);
          parent.children.add(level);
        }
        parent = level;
      }
    }
    // The folder's own page, when it is the first thing in it, is its
    // entry; anywhere else it is a chapter like the others.
    if (parent != root &&
        chapter.opensFolder &&
        parent.opening == null &&
        parent.children.isEmpty) {
      parent.opening = chapter;
    } else {
      parent.children.add(chapter);
    }
  }
  return root;
}

/// The `<li>` of [items] at [depth] levels of indentation (two spaces
/// each).
void _write(StringBuffer out, List<Object> items, int depth) {
  final pad = '  ' * (depth + 1);
  for (final item in items) {
    switch (item) {
      case final EpubChapterEntry chapter:
        out.write('$pad<li>${_link(chapter, chapter.title)}</li>\n');
      case final _Level level:
        final opening = level.opening;
        final head = opening == null
            ? '<span>${escapeHtml(level.name)}</span>'
            : _link(opening, level.name);
        if (level.children.isEmpty) {
          out.write('$pad<li>$head</li>\n');
          continue;
        }
        out
          ..write('$pad<li>$head\n')
          ..write('$pad  <ol>\n');
        _write(out, level.children, depth + 2);
        out
          ..write('$pad  </ol>\n')
          ..write('$pad</li>\n');
    }
  }
}

/// [chapter]'s link, [text] its words.
String _link(EpubChapterEntry chapter, String text) {
  final href = epubIri(p.posix.relative(chapter.href, from: epubOpfDir));
  return '<a href="${escapeAttribute(href)}">${escapeHtml(text)}</a>';
}
