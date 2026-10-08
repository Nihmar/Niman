/// A quote shared from a web page (#531), as a note holds it: the passage
/// as a block quote, its words escaped so they stay words, and the page it
/// came from under it — as a passage quoted from a book or a PDF is
/// written (#284).
library;

import 'package:niman/src/capture/capture_note.dart';
import 'package:niman/src/capture/page_reading.dart';
import 'package:niman/src/markdown/text_escape.dart';

/// [quote], from the page at [url] titled [title], ending in a newline.
String quoteMarkdown(String quote, Uri url, {String? title}) {
  final out = StringBuffer();
  final lines = quote.trim().split(RegExp(r'\r?\n'));
  for (final line in lines) {
    final text = line.trim();
    out.writeln(
      text.isEmpty
          ? '>'
          : '> ${escapeMarkdownLineStart(escapeMarkdownText(text))}',
    );
  }
  final name = title?.trim();
  final label = escapeMarkdownText(
    name == null || name.isEmpty ? url.host : name,
  );
  out.writeln('> — [$label](<$url>)');
  return out.toString();
}

/// A new note of [quote] alone: the frontmatter a captured page has —
/// `source`, `captured`, `tags` — then the quote.
String quoteNote(
  String quote,
  Uri url, {
  required DateTime captured,
  String? title,
  List<String> tags = const [],
}) {
  final page = PageReading(url: url, title: title ?? url.host);
  return '${captureFrontmatter(page, captured, tags)}\n'
      '${quoteMarkdown(quote, url, title: title)}';
}
