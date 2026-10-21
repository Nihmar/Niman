/// What a book says about itself (#1138): its package document's metadata,
/// read into the keys a folder's `index.md` gives a book back when it is
/// exported (`epub_package.dart`, `epubMetadataOf`), so a book converted to
/// notes and exported again keeps its title, authors, series and cover.
library;

import 'package:meta/meta.dart';
import 'package:xml/xml.dart';

/// A book's metadata, as its package document gives it.
@immutable
final class EpubInfo {
  /// The metadata of a book.
  const new({
    this.title,
    this.authors = const [],
    this.language,
    this.publisher,
    this.published,
    this.identifier,
    this.isbn,
    this.description,
    this.subjects = const [],
    this.series,
    this.seriesIndex,
    this.rights,
    this.cover,
  });

  /// `dc:title`.
  final String? title;

  /// Every `dc:creator`, in order.
  final List<String> authors;

  /// `dc:language`.
  final String? language;

  /// `dc:publisher`.
  final String? publisher;

  /// `dc:date`, as written.
  final String? published;

  /// The book's identifier when it is not an ISBN.
  final String? identifier;

  /// The book's ISBN, its digits alone.
  final String? isbn;

  /// `dc:description`, its markup taken out.
  final String? description;

  /// Every `dc:subject`.
  final List<String> subjects;

  /// The series it belongs to: EPUB 3's `belongs-to-collection`, or
  /// Calibre's `calibre:series`.
  final String? series;

  /// Its place in [series].
  final String? seriesIndex;

  /// `dc:rights`.
  final String? rights;

  /// The cover picture's path in the zip.
  final String? cover;
}

/// The metadata of the package document [opf], whose manifest maps item ids
/// to paths in the zip through [pathOf].
EpubInfo epubInfoOf(XmlDocument opf, String? Function(String id) pathOf) {
  final metadata = opf.descendantElements
      .where((element) => element.localName == 'metadata')
      .firstOrNull;
  if (metadata == null) return const EpubInfo();
  List<String> all(String local) => [
    for (final element in metadata.descendantElements)
      if (element.localName == local)
        if (_clean(element.innerText) case final text when text.isNotEmpty)
          text,
  ];
  String? first(String local) => all(local).firstOrNull;
  final metas = [
    for (final element in metadata.descendantElements)
      if (element.localName == 'meta') element,
  ];
  String? named(String name) => metas
      .where((meta) => meta.getAttribute('name') == name)
      .map((meta) => meta.getAttribute('content')?.trim())
      .nonNulls
      .where((value) => value.isNotEmpty)
      .firstOrNull;
  final identifier = _identifier(opf, metadata);
  final collection = _collection(metas);
  return EpubInfo(
    title: first('title'),
    authors: all('creator'),
    language: first('language'),
    publisher: first('publisher'),
    published: first('date'),
    identifier: identifier.isbn == null ? identifier.value : null,
    isbn: identifier.isbn,
    description: switch (first('description')) {
      final text? => _clean(text.replaceAll(_markup, ' ')),
      null => null,
    },
    subjects: all('subject'),
    series: collection?.name ?? named('calibre:series'),
    seriesIndex: collection?.index ?? named('calibre:series_index'),
    rights: first('rights'),
    cover: _cover(opf, metas, pathOf),
  );
}

/// The book's own identifier: the one the package names as unique, else
/// the first; and its ISBN when it is one.
({String? value, String? isbn}) _identifier(
  XmlDocument opf,
  XmlElement metadata,
) {
  final unique = opf.rootElement.getAttribute('unique-identifier');
  final ids = [
    for (final element in metadata.descendantElements)
      if (element.localName == 'identifier') element,
  ];
  final chosen =
      ids.where((id) => id.getAttribute('id') == unique).firstOrNull ??
      ids.firstOrNull;
  // An ISBN wherever one is written: the unique id is often a UUID beside it.
  for (final id in [?chosen, ...ids]) {
    final scheme = (id.getAttribute('opf:scheme') ?? id.getAttribute('scheme'))
        ?.toLowerCase();
    final text = _clean(id.innerText);
    final digits = text.replaceAll(_isbnNoise, '');
    final looksLike =
        text.toLowerCase().startsWith('urn:isbn:') ||
        (scheme == 'isbn' && _isbnDigits.hasMatch(digits));
    if (looksLike && _isbnDigits.hasMatch(digits)) {
      return (
        value: chosen == null ? null : _clean(chosen.innerText),
        isbn: digits,
      );
    }
  }
  final value = chosen == null ? null : _clean(chosen.innerText);
  return (value: value == null || value.isEmpty ? null : value, isbn: null);
}

/// EPUB 3's series: a `belongs-to-collection` and the `group-position`
/// that refines it.
({String name, String? index})? _collection(List<XmlElement> metas) {
  for (final meta in metas) {
    if (meta.getAttribute('property') != 'belongs-to-collection') continue;
    final name = _clean(meta.innerText);
    if (name.isEmpty) continue;
    final id = meta.getAttribute('id');
    final position = id == null
        ? null
        : metas
              .where(
                (other) =>
                    other.getAttribute('refines') == '#$id' &&
                    other.getAttribute('property') == 'group-position',
              )
              .map((other) => _clean(other.innerText))
              .where((text) => text.isNotEmpty)
              .firstOrNull;
    return (name: name, index: position);
  }
  return null;
}

/// The cover picture's path: EPUB 3's `cover-image` item, else EPUB 2's
/// `<meta name="cover">` naming one.
String? _cover(
  XmlDocument opf,
  List<XmlElement> metas,
  String? Function(String id) pathOf,
) {
  for (final item in opf.descendantElements) {
    if (item.localName != 'item') continue;
    final properties = (item.getAttribute('properties') ?? '').split(' ');
    if (!properties.contains('cover-image')) continue;
    if (item.getAttribute('id') case final id?) return pathOf(id);
  }
  final id = metas
      .where((meta) => meta.getAttribute('name') == 'cover')
      .map((meta) => meta.getAttribute('content'))
      .nonNulls
      .firstOrNull;
  return id == null ? null : pathOf(id);
}

String _clean(String text) => text.replaceAll(_space, ' ').trim();

final RegExp _space = RegExp(r'\s+');
final RegExp _markup = RegExp('<[^>]*>');
final RegExp _isbnNoise = RegExp(r'urn:isbn:|[\s-]', caseSensitive: false);
final RegExp _isbnDigits = RegExp(r'^(\d{9}[\dXx]|\d{13})$');
