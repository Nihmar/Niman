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

import 'package:niman/src/core/files.dart';
import 'package:niman/src/markdown/text_escape.dart';
import 'package:niman/src/ocr/ocr_line.dart';
import 'package:path/path.dart' as p;

/// The frontmatter key naming the recognized file.
const String ocrSidecarKey = 'ocr';

/// The sidecar's note name for the file [fileName], without `.md`:
/// the file's name without its extension, then `.ocr` — as a note is
/// named ([sanitizeName]), so `Scan 10:30.pdf` gets `Scan 1030.ocr`.
String ocrSidecarName(String fileName) =>
    _noteName('${p.posix.basenameWithoutExtension(fileName)}.ocr');

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
  final head =
      '---\n'
      '$ocrSidecarKey: ${_link(fileName)}\n'
      '$_languageKey: $languages\n'
      '$_recognizedKey: ${_day(date)}\n'
      '---\n';
  return _join(head, pages, paged: paged);
}

/// [existing] with the sections of [pages] replaced, or added in page
/// order, and every other section kept as it is — a page recognized
/// again leaves the corrections made by hand on the others. A picture's
/// sidecar ([paged] false) keeps its frontmatter and takes the new text.
/// Either way the frontmatter's `language:` and `recognized:` become
/// this recognition's, [languages] on [date], and every other key stays.
String mergeOcrSidecar(
  String existing,
  Map<int, List<OcrLine>> pages, {
  required bool paged,
  required String languages,
  required DateTime date,
}) {
  final text = _restamped(existing.replaceAll('\r\n', '\n'), {
    _languageKey: languages,
    _recognizedKey: _day(date),
  });
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
/// name's; each as a note is named, so a re-run finds the note the first
/// run created.
List<String> ocrSidecarNames(String fileName) => [
  ocrSidecarName(fileName),
  _noteName('${p.posix.basename(fileName)}.ocr'),
];

/// Whether [sidecarText] is the sidecar of the file [fileName]: its
/// frontmatter links to it, as [ocrSidecarText] writes the link.
bool isOcrSidecarOf(String sidecarText, String fileName) =>
    sidecarText.contains(_wikilink(fileName));

/// The frontmatter's link to the file [fileName], a quoted YAML string.
String _link(String fileName) => '"${_wikilink(fileName)}"';

/// The wikilink to the file [fileName], its `\` and `"` escaped as the
/// quoted string it stands in holds them.
String _wikilink(String fileName) {
  final name = p.posix.basename(fileName);
  return '[[${name.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}]]';
}

/// [name] as `createNote` names the note.
String _noteName(String name) => sanitizeName(name, fallback: defaultNoteName);

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

const String _languageKey = 'language';
const String _recognizedKey = 'recognized';

/// [date] as `2026-10-07`.
String _day(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// [text] with each of [values]' top-level keys in its frontmatter set to
/// its value — a key's indented or listed continuation lines replaced
/// with it, a missing key added at the end; [text] as it is when it has
/// no frontmatter.
String _restamped(String text, Map<String, String> values) {
  final front = _frontmatterOf(text);
  if (front.isEmpty) return text;
  final lines = front.split('\n');
  var close = lines.indexWhere((line) => line.startsWith('---'), 1);
  for (final MapEntry(:key, :value) in values.entries) {
    final at = lines.indexWhere((line) => line.startsWith('$key:'), 1);
    if (at < 0 || at >= close) {
      lines.insert(close++, '$key: $value');
      continue;
    }
    var end = at + 1;
    while (end < close && _continuation.hasMatch(lines[end])) {
      end++;
    }
    lines.replaceRange(at, end, ['$key: $value']);
    close -= end - at - 1;
  }
  return lines.join('\n') + text.substring(front.length);
}

/// A line that belongs to the key above it: indented, or a list item.
final RegExp _continuation = RegExp(r'^([ \t]|- |-$)');

/// The frontmatter block at the start of [text], or nothing.
String _frontmatterOf(String text) {
  if (!text.startsWith('---\n')) return '';
  final end = text.indexOf('\n---', 4);
  if (end < 0) return '';
  final close = text.indexOf('\n', end + 4);
  return text.substring(0, close < 0 ? text.length : close + 1);
}
