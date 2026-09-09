import 'dart:convert';
import 'dart:io';

import 'package:copist/src/core/files.dart';
import 'package:copist/src/core/settings/library_settings.dart'
    show defaultListFolder;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// The per-library settings, stored in the library folder itself as
/// `<library>/.copist/settings.json` (T-ML-01).
///
/// A library is a self-describing folder: these settings travel with it,
/// survive a sync, and can be read and fixed in any editor — the same
/// bargain the notes get. Keys this build does not understand are preserved
/// on read and written back untouched, so a newer build's settings survive
/// an older one opening the library.
@immutable
final class LibraryConfig {
  /// Creates a library config. [extra] holds keys this build does not
  /// understand, preserved verbatim.
  const new({
    required this.trashEnabled,
    required this.historyVersions,
    required this.quickNotePath,
    required this.listNoteFolder,
    this.extra = const {},
  });

  /// Parses the raw `settings.json` object into a config.
  ///
  /// Wrong-type known keys fall back to their defaults; every other key
  /// goes into [LibraryConfig.extra].
  factory fromJsonMap(Map<String, Object?> json) {
    final extra = <String, Object?>{};
    for (final entry in json.entries) {
      if (!_knownKeys.contains(entry.key)) {
        extra[entry.key] = entry.value;
      }
    }
    final trash = json['trashEnabled'];
    final versions = json['historyVersions'];
    final quick = json['quickNotePath'];
    final folder = json['listNoteFolder'];
    return LibraryConfig(
      trashEnabled: switch (trash) {
        final bool enabled => enabled,
        _ => true,
      },
      historyVersions: switch (versions) {
        final num count => count.toInt(),
        _ => 10,
      },
      quickNotePath: quick is String ? quick : null,
      listNoteFolder: folder is String ? folder : defaultListFolder,
      extra: extra,
    );
  }

  /// The settings of a fresh library: trash enabled, 10 history versions,
  /// the default quick note at the root, list notes in `Lists`.
  static const LibraryConfig defaults = LibraryConfig(
    trashEnabled: true,
    historyVersions: 10,
    quickNotePath: null,
    listNoteFolder: defaultListFolder,
  );

  /// Whether deletes move notes into `.trash/` (default true).
  final bool trashEnabled;

  /// The number of kept `.history/` versions (default 10).
  final int historyVersions;

  /// The user-chosen quick note (library-relative path), or null when the
  /// default `Quick note.md` at the library root is used.
  final String? quickNotePath;

  /// The folder (library-relative) holding the list notes.
  final String listNoteFolder;

  /// Keys this build does not understand, preserved verbatim.
  final Map<String, Object?> extra;

  /// A copy with the given fields replaced.
  LibraryConfig copyWith({
    bool? trashEnabled,
    int? historyVersions,
    String? quickNotePath,
    bool clearQuickNotePath = false,
    String? listNoteFolder,
  }) {
    return LibraryConfig(
      trashEnabled: trashEnabled ?? this.trashEnabled,
      historyVersions: historyVersions ?? this.historyVersions,
      quickNotePath: clearQuickNotePath
          ? null
          : quickNotePath ?? this.quickNotePath,
      listNoteFolder: listNoteFolder ?? this.listNoteFolder,
      extra: extra,
    );
  }

  static const _knownKeys = {
    'trashEnabled',
    'historyVersions',
    'quickNotePath',
    'listNoteFolder',
  };

  /// The JSON object to write: the known keys (a null quick note is
  /// omitted) followed by the preserved unknown keys.
  ///
  /// A known key found in [extra] is dropped rather than written. It
  /// cannot get there through [LibraryConfig.fromJsonMap], which filters
  /// the known ones
  /// out, but a config built by hand could carry one, and an `addAll`
  /// would then let it overwrite the typed field it duplicates. The typed
  /// field is the authority; this makes that true by construction instead
  /// of by the caller's care.
  Map<String, Object?> toJsonMap() {
    final json = <String, Object?>{
      'trashEnabled': trashEnabled,
      'historyVersions': historyVersions,
      'listNoteFolder': listNoteFolder,
    };
    if (quickNotePath != null) {
      json['quickNotePath'] = quickNotePath;
    }
    for (final entry in extra.entries) {
      if (_knownKeys.contains(entry.key)) continue;
      json[entry.key] = entry.value;
    }
    return json;
  }

  /// Deep-compares two (small) JSON values, recursing into maps and lists.
  bool _deepEquals(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a is Map<String, Object?> && b is Map<String, Object?>) {
      if (a.length != b.length) return false;
      for (final entry in a.entries) {
        if (!b.containsKey(entry.key) ||
            !_deepEquals(b[entry.key], entry.value)) {
          return false;
        }
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  /// A stable hash for a (possibly nested) JSON value.
  int _stableHash(Object? v) {
    if (v is Map<String, Object?>) {
      final keys = v.keys.toList()..sort();
      final parts = <Object?>[];
      for (final key in keys) {
        parts
          ..add(key)
          ..add(_stableHash(v[key]));
      }
      return Object.hashAll(parts);
    }
    if (v is List) return Object.hashAll(v);
    return v.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LibraryConfig) return false;
    return trashEnabled == other.trashEnabled &&
        historyVersions == other.historyVersions &&
        quickNotePath == other.quickNotePath &&
        listNoteFolder == other.listNoteFolder &&
        _deepEquals(extra, other.extra);
  }

  /// Hashed over [toJsonMap], which is the same filtered view `==`
  /// compares. The spread this replaced had the shadowing problem too: a
  /// known key in [extra] displaced the typed field it duplicates, so two
  /// configs that compare equal could hash differently.
  @override
  int get hashCode => _stableHash(toJsonMap());
}

/// The reader/writer for one library's `.copist/settings.json`.
///
/// Reading a missing, unreadable or malformed file yields
/// [LibraryConfig.defaults] rather than throwing: the settings file is
/// user-editable and must never take the app down. Writing is atomic
/// (temp file + rename, same as a note), so a reader never observes a
/// partial write.
final class LibraryConfigStore {
  /// Creates a store for the library at its absolute path.
  new(this._libraryPath);

  final String _libraryPath;

  /// The settings file: `<library>/.copist/settings.json`.
  File get file => File(p.join(_libraryPath, '.copist', 'settings.json'));

  /// Reads the library's settings; defaults when the file is missing,
  /// unreadable or malformed.
  Future<LibraryConfig> read() async {
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return LibraryConfig.defaults;
      }
      // jsonDecode yields `Map<String, dynamic>`; bridge to the typed view.
      final json = <String, Object?>{
        for (final entry in decoded.entries) entry.key.toString(): entry.value,
      };
      return LibraryConfig.fromJsonMap(json);
    } on Object catch (_) {
      return LibraryConfig.defaults;
    }
  }

  /// Writes [config] atomically, creating the `.copist/` folder if needed.
  Future<void> write(LibraryConfig config) async {
    await file.parent.create(recursive: true);
    final text = const JsonEncoder.withIndent('  ').convert(config.toJsonMap());
    await writeFileAtomically(file, utf8.encode('$text\n'));
  }
}
