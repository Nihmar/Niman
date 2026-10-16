import 'package:flutter/foundation.dart';
import 'package:niman/src/workspace/note_memento.dart';

/// Where the notes that are not open were last left (#1076): a bounded,
/// least-recently-used store of mementos by path.
///
/// A tab carries its own memento while it is open. Once it is gone — closed,
/// replaced by the note a click opened in its place, evicted to keep a
/// phone's open notes in bounds — what it knew goes here, and a note that
/// opens again, in a new tab or in the place of another, is seeded from it
/// instead of starting at the top. It is part of the saved workspace, so the
/// places outlive a restart.
@immutable
final class NotePlaces {
  /// The places the entries say, oldest first.
  const new([this._entries = const <String, NoteMemento>{}]);

  /// Reads a stored form; anything malformed reads as absent.
  factory fromJson(Object? json) {
    if (json is! List) return const NotePlaces();
    final entries = <String, NoteMemento>{};
    for (final raw in json) {
      if (raw is! Map) continue;
      final path = raw['path'];
      if (path is! String || path.isEmpty) continue;
      final memento = NoteMemento.fromJson(raw['memento']);
      if (!memento.isEmpty) entries[path] = memento;
    }
    return NotePlaces(_trimmed(entries));
  }

  /// How many notes' places are kept: the oldest is forgotten past it.
  static const int capacity = 200;

  /// Oldest first (insertion order), at most [capacity] of them.
  final Map<String, NoteMemento> _entries;

  /// How many places are kept.
  int get length => _entries.length;

  /// The paths with a place, the least recently left first.
  Iterable<String> get paths => _entries.keys;

  /// Where the note at [path] was left, or null.
  NoteMemento? operator [](String path) => _entries[path];

  /// [memento] as where [path] was last left: the most recent place. One
  /// that knows no scroll keeps the scroll the store had ([NoteMemento
  /// .keepingScrollOf]); one that remembers nothing forgets the note.
  NotePlaces remember(String path, NoteMemento memento) {
    final before = _entries[path];
    final next = before == null ? memento : memento.keepingScrollOf(before);
    final entries = {..._entries}..remove(path);
    if (!next.isEmpty) entries[path] = next;
    return NotePlaces(_trimmed(entries));
  }

  /// The places of the notes at [from], or under it when it is a folder,
  /// moved to [to].
  NotePlaces moved(String from, String to) {
    if (from == to) return this;
    final prefix = '$from/';
    var changed = false;
    final entries = <String, NoteMemento>{};
    _entries.forEach((path, memento) {
      if (path == from) {
        entries[to] = memento;
        changed = true;
      } else if (path.startsWith(prefix)) {
        entries['$to/${path.substring(prefix.length)}'] = memento;
        changed = true;
      } else {
        entries[path] = memento;
      }
    });
    return changed ? NotePlaces(_trimmed(entries)) : this;
  }

  /// Forgets the notes at [paths], and under them when one is a folder.
  NotePlaces forgetting(Set<String> paths) {
    if (paths.isEmpty) return this;
    final entries = <String, NoteMemento>{
      for (final entry in _entries.entries)
        if (!paths.any(
          (path) => entry.key == path || entry.key.startsWith('$path/'),
        ))
          entry.key: entry.value,
    };
    return entries.length == _entries.length ? this : NotePlaces(entries);
  }

  /// The stored form, oldest first.
  List<Map<String, Object>> toJson() => [
    for (final entry in _entries.entries)
      {'path': entry.key, 'memento': entry.value.toJson()},
  ];

  static Map<String, NoteMemento> _trimmed(Map<String, NoteMemento> entries) {
    if (entries.length <= capacity) return entries;
    final keep = entries.keys.skip(entries.length - capacity);
    return {for (final path in keep) path: entries[path]!};
  }

  @override
  bool operator ==(Object other) =>
      other is NotePlaces &&
      listEquals(other._entries.keys.toList(), _entries.keys.toList()) &&
      mapEquals(other._entries, _entries);

  @override
  int get hashCode => Object.hashAll(
    _entries.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}
