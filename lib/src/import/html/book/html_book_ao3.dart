/// The AO3 profile (#1294): a work downloaded from the Archive of Our Own as
/// HTML, which has its stable shape and says everything about itself in it —
/// the Archive having turned its EPUB downloads off, this is how a work is
/// taken.
///
/// **Recognized by** `div#preface`, `div#chapters` and, in the preface, a
/// link to `archiveofourown.org/works/<id>`.
///
/// - **The preface** gives the metadata (`dl.tags`: rating, warnings,
///   category, fandom, relationships, characters, tags, language, series,
///   stats), the title (`h1`), the authors (`a[rel=author]`) and the work's
///   source; its summary and notes, quoted under their labels, are the
///   [HtmlBook.introHtml] — the index's body — with a list of related works
///   when there is one.
/// - **The chapters** are `div.meta.group > h2.heading` (`Chapter 1`, or
///   `Chapter 1: Title`), each followed by its text. A chapter's own notes
///   are quoted at its top, its end notes (`div.meta#endnotes<n>`) at its
///   bottom; the "See the end of the chapter for notes" line is dropped, the
///   notes being in the same note. A work of one chapter has no heading: it
///   is one chapter, titled as the work.
/// - **The afterword** keeps the work's end notes and the works inspired by
///   this one, at the end of the last chapter.
/// - **Dropped**: the `h2.toc-heading`s (`Preface`, `Afterword`, hidden by the
///   download's own CSS), the `p.message`s (the link to the work, the
///   invitation to comment), the tags and an empty list of related works.
library;

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:niman/src/import/html/book/html_book.dart';
import 'package:niman/src/import/html/html_page.dart';

/// The work's own address, the part of a link to it that names it.
final RegExp _workAddress = RegExp(
  r'^https?://(?:www\.)?archiveofourown\.org/works/\d+',
  caseSensitive: false,
);

/// [page] as an AO3 work, or null when it is not one.
HtmlBook? readAo3Book(HtmlPage page) {
  // Cheap, before a page that is nothing of the kind is parsed for it.
  if (!page.html.contains('archiveofourown')) return null;
  final document = html.parse(page.html);
  final preface = document.querySelector('div#preface');
  final chapters = document.querySelector('div#chapters');
  if (preface == null || chapters == null) return null;
  final source = _workAddress
      .firstMatch(
        preface
            .querySelectorAll('p.message a[href]')
            .map((link) => link.attributes['href']!.trim())
            .firstWhere(_workAddress.hasMatch, orElse: () => ''),
      )
      ?.group(0);
  if (source == null) return null;

  final title =
      _clean(preface.querySelector('h1')?.text) ??
      _clean(preface.querySelector('p.message b')?.text) ??
      page.title;
  final authors = _authors(preface);
  final tags = _tags(preface);
  final intro = StringBuffer();
  String? summary;
  final meta = preface.querySelector('div.meta');
  if (meta != null) {
    _keepMeta(
      meta,
      intro,
      onQuote: (label, quote) {
        if (_norm(label) == 'summary') summary ??= _plain(quote);
      },
    );
  }

  final text = StringBuffer();
  final titles = <String>[];
  for (final child in chapters.children) {
    if (!child.classes.contains('meta')) {
      text.write(child.outerHtml);
      continue;
    }
    final heading = child.querySelector('h2.heading');
    if (heading != null) {
      final words = _clean(heading.text) ?? '';
      text
        ..write(chapterMarkerElement(titles.length).outerHtml)
        ..write((Element.tag('h2')..text = words).outerHtml);
      titles.add(words);
    }
    _keepMeta(child, text);
  }
  final single = titles.isEmpty;
  if (single) titles.add(title);
  final afterword = document.querySelector('div#afterword');
  if (afterword != null) {
    for (final meta in afterword.children) {
      if (meta.classes.contains('meta')) _keepMeta(meta, text);
    }
  }

  final stats = _plain(tags['stat']?.firstOrNull);
  final series = tags['serie']?.firstOrNull;
  final seriesName = series == null
      ? null
      : _clean(series.querySelector('a')?.text) ?? _clean(series.text);
  return HtmlBook(
    profile: HtmlBookProfile.ao3,
    title: title,
    authors: authors,
    fields: [
      ('title', title),
      ('author', authors),
      (
        'language',
        page.language ?? _clean(tags['language']?.firstOrNull?.text),
      ),
      ('published', _stat(stats, 'Published', r'\d{4}-\d{2}-\d{2}')),
      ('series', seriesName),
      (
        'series_index',
        series == null
            ? null
            : int.tryParse(_stat(_plain(series), 'Part', r'\d+') ?? ''),
      ),
      ('description', summary),
      ('tags', _items(tags['additional tag'])),
      ('source', source),
      ('fandom', _items(tags['fandom'])),
      ('rating', _items(tags['rating'])),
      ('warnings', _items(tags['archive warning'])),
      ('category', _items(tags['category'])),
      ('relationships', _items(tags['relationship'])),
      ('characters', _items(tags['character'])),
      ('completed', _stat(stats, 'Completed', r'\d{4}-\d{2}-\d{2}')),
      (
        'words',
        int.tryParse(
          (_stat(stats, 'Words', r'[\d,.]+') ?? '').replaceAll(
            RegExp('[,.]'),
            '',
          ),
        ),
      ),
    ],
    html: single
        ? '${chapterMarkerElement(0).outerHtml}$text'
        : text.toString(),
    chapters: [
      for (final (index, name) in titles.indexed)
        (marker: chapterMarker(index), title: name),
    ],
    headingLevel: single ? 0 : 2,
    introHtml: intro.toString(),
  );
}

/// The authors the byline links; else the byline's own words.
List<String> _authors(Element preface) {
  final byline = preface.querySelector('.byline');
  if (byline == null) return const [];
  final linked = [
    for (final link in byline.querySelectorAll('a[rel~="author"]'))
      ?_clean(link.text),
  ];
  if (linked.isNotEmpty) return linked.toSet().toList();
  final words = _clean(byline.text)
      ?.replaceFirst(RegExp('^by ', caseSensitive: false), '');
  return words == null || words.isEmpty ? const [] : [words];
}

/// The `dl.tags` of [preface]: each `dd`, under its label as [_norm] spells
/// it.
Map<String, List<Element>> _tags(Element preface) {
  final out = <String, List<Element>>{};
  String? label;
  for (final child
      in preface.querySelector('dl.tags')?.children ?? const <Element>[]) {
    if (child.localName == 'dt') {
      label = _norm(child.text);
    } else if (child.localName == 'dd' && label != null) {
      (out[label] ??= []).add(child);
    }
  }
  return out;
}

/// What a label comes to: lower case, no colon, no plural (`Additional
/// Tags:` and `Additional Tag:` are one).
String _norm(String text) => (_clean(text) ?? '')
    .toLowerCase()
    .replaceAll(RegExp(r':$'), '')
    .replaceAll(RegExp(r's$'), '');

/// The values of a `dd`: its links' words, else what is between its commas.
List<String> _items(List<Element>? dds) => [
  for (final dd in dds ?? const <Element>[])
    ...() {
      final links = dd.querySelectorAll('a');
      return links.isNotEmpty
          ? [for (final link in links) ?_clean(link.text)]
          : [for (final part in dd.text.split(',')) ?_clean(part)];
    }(),
];

/// What follows [label] in [text] (`Published: 2025-07-15`), when it is
/// what [pattern] reads.
String? _stat(String? text, String label, String pattern) {
  if (text == null) return null;
  return RegExp('$label:?\\s*($pattern)').firstMatch(text)?.group(1);
}

/// What [meta] says that the book keeps, written to [out]: a quote under its
/// label (a paragraph of bare words, which [onQuote] hears with the quote),
/// the lists of related works. The title, the byline, the tags and the line
/// that points at the end notes are left.
void _keepMeta(
  Element meta,
  StringBuffer out, {
  void Function(String label, Element quote)? onQuote,
}) {
  // What a link into the book names (`#endnotes2`) is where its notes begin.
  if (meta.id.isNotEmpty) {
    out.write((Element.tag('div')..id = meta.id).outerHtml);
  }
  final children = meta.children;
  for (var i = 0; i < children.length; i++) {
    final child = children[i];
    final next = i + 1 < children.length ? children[i + 1] : null;
    switch (child.localName) {
      case 'p' when child.children.isEmpty && next?.localName == 'blockquote':
        final label = _clean(child.text) ?? '';
        final bold = Element.tag('p')
          ..append(Element.tag('strong')..text = label);
        out.write(bold.outerHtml);
        onQuote?.call(label, next!);
      case 'blockquote' || 'ul' || 'ol':
        out.write(child.outerHtml);
      // A list of the works inspired by this one is kept when it lists any.
      case 'dl' when !child.classes.contains('tags'):
        if (child.querySelector('dd') != null) out.write(child.outerHtml);
    }
  }
}

/// [node]'s words, a break a space, whitespace made one space.
String? _plain(Node? node) {
  if (node == null) return null;
  final out = StringBuffer();
  void walk(Node at) {
    if (at is Text) {
      out.write(at.data);
    } else if (at is Element) {
      if (at.localName == 'br' || at.localName == 'p') out.write(' ');
      at.nodes.forEach(walk);
      if (at.localName == 'p') out.write(' ');
    }
  }

  walk(node);
  return _clean(out.toString());
}

/// [text] with its whitespace runs made one space; null when nothing is
/// left.
String? _clean(String? text) {
  final cleaned = text?.replaceAll(RegExp(r'\s+'), ' ').trim();
  return cleaned == null || cleaned.isEmpty ? null : cleaned;
}
