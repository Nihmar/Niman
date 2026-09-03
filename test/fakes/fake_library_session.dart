import 'dart:async';

import 'package:copist/src/core/files.dart';
import 'package:copist/src/db/database.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/library/note_ops.dart';
import 'package:copist/src/library/session.dart';
import 'package:path/path.dart' as p;

/// In-memory [LibrarySession] for widget tests.
///
/// `testWidgets` runs in a fake-async zone where real filesystem/sqlite I/O
/// never completes, so the UI is exercised against this fake while the real
/// controller and ops implementations are covered by the unit tests in
/// `test/unit/`.
///
/// Mirrors the real semantics the UI relies on: library-relative slash paths
/// (empty string = root), sanitized and uniquified names, directories first
/// in listings, and a trash manifest with restore.
final class FakeLibrarySession implements LibrarySession, NoteOperations {
  /// Creates a fake session; [resumePath] is auto-opened by [resume] when
  /// non-null (simulates the persisted last-library path).
  FakeLibrarySession({this.resumePath});

  /// The path [resume] opens, simulating a persisted last-library path.
  final String? resumePath;

  final StreamController<int> _events = StreamController<int>.broadcast();
  final List<_Row> _rows = <_Row>[];
  final List<_TrashEntry> _trash = <_TrashEntry>[];
  int _nextId = 1;
  int _revision = 0;
  LibraryPhase _phase = LibraryPhase.none;
  String? _root;
  String? _lastError;
  bool _resumeStarted = false;
  bool _trashEnabled = true;

  @override
  LibraryPhase get phase => _phase;

  @override
  String? get root => _root;

  @override
  String? get lastError => _lastError;

  @override
  int get revision => _revision;

  @override
  Stream<int> get events => _events.stream;

  @override
  NoteOperations? get ops => _phase == LibraryPhase.ready ? this : null;

  @override
  Future<void> resume() {
    if (_resumeStarted) return Future<void>.value();
    _resumeStarted = true;
    final path = resumePath;
    if (path == null) return Future<void>.value();
    // Mirrors the real resume: non-blocking, and the in-memory index already
    // mirrors the tree, so there is nothing to reconcile.
    return open(path, create: false, blockingScan: false);
  }

  @override
  Future<void> open(
    String path, {
    required bool create,
    bool blockingScan = true,
  }) async {
    if (_phase != LibraryPhase.none) {
      throw StateError('A library is already open (phase: ${_phase.name})');
    }
    _phase = LibraryPhase.opening;
    _lastError = null;
    _bump();
    _root = path;
    _phase = LibraryPhase.ready;
    _bump();
  }

  @override
  Future<void> close() async {
    _root = null;
    _phase = LibraryPhase.none;
    _bump();
  }

  @override
  Future<void> rescanNow() async {
    throw StateError('No library is open');
  }

  @override
  Future<bool> get debugLogsEnabled async => true;

  @override
  Future<void> setDebugLogsEnabled({required bool enabled}) async {}

  @override
  void notify() => _bump();

  @override
  Future<void> dispose() async {
    await close();
    if (!_events.isClosed) {
      await _events.close();
    }
  }

  @override
  Future<List<Note>> children(int parentId) async {
    final kids = <_Row>[
      for (final row in _rows)
        if (!row.trashed && _parentIdOf(row.path) == parentId) row,
    ]..sort((a, b) {
      if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return kids.map(_toNote).toList();
  }

  @override
  Future<List<Note>> folders() async {
    final dirs = <_Row>[
      for (final row in _rows)
        if (!row.trashed && row.isDir) row,
    ]..sort((a, b) => a.path.compareTo(b.path));
    return dirs.map(_toNote).toList();
  }

  /// Test-only bulk seeding of [count] notes at the library root.
  ///
  /// Avoids the O(n²) cost of [count] × [createNote] for the 10k-note
  /// lazy-render smoke test.
  Future<void> seedNotes(int count) async {
    if (_phase != LibraryPhase.ready) {
      throw StateError('Open the fake before seeding notes');
    }
    for (var i = 0; i < count; i++) {
      _addRow('note_$i.md', isDir: false);
    }
    _bump();
  }

  // -- NoteOperations --------------------------------------------------

  @override
  Future<bool> get trashEnabled async => _trashEnabled;

  @override
  Future<void> setTrashEnabled({required bool enabled}) async {
    _trashEnabled = enabled;
  }

  @override
  Future<Note> createNote({
    required String parentPath,
    required String name,
  }) async {
    _checkParent(parentPath);
    final clean = sanitizeName(name, fallback: defaultNoteName);
    final unique = _uniqueInParent(parentPath, clean, '.md');
    final rel = resolvePath(parentPath, unique);
    _addRow(rel, isDir: false);
    _bump();
    return _noteAt(rel);
  }

  @override
  Future<Note> createFolder({
    required String parentPath,
    required String name,
  }) async {
    _checkParent(parentPath);
    final clean = sanitizeName(name, fallback: defaultFolderName);
    final unique = _uniqueInParent(parentPath, clean, '');
    final rel = resolvePath(parentPath, unique);
    _addRow(rel, isDir: true);
    _bump();
    return _noteAt(rel);
  }

  @override
  Future<Note> rename(String path, String newName) async {
    final row = _requireRow(path);
    final parent = parentOf(path);
    var base = newName;
    if (base.endsWith('.md')) {
      base = base.substring(0, base.length - 3);
    }
    final clean = sanitizeName(
      base,
      fallback: row.isDir ? defaultFolderName : defaultNoteName,
    );
    final target = _uniqueInParent(
      parent,
      clean,
      row.isDir ? '' : '.md',
      exclude: path,
    );
    final newRel = resolvePath(parent, target);
    if (newRel == path) return _noteAt(path);
    _repath(path, newRel);
    _bump();
    return _noteAt(newRel);
  }

  @override
  Future<Note> move(String path, String targetParent) async {
    final row = _requireRow(path);
    final same = resolvePath(targetParent, p.basename(path)) == path;
    if (same) return _noteAt(path);
    _checkParent(targetParent);
    final name = p.basename(path);
    final String target;
    if (row.isDir) {
      target = _uniqueInParent(targetParent, name, '');
    } else {
      final parts = splitFileName(name);
      target = _uniqueInParent(targetParent, parts.base, parts.ext);
    }
    final newRel = resolvePath(targetParent, target);
    _repath(path, newRel);
    _bump();
    return _noteAt(newRel);
  }

  @override
  Future<void> delete(String path) async {
    final row = _requireRow(path);
    if (_trashEnabled) {
      final parts = splitFileName(p.basename(path));
      final trashName = row.isDir
          ? _uniqueTrashName(parts.base, '')
          : _uniqueTrashName(parts.base, parts.ext);
      _markTrashed(path, trashName);
    } else {
      _removeSubtree(path);
    }
    _bump();
  }

  @override
  Future<List<TrashItem>> trashItems() async {
    return [
      for (final entry in _trash)
        TrashItem(
          name: entry.name,
          originalPath: entry.originalPath,
          deletedAt: entry.deletedAt,
        ),
    ];
  }

  @override
  Future<Note> restoreTrash(String trashName) async {
    final entry = _findTrash(trashName);
    if (entry == null) {
      throw StateError('Not a managed trash item: "$trashName"');
    }
    final row = _rowByTrashName(trashName)!;
    final originalParent = parentOf(entry.originalPath);
    final originalDir = _findRow(originalParent);
    final restoreParent = originalDir != null && originalDir.isDir
        ? originalParent
        : '';
    final parts = splitFileName(trashName);
    final target = _uniqueInParent(
      restoreParent,
      parts.base,
      row.isDir ? '' : parts.ext,
    );
    final newRel = resolvePath(restoreParent, target);
    _untrash(entry, newRel);
    _bump();
    return _noteAt(newRel);
  }

  @override
  Future<void> deleteTrashPermanently(String trashName) async {
    final entry = _findTrash(trashName);
    if (entry == null) {
      throw StateError('Not a managed trash item: "$trashName"');
    }
    _dropTrash(entry);
  }

  @override
  Future<void> emptyTrash() async {
    _trash.toList().forEach(_dropTrash);
  }

  // -- internal model --------------------------------------------------

  void _bump() {
    _revision++;
    if (!_events.isClosed) {
      _events.add(_revision);
    }
  }

  Note _toNote(_Row row) {
    return Note(
      id: row.id,
      path: row.path,
      parent: _parentIdOf(row.path),
      name: row.name,
      isDir: row.isDir,
      size: 0,
      modified: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Note _noteAt(String path) => _toNote(_requireRow(path));

  _Row? _findRow(String path) {
    for (final row in _rows) {
      if (!row.trashed && row.path == path) return row;
    }
    return null;
  }

  _Row _requireRow(String path) {
    final row = _findRow(path);
    if (row == null) throw StateError('No indexed note at "$path"');
    return row;
  }

  int _parentIdOf(String path) {
    final parent = parentOf(path);
    if (parent.isEmpty) return 0;
    final row = _findRow(parent);
    return row == null ? 0 : row.id;
  }

  void _checkParent(String parentPath) {
    if (parentPath.isEmpty) return;
    final row = _findRow(parentPath);
    if (row == null || !row.isDir) {
      throw StateError('Parent folder not found: "$parentPath"');
    }
  }

  /// Collision-free name for [base] + [ext] inside [parent], mirroring the
  /// numeric-suffix strategy of the real ops.
  String _uniqueInParent(
    String parent,
    String base,
    String ext, {
    String? exclude,
  }) {
    for (var i = 0; i < 100; i++) {
      final candidate = i == 0 ? '$base$ext' : '${base}_$i$ext';
      final rel = resolvePath(parent, candidate);
      if (rel == exclude) return candidate;
      if (_findRow(rel) == null) return candidate;
    }
    throw StateError('Could not find a free name for "$base$ext"');
  }

  /// Collision-safe trash name, mirroring the real trash naming: the plain
  /// name, or a timestamped one on collision.
  String _uniqueTrashName(String base, String ext) {
    final plain = '$base$ext';
    if (!_trashNameTaken(plain)) return plain;
    var suffix = trashTimestampSuffix(DateTime.now());
    while (_trashNameTaken('$base.$suffix$ext')) {
      suffix++;
    }
    return '$base.$suffix$ext';
  }

  bool _trashNameTaken(String name) =>
      _rows.any((row) => row.trashed && row.trashName == name);

  void _addRow(String path, {required bool isDir}) {
    _rows.add(_Row(id: _nextId++, path: path, isDir: isDir));
  }

  void _repath(String oldPath, String newPath) {
    final subtree = <_Row>[
      for (final row in _rows)
        if (!row.trashed && (row.path == oldPath || isUnder(oldPath, row.path)))
          row,
    ];
    for (final row in subtree) {
      row.path = row.path == oldPath
          ? newPath
          : '$newPath${row.path.substring(oldPath.length)}';
    }
  }

  void _markTrashed(String path, String trashName) {
    final ids = <int>{
      for (final row in _rows)
        if (!row.trashed && (row.path == path || isUnder(path, row.path)))
          row.id,
    };
    final root = _requireRow(path);
    for (final id in ids) {
      _rowById(id)!.trashed = true;
    }
    root.trashName = trashName;
    _trash.add(
      _TrashEntry(
        name: trashName,
        originalPath: path,
        deletedAt: DateTime.now(),
        rootId: root.id,
        rowIds: ids,
      ),
    );
  }

  void _removeSubtree(String path) {
    final ids = <int>{
      for (final row in _rows)
        if (!row.trashed && (row.path == path || isUnder(path, row.path)))
          row.id,
    };
    _rows.removeWhere((row) => ids.contains(row.id));
  }

  _TrashEntry? _findTrash(String name) {
    for (final entry in _trash) {
      if (entry.name == name) return entry;
    }
    return null;
  }

  _Row? _rowByTrashName(String name) {
    for (final row in _rows) {
      if (row.trashed && row.trashName == name) return row;
    }
    return null;
  }

  void _untrash(_TrashEntry entry, String newRel) {
    _trash.remove(entry);
    final prefix = entry.originalPath;
    for (final id in entry.rowIds) {
      final row = _rowById(id);
      if (row == null) continue;
      final old = row.path;
      row
        ..path = row.id == entry.rootId
            ? newRel
            : '$newRel${old.substring(prefix.length)}'
        ..trashed = false
        ..trashName = null;
    }
  }

  void _dropTrash(_TrashEntry entry) {
    _trash.remove(entry);
    _rows.removeWhere((row) => entry.rowIds.contains(row.id));
  }

  _Row? _rowById(int id) {
    for (final row in _rows) {
      if (row.id == id) return row;
    }
    return null;
  }
}

/// One in-memory row of the fake index (a live or trashed note/folder).
final class _Row {
  /// Creates a row at library-relative [path].
  _Row({required this.id, required this.path, required this.isDir});

  final int id;
  final bool isDir;

  /// Library-relative slash path; kept on its original value while trashed.
  String path;

  bool trashed = false;

  /// Name inside `.trash/` while [trashed]; unique among trashed rows.
  String? trashName;

  /// Display name: the last path segment.
  String get name => p.basename(path);
}

/// One manifest entry of the fake trash.
final class _TrashEntry {
  /// Creates a manifest entry for the trashed subtree rooted at [rootId].
  _TrashEntry({
    required this.name,
    required this.originalPath,
    required this.deletedAt,
    required this.rootId,
    required this.rowIds,
  });

  /// Name inside `.trash/`.
  final String name;

  /// Library-relative path before the delete.
  final String originalPath;

  /// When the item was deleted.
  final DateTime deletedAt;

  /// Row id of the trashed root.
  final int rootId;

  /// Row ids of the whole trashed subtree.
  final Set<int> rowIds;
}
