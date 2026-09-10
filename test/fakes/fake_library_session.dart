import 'dart:async';

import 'package:copist/src/core/files.dart';
import 'package:copist/src/core/language.dart';
import 'package:copist/src/core/settings/library_config.dart';
import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/core/text_scale.dart';
import 'package:copist/src/db/app_database.dart';
import 'package:copist/src/db/index_database.dart';
import 'package:copist/src/db/indexer.dart';
import 'package:copist/src/frontmatter/edit.dart';
import 'package:copist/src/frontmatter/fields.dart';
import 'package:copist/src/frontmatter/parser.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/library/note_ops.dart';
import 'package:copist/src/library/session.dart';
import 'package:copist/src/links/resolver.dart';
import 'package:copist/src/search/replace.dart';
import 'package:copist/src/search/search_repo.dart';
import 'package:copist/src/search/tag_repo.dart';
import 'package:copist/src/templates/repo.dart';
import 'package:path/path.dart' as p;

import 'fake_link_source.dart';
import 'fake_replace_source.dart';
import 'fake_search_source.dart';
import 'fake_tag_source.dart';

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
  new({this.resumePath});

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
  String? _quickNotePath;
  String _listNoteFolder = 'Lists';
  String _templateFolder = defaultTemplateFolder;
  AppLanguage _language = AppLanguage.system;

  @override
  LibraryPhase get phase => _phase;

  @override
  String? get root => _root;

  @override
  String? get lastError => _lastError;

  @override
  int get revision => _revision;

  /// The fake indexes nothing, so there is never a scan to report on.
  /// Tests that need the indexing line set this and pump.
  IndexProgress? indexing;

  @override
  IndexProgress? get indexProgress => indexing;

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
    // Held while a test wants to look at the opening screen: the progress
    // bar and the line naming the note being indexed only exist there.
    final gate = openGate;
    if (gate != null) await gate.future;
    _root = path;
    // As the real session does: the library's text sizes go on screen
    // with it (T-M6-12).
    AppTextScales.apply(ui: _config.uiTextScale, note: _config.noteTextScale);
    _phase = LibraryPhase.ready;
    _bump();
  }

  /// Set to pause [open] in its opening phase; complete it to finish.
  Completer<void>? openGate;

  @override
  Future<void> close() async {
    _root = null;
    _phase = LibraryPhase.none;
    AppTextScales.reset();
    _bump();
  }

  @override
  Future<void> switchTo(String libraryPath) async {
    if (libraryPath == _root) return;
    if (_phase != LibraryPhase.none) await close();
    await open(libraryPath, create: false, blockingScan: false);
  }

  /// The known-library list, newest first (T-ML-04).
  final List<KnownLibrary> _known = <KnownLibrary>[];

  @override
  Future<List<KnownLibrary>> knownLibraries() async => List.of(_known);

  @override
  Future<void> forgetLibrary(String libraryPath) async {
    _known.removeWhere((entry) => entry.path == libraryPath);
    _bump();
  }

  /// Test-only seeding of the known list, so the home screen has rows
  /// without a real registry behind it.
  void seedKnownLibrary(String path, {String? name, DateTime? lastOpened}) {
    _known
      ..removeWhere((entry) => entry.path == path)
      ..insert(
        0,
        KnownLibrary(
          path: path,
          name: name ?? p.basename(path),
          lastOpened: lastOpened ?? DateTime.now(),
        ),
      );
  }

  @override
  Future<void> rescanNow() async {
    throw StateError('No library is open');
  }

  @override
  Future<bool> get debugLogsEnabled async => true;

  @override
  Future<void> setDebugLogsEnabled({required bool enabled}) async {}

  /// The settings a library keeps for itself (T-ML-10), in memory. A
  /// fresh fake starts at the shipped defaults, as a fresh library does.
  LibraryConfig _config = LibraryConfig.defaults;

  @override
  Future<bool> get lineNumbersEnabled async => _config.lineNumbers;

  @override
  Future<void> setLineNumbersEnabled({required bool enabled}) async {
    _config = _config.copyWith(lineNumbers: enabled);
  }

  @override
  Future<bool> get editorAutofocusEnabled async => _config.editorAutofocus;

  @override
  Future<void> setEditorAutofocusEnabled({required bool enabled}) async {
    _config = _config.copyWith(editorAutofocus: enabled);
  }

  @override
  Future<bool> get reminderShowTokens async => _config.reminderShowTokens;

  @override
  Future<void> setReminderShowTokens({required bool enabled}) async {
    _config = _config.copyWith(reminderShowTokens: enabled);
  }

  // The preview layout is app-wide: it follows the screen, not the
  // library.
  PreviewLayoutMode _previewMode = PreviewLayoutMode.auto;
  double _splitRatio = defaultSplitRatio;

  @override
  Future<PreviewLayoutMode> get previewMode async => _previewMode;

  @override
  Future<void> setPreviewMode(PreviewLayoutMode mode) async {
    _previewMode = mode;
  }

  @override
  Future<double> get splitRatio async => _splitRatio;

  @override
  Future<void> setSplitRatio(double ratio) async {
    _splitRatio = ratio;
  }

  @override
  Future<TreeSort> get treeSort async => _config.treeSort;

  @override
  Future<void> setTreeSort(TreeSort sort) async {
    _config = _config.copyWith(treeSort: sort);
  }

  @override
  Future<bool> get pinnedCollapsed async => _config.pinnedCollapsed;

  @override
  Future<void> setPinnedCollapsed({required bool collapsed}) async {
    _config = _config.copyWith(pinnedCollapsed: collapsed);
  }

  @override
  Future<LinkType> get linkType async => _config.linkType;

  @override
  Future<void> setLinkType(LinkType type) async {
    _config = _config.copyWith(linkType: type);
  }

  @override
  Future<int> get indentWidth async => _config.indentWidth;

  @override
  Future<void> setIndentWidth(int width) async {
    _config = _config.copyWith(indentWidth: normalizeIndentWidth(width));
  }

  @override
  Future<String> get editorToolbar async => _config.editorToolbar;

  @override
  Future<void> setEditorToolbar(String layout) async {
    _config = _config.copyWith(editorToolbar: layout);
  }

  @override
  Future<double> get uiTextScale async => _config.uiTextScale;

  @override
  Future<void> setUiTextScale(double scale) async {
    final clamped = normalizeTextScale(scale);
    _config = _config.copyWith(uiTextScale: clamped);
    AppTextScales.ui = clamped;
  }

  @override
  Future<double> get noteTextScale async => _config.noteTextScale;

  @override
  Future<void> setNoteTextScale(double scale) async {
    final clamped = normalizeTextScale(scale);
    _config = _config.copyWith(noteTextScale: clamped);
    AppTextScales.note = clamped;
  }

  @override
  Future<AppLanguage> get language async => _language;

  @override
  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
  }

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
  Future<List<Note>> children(int parentId, {bool nameDesc = false}) async {
    final kids =
        <_Row>[
          for (final row in _rows)
            if (!row.trashed && _parentIdOf(row.path) == parentId) row,
        ]..sort((a, b) {
          if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
          return nameDesc ? b.name.compareTo(a.name) : a.name.compareTo(b.name);
        });
    return kids.map(_toNote).toList();
  }

  @override
  Future<List<Note>> tree(
    Iterable<String> expandedPaths, {
    bool nameDesc = false,
  }) async {
    final expanded = Set<String>.from(expandedPaths);
    final results =
        <_Row>[
          for (final row in _rows)
            if (!row.trashed &&
                (parentOf(row.path).isEmpty ||
                    expanded.contains(parentOf(row.path))))
              row,
        ]..sort((a, b) {
          if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
          return nameDesc ? b.name.compareTo(a.name) : a.name.compareTo(b.name);
        });
    return results.map(_toNote).toList();
  }

  @override
  Future<Note?> find(String path) {
    final row = _findRow(path);
    return Future<Note?>.value(row == null ? null : _toNote(row));
  }

  @override
  Future<SearchSource?> get searchSource async => FakeSearchSource();

  @override
  Future<ReplaceSource?> get replaceSource async => FakeReplaceSource();

  @override
  Future<TagSource?> get tagSource async => FakeTagSource();

  /// Answered from the fake's own rows rather than a canned fake: the
  /// content is right there, so pinned notes and `key = value` filters
  /// behave the way they will against a real index.
  @override
  Future<FieldSource?> get fieldSource async => _FakeFieldSource(this);

  @override
  Future<LinkSource?> get linkSource async => FakeLinkSource();

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

  /// Test-only: puts a file at [path] verbatim, extension and all.
  ///
  /// [createNote] always makes a `.md`, as the real ops do, but a library
  /// holds files nobody created through the app — attachments, a
  /// `todo.txt` — and the tree lists them. This is how a test gets one.
  Future<Note> seedFile(String path, {String content = ''}) async {
    if (_phase != LibraryPhase.ready) {
      throw StateError('Open the fake before seeding files');
    }
    _addRow(path, isDir: false).content = content;
    _bump();
    return _noteAt(path);
  }

  // -- NoteOperations --------------------------------------------------

  @override
  Future<bool> get trashEnabled async => _trashEnabled;

  @override
  Future<void> setTrashEnabled({required bool enabled}) async {
    _trashEnabled = enabled;
  }

  @override
  Future<String?> get quickNotePath async => _quickNotePath;

  @override
  Future<void> setQuickNotePath({required String? path}) async {
    _quickNotePath = path;
  }

  /// The stored content of the note at [path], or null (test aid).
  String? contentOf(String path) => _findRow(path)?.content;

  @override
  Future<String> get listNoteFolder async => _listNoteFolder;

  @override
  Future<void> setListNoteFolder({required String folder}) async {
    _listNoteFolder = folder;
  }

  @override
  Future<String> readNote(String path) async => _requireRow(path).content;

  @override
  Future<String> get templateFolder async => _templateFolder;

  @override
  Future<void> setTemplateFolder({required String folder}) async {
    _templateFolder = folder;
  }

  /// Templates come from the fake's own rows, so a test that creates a
  /// note under the folder has a template.
  @override
  Future<TemplateSource?> get templateSource async => _FakeTemplateSource(this);

  @override
  Future<Note> createNote({
    required String parentPath,
    required String name,
    String content = '',
  }) async {
    _checkParent(parentPath);
    final clean = sanitizeName(name, fallback: defaultNoteName);
    final unique = _uniqueInParent(parentPath, clean, '.md');
    final rel = resolvePath(parentPath, unique);
    _addRow(rel, isDir: false).content = content;
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
  Future<Note> ensureFolder(String path) async {
    final clean = cleanFolderPath(path, '');
    if (clean.isEmpty) {
      throw ArgumentError('ensureFolder was given no folder: "$path"');
    }
    final segments = clean.split('/');
    for (var i = 1; i <= segments.length; i++) {
      final rel = segments.take(i).join('/');
      if (_findRow(rel) != null) continue;
      _addRow(rel, isDir: true);
    }
    _bump();
    return _noteAt(clean);
  }

  @override
  Future<Note> appendToNote(String path, String content) async {
    final existing = _findRow(path);
    if (existing == null) {
      _addRow(path, isDir: false).content = content;
    } else {
      final before = existing.content.replaceFirst(RegExp(r'\s+$'), '');
      existing.content = before.isEmpty ? content : '$before\n\n$content';
    }
    _bump();
    return _noteAt(path);
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
    if (targetParent == path || isUnder(path, targetParent)) {
      throw ArgumentError('Cannot move "$path" into itself or its own subtree');
    }
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

  /// Pins by editing the row's content, exactly as the real ops edit the
  /// file — so a widget test that pins sees the same frontmatter a person
  /// would find in the note afterwards.
  @override
  Future<Note> setPinned(String path, {required bool pinned}) async {
    final row = _requireRow(path);
    if (row.isDir || (pinned && !isMarkdownNote(row.name))) {
      throw ArgumentError('Only Markdown notes can be pinned, not "$path"');
    }
    row.content = pinned
        ? setFrontmatterKey(row.content, 'pinned', 'true')
        : removeFrontmatterKey(row.content, 'pinned');
    _bump();
    return _toNote(row);
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
    // The original name comes from the manifest, as in the real ops: the
    // trash name may carry a collision timestamp.
    final originalName = p.basename(entry.originalPath);
    String base;
    String ext;
    if (row.isDir) {
      base = originalName;
      ext = '';
    } else {
      final parts = splitFileName(originalName);
      base = parts.base;
      ext = parts.ext;
    }
    final target = _uniqueInParent(restoreParent, base, ext);
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

  /// The row as an indexed note, with the frontmatter fields the real
  /// indexer would have derived from its content (T-M4-02) — so a widget
  /// test can pin a note by writing `pinned: true` into it, exactly as a
  /// person would.
  Note _toNote(_Row row) {
    final fm = row.isDir ? null : parseFrontmatter(row.content);
    return Note(
      id: row.id,
      path: row.path,
      parent: _parentIdOf(row.path),
      name: row.name,
      isDir: row.isDir,
      size: 0,
      modified: DateTime.fromMillisecondsSinceEpoch(0),
      title: fm?.fields['title']?.first,
      date: fm?.date,
      pinned: fm?.pinned ?? false,
    );
  }

  Note _noteAt(String path) => _toNote(_requireRow(path));

  /// Every live (untrashed) note row as an indexed note; folders included.
  Iterable<Note> _liveNotes() sync* {
    for (final row in _rows) {
      if (!row.trashed) yield _toNote(row);
    }
  }

  /// Every live note paired with its parsed frontmatter (null for folders
  /// and for notes without a block).
  Iterable<(Note, Frontmatter?)> _liveFrontmatter() sync* {
    for (final row in _rows) {
      if (row.trashed || row.isDir) continue;
      yield (_toNote(row), parseFrontmatter(row.content));
    }
  }

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

  _Row _addRow(String path, {required bool isDir}) {
    final row = _Row(id: _nextId++, path: path, isDir: isDir);
    _rows.add(row);
    return row;
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

/// The fake's frontmatter-field source: parses each live note's content
/// on demand, which is cheap at the handful of notes a widget test has.
final class _FakeFieldSource implements FieldSource {
  new(this._session);

  final FakeLibrarySession _session;

  @override
  Future<List<Note>> pinnedNotes() async {
    final notes = [
      for (final note in _session._liveNotes())
        if (note.pinned) note,
    ]..sort((a, b) => a.path.compareTo(b.path));
    return notes;
  }

  @override
  Future<List<Note>> notesWithField(String key, String value) async {
    final wanted = value.trim().toLowerCase();
    final name = key.trim().toLowerCase();
    final out = <Note>[];
    for (final (note, fm) in _session._liveFrontmatter()) {
      final values = fm?.fields[name];
      if (values == null) continue;
      if (wanted.isEmpty || values.any((v) => v.toLowerCase() == wanted)) {
        out.add(note);
      }
    }
    return out..sort((a, b) => a.path.compareTo(b.path));
  }

  @override
  Future<List<FieldKeyCount>> fieldKeys() async {
    final counts = <String, int>{};
    for (final (_, fm) in _session._liveFrontmatter()) {
      for (final key in fm?.fields.keys ?? const <String>[]) {
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final keys = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    return [
      for (final key in keys) FieldKeyCount(key: key, count: counts[key]!),
    ];
  }
}

/// The fake's template source: the live notes under the configured
/// folder, named the way the real repo names them.
final class _FakeTemplateSource implements TemplateSource {
  new(this._session);

  final FakeLibrarySession _session;

  @override
  Future<String> get folder => _session.templateFolder;

  @override
  Future<List<TemplateEntry>> templates() async {
    final root = await folder;
    final out = <TemplateEntry>[];
    for (final note in _session._liveNotes()) {
      if (note.isDir || !note.name.toLowerCase().endsWith('.md')) continue;
      if (!note.path.startsWith('$root/')) continue;
      var name = note.path.substring(root.length + 1);
      name = name.substring(0, name.length - 3);
      out.add(TemplateEntry(path: note.path, name: name));
    }
    return out
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}

/// One in-memory row of the fake index (a live or trashed note/folder).
final class _Row {
  /// Creates a row at library-relative [path].
  new({required this.id, required this.path, required this.isDir});

  final int id;
  final bool isDir;

  /// The note's content (created notes; the fake never edits it).
  String content = '';

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
  new({
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
