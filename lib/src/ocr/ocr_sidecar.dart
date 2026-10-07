/// The note a recognition writes next to its file (#594): a real note,
/// `Contratto 2019 (scan).ocr.md` beside `Contratto 2019 (scan).pdf`,
/// that search indexes and a hand corrects like any other.
///
/// ```markdown
/// ---
/// ocr: "[[Contratto 2019 (scan).pdf]]"
/// language: ita+eng
/// recognized: 2026-10-07
/// ---
///
/// ## p. 1
///
/// First line of a paragraph <!-- ocr 0.120 0.410 0.860 0.440 -->
/// its second line <!-- ocr 0.120 0.445 0.858 0.474 -->
/// ```
///
/// A PDF gets one `## p. N` section per page; a picture is one page, with
/// no heading. Each line ends in an HTML comment holding its box on the
/// page, in fractions of the page's width and height: invisible in every
/// preview, and where the scan finds the line again (#596). The comment
/// ends the line rather than sitting under it, so one source line is one
/// recognized line and a paragraph's lines still read as one paragraph.
/// The text is escaped as a PDF's quoted text is: a `#` on a scan never
/// becomes a tag.
library;

import 'package:niman/src/markdown/text_escape.dart';
import 'package:niman/src/ocr/ocr_line.dart';
import 'package:path/path.dart' as p;

/// The frontmatter key naming the recognized file.
const String ocrSidecarKey = 'ocr';

/// The sidecar's note name for the file [fileName], without `.md`:
/// the file's name without its extension, then `.ocr`.
String ocrSidecarName(String fileName) =>
    '${p.basenameWithoutExtension(fileName)}.ocr';

/// The whole sidecar of the file [fileName], read in [languages]
/// (`ita+eng`) on [date]: [pages] by page number, each under its heading
/// when [paged] (a PDF), the one page bare otherwise (a picture).
String ocrSidecarText({
  required String fileName,
  required String languages,
  required DateTime date,
  required Map<int, List<OcrLine>> pages,
  required bool paged,
}) {
  final day =
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
  final name = fileName.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  final head =
      '---\n'
      '$ocrSidecarKey: "[[$name]]"\n'
      'language: $languages\n'
      'recognized: $day\n'
      '---\n';
  return _join(head, pages, paged: paged);
}

/// [existing] with the sections of [pages] replaced, or added in page
/// order, and every other section kept as it is — a page recognized
/// again leaves the corrections made by hand on the others. A picture's
/// sidecar ([paged] false) keeps its frontmatter and takes the new text.
String mergeOcrSidecar(
  String existing,
  Map<int, List<OcrLine>> pages, {
  required bool paged,
}) {
  final text = existing.replaceAll('\r\n', '\n');
  if (!paged) return _join(_frontmatterOf(text), pages, paged: false);
  final headings = _pageHeading.allMatches(text).toList();
  final head = headings.isEmpty
      ? text
      : text.substring(0, headings.first.start);
  final sections = <int, String>{
    for (final (index, match) in headings.indexed)
      int.parse(match.group(1)!): text
          .substring(
            match.start,
            index + 1 < headings.length
                ? headings[index + 1].start
                : text.length,
          )
          .trimRight(),
  };
  for (final MapEntry(key: page, value: lines) in pages.entries) {
    sections[page] = _section(page, lines);
  }
  final ordered = sections.keys.toList()..sort();
  return '${head.trimRight()}\n\n'
      '${[for (final page in ordered) sections[page]].join('\n\n')}\n';
}

/// The names a sidecar of the file [fileName] may have, without `.md`:
/// the stem's, then — when another file of that stem owns it — the full
/// name's.
List<String> ocrSidecarNames(String fileName) => [
  ocrSidecarName(fileName),
  '${p.basename(fileName)}.ocr',
];

/// Whether [sidecarText] is the sidecar of the file [fileName]: its
/// frontmatter links to it.
bool isOcrSidecarOf(String sidecarText, String fileName) =>
    sidecarText.contains('[[${p.basename(fileName)}]]');

/// The recognized text of [sidecarText] as plain text, for a clipboard:
/// no frontmatter, no page headings, no position comments, no escapes.
String ocrSidecarPlainText(String sidecarText) {
  final text = sidecarText.replaceAll('\r\n', '\n');
  final body = text.substring(_frontmatterOf(text).length);
  return body
      .split('\n')
      .where((line) => !_pageHeading.hasMatch(line))
      .map(
        (line) => line
            .replaceAll(_position, '')
            .replaceAllMapped(_escape, (m) => m.group(1)!),
      )
      .join('\n')
      .replaceAll(RegExp('\n{3,}'), '\n\n')
      .trim();
}

/// A line's position comment, with the space before it.
final RegExp _position = RegExp(' ?<!-- ocr [0-9. ]+-->');

/// A backslash escape: the character it keeps from being syntax.
final RegExp _escape = RegExp(r'\\([\\`*_\[\]<>#$|~=^&!.)+-])');

/// How many words [pages] hold.
int ocrWordCount(Map<int, List<OcrLine>> pages) => [
  for (final lines in pages.values)
    for (final line in lines)
      line.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
].fold(0, (sum, n) => sum + n);

/// `## p. 3`, at a line's start.
final RegExp _pageHeading = RegExp(r'^## p\. (\d+)[ \t]*$', multiLine: true);

String _join(
  String head,
  Map<int, List<OcrLine>> pages, {
  required bool paged,
}) {
  final ordered = pages.keys.toList()..sort();
  final body = paged
      ? [for (final page in ordered) _section(page, pages[page]!)].join('\n\n')
      : _body([for (final page in ordered) ...pages[page]!]);
  return '${head.trimRight()}\n\n${body.isEmpty ? '' : '$body\n'}';
}

String _section(int page, List<OcrLine> lines) {
  final body = _body(lines);
  return body.isEmpty ? '## p. $page' : '## p. $page\n\n$body';
}

/// One source line per recognized line, a blank line between paragraphs.
String _body(List<OcrLine> lines) {
  final out = StringBuffer();
  for (final (index, line) in lines.indexed) {
    if (index > 0) out.write(line.paragraphStart ? '\n\n' : '\n');
    out
      ..write(escapeMarkdownLineStart(escapeMarkdownText(line.text)))
      ..write(' <!-- ocr ${_f(line.left)} ${_f(line.top)} ')
      ..write('${_f(line.right)} ${_f(line.bottom)} -->');
  }
  return out.toString();
}

String _f(double fraction) => fraction.clamp(0, 1).toStringAsFixed(3);

/// The frontmatter block at the start of [text], or nothing.
String _frontmatterOf(String text) {
  if (!text.startsWith('---\n')) return '';
  final end = text.indexOf('\n---', 4);
  if (end < 0) return '';
  final close = text.indexOf('\n', end + 4);
  return text.substring(0, close < 0 ? text.length : close + 1);
}
