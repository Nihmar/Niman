// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _parentMeta = const VerificationMeta('parent');
  @override
  late final GeneratedColumn<int> parent = GeneratedColumn<int>(
    'parent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDirMeta = const VerificationMeta('isDir');
  @override
  late final GeneratedColumn<bool> isDir = GeneratedColumn<bool>(
    'is_dir',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dir" IN (0, 1))',
    ),
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedMeta = const VerificationMeta(
    'modified',
  );
  @override
  late final GeneratedColumn<DateTime> modified = GeneratedColumn<DateTime>(
    'modified',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    path,
    parent,
    name,
    isDir,
    size,
    modified,
    sha256,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('parent')) {
      context.handle(
        _parentMeta,
        parent.isAcceptableOrUnknown(data['parent']!, _parentMeta),
      );
    } else if (isInserting) {
      context.missing(_parentMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_dir')) {
      context.handle(
        _isDirMeta,
        isDir.isAcceptableOrUnknown(data['is_dir']!, _isDirMeta),
      );
    } else if (isInserting) {
      context.missing(_isDirMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('modified')) {
      context.handle(
        _modifiedMeta,
        modified.isAcceptableOrUnknown(data['modified']!, _modifiedMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      parent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isDir: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dir'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      modified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      ),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  /// Primary key.
  final int id;

  /// Library-relative slash-separated path; unique.
  final String path;

  /// Parent row id; 0 = library root.
  final int parent;

  /// Display name (file or folder name).
  final String name;

  /// Whether this row is a directory.
  final bool isDir;

  /// Byte size; 0 for directories.
  final int size;

  /// Last modification time as seen on disk.
  final DateTime modified;

  /// Content sha256, hex; files only (directories are null).
  final String? sha256;
  const Note({
    required this.id,
    required this.path,
    required this.parent,
    required this.name,
    required this.isDir,
    required this.size,
    required this.modified,
    this.sha256,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['path'] = Variable<String>(path);
    map['parent'] = Variable<int>(parent);
    map['name'] = Variable<String>(name);
    map['is_dir'] = Variable<bool>(isDir);
    map['size'] = Variable<int>(size);
    map['modified'] = Variable<DateTime>(modified);
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      path: Value(path),
      parent: Value(parent),
      name: Value(name),
      isDir: Value(isDir),
      size: Value(size),
      modified: Value(modified),
      sha256: sha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      parent: serializer.fromJson<int>(json['parent']),
      name: serializer.fromJson<String>(json['name']),
      isDir: serializer.fromJson<bool>(json['isDir']),
      size: serializer.fromJson<int>(json['size']),
      modified: serializer.fromJson<DateTime>(json['modified']),
      sha256: serializer.fromJson<String?>(json['sha256']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'path': serializer.toJson<String>(path),
      'parent': serializer.toJson<int>(parent),
      'name': serializer.toJson<String>(name),
      'isDir': serializer.toJson<bool>(isDir),
      'size': serializer.toJson<int>(size),
      'modified': serializer.toJson<DateTime>(modified),
      'sha256': serializer.toJson<String?>(sha256),
    };
  }

  Note copyWith({
    int? id,
    String? path,
    int? parent,
    String? name,
    bool? isDir,
    int? size,
    DateTime? modified,
    Value<String?> sha256 = const Value.absent(),
  }) => Note(
    id: id ?? this.id,
    path: path ?? this.path,
    parent: parent ?? this.parent,
    name: name ?? this.name,
    isDir: isDir ?? this.isDir,
    size: size ?? this.size,
    modified: modified ?? this.modified,
    sha256: sha256.present ? sha256.value : this.sha256,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      parent: data.parent.present ? data.parent.value : this.parent,
      name: data.name.present ? data.name.value : this.name,
      isDir: data.isDir.present ? data.isDir.value : this.isDir,
      size: data.size.present ? data.size.value : this.size,
      modified: data.modified.present ? data.modified.value : this.modified,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('parent: $parent, ')
          ..write('name: $name, ')
          ..write('isDir: $isDir, ')
          ..write('size: $size, ')
          ..write('modified: $modified, ')
          ..write('sha256: $sha256')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, path, parent, name, isDir, size, modified, sha256);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.path == this.path &&
          other.parent == this.parent &&
          other.name == this.name &&
          other.isDir == this.isDir &&
          other.size == this.size &&
          other.modified == this.modified &&
          other.sha256 == this.sha256);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<int> id;
  final Value<String> path;
  final Value<int> parent;
  final Value<String> name;
  final Value<bool> isDir;
  final Value<int> size;
  final Value<DateTime> modified;
  final Value<String?> sha256;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.parent = const Value.absent(),
    this.name = const Value.absent(),
    this.isDir = const Value.absent(),
    this.size = const Value.absent(),
    this.modified = const Value.absent(),
    this.sha256 = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    required String path,
    required int parent,
    required String name,
    required bool isDir,
    required int size,
    required DateTime modified,
    this.sha256 = const Value.absent(),
  }) : path = Value(path),
       parent = Value(parent),
       name = Value(name),
       isDir = Value(isDir),
       size = Value(size),
       modified = Value(modified);
  static Insertable<Note> custom({
    Expression<int>? id,
    Expression<String>? path,
    Expression<int>? parent,
    Expression<String>? name,
    Expression<bool>? isDir,
    Expression<int>? size,
    Expression<DateTime>? modified,
    Expression<String>? sha256,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (parent != null) 'parent': parent,
      if (name != null) 'name': name,
      if (isDir != null) 'is_dir': isDir,
      if (size != null) 'size': size,
      if (modified != null) 'modified': modified,
      if (sha256 != null) 'sha256': sha256,
    });
  }

  NotesCompanion copyWith({
    Value<int>? id,
    Value<String>? path,
    Value<int>? parent,
    Value<String>? name,
    Value<bool>? isDir,
    Value<int>? size,
    Value<DateTime>? modified,
    Value<String?>? sha256,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      parent: parent ?? this.parent,
      name: name ?? this.name,
      isDir: isDir ?? this.isDir,
      size: size ?? this.size,
      modified: modified ?? this.modified,
      sha256: sha256 ?? this.sha256,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (parent.present) {
      map['parent'] = Variable<int>(parent.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isDir.present) {
      map['is_dir'] = Variable<bool>(isDir.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (modified.present) {
      map['modified'] = Variable<DateTime>(modified.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('parent: $parent, ')
          ..write('name: $name, ')
          ..write('isDir: $isDir, ')
          ..write('size: $size, ')
          ..write('modified: $modified, ')
          ..write('sha256: $sha256')
          ..write(')'))
        .toString();
  }
}

class $LibrarySettingsTable extends LibrarySettings
    with TableInfo<$LibrarySettingsTable, LibrarySetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibrarySettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trashEnabledMeta = const VerificationMeta(
    'trashEnabled',
  );
  @override
  late final GeneratedColumn<bool> trashEnabled = GeneratedColumn<bool>(
    'trash_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("trash_enabled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _historyVersionsMeta = const VerificationMeta(
    'historyVersions',
  );
  @override
  late final GeneratedColumn<int> historyVersions = GeneratedColumn<int>(
    'history_versions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quickNotePathMeta = const VerificationMeta(
    'quickNotePath',
  );
  @override
  late final GeneratedColumn<String> quickNotePath = GeneratedColumn<String>(
    'quick_note_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    path,
    trashEnabled,
    historyVersions,
    quickNotePath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibrarySetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('trash_enabled')) {
      context.handle(
        _trashEnabledMeta,
        trashEnabled.isAcceptableOrUnknown(
          data['trash_enabled']!,
          _trashEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trashEnabledMeta);
    }
    if (data.containsKey('history_versions')) {
      context.handle(
        _historyVersionsMeta,
        historyVersions.isAcceptableOrUnknown(
          data['history_versions']!,
          _historyVersionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_historyVersionsMeta);
    }
    if (data.containsKey('quick_note_path')) {
      context.handle(
        _quickNotePathMeta,
        quickNotePath.isAcceptableOrUnknown(
          data['quick_note_path']!,
          _quickNotePathMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {path};
  @override
  LibrarySetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibrarySetting(
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      trashEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}trash_enabled'],
      )!,
      historyVersions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}history_versions'],
      )!,
      quickNotePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quick_note_path'],
      ),
    );
  }

  @override
  $LibrarySettingsTable createAlias(String alias) {
    return $LibrarySettingsTable(attachedDatabase, alias);
  }
}

class LibrarySetting extends DataClass implements Insertable<LibrarySetting> {
  /// Absolute, normalized path of the library root; the primary key.
  final String path;

  /// Whether deletes move notes into `.trash/` (true) or hard-delete them.
  final bool trashEnabled;

  /// Number of `.history/` versions to keep (M5); default 10.
  final int historyVersions;

  /// Library-relative path of the user-chosen quick note; null = the
  /// default `Quick note.md` at the library root.
  final String? quickNotePath;
  const LibrarySetting({
    required this.path,
    required this.trashEnabled,
    required this.historyVersions,
    this.quickNotePath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    map['trash_enabled'] = Variable<bool>(trashEnabled);
    map['history_versions'] = Variable<int>(historyVersions);
    if (!nullToAbsent || quickNotePath != null) {
      map['quick_note_path'] = Variable<String>(quickNotePath);
    }
    return map;
  }

  LibrarySettingsCompanion toCompanion(bool nullToAbsent) {
    return LibrarySettingsCompanion(
      path: Value(path),
      trashEnabled: Value(trashEnabled),
      historyVersions: Value(historyVersions),
      quickNotePath: quickNotePath == null && nullToAbsent
          ? const Value.absent()
          : Value(quickNotePath),
    );
  }

  factory LibrarySetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibrarySetting(
      path: serializer.fromJson<String>(json['path']),
      trashEnabled: serializer.fromJson<bool>(json['trashEnabled']),
      historyVersions: serializer.fromJson<int>(json['historyVersions']),
      quickNotePath: serializer.fromJson<String?>(json['quickNotePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'path': serializer.toJson<String>(path),
      'trashEnabled': serializer.toJson<bool>(trashEnabled),
      'historyVersions': serializer.toJson<int>(historyVersions),
      'quickNotePath': serializer.toJson<String?>(quickNotePath),
    };
  }

  LibrarySetting copyWith({
    String? path,
    bool? trashEnabled,
    int? historyVersions,
    Value<String?> quickNotePath = const Value.absent(),
  }) => LibrarySetting(
    path: path ?? this.path,
    trashEnabled: trashEnabled ?? this.trashEnabled,
    historyVersions: historyVersions ?? this.historyVersions,
    quickNotePath: quickNotePath.present
        ? quickNotePath.value
        : this.quickNotePath,
  );
  LibrarySetting copyWithCompanion(LibrarySettingsCompanion data) {
    return LibrarySetting(
      path: data.path.present ? data.path.value : this.path,
      trashEnabled: data.trashEnabled.present
          ? data.trashEnabled.value
          : this.trashEnabled,
      historyVersions: data.historyVersions.present
          ? data.historyVersions.value
          : this.historyVersions,
      quickNotePath: data.quickNotePath.present
          ? data.quickNotePath.value
          : this.quickNotePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibrarySetting(')
          ..write('path: $path, ')
          ..write('trashEnabled: $trashEnabled, ')
          ..write('historyVersions: $historyVersions, ')
          ..write('quickNotePath: $quickNotePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(path, trashEnabled, historyVersions, quickNotePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibrarySetting &&
          other.path == this.path &&
          other.trashEnabled == this.trashEnabled &&
          other.historyVersions == this.historyVersions &&
          other.quickNotePath == this.quickNotePath);
}

class LibrarySettingsCompanion extends UpdateCompanion<LibrarySetting> {
  final Value<String> path;
  final Value<bool> trashEnabled;
  final Value<int> historyVersions;
  final Value<String?> quickNotePath;
  final Value<int> rowid;
  const LibrarySettingsCompanion({
    this.path = const Value.absent(),
    this.trashEnabled = const Value.absent(),
    this.historyVersions = const Value.absent(),
    this.quickNotePath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibrarySettingsCompanion.insert({
    required String path,
    required bool trashEnabled,
    required int historyVersions,
    this.quickNotePath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : path = Value(path),
       trashEnabled = Value(trashEnabled),
       historyVersions = Value(historyVersions);
  static Insertable<LibrarySetting> custom({
    Expression<String>? path,
    Expression<bool>? trashEnabled,
    Expression<int>? historyVersions,
    Expression<String>? quickNotePath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (trashEnabled != null) 'trash_enabled': trashEnabled,
      if (historyVersions != null) 'history_versions': historyVersions,
      if (quickNotePath != null) 'quick_note_path': quickNotePath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibrarySettingsCompanion copyWith({
    Value<String>? path,
    Value<bool>? trashEnabled,
    Value<int>? historyVersions,
    Value<String?>? quickNotePath,
    Value<int>? rowid,
  }) {
    return LibrarySettingsCompanion(
      path: path ?? this.path,
      trashEnabled: trashEnabled ?? this.trashEnabled,
      historyVersions: historyVersions ?? this.historyVersions,
      quickNotePath: quickNotePath ?? this.quickNotePath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (trashEnabled.present) {
      map['trash_enabled'] = Variable<bool>(trashEnabled.value);
    }
    if (historyVersions.present) {
      map['history_versions'] = Variable<int>(historyVersions.value);
    }
    if (quickNotePath.present) {
      map['quick_note_path'] = Variable<String>(quickNotePath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibrarySettingsCompanion(')
          ..write('path: $path, ')
          ..write('trashEnabled: $trashEnabled, ')
          ..write('historyVersions: $historyVersions, ')
          ..write('quickNotePath: $quickNotePath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _libraryPathMeta = const VerificationMeta(
    'libraryPath',
  );
  @override
  late final GeneratedColumn<String> libraryPath = GeneratedColumn<String>(
    'library_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _debugLogsEnabledMeta = const VerificationMeta(
    'debugLogsEnabled',
  );
  @override
  late final GeneratedColumn<bool> debugLogsEnabled = GeneratedColumn<bool>(
    'debug_logs_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("debug_logs_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lineNumbersMeta = const VerificationMeta(
    'lineNumbers',
  );
  @override
  late final GeneratedColumn<bool> lineNumbers = GeneratedColumn<bool>(
    'line_numbers',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("line_numbers" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _editorAutofocusMeta = const VerificationMeta(
    'editorAutofocus',
  );
  @override
  late final GeneratedColumn<bool> editorAutofocus = GeneratedColumn<bool>(
    'editor_autofocus',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("editor_autofocus" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _previewModeMeta = const VerificationMeta(
    'previewMode',
  );
  @override
  late final GeneratedColumn<String> previewMode = GeneratedColumn<String>(
    'preview_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('auto'),
  );
  static const VerificationMeta _splitRatioMeta = const VerificationMeta(
    'splitRatio',
  );
  @override
  late final GeneratedColumn<double> splitRatio = GeneratedColumn<double>(
    'split_ratio',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.55),
  );
  static const VerificationMeta _treeSortMeta = const VerificationMeta(
    'treeSort',
  );
  @override
  late final GeneratedColumn<String> treeSort = GeneratedColumn<String>(
    'tree_sort',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('nameAsc'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    libraryPath,
    debugLogsEnabled,
    lineNumbers,
    editorAutofocus,
    previewMode,
    splitRatio,
    treeSort,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('library_path')) {
      context.handle(
        _libraryPathMeta,
        libraryPath.isAcceptableOrUnknown(
          data['library_path']!,
          _libraryPathMeta,
        ),
      );
    }
    if (data.containsKey('debug_logs_enabled')) {
      context.handle(
        _debugLogsEnabledMeta,
        debugLogsEnabled.isAcceptableOrUnknown(
          data['debug_logs_enabled']!,
          _debugLogsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('line_numbers')) {
      context.handle(
        _lineNumbersMeta,
        lineNumbers.isAcceptableOrUnknown(
          data['line_numbers']!,
          _lineNumbersMeta,
        ),
      );
    }
    if (data.containsKey('editor_autofocus')) {
      context.handle(
        _editorAutofocusMeta,
        editorAutofocus.isAcceptableOrUnknown(
          data['editor_autofocus']!,
          _editorAutofocusMeta,
        ),
      );
    }
    if (data.containsKey('preview_mode')) {
      context.handle(
        _previewModeMeta,
        previewMode.isAcceptableOrUnknown(
          data['preview_mode']!,
          _previewModeMeta,
        ),
      );
    }
    if (data.containsKey('split_ratio')) {
      context.handle(
        _splitRatioMeta,
        splitRatio.isAcceptableOrUnknown(data['split_ratio']!, _splitRatioMeta),
      );
    }
    if (data.containsKey('tree_sort')) {
      context.handle(
        _treeSortMeta,
        treeSort.isAcceptableOrUnknown(data['tree_sort']!, _treeSortMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      libraryPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_path'],
      ),
      debugLogsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}debug_logs_enabled'],
      )!,
      lineNumbers: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}line_numbers'],
      )!,
      editorAutofocus: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}editor_autofocus'],
      )!,
      previewMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preview_mode'],
      )!,
      splitRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}split_ratio'],
      )!,
      treeSort: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tree_sort'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  /// Row id; always 1.
  final int id;

  /// Last opened library root, used to resume the library on startup;
  /// null until a library has been opened.
  final String? libraryPath;

  /// Whether the in-app debug log buffer records events (default true).
  final bool debugLogsEnabled;

  /// Whether the note editor shows the row-number column (default true).
  final bool lineNumbers;

  /// Whether the note editor focuses (shows the keyboard) when a note
  /// opens (default false — the keyboard appears on the first tap).
  final bool editorAutofocus;

  /// The preview layout mode: `auto` (width-based), `split` or `switch`
  /// (forced; default `auto`).
  final String previewMode;

  /// The editor|preview split fraction (0..1; default 0.55).
  final double splitRatio;

  /// The library tree sort order (T-UI-03): the [TreeSort] `.name`
  /// value, `nameAsc` or `nameDesc`.
  final String treeSort;
  const AppSetting({
    required this.id,
    this.libraryPath,
    required this.debugLogsEnabled,
    required this.lineNumbers,
    required this.editorAutofocus,
    required this.previewMode,
    required this.splitRatio,
    required this.treeSort,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || libraryPath != null) {
      map['library_path'] = Variable<String>(libraryPath);
    }
    map['debug_logs_enabled'] = Variable<bool>(debugLogsEnabled);
    map['line_numbers'] = Variable<bool>(lineNumbers);
    map['editor_autofocus'] = Variable<bool>(editorAutofocus);
    map['preview_mode'] = Variable<String>(previewMode);
    map['split_ratio'] = Variable<double>(splitRatio);
    map['tree_sort'] = Variable<String>(treeSort);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      libraryPath: libraryPath == null && nullToAbsent
          ? const Value.absent()
          : Value(libraryPath),
      debugLogsEnabled: Value(debugLogsEnabled),
      lineNumbers: Value(lineNumbers),
      editorAutofocus: Value(editorAutofocus),
      previewMode: Value(previewMode),
      splitRatio: Value(splitRatio),
      treeSort: Value(treeSort),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      libraryPath: serializer.fromJson<String?>(json['libraryPath']),
      debugLogsEnabled: serializer.fromJson<bool>(json['debugLogsEnabled']),
      lineNumbers: serializer.fromJson<bool>(json['lineNumbers']),
      editorAutofocus: serializer.fromJson<bool>(json['editorAutofocus']),
      previewMode: serializer.fromJson<String>(json['previewMode']),
      splitRatio: serializer.fromJson<double>(json['splitRatio']),
      treeSort: serializer.fromJson<String>(json['treeSort']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'libraryPath': serializer.toJson<String?>(libraryPath),
      'debugLogsEnabled': serializer.toJson<bool>(debugLogsEnabled),
      'lineNumbers': serializer.toJson<bool>(lineNumbers),
      'editorAutofocus': serializer.toJson<bool>(editorAutofocus),
      'previewMode': serializer.toJson<String>(previewMode),
      'splitRatio': serializer.toJson<double>(splitRatio),
      'treeSort': serializer.toJson<String>(treeSort),
    };
  }

  AppSetting copyWith({
    int? id,
    Value<String?> libraryPath = const Value.absent(),
    bool? debugLogsEnabled,
    bool? lineNumbers,
    bool? editorAutofocus,
    String? previewMode,
    double? splitRatio,
    String? treeSort,
  }) => AppSetting(
    id: id ?? this.id,
    libraryPath: libraryPath.present ? libraryPath.value : this.libraryPath,
    debugLogsEnabled: debugLogsEnabled ?? this.debugLogsEnabled,
    lineNumbers: lineNumbers ?? this.lineNumbers,
    editorAutofocus: editorAutofocus ?? this.editorAutofocus,
    previewMode: previewMode ?? this.previewMode,
    splitRatio: splitRatio ?? this.splitRatio,
    treeSort: treeSort ?? this.treeSort,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      libraryPath: data.libraryPath.present
          ? data.libraryPath.value
          : this.libraryPath,
      debugLogsEnabled: data.debugLogsEnabled.present
          ? data.debugLogsEnabled.value
          : this.debugLogsEnabled,
      lineNumbers: data.lineNumbers.present
          ? data.lineNumbers.value
          : this.lineNumbers,
      editorAutofocus: data.editorAutofocus.present
          ? data.editorAutofocus.value
          : this.editorAutofocus,
      previewMode: data.previewMode.present
          ? data.previewMode.value
          : this.previewMode,
      splitRatio: data.splitRatio.present
          ? data.splitRatio.value
          : this.splitRatio,
      treeSort: data.treeSort.present ? data.treeSort.value : this.treeSort,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('libraryPath: $libraryPath, ')
          ..write('debugLogsEnabled: $debugLogsEnabled, ')
          ..write('lineNumbers: $lineNumbers, ')
          ..write('editorAutofocus: $editorAutofocus, ')
          ..write('previewMode: $previewMode, ')
          ..write('splitRatio: $splitRatio, ')
          ..write('treeSort: $treeSort')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    libraryPath,
    debugLogsEnabled,
    lineNumbers,
    editorAutofocus,
    previewMode,
    splitRatio,
    treeSort,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.libraryPath == this.libraryPath &&
          other.debugLogsEnabled == this.debugLogsEnabled &&
          other.lineNumbers == this.lineNumbers &&
          other.editorAutofocus == this.editorAutofocus &&
          other.previewMode == this.previewMode &&
          other.splitRatio == this.splitRatio &&
          other.treeSort == this.treeSort);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String?> libraryPath;
  final Value<bool> debugLogsEnabled;
  final Value<bool> lineNumbers;
  final Value<bool> editorAutofocus;
  final Value<String> previewMode;
  final Value<double> splitRatio;
  final Value<String> treeSort;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.libraryPath = const Value.absent(),
    this.debugLogsEnabled = const Value.absent(),
    this.lineNumbers = const Value.absent(),
    this.editorAutofocus = const Value.absent(),
    this.previewMode = const Value.absent(),
    this.splitRatio = const Value.absent(),
    this.treeSort = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.libraryPath = const Value.absent(),
    this.debugLogsEnabled = const Value.absent(),
    this.lineNumbers = const Value.absent(),
    this.editorAutofocus = const Value.absent(),
    this.previewMode = const Value.absent(),
    this.splitRatio = const Value.absent(),
    this.treeSort = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? libraryPath,
    Expression<bool>? debugLogsEnabled,
    Expression<bool>? lineNumbers,
    Expression<bool>? editorAutofocus,
    Expression<String>? previewMode,
    Expression<double>? splitRatio,
    Expression<String>? treeSort,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (libraryPath != null) 'library_path': libraryPath,
      if (debugLogsEnabled != null) 'debug_logs_enabled': debugLogsEnabled,
      if (lineNumbers != null) 'line_numbers': lineNumbers,
      if (editorAutofocus != null) 'editor_autofocus': editorAutofocus,
      if (previewMode != null) 'preview_mode': previewMode,
      if (splitRatio != null) 'split_ratio': splitRatio,
      if (treeSort != null) 'tree_sort': treeSort,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? libraryPath,
    Value<bool>? debugLogsEnabled,
    Value<bool>? lineNumbers,
    Value<bool>? editorAutofocus,
    Value<String>? previewMode,
    Value<double>? splitRatio,
    Value<String>? treeSort,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      libraryPath: libraryPath ?? this.libraryPath,
      debugLogsEnabled: debugLogsEnabled ?? this.debugLogsEnabled,
      lineNumbers: lineNumbers ?? this.lineNumbers,
      editorAutofocus: editorAutofocus ?? this.editorAutofocus,
      previewMode: previewMode ?? this.previewMode,
      splitRatio: splitRatio ?? this.splitRatio,
      treeSort: treeSort ?? this.treeSort,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (libraryPath.present) {
      map['library_path'] = Variable<String>(libraryPath.value);
    }
    if (debugLogsEnabled.present) {
      map['debug_logs_enabled'] = Variable<bool>(debugLogsEnabled.value);
    }
    if (lineNumbers.present) {
      map['line_numbers'] = Variable<bool>(lineNumbers.value);
    }
    if (editorAutofocus.present) {
      map['editor_autofocus'] = Variable<bool>(editorAutofocus.value);
    }
    if (previewMode.present) {
      map['preview_mode'] = Variable<String>(previewMode.value);
    }
    if (splitRatio.present) {
      map['split_ratio'] = Variable<double>(splitRatio.value);
    }
    if (treeSort.present) {
      map['tree_sort'] = Variable<String>(treeSort.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('libraryPath: $libraryPath, ')
          ..write('debugLogsEnabled: $debugLogsEnabled, ')
          ..write('lineNumbers: $lineNumbers, ')
          ..write('editorAutofocus: $editorAutofocus, ')
          ..write('previewMode: $previewMode, ')
          ..write('splitRatio: $splitRatio, ')
          ..write('treeSort: $treeSort')
          ..write(')'))
        .toString();
  }
}

abstract class _$CopistDatabase extends GeneratedDatabase {
  _$CopistDatabase(QueryExecutor e) : super(e);
  $CopistDatabaseManager get managers => $CopistDatabaseManager(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $LibrarySettingsTable librarySettings = $LibrarySettingsTable(
    this,
  );
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    notes,
    librarySettings,
    appSettings,
  ];
}

typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  required String path,
  required int parent,
  required String name,
  required bool isDir,
  required int size,
  required DateTime modified,
  Value<String?> sha256,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  Value<String> path,
  Value<int> parent,
  Value<String> name,
  Value<bool> isDir,
  Value<int> size,
  Value<DateTime> modified,
  Value<String?> sha256,
});

class $$NotesTableFilterComposer
    extends Composer<_$CopistDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parent => $composableBuilder(
    column: $table.parent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDir => $composableBuilder(
    column: $table.isDir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$CopistDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parent => $composableBuilder(
    column: $table.parent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDir => $composableBuilder(
    column: $table.isDir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$CopistDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get parent =>
      $composableBuilder(column: $table.parent, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isDir =>
      $composableBuilder(column: $table.isDir, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<DateTime> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$CopistDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, BaseReferences<_$CopistDatabase, $NotesTable, Note>),
          Note,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$CopistDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int> parent = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isDir = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<DateTime> modified = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                path: path,
                parent: parent,
                name: name,
                isDir: isDir,
                size: size,
                modified: modified,
                sha256: sha256,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String path,
                required int parent,
                required String name,
                required bool isDir,
                required int size,
                required DateTime modified,
                Value<String?> sha256 = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                path: path,
                parent: parent,
                name: name,
                isDir: isDir,
                size: size,
                modified: modified,
                sha256: sha256,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$CopistDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, BaseReferences<_$CopistDatabase, $NotesTable, Note>),
      Note,
      PrefetchHooks Function()
    >;
typedef $$LibrarySettingsTableCreateCompanionBuilder =
    LibrarySettingsCompanion Function({
      required String path,
      required bool trashEnabled,
      required int historyVersions,
      Value<String?> quickNotePath,
      Value<int> rowid,
    });
typedef $$LibrarySettingsTableUpdateCompanionBuilder =
    LibrarySettingsCompanion Function({
      Value<String> path,
      Value<bool> trashEnabled,
      Value<int> historyVersions,
      Value<String?> quickNotePath,
      Value<int> rowid,
    });

class $$LibrarySettingsTableFilterComposer
    extends Composer<_$CopistDatabase, $LibrarySettingsTable> {
  $$LibrarySettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get trashEnabled => $composableBuilder(
    column: $table.trashEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get historyVersions => $composableBuilder(
    column: $table.historyVersions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quickNotePath => $composableBuilder(
    column: $table.quickNotePath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LibrarySettingsTableOrderingComposer
    extends Composer<_$CopistDatabase, $LibrarySettingsTable> {
  $$LibrarySettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get trashEnabled => $composableBuilder(
    column: $table.trashEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get historyVersions => $composableBuilder(
    column: $table.historyVersions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quickNotePath => $composableBuilder(
    column: $table.quickNotePath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibrarySettingsTableAnnotationComposer
    extends Composer<_$CopistDatabase, $LibrarySettingsTable> {
  $$LibrarySettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<bool> get trashEnabled => $composableBuilder(
    column: $table.trashEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get historyVersions => $composableBuilder(
    column: $table.historyVersions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quickNotePath => $composableBuilder(
    column: $table.quickNotePath,
    builder: (column) => column,
  );
}

class $$LibrarySettingsTableTableManager
    extends
        RootTableManager<
          _$CopistDatabase,
          $LibrarySettingsTable,
          LibrarySetting,
          $$LibrarySettingsTableFilterComposer,
          $$LibrarySettingsTableOrderingComposer,
          $$LibrarySettingsTableAnnotationComposer,
          $$LibrarySettingsTableCreateCompanionBuilder,
          $$LibrarySettingsTableUpdateCompanionBuilder,
          (
            LibrarySetting,
            BaseReferences<
              _$CopistDatabase,
              $LibrarySettingsTable,
              LibrarySetting
            >,
          ),
          LibrarySetting,
          PrefetchHooks Function()
        > {
  $$LibrarySettingsTableTableManager(
    _$CopistDatabase db,
    $LibrarySettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibrarySettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibrarySettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibrarySettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> path = const Value.absent(),
                Value<bool> trashEnabled = const Value.absent(),
                Value<int> historyVersions = const Value.absent(),
                Value<String?> quickNotePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibrarySettingsCompanion(
                path: path,
                trashEnabled: trashEnabled,
                historyVersions: historyVersions,
                quickNotePath: quickNotePath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String path,
                required bool trashEnabled,
                required int historyVersions,
                Value<String?> quickNotePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibrarySettingsCompanion.insert(
                path: path,
                trashEnabled: trashEnabled,
                historyVersions: historyVersions,
                quickNotePath: quickNotePath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LibrarySettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$CopistDatabase,
      $LibrarySettingsTable,
      LibrarySetting,
      $$LibrarySettingsTableFilterComposer,
      $$LibrarySettingsTableOrderingComposer,
      $$LibrarySettingsTableAnnotationComposer,
      $$LibrarySettingsTableCreateCompanionBuilder,
      $$LibrarySettingsTableUpdateCompanionBuilder,
      (
        LibrarySetting,
        BaseReferences<_$CopistDatabase, $LibrarySettingsTable, LibrarySetting>,
      ),
      LibrarySetting,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String?> libraryPath,
      Value<bool> debugLogsEnabled,
      Value<bool> lineNumbers,
      Value<bool> editorAutofocus,
      Value<String> previewMode,
      Value<double> splitRatio,
      Value<String> treeSort,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String?> libraryPath,
      Value<bool> debugLogsEnabled,
      Value<bool> lineNumbers,
      Value<bool> editorAutofocus,
      Value<String> previewMode,
      Value<double> splitRatio,
      Value<String> treeSort,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$CopistDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get debugLogsEnabled => $composableBuilder(
    column: $table.debugLogsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lineNumbers => $composableBuilder(
    column: $table.lineNumbers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get editorAutofocus => $composableBuilder(
    column: $table.editorAutofocus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previewMode => $composableBuilder(
    column: $table.previewMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get splitRatio => $composableBuilder(
    column: $table.splitRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get treeSort => $composableBuilder(
    column: $table.treeSort,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$CopistDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get debugLogsEnabled => $composableBuilder(
    column: $table.debugLogsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lineNumbers => $composableBuilder(
    column: $table.lineNumbers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get editorAutofocus => $composableBuilder(
    column: $table.editorAutofocus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previewMode => $composableBuilder(
    column: $table.previewMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get splitRatio => $composableBuilder(
    column: $table.splitRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get treeSort => $composableBuilder(
    column: $table.treeSort,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$CopistDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get debugLogsEnabled => $composableBuilder(
    column: $table.debugLogsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lineNumbers => $composableBuilder(
    column: $table.lineNumbers,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get editorAutofocus => $composableBuilder(
    column: $table.editorAutofocus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get previewMode => $composableBuilder(
    column: $table.previewMode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get splitRatio => $composableBuilder(
    column: $table.splitRatio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get treeSort =>
      $composableBuilder(column: $table.treeSort, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$CopistDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$CopistDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$CopistDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> libraryPath = const Value.absent(),
                Value<bool> debugLogsEnabled = const Value.absent(),
                Value<bool> lineNumbers = const Value.absent(),
                Value<bool> editorAutofocus = const Value.absent(),
                Value<String> previewMode = const Value.absent(),
                Value<double> splitRatio = const Value.absent(),
                Value<String> treeSort = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                libraryPath: libraryPath,
                debugLogsEnabled: debugLogsEnabled,
                lineNumbers: lineNumbers,
                editorAutofocus: editorAutofocus,
                previewMode: previewMode,
                splitRatio: splitRatio,
                treeSort: treeSort,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> libraryPath = const Value.absent(),
                Value<bool> debugLogsEnabled = const Value.absent(),
                Value<bool> lineNumbers = const Value.absent(),
                Value<bool> editorAutofocus = const Value.absent(),
                Value<String> previewMode = const Value.absent(),
                Value<double> splitRatio = const Value.absent(),
                Value<String> treeSort = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                libraryPath: libraryPath,
                debugLogsEnabled: debugLogsEnabled,
                lineNumbers: lineNumbers,
                editorAutofocus: editorAutofocus,
                previewMode: previewMode,
                splitRatio: splitRatio,
                treeSort: treeSort,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$CopistDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$CopistDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $CopistDatabaseManager {
  final _$CopistDatabase _db;
  $CopistDatabaseManager(this._db);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$LibrarySettingsTableTableManager get librarySettings =>
      $$LibrarySettingsTableTableManager(_db, _db.librarySettings);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
