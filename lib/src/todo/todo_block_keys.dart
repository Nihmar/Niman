/// The keys a `todo` block knows, and the nearest of them to a mistyped one
/// (#1152).
library;

/// The keys of a `todo` block: what each line is written as before its colon.
const List<String> todoBlockKeys = <String>[
  'link',
  'project',
  'context',
  'tag',
  'due',
  'priority',
  'done',
  'sort',
];

/// The key [typed] most likely meant, or null when none is near it.
///
/// A key written short (`prio`) names the one key it starts; otherwise the
/// nearest one by edit distance, two edits at most and fewer than the word
/// has letters, so `tags` is `tag` and `x` is nothing.
String? nearestTodoBlockKey(String typed) {
  final word = typed.toLowerCase();
  if (word.length >= 2) {
    final starts = <String>[
      for (final key in todoBlockKeys)
        if (key.startsWith(word)) key,
    ];
    if (starts.length == 1) return starts.single;
  }
  String? best;
  var bestDistance = 3;
  for (final key in todoBlockKeys) {
    final distance = _distance(word, key);
    if (distance < bestDistance && distance < word.length) {
      best = key;
      bestDistance = distance;
    }
  }
  return best;
}

/// The edit distance between [a] and [b]: insertions, deletions and
/// substitutions.
int _distance(String a, String b) {
  var row = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final next = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final same = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var best = row[j - 1] + same;
      if (row[j] + 1 < best) best = row[j] + 1;
      if (next[j - 1] + 1 < best) best = next[j - 1] + 1;
      next[j] = best;
    }
    row = next;
  }
  return row[b.length];
}
