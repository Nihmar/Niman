/// A cache that holds at most `capacity` entries and lets go of the one asked
/// for least recently when it is full.
///
/// The one bounded cache the app's lazy readers share: what a wikilink panel
/// keeps of a note's headings, what a preview card keeps of a note's first
/// bytes, what a list of the notes that link to one note keeps of each line.
/// A hit counts as a use, so what is being scrolled through or hovered over
/// again stays and what was left behind goes.
library;

import 'dart:collection';

/// A least-recently-used cache of at most [capacity] entries.
final class LruCache<K, V> {
  /// An empty cache that holds [capacity] entries (at least one).
  new(this.capacity) : assert(capacity > 0, 'a cache holds at least one entry');

  /// How many entries are kept at most.
  final int capacity;

  // A LinkedHashMap iterates in insertion order: the first key is the least
  // recently used, and a use moves its key to the end.
  final LinkedHashMap<K, V> _entries = LinkedHashMap<K, V>();

  /// How many entries are held.
  int get length => _entries.length;

  /// Whether nothing is held.
  bool get isEmpty => _entries.isEmpty;

  /// The entry for [key], which becomes the most recently used; null when
  /// there is none.
  V? operator [](K key) {
    final value = _entries.remove(key);
    if (value == null) return null;
    _entries[key] = value;
    return value;
  }

  /// Keeps [value] for [key] as the most recently used entry, letting go of
  /// the least recently used one if the cache is full.
  void operator []=(K key, V value) {
    _entries.remove(key);
    _entries[key] = value;
    if (_entries.length > capacity) _entries.remove(_entries.keys.first);
  }

  /// Lets go of [key]'s entry and returns it, or null.
  V? remove(K key) => _entries.remove(key);

  /// Lets go of everything.
  void clear() => _entries.clear();
}
