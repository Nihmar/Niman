/// What a card's title shows apart from its chips (#1167): the title without
/// its `#tags` and its `due:` date, which the chips say. The title as
/// written when nothing else would be left.
String cardShownTitle(String title) {
  final shown = title
      .replaceAll(RegExp(r'(?:^|\s)#\S+'), ' ')
      .replaceAll(RegExp(r'(?:^|\s)due:\d{4}-\d{2}-\d{2}(?=\s|$)'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return shown.isEmpty ? title : shown;
}

/// The first line of a card's body that says something: the card's preview.
String? cardPreview(List<String> body) {
  for (final line in body) {
    final text = line.trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

/// [date] as `YYYY-MM-DD`: the form `due:` is written in, whatever the
/// language.
String cardDueText(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  final year = date.year.toString().padLeft(4, '0');
  return '$year-${two(date.month)}-${two(date.day)}';
}
