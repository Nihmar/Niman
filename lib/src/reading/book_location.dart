/// A place in a book or a PDF (#281): where the reader was left, and what
/// links into a document and annotations point with.
///
/// Said in the document's own terms, never in pixels or in lines of the
/// whole book: a PDF by its page, an EPUB by its chapter and a line of that
/// chapter. The book is Markdown converted from its XHTML, so a change to
/// the conversion moves its lines; kept per chapter, such a change moves
/// the place within one chapter at most.
library;

import 'package:meta/meta.dart';

/// Where a reader is in a document.
@immutable
sealed class BookLocation {
  const new();

  /// The location [json] spells, or null when it spells none: a missing
  /// field, a wrong type, a page before the first.
  static BookLocation? fromJson(Object? json) {
    if (json is! Map) return null;
    final fraction = _fraction(json['fraction']);
    final page = json['page'];
    if (page is int) {
      return page < 1 ? null : PdfLocation(page: page, fraction: fraction);
    }
    final chapter = json['chapter'];
    final line = json['line'];
    if (chapter is String && chapter.isNotEmpty && line is int && line >= 0) {
      return EpubLocation(chapter: chapter, line: line, fraction: fraction);
    }
    return null;
  }

  /// The location as JSON, which [fromJson] reads back.
  Map<String, Object?> toJson();

  /// Whether this is where [other] is, give or take a view settling on
  /// it.
  bool isNear(BookLocation? other);

  static double _fraction(Object? value) =>
      value is num ? value.toDouble().clamp(0.0, 1.0) : 0.0;
}

/// A place in a PDF: its page, and how far down it the view's top is.
final class PdfLocation extends BookLocation {
  /// The place [fraction] of the way down [page], counted from 1.
  const new({required this.page, this.fraction = 0});

  /// The page, the first being 1.
  final int page;

  /// How far down the page: 0 at its top, 1 at its bottom.
  final double fraction;

  @override
  Map<String, Object?> toJson() => {'page': page, 'fraction': fraction};

  @override
  bool isNear(BookLocation? other) =>
      other is PdfLocation &&
      other.page == page &&
      (other.fraction - fraction).abs() < 0.02;

  @override
  bool operator ==(Object other) =>
      other is PdfLocation && other.page == page && other.fraction == fraction;

  @override
  int get hashCode => Object.hash(page, fraction);

  @override
  String toString() => 'PdfLocation($page, $fraction)';
}

/// A place in an EPUB: a chapter, a line of the chapter's text, and how far
/// into that line.
final class EpubLocation extends BookLocation {
  /// The place [fraction] into [line] of [chapter].
  const new({required this.chapter, required this.line, this.fraction = 0});

  /// The chapter: its path in the book's archive, as the spine names it.
  final String chapter;

  /// The line of the chapter's text, the first being 0.
  final int line;

  /// How far into the line, a block's lines sharing its height: 0 at its
  /// top, towards 1 at its bottom.
  final double fraction;

  @override
  Map<String, Object?> toJson() => {
    'chapter': chapter,
    'line': line,
    'fraction': fraction,
  };

  @override
  bool isNear(BookLocation? other) =>
      other is EpubLocation &&
      other.chapter == chapter &&
      other.line == line &&
      (other.fraction - fraction).abs() < 0.05;

  @override
  bool operator ==(Object other) =>
      other is EpubLocation &&
      other.chapter == chapter &&
      other.line == line &&
      other.fraction == fraction;

  @override
  int get hashCode => Object.hash(chapter, line, fraction);

  @override
  String toString() => 'EpubLocation($chapter, $line, $fraction)';
}
