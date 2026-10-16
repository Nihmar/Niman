import 'package:flutter/widgets.dart';

/// One key per mounted note, so a tab moved to the other pane takes its
/// editor along — undo and all — instead of starting a new one, and so does
/// a note whose file is renamed or moved (#1076).
final class NoteEditorKeys {
  final Map<String, GlobalKey> _keys = {};

  /// Where each note renamed or moved since the last frame was before, by
  /// its path now.
  final Map<String, String> _movedFrom = {};

  /// The key of the editor of the note at [path], made on first use.
  GlobalKey keyOf(String path) => _keys.putIfAbsent(path, GlobalKey.new);

  /// The key of the editor of the note at [path], or null if it has none.
  GlobalKey? operator [](String path) => _keys[path];

  /// Forgets the keys of every note not in [mounted].
  void keepOnly(Set<String> mounted) =>
      _keys.removeWhere((path, _) => !mounted.contains(path));

  /// [from] is now at [to], a note or a folder with notes under it: the
  /// editors follow, and are told where they came from until [settle].
  void moved(String from, String to) {
    final prefix = '$from/';
    for (final path in [..._keys.keys]) {
      final String? target;
      if (path == from) {
        target = to;
      } else if (path.startsWith(prefix)) {
        target = '$to/${path.substring(prefix.length)}';
      } else {
        continue;
      }
      _keys[target] = _keys.remove(path)!;
      _movedFrom[target] = path;
    }
  }

  /// Where the note at [path] was a moment ago, if it was moved since the
  /// last [settle].
  String? movedFrom(String path) => _movedFrom[path];

  /// A frame has shown the moved notes: they are where they are.
  void settle() => _movedFrom.clear();
}
