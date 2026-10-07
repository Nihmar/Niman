/// The recognized lines of a sidecar read back with their places on the
/// scan (#596): what the scan draws, selects and highlights, and which
/// pages a hand edit left without them.
library;

import 'package:niman/src/ocr/ocr_language.dart';

/// One line of a sidecar with its place on its page.
typedef OcrPlacedLine = ({
  /// The page, 1-based (a picture's is 1).
  int page,

  /// The line's index in the sidecar's text.
  int sourceLine,

  /// The text, as the read view draws it: no comment, no escapes.
  String text,

  /// The box on the page, fractions of its width and height.
  ({double left, double top, double right, double bottom}) box,

  /// Where [text] sits in its paragraph's drawn text, for a highlight of
  /// the line alone.
  ({int start, int end}) chars,
});

/// A sidecar's lines with their places, and the pages where some lost
/// theirs: a line joined or split by hand has no comment, or two.
typedef OcrPlacedLines = ({
  List<OcrPlacedLine> lines,
  Map<int, int> lostByPage,
  List<OcrLanguage> languages,
});

/// Reads [text], a sidecar, back into its placed lines: pages from the
/// `## p. N` headings (a picture's sidecar has none: page 1).
OcrPlacedLines readOcrPlacedLines(String text) {
  final rows = text.replaceAll('\r\n', '\n').split('\n');
  final lines = <OcrPlacedLine>[];
  final lost = <int, int>{};
  final languages = <OcrLanguage>[];
  var index = 0;
  // The frontmatter: only its language matters here.
  if (rows.isNotEmpty && rows.first == '---') {
    for (index = 1; index < rows.length && rows[index] != '---'; index++) {
      final match = _language.firstMatch(rows[index]);
      if (match == null) continue;
      for (final code in match[1]!.split('+')) {
        if (ocrLanguageByCode(code.trim()) case final language?) {
          languages.add(language);
        }
      }
    }
    index++;
  }
  var page = 1;
  var offset = 0;
  for (; index < rows.length; index++) {
    final row = rows[index];
    final heading = _heading.firstMatch(row);
    if (heading != null) {
      page = int.parse(heading[1]!);
      offset = 0;
      continue;
    }
    if (row.trim().isEmpty) {
      offset = 0;
      continue;
    }
    final places = _place.allMatches(row).toList();
    final drawn = _unescape(row.replaceAll(_comment, ''));
    if (places.length == 1) {
      final values = [for (var i = 1; i <= 4; i++) double.parse(places[0][i]!)];
      lines.add((
        page: page,
        sourceLine: index,
        text: drawn.trimRight(),
        box: (
          left: values[0],
          top: values[1],
          right: values[2],
          bottom: values[3],
        ),
        chars: (start: offset, end: offset + drawn.trimRight().length),
      ));
    } else {
      lost[page] = (lost[page] ?? 0) + 1;
    }
    // A soft break between a paragraph's lines is drawn as one.
    offset += drawn.length + 1;
  }
  return (lines: lines, lostByPage: lost, languages: languages);
}

final RegExp _language = RegExp(r'^language:\s*(\S+)\s*$');
final RegExp _heading = RegExp(r'^## p\. (\d+)[ \t]*$');
final RegExp _place = RegExp(
  '<!-- ocr ([0-9.]+) ([0-9.]+) ([0-9.]+) ([0-9.]+) -->',
);
final RegExp _comment = RegExp('<!--.*?-->');
final RegExp _escape = RegExp(r'\\([\\`*_\[\]<>#$|~=^&!.)+-])');

String _unescape(String text) =>
    text.replaceAllMapped(_escape, (match) => match.group(1)!);
