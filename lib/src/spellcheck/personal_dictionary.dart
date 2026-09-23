/// The library's personal dictionary (issue #60): the words the writer has
/// added by right-click, one per line at `<library>/.niman/dictionary.txt`,
/// next to `settings.json`.
///
/// Layered on top of the system dictionaries: a word in it is always
/// correct, whatever the hunspell engines say. Words are read
/// case-insensitively but stored as typed, so the file keeps the first form
/// the writer typed. The file survives restarts and stays with the library
/// — per-library dictionaries on purpose, so different libraries can carry
/// different vocabularies.
///
/// The words are few (one per right-click), so the whole file lives in
/// memory as the typed words plus their lowercase lookup keys.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/logging.dart';
import 'package:path/path.dart' as p;

/// The library's personal words, layered in front of the spell engines.
final class PersonalDictionary extends ChangeNotifier {
  new _(this._file);

  /// Reads the library's dictionary file, or starts empty when it is
  /// missing, unreadable or malformed — a hostile file must never take the
  /// app down (the settings file's rule).
  static Future<PersonalDictionary> open(String libraryPath) async {
    final file = File(p.join(libraryPath, '.niman', 'dictionary.txt'));
    final dictionary = PersonalDictionary._(file);
    await dictionary._load();
    return dictionary;
  }

  final File _file;
  final Set<String> _words = <String>{};
  final Set<String> _lowercase = <String>{};
  bool _disposed = false;

  /// The file the words live in.
  String get path => _file.path;

  /// How many words are in it.
  int get length => _words.length;

  /// Whether [word] is in it (case-insensitive).
  bool contains(String word) =>
      !_disposed && _lowercase.contains(word.toLowerCase());

  /// Adds [word]: the disk append completes first, then the word is
  /// remembered and listeners are told — memory and disk commit together,
  /// so a failed write is not a word that survives only in RAM.
  ///
  /// A word already in it (whatever the case) is a no-op; the file keeps
  /// the first form the writer typed.
  Future<void> add(String word) async {
    final key = word.toLowerCase();
    if (_disposed || key.isEmpty || _lowercase.contains(key)) return;
    await _append(word);
    _words.add(word);
    _lowercase.add(key);
    notifyListeners();
  }

  Future<void> _append(String word) async {
    try {
      await _file.parent.create(recursive: true);
      var existing = '';
      if (_file.existsSync()) existing = await _file.readAsString();
      final prefix = existing.isEmpty || existing.endsWith('\n') ? '' : '\n';
      await _file.writeAsString('$prefix$word\n', mode: FileMode.append);
    } on Object catch (error) {
      const AppLogger(name: 'spellcheck')
          .warning('personal dictionary write failed: $error');
    }
  }

  /// Reads the file again, after something other than [add] changed it
  /// (a sync brought the words added on another device), and tells the
  /// listeners.
  Future<void> reload() async {
    if (_disposed) return;
    _words.clear();
    _lowercase.clear();
    await _load();
    if (!_disposed) notifyListeners();
  }

  Future<void> _load() async {
    try {
      final raw = await _file.readAsString();
      for (final line in raw.split('\n')) {
        final word = line.trim();
        if (word.isEmpty) continue;
        _words.add(word);
        _lowercase.add(word.toLowerCase());
      }
    } on Object catch (error) {
      const AppLogger(name: 'spellcheck')
          .warning('personal dictionary read failed: $error');
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}
