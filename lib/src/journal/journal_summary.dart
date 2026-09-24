/// An entry's first words, for the journal's recent list (#7): what the
/// day was about, without opening it.
library;

/// The first line of [text] that says something: past the frontmatter,
/// headings and empty lines, with its list and task markers taken off and
/// cut at [max] characters. Empty when the entry holds nothing else.
String journalSummary(String text, {int max = 80}) {
  final lines = text.split('\n');
  var i = 0;
  if (lines.isNotEmpty && lines.first.trim() == '---') {
    i = 1;
    while (i < lines.length && lines[i].trim() != '---') {
      i++;
    }
    i++;
  }
  for (; i < lines.length; i++) {
    var line = lines[i].trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    line = line
        .replaceFirst(RegExp(r'^([-*+]|\d+[.)])\s+'), '')
        .replaceFirst(RegExp(r'^\[[ xX]\]\s+'), '')
        .replaceFirst(RegExp(r'^>\s*'), '')
        .trim();
    if (line.isEmpty) continue;
    return line.length <= max ? line : '${line.substring(0, max - 1)}…';
  }
  return '';
}
