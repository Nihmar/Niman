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
  static const VerificationMeta _reminderShowTokensMeta =
      const VerificationMeta('reminderShowTokens');
  @override
  late final GeneratedColumn<bool> reminderShowTokens = GeneratedColumn<bool>(
    'reminder_show_tokens',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminder_show_tokens" IN (0, 1))',
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
  static const VerificationMeta _linkTypeMeta = const VerificationMeta(
    'linkType',
  );
  @override
  late final GeneratedColumn<String> linkType = GeneratedColumn<String>(
    'link_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('wikilink'),
  );
  static const VerificationMeta _indentWidthMeta = const VerificationMeta(
    'indentWidth',
  );
  @override
  late final GeneratedColumn<int> indentWidth = GeneratedColumn<int>(
    'indent_width',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _editorToolbarMeta = const VerificationMeta(
    'editorToolbar',
  );
  @override
  late final GeneratedColumn<String> editorToolbar = GeneratedColumn<String>(
    'editor_toolbar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _legacyLibrarySettingsMeta =
      const VerificationMeta('legacyLibrarySettings');
  @override
  late final GeneratedColumn<String> legacyLibrarySettings =
      GeneratedColumn<String>(
        'legacy_library_settings',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    libraryPath,
    debugLogsEnabled,
    lineNumbers,
    editorAutofocus,
    reminderShowTokens,
    previewMode,
    splitRatio,
    treeSort,
    linkType,
    indentWidth,
    editorToolbar,
    language,
    legacyLibrarySettings,
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
    if (data.containsKey('reminder_show_tokens')) {
      context.handle(
        _reminderShowTokensMeta,
        reminderShowTokens.isAcceptableOrUnknown(
          data['reminder_show_tokens']!,
          _reminderShowTokensMeta,
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
    if (data.containsKey('link_type')) {
      context.handle(
        _linkTypeMeta,
        linkType.isAcceptableOrUnknown(data['link_type']!, _linkTypeMeta),
      );
    }
    if (data.containsKey('indent_width')) {
      context.handle(
        _indentWidthMeta,
        indentWidth.isAcceptableOrUnknown(
          data['indent_width']!,
          _indentWidthMeta,
        ),
      );
    }
    if (data.containsKey('editor_toolbar')) {
      context.handle(
        _editorToolbarMeta,
        editorToolbar.isAcceptableOrUnknown(
          data['editor_toolbar']!,
          _editorToolbarMeta,
        ),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('legacy_library_settings')) {
      context.handle(
        _legacyLibrarySettingsMeta,
        legacyLibrarySettings.isAcceptableOrUnknown(
          data['legacy_library_settings']!,
          _legacyLibrarySettingsMeta,
        ),
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
      reminderShowTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminder_show_tokens'],
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
      linkType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link_type'],
      )!,
      indentWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}indent_width'],
      )!,
      editorToolbar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}editor_toolbar'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      legacyLibrarySettings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_library_settings'],
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

  /// Whether a reminder's notification text keeps the `+project`,
  /// `@context` and `#tag` markers (default false).
  ///
  /// In the list they carry meaning next to the checkbox and the filter
  /// chips; on a lock screen there is nothing to explain them, so they
  /// are off by default — but someone who files by project may want them.
  final bool reminderShowTokens;

  /// The preview layout mode: `auto` (width-based), `split` or `switch`
  /// (forced; default `auto`).
  final String previewMode;

  /// The editor|preview split fraction (0..1; default 0.55).
  final double splitRatio;

  /// The library tree sort order (T-UI-03): the sort enum `.name`
  /// value (`nameAsc` or `nameDesc`).
  final String treeSort;

  /// The link format the editor's link button inserts: `wikilink`
  /// (`[[…]]`) or `markdown` (`[…](…)`; default `wikilink`).
  final String linkType;

  /// The editor's indent/outdent width in spaces (default 2).
  final int indentWidth;

  /// The editor toolbar the user arranged: every button id in their
  /// order, a `-` prefix marking a hidden one (see `ToolbarLayout`).
  /// Empty means the shipped toolbar.
  final String editorToolbar;

  /// The UI language: `system` (follow the OS, the default), `en` or
  /// `it`.
  final String language;

  /// The settings the dropped `library_settings` table held, waiting to
  /// reach the libraries they belong to (T-ML-02).
  ///
  /// A JSON object keyed by absolute library path; empty (`''`) once
  /// every one of them has been opened at least once, and on any install
  /// that never had the table. It exists because the two events cannot be
  /// made to coincide: the table is dropped when the database migrates,
  /// which on Android happens at startup, while the library folder is
  /// only writable later, after the storage permission — and a library on
  /// a disconnected drive may not be writable for weeks.
  final String legacyLibrarySettings;
  const AppSetting({
    required this.id,
    this.libraryPath,
    required this.debugLogsEnabled,
    required this.lineNumbers,
    required this.editorAutofocus,
    required this.reminderShowTokens,
    required this.previewMode,
    required this.splitRatio,
    required this.treeSort,
    required this.linkType,
    required this.indentWidth,
    required this.editorToolbar,
    required this.language,
    required this.legacyLibrarySettings,
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
    map['reminder_show_tokens'] = Variable<bool>(reminderShowTokens);
    map['preview_mode'] = Variable<String>(previewMode);
    map['split_ratio'] = Variable<double>(splitRatio);
    map['tree_sort'] = Variable<String>(treeSort);
    map['link_type'] = Variable<String>(linkType);
    map['indent_width'] = Variable<int>(indentWidth);
    map['editor_toolbar'] = Variable<String>(editorToolbar);
    map['language'] = Variable<String>(language);
    map['legacy_library_settings'] = Variable<String>(legacyLibrarySettings);
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
      reminderShowTokens: Value(reminderShowTokens),
      previewMode: Value(previewMode),
      splitRatio: Value(splitRatio),
      treeSort: Value(treeSort),
      linkType: Value(linkType),
      indentWidth: Value(indentWidth),
      editorToolbar: Value(editorToolbar),
      language: Value(language),
      legacyLibrarySettings: Value(legacyLibrarySettings),
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
      reminderShowTokens: serializer.fromJson<bool>(json['reminderShowTokens']),
      previewMode: serializer.fromJson<String>(json['previewMode']),
      splitRatio: serializer.fromJson<double>(json['splitRatio']),
      treeSort: serializer.fromJson<String>(json['treeSort']),
      linkType: serializer.fromJson<String>(json['linkType']),
      indentWidth: serializer.fromJson<int>(json['indentWidth']),
      editorToolbar: serializer.fromJson<String>(json['editorToolbar']),
      language: serializer.fromJson<String>(json['language']),
      legacyLibrarySettings: serializer.fromJson<String>(
        json['legacyLibrarySettings'],
      ),
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
      'reminderShowTokens': serializer.toJson<bool>(reminderShowTokens),
      'previewMode': serializer.toJson<String>(previewMode),
      'splitRatio': serializer.toJson<double>(splitRatio),
      'treeSort': serializer.toJson<String>(treeSort),
      'linkType': serializer.toJson<String>(linkType),
      'indentWidth': serializer.toJson<int>(indentWidth),
      'editorToolbar': serializer.toJson<String>(editorToolbar),
      'language': serializer.toJson<String>(language),
      'legacyLibrarySettings': serializer.toJson<String>(legacyLibrarySettings),
    };
  }

  AppSetting copyWith({
    int? id,
    Value<String?> libraryPath = const Value.absent(),
    bool? debugLogsEnabled,
    bool? lineNumbers,
    bool? editorAutofocus,
    bool? reminderShowTokens,
    String? previewMode,
    double? splitRatio,
    String? treeSort,
    String? linkType,
    int? indentWidth,
    String? editorToolbar,
    String? language,
    String? legacyLibrarySettings,
  }) => AppSetting(
    id: id ?? this.id,
    libraryPath: libraryPath.present ? libraryPath.value : this.libraryPath,
    debugLogsEnabled: debugLogsEnabled ?? this.debugLogsEnabled,
    lineNumbers: lineNumbers ?? this.lineNumbers,
    editorAutofocus: editorAutofocus ?? this.editorAutofocus,
    reminderShowTokens: reminderShowTokens ?? this.reminderShowTokens,
    previewMode: previewMode ?? this.previewMode,
    splitRatio: splitRatio ?? this.splitRatio,
    treeSort: treeSort ?? this.treeSort,
    linkType: linkType ?? this.linkType,
    indentWidth: indentWidth ?? this.indentWidth,
    editorToolbar: editorToolbar ?? this.editorToolbar,
    language: language ?? this.language,
    legacyLibrarySettings: legacyLibrarySettings ?? this.legacyLibrarySettings,
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
      reminderShowTokens: data.reminderShowTokens.present
          ? data.reminderShowTokens.value
          : this.reminderShowTokens,
      previewMode: data.previewMode.present
          ? data.previewMode.value
          : this.previewMode,
      splitRatio: data.splitRatio.present
          ? data.splitRatio.value
          : this.splitRatio,
      treeSort: data.treeSort.present ? data.treeSort.value : this.treeSort,
      linkType: data.linkType.present ? data.linkType.value : this.linkType,
      indentWidth: data.indentWidth.present
          ? data.indentWidth.value
          : this.indentWidth,
      editorToolbar: data.editorToolbar.present
          ? data.editorToolbar.value
          : this.editorToolbar,
      language: data.language.present ? data.language.value : this.language,
      legacyLibrarySettings: data.legacyLibrarySettings.present
          ? data.legacyLibrarySettings.value
          : this.legacyLibrarySettings,
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
          ..write('reminderShowTokens: $reminderShowTokens, ')
          ..write('previewMode: $previewMode, ')
          ..write('splitRatio: $splitRatio, ')
          ..write('treeSort: $treeSort, ')
          ..write('linkType: $linkType, ')
          ..write('indentWidth: $indentWidth, ')
          ..write('editorToolbar: $editorToolbar, ')
          ..write('language: $language, ')
          ..write('legacyLibrarySettings: $legacyLibrarySettings')
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
    reminderShowTokens,
    previewMode,
    splitRatio,
    treeSort,
    linkType,
    indentWidth,
    editorToolbar,
    language,
    legacyLibrarySettings,
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
          other.reminderShowTokens == this.reminderShowTokens &&
          other.previewMode == this.previewMode &&
          other.splitRatio == this.splitRatio &&
          other.treeSort == this.treeSort &&
          other.linkType == this.linkType &&
          other.indentWidth == this.indentWidth &&
          other.editorToolbar == this.editorToolbar &&
          other.language == this.language &&
          other.legacyLibrarySettings == this.legacyLibrarySettings);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String?> libraryPath;
  final Value<bool> debugLogsEnabled;
  final Value<bool> lineNumbers;
  final Value<bool> editorAutofocus;
  final Value<bool> reminderShowTokens;
  final Value<String> previewMode;
  final Value<double> splitRatio;
  final Value<String> treeSort;
  final Value<String> linkType;
  final Value<int> indentWidth;
  final Value<String> editorToolbar;
  final Value<String> language;
  final Value<String> legacyLibrarySettings;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.libraryPath = const Value.absent(),
    this.debugLogsEnabled = const Value.absent(),
    this.lineNumbers = const Value.absent(),
    this.editorAutofocus = const Value.absent(),
    this.reminderShowTokens = const Value.absent(),
    this.previewMode = const Value.absent(),
    this.splitRatio = const Value.absent(),
    this.treeSort = const Value.absent(),
    this.linkType = const Value.absent(),
    this.indentWidth = const Value.absent(),
    this.editorToolbar = const Value.absent(),
    this.language = const Value.absent(),
    this.legacyLibrarySettings = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.libraryPath = const Value.absent(),
    this.debugLogsEnabled = const Value.absent(),
    this.lineNumbers = const Value.absent(),
    this.editorAutofocus = const Value.absent(),
    this.reminderShowTokens = const Value.absent(),
    this.previewMode = const Value.absent(),
    this.splitRatio = const Value.absent(),
    this.treeSort = const Value.absent(),
    this.linkType = const Value.absent(),
    this.indentWidth = const Value.absent(),
    this.editorToolbar = const Value.absent(),
    this.language = const Value.absent(),
    this.legacyLibrarySettings = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? libraryPath,
    Expression<bool>? debugLogsEnabled,
    Expression<bool>? lineNumbers,
    Expression<bool>? editorAutofocus,
    Expression<bool>? reminderShowTokens,
    Expression<String>? previewMode,
    Expression<double>? splitRatio,
    Expression<String>? treeSort,
    Expression<String>? linkType,
    Expression<int>? indentWidth,
    Expression<String>? editorToolbar,
    Expression<String>? language,
    Expression<String>? legacyLibrarySettings,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (libraryPath != null) 'library_path': libraryPath,
      if (debugLogsEnabled != null) 'debug_logs_enabled': debugLogsEnabled,
      if (lineNumbers != null) 'line_numbers': lineNumbers,
      if (editorAutofocus != null) 'editor_autofocus': editorAutofocus,
      if (reminderShowTokens != null)
        'reminder_show_tokens': reminderShowTokens,
      if (previewMode != null) 'preview_mode': previewMode,
      if (splitRatio != null) 'split_ratio': splitRatio,
      if (treeSort != null) 'tree_sort': treeSort,
      if (linkType != null) 'link_type': linkType,
      if (indentWidth != null) 'indent_width': indentWidth,
      if (editorToolbar != null) 'editor_toolbar': editorToolbar,
      if (language != null) 'language': language,
      if (legacyLibrarySettings != null)
        'legacy_library_settings': legacyLibrarySettings,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? libraryPath,
    Value<bool>? debugLogsEnabled,
    Value<bool>? lineNumbers,
    Value<bool>? editorAutofocus,
    Value<bool>? reminderShowTokens,
    Value<String>? previewMode,
    Value<double>? splitRatio,
    Value<String>? treeSort,
    Value<String>? linkType,
    Value<int>? indentWidth,
    Value<String>? editorToolbar,
    Value<String>? language,
    Value<String>? legacyLibrarySettings,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      libraryPath: libraryPath ?? this.libraryPath,
      debugLogsEnabled: debugLogsEnabled ?? this.debugLogsEnabled,
      lineNumbers: lineNumbers ?? this.lineNumbers,
      editorAutofocus: editorAutofocus ?? this.editorAutofocus,
      reminderShowTokens: reminderShowTokens ?? this.reminderShowTokens,
      previewMode: previewMode ?? this.previewMode,
      splitRatio: splitRatio ?? this.splitRatio,
      treeSort: treeSort ?? this.treeSort,
      linkType: linkType ?? this.linkType,
      indentWidth: indentWidth ?? this.indentWidth,
      editorToolbar: editorToolbar ?? this.editorToolbar,
      language: language ?? this.language,
      legacyLibrarySettings:
          legacyLibrarySettings ?? this.legacyLibrarySettings,
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
    if (reminderShowTokens.present) {
      map['reminder_show_tokens'] = Variable<bool>(reminderShowTokens.value);
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
    if (linkType.present) {
      map['link_type'] = Variable<String>(linkType.value);
    }
    if (indentWidth.present) {
      map['indent_width'] = Variable<int>(indentWidth.value);
    }
    if (editorToolbar.present) {
      map['editor_toolbar'] = Variable<String>(editorToolbar.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (legacyLibrarySettings.present) {
      map['legacy_library_settings'] = Variable<String>(
        legacyLibrarySettings.value,
      );
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
          ..write('reminderShowTokens: $reminderShowTokens, ')
          ..write('previewMode: $previewMode, ')
          ..write('splitRatio: $splitRatio, ')
          ..write('treeSort: $treeSort, ')
          ..write('linkType: $linkType, ')
          ..write('indentWidth: $indentWidth, ')
          ..write('editorToolbar: $editorToolbar, ')
          ..write('language: $language, ')
          ..write('legacyLibrarySettings: $legacyLibrarySettings')
          ..write(')'))
        .toString();
  }
}

class $NoteStemsTable extends NoteStems
    with TableInfo<$NoteStemsTable, NoteStem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteStemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _stemMeta = const VerificationMeta('stem');
  @override
  late final GeneratedColumn<String> stem = GeneratedColumn<String>(
    'stem',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'COLLATE NOCASE',
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<int> noteId = GeneratedColumn<int>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [stem, noteId, source];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_stems';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteStem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('stem')) {
      context.handle(
        _stemMeta,
        stem.isAcceptableOrUnknown(data['stem']!, _stemMeta),
      );
    } else if (isInserting) {
      context.missing(_stemMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {stem, noteId, source};
  @override
  NoteStem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteStem(
      stem: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stem'],
      )!,
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}note_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $NoteStemsTable createAlias(String alias) {
    return $NoteStemsTable(attachedDatabase, alias);
  }
}

class NoteStem extends DataClass implements Insertable<NoteStem> {
  /// The normalized (lowercased) stem or alias text.
  final String stem;

  /// The id of the note row the stem points at.
  final int noteId;

  /// Where the stem came from: `file` (the filename stem) or `alias`
  /// (a frontmatter alias).
  final String source;
  const NoteStem({
    required this.stem,
    required this.noteId,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['stem'] = Variable<String>(stem);
    map['note_id'] = Variable<int>(noteId);
    map['source'] = Variable<String>(source);
    return map;
  }

  NoteStemsCompanion toCompanion(bool nullToAbsent) {
    return NoteStemsCompanion(
      stem: Value(stem),
      noteId: Value(noteId),
      source: Value(source),
    );
  }

  factory NoteStem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteStem(
      stem: serializer.fromJson<String>(json['stem']),
      noteId: serializer.fromJson<int>(json['noteId']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'stem': serializer.toJson<String>(stem),
      'noteId': serializer.toJson<int>(noteId),
      'source': serializer.toJson<String>(source),
    };
  }

  NoteStem copyWith({String? stem, int? noteId, String? source}) => NoteStem(
    stem: stem ?? this.stem,
    noteId: noteId ?? this.noteId,
    source: source ?? this.source,
  );
  NoteStem copyWithCompanion(NoteStemsCompanion data) {
    return NoteStem(
      stem: data.stem.present ? data.stem.value : this.stem,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteStem(')
          ..write('stem: $stem, ')
          ..write('noteId: $noteId, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(stem, noteId, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteStem &&
          other.stem == this.stem &&
          other.noteId == this.noteId &&
          other.source == this.source);
}

class NoteStemsCompanion extends UpdateCompanion<NoteStem> {
  final Value<String> stem;
  final Value<int> noteId;
  final Value<String> source;
  final Value<int> rowid;
  const NoteStemsCompanion({
    this.stem = const Value.absent(),
    this.noteId = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteStemsCompanion.insert({
    required String stem,
    required int noteId,
    required String source,
    this.rowid = const Value.absent(),
  }) : stem = Value(stem),
       noteId = Value(noteId),
       source = Value(source);
  static Insertable<NoteStem> custom({
    Expression<String>? stem,
    Expression<int>? noteId,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (stem != null) 'stem': stem,
      if (noteId != null) 'note_id': noteId,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteStemsCompanion copyWith({
    Value<String>? stem,
    Value<int>? noteId,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return NoteStemsCompanion(
      stem: stem ?? this.stem,
      noteId: noteId ?? this.noteId,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stem.present) {
      map['stem'] = Variable<String>(stem.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<int>(noteId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteStemsCompanion(')
          ..write('stem: $stem, ')
          ..write('noteId: $noteId, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  /// The normalized tag name.
  final String name;
  const Tag({required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(name: Value(name));
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(name: serializer.fromJson<String>(json['name']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'name': serializer.toJson<String>(name)};
  }

  Tag copyWith({String? name}) => Tag(name: name ?? this.name);
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(name: data.name.present ? data.name.value : this.name);
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => name.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Tag && other.name == this.name);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> name;
  final Value<int> rowid;
  const TagsCompanion({
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String name,
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Tag> custom({
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({Value<String>? name, Value<int>? rowid}) {
    return TagsCompanion(name: name ?? this.name, rowid: rowid ?? this.rowid);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteTagsTable extends NoteTags with TableInfo<$NoteTagsTable, NoteTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<int> noteId = GeneratedColumn<int>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFrontmatterMeta = const VerificationMeta(
    'isFrontmatter',
  );
  @override
  late final GeneratedColumn<bool> isFrontmatter = GeneratedColumn<bool>(
    'is_frontmatter',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_frontmatter" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [tag, noteId, isFrontmatter];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('is_frontmatter')) {
      context.handle(
        _isFrontmatterMeta,
        isFrontmatter.isAcceptableOrUnknown(
          data['is_frontmatter']!,
          _isFrontmatterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isFrontmatterMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tag, noteId, isFrontmatter};
  @override
  NoteTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteTag(
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}note_id'],
      )!,
      isFrontmatter: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_frontmatter'],
      )!,
    );
  }

  @override
  $NoteTagsTable createAlias(String alias) {
    return $NoteTagsTable(attachedDatabase, alias);
  }
}

class NoteTag extends DataClass implements Insertable<NoteTag> {
  /// The normalized tag name (see [Tags]).
  final String tag;

  /// The ids of the note row.
  final int noteId;

  /// Whether the tag came from frontmatter (true) or inline `#tag` (false).
  final bool isFrontmatter;
  const NoteTag({
    required this.tag,
    required this.noteId,
    required this.isFrontmatter,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tag'] = Variable<String>(tag);
    map['note_id'] = Variable<int>(noteId);
    map['is_frontmatter'] = Variable<bool>(isFrontmatter);
    return map;
  }

  NoteTagsCompanion toCompanion(bool nullToAbsent) {
    return NoteTagsCompanion(
      tag: Value(tag),
      noteId: Value(noteId),
      isFrontmatter: Value(isFrontmatter),
    );
  }

  factory NoteTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteTag(
      tag: serializer.fromJson<String>(json['tag']),
      noteId: serializer.fromJson<int>(json['noteId']),
      isFrontmatter: serializer.fromJson<bool>(json['isFrontmatter']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tag': serializer.toJson<String>(tag),
      'noteId': serializer.toJson<int>(noteId),
      'isFrontmatter': serializer.toJson<bool>(isFrontmatter),
    };
  }

  NoteTag copyWith({String? tag, int? noteId, bool? isFrontmatter}) => NoteTag(
    tag: tag ?? this.tag,
    noteId: noteId ?? this.noteId,
    isFrontmatter: isFrontmatter ?? this.isFrontmatter,
  );
  NoteTag copyWithCompanion(NoteTagsCompanion data) {
    return NoteTag(
      tag: data.tag.present ? data.tag.value : this.tag,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      isFrontmatter: data.isFrontmatter.present
          ? data.isFrontmatter.value
          : this.isFrontmatter,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteTag(')
          ..write('tag: $tag, ')
          ..write('noteId: $noteId, ')
          ..write('isFrontmatter: $isFrontmatter')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tag, noteId, isFrontmatter);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteTag &&
          other.tag == this.tag &&
          other.noteId == this.noteId &&
          other.isFrontmatter == this.isFrontmatter);
}

class NoteTagsCompanion extends UpdateCompanion<NoteTag> {
  final Value<String> tag;
  final Value<int> noteId;
  final Value<bool> isFrontmatter;
  final Value<int> rowid;
  const NoteTagsCompanion({
    this.tag = const Value.absent(),
    this.noteId = const Value.absent(),
    this.isFrontmatter = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteTagsCompanion.insert({
    required String tag,
    required int noteId,
    required bool isFrontmatter,
    this.rowid = const Value.absent(),
  }) : tag = Value(tag),
       noteId = Value(noteId),
       isFrontmatter = Value(isFrontmatter);
  static Insertable<NoteTag> custom({
    Expression<String>? tag,
    Expression<int>? noteId,
    Expression<bool>? isFrontmatter,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tag != null) 'tag': tag,
      if (noteId != null) 'note_id': noteId,
      if (isFrontmatter != null) 'is_frontmatter': isFrontmatter,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteTagsCompanion copyWith({
    Value<String>? tag,
    Value<int>? noteId,
    Value<bool>? isFrontmatter,
    Value<int>? rowid,
  }) {
    return NoteTagsCompanion(
      tag: tag ?? this.tag,
      noteId: noteId ?? this.noteId,
      isFrontmatter: isFrontmatter ?? this.isFrontmatter,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<int>(noteId.value);
    }
    if (isFrontmatter.present) {
      map['is_frontmatter'] = Variable<bool>(isFrontmatter.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteTagsCompanion(')
          ..write('tag: $tag, ')
          ..write('noteId: $noteId, ')
          ..write('isFrontmatter: $isFrontmatter, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteLinksTable extends NoteLinks
    with TableInfo<$NoteLinksTable, NoteLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fromNoteMeta = const VerificationMeta(
    'fromNote',
  );
  @override
  late final GeneratedColumn<int> fromNote = GeneratedColumn<int>(
    'from_note',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toNoteMeta = const VerificationMeta('toNote');
  @override
  late final GeneratedColumn<int> toNote = GeneratedColumn<int>(
    'to_note',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [fromNote, toNote, kind];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteLink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('from_note')) {
      context.handle(
        _fromNoteMeta,
        fromNote.isAcceptableOrUnknown(data['from_note']!, _fromNoteMeta),
      );
    } else if (isInserting) {
      context.missing(_fromNoteMeta);
    }
    if (data.containsKey('to_note')) {
      context.handle(
        _toNoteMeta,
        toNote.isAcceptableOrUnknown(data['to_note']!, _toNoteMeta),
      );
    } else if (isInserting) {
      context.missing(_toNoteMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fromNote, toNote, kind};
  @override
  NoteLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteLink(
      fromNote: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_note'],
      )!,
      toNote: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_note'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
    );
  }

  @override
  $NoteLinksTable createAlias(String alias) {
    return $NoteLinksTable(attachedDatabase, alias);
  }
}

class NoteLink extends DataClass implements Insertable<NoteLink> {
  /// The id of the note containing the link.
  final int fromNote;

  /// The id of the linked note.
  final int toNote;

  /// The link form: `wiki` (`[[…]]`) or `md` (`[t](p)`).
  final String kind;
  const NoteLink({
    required this.fromNote,
    required this.toNote,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['from_note'] = Variable<int>(fromNote);
    map['to_note'] = Variable<int>(toNote);
    map['kind'] = Variable<String>(kind);
    return map;
  }

  NoteLinksCompanion toCompanion(bool nullToAbsent) {
    return NoteLinksCompanion(
      fromNote: Value(fromNote),
      toNote: Value(toNote),
      kind: Value(kind),
    );
  }

  factory NoteLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteLink(
      fromNote: serializer.fromJson<int>(json['fromNote']),
      toNote: serializer.fromJson<int>(json['toNote']),
      kind: serializer.fromJson<String>(json['kind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fromNote': serializer.toJson<int>(fromNote),
      'toNote': serializer.toJson<int>(toNote),
      'kind': serializer.toJson<String>(kind),
    };
  }

  NoteLink copyWith({int? fromNote, int? toNote, String? kind}) => NoteLink(
    fromNote: fromNote ?? this.fromNote,
    toNote: toNote ?? this.toNote,
    kind: kind ?? this.kind,
  );
  NoteLink copyWithCompanion(NoteLinksCompanion data) {
    return NoteLink(
      fromNote: data.fromNote.present ? data.fromNote.value : this.fromNote,
      toNote: data.toNote.present ? data.toNote.value : this.toNote,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteLink(')
          ..write('fromNote: $fromNote, ')
          ..write('toNote: $toNote, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fromNote, toNote, kind);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteLink &&
          other.fromNote == this.fromNote &&
          other.toNote == this.toNote &&
          other.kind == this.kind);
}

class NoteLinksCompanion extends UpdateCompanion<NoteLink> {
  final Value<int> fromNote;
  final Value<int> toNote;
  final Value<String> kind;
  final Value<int> rowid;
  const NoteLinksCompanion({
    this.fromNote = const Value.absent(),
    this.toNote = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteLinksCompanion.insert({
    required int fromNote,
    required int toNote,
    required String kind,
    this.rowid = const Value.absent(),
  }) : fromNote = Value(fromNote),
       toNote = Value(toNote),
       kind = Value(kind);
  static Insertable<NoteLink> custom({
    Expression<int>? fromNote,
    Expression<int>? toNote,
    Expression<String>? kind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fromNote != null) 'from_note': fromNote,
      if (toNote != null) 'to_note': toNote,
      if (kind != null) 'kind': kind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteLinksCompanion copyWith({
    Value<int>? fromNote,
    Value<int>? toNote,
    Value<String>? kind,
    Value<int>? rowid,
  }) {
    return NoteLinksCompanion(
      fromNote: fromNote ?? this.fromNote,
      toNote: toNote ?? this.toNote,
      kind: kind ?? this.kind,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fromNote.present) {
      map['from_note'] = Variable<int>(fromNote.value);
    }
    if (toNote.present) {
      map['to_note'] = Variable<int>(toNote.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteLinksCompanion(')
          ..write('fromNote: $fromNote, ')
          ..write('toNote: $toNote, ')
          ..write('kind: $kind, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CopistDatabase extends GeneratedDatabase {
  _$CopistDatabase(QueryExecutor e) : super(e);
  $CopistDatabaseManager get managers => $CopistDatabaseManager(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $NoteStemsTable noteStems = $NoteStemsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $NoteTagsTable noteTags = $NoteTagsTable(this);
  late final $NoteLinksTable noteLinks = $NoteLinksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    notes,
    appSettings,
    noteStems,
    tags,
    noteTags,
    noteLinks,
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
              .map(
                (e) => (
                  e.readTable<$NotesTable, Note>(table),
                  BaseReferences<_$CopistDatabase, $NotesTable, Note>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
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
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String?> libraryPath,
      Value<bool> debugLogsEnabled,
      Value<bool> lineNumbers,
      Value<bool> editorAutofocus,
      Value<bool> reminderShowTokens,
      Value<String> previewMode,
      Value<double> splitRatio,
      Value<String> treeSort,
      Value<String> linkType,
      Value<int> indentWidth,
      Value<String> editorToolbar,
      Value<String> language,
      Value<String> legacyLibrarySettings,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String?> libraryPath,
      Value<bool> debugLogsEnabled,
      Value<bool> lineNumbers,
      Value<bool> editorAutofocus,
      Value<bool> reminderShowTokens,
      Value<String> previewMode,
      Value<double> splitRatio,
      Value<String> treeSort,
      Value<String> linkType,
      Value<int> indentWidth,
      Value<String> editorToolbar,
      Value<String> language,
      Value<String> legacyLibrarySettings,
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

  ColumnFilters<bool> get reminderShowTokens => $composableBuilder(
    column: $table.reminderShowTokens,
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

  ColumnFilters<String> get linkType => $composableBuilder(
    column: $table.linkType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get indentWidth => $composableBuilder(
    column: $table.indentWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get editorToolbar => $composableBuilder(
    column: $table.editorToolbar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legacyLibrarySettings => $composableBuilder(
    column: $table.legacyLibrarySettings,
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

  ColumnOrderings<bool> get reminderShowTokens => $composableBuilder(
    column: $table.reminderShowTokens,
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

  ColumnOrderings<String> get linkType => $composableBuilder(
    column: $table.linkType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get indentWidth => $composableBuilder(
    column: $table.indentWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get editorToolbar => $composableBuilder(
    column: $table.editorToolbar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legacyLibrarySettings => $composableBuilder(
    column: $table.legacyLibrarySettings,
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

  GeneratedColumn<bool> get reminderShowTokens => $composableBuilder(
    column: $table.reminderShowTokens,
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

  GeneratedColumn<String> get linkType =>
      $composableBuilder(column: $table.linkType, builder: (column) => column);

  GeneratedColumn<int> get indentWidth => $composableBuilder(
    column: $table.indentWidth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get editorToolbar => $composableBuilder(
    column: $table.editorToolbar,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get legacyLibrarySettings => $composableBuilder(
    column: $table.legacyLibrarySettings,
    builder: (column) => column,
  );
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
                Value<bool> reminderShowTokens = const Value.absent(),
                Value<String> previewMode = const Value.absent(),
                Value<double> splitRatio = const Value.absent(),
                Value<String> treeSort = const Value.absent(),
                Value<String> linkType = const Value.absent(),
                Value<int> indentWidth = const Value.absent(),
                Value<String> editorToolbar = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> legacyLibrarySettings = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                libraryPath: libraryPath,
                debugLogsEnabled: debugLogsEnabled,
                lineNumbers: lineNumbers,
                editorAutofocus: editorAutofocus,
                reminderShowTokens: reminderShowTokens,
                previewMode: previewMode,
                splitRatio: splitRatio,
                treeSort: treeSort,
                linkType: linkType,
                indentWidth: indentWidth,
                editorToolbar: editorToolbar,
                language: language,
                legacyLibrarySettings: legacyLibrarySettings,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> libraryPath = const Value.absent(),
                Value<bool> debugLogsEnabled = const Value.absent(),
                Value<bool> lineNumbers = const Value.absent(),
                Value<bool> editorAutofocus = const Value.absent(),
                Value<bool> reminderShowTokens = const Value.absent(),
                Value<String> previewMode = const Value.absent(),
                Value<double> splitRatio = const Value.absent(),
                Value<String> treeSort = const Value.absent(),
                Value<String> linkType = const Value.absent(),
                Value<int> indentWidth = const Value.absent(),
                Value<String> editorToolbar = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> legacyLibrarySettings = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                libraryPath: libraryPath,
                debugLogsEnabled: debugLogsEnabled,
                lineNumbers: lineNumbers,
                editorAutofocus: editorAutofocus,
                reminderShowTokens: reminderShowTokens,
                previewMode: previewMode,
                splitRatio: splitRatio,
                treeSort: treeSort,
                linkType: linkType,
                indentWidth: indentWidth,
                editorToolbar: editorToolbar,
                language: language,
                legacyLibrarySettings: legacyLibrarySettings,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<
                    _$CopistDatabase,
                    $AppSettingsTable,
                    AppSetting
                  >(db, table, e),
                ),
              )
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
typedef $$NoteStemsTableCreateCompanionBuilder = NoteStemsCompanion Function({
  required String stem,
  required int noteId,
  required String source,
  Value<int> rowid,
});
typedef $$NoteStemsTableUpdateCompanionBuilder = NoteStemsCompanion Function({
  Value<String> stem,
  Value<int> noteId,
  Value<String> source,
  Value<int> rowid,
});

class $$NoteStemsTableFilterComposer
    extends Composer<_$CopistDatabase, $NoteStemsTable> {
  $$NoteStemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get stem => $composableBuilder(
    column: $table.stem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NoteStemsTableOrderingComposer
    extends Composer<_$CopistDatabase, $NoteStemsTable> {
  $$NoteStemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get stem => $composableBuilder(
    column: $table.stem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NoteStemsTableAnnotationComposer
    extends Composer<_$CopistDatabase, $NoteStemsTable> {
  $$NoteStemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get stem =>
      $composableBuilder(column: $table.stem, builder: (column) => column);

  GeneratedColumn<int> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$NoteStemsTableTableManager
    extends
        RootTableManager<
          _$CopistDatabase,
          $NoteStemsTable,
          NoteStem,
          $$NoteStemsTableFilterComposer,
          $$NoteStemsTableOrderingComposer,
          $$NoteStemsTableAnnotationComposer,
          $$NoteStemsTableCreateCompanionBuilder,
          $$NoteStemsTableUpdateCompanionBuilder,
          (
            NoteStem,
            BaseReferences<_$CopistDatabase, $NoteStemsTable, NoteStem>,
          ),
          NoteStem,
          PrefetchHooks Function()
        > {
  $$NoteStemsTableTableManager(_$CopistDatabase db, $NoteStemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteStemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteStemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteStemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> stem = const Value.absent(),
                Value<int> noteId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteStemsCompanion(
                stem: stem,
                noteId: noteId,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String stem,
                required int noteId,
                required String source,
                Value<int> rowid = const Value.absent(),
              }) => NoteStemsCompanion.insert(
                stem: stem,
                noteId: noteId,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NoteStemsTable, NoteStem>(table),
                  BaseReferences<_$CopistDatabase, $NoteStemsTable, NoteStem>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NoteStemsTableProcessedTableManager =
    ProcessedTableManager<
      _$CopistDatabase,
      $NoteStemsTable,
      NoteStem,
      $$NoteStemsTableFilterComposer,
      $$NoteStemsTableOrderingComposer,
      $$NoteStemsTableAnnotationComposer,
      $$NoteStemsTableCreateCompanionBuilder,
      $$NoteStemsTableUpdateCompanionBuilder,
      (NoteStem, BaseReferences<_$CopistDatabase, $NoteStemsTable, NoteStem>),
      NoteStem,
      PrefetchHooks Function()
    >;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  required String name,
  Value<int> rowid,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<String> name,
  Value<int> rowid,
});

class $$TagsTableFilterComposer extends Composer<_$CopistDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagsTableOrderingComposer
    extends Composer<_$CopistDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$CopistDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$CopistDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, BaseReferences<_$CopistDatabase, $TagsTable, Tag>),
          Tag,
          PrefetchHooks Function()
        > {
  $$TagsTableTableManager(_$CopistDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> name = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => TagsCompanion(name: name, rowid: rowid),
          createCompanionCallback: ({
            required String name,
            Value<int> rowid = const Value.absent(),
          }) => TagsCompanion.insert(name: name, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, Tag>(table),
                  BaseReferences<_$CopistDatabase, $TagsTable, Tag>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$CopistDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, BaseReferences<_$CopistDatabase, $TagsTable, Tag>),
      Tag,
      PrefetchHooks Function()
    >;
typedef $$NoteTagsTableCreateCompanionBuilder = NoteTagsCompanion Function({
  required String tag,
  required int noteId,
  required bool isFrontmatter,
  Value<int> rowid,
});
typedef $$NoteTagsTableUpdateCompanionBuilder = NoteTagsCompanion Function({
  Value<String> tag,
  Value<int> noteId,
  Value<bool> isFrontmatter,
  Value<int> rowid,
});

class $$NoteTagsTableFilterComposer
    extends Composer<_$CopistDatabase, $NoteTagsTable> {
  $$NoteTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFrontmatter => $composableBuilder(
    column: $table.isFrontmatter,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NoteTagsTableOrderingComposer
    extends Composer<_$CopistDatabase, $NoteTagsTable> {
  $$NoteTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get noteId => $composableBuilder(
    column: $table.noteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFrontmatter => $composableBuilder(
    column: $table.isFrontmatter,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NoteTagsTableAnnotationComposer
    extends Composer<_$CopistDatabase, $NoteTagsTable> {
  $$NoteTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<int> get noteId =>
      $composableBuilder(column: $table.noteId, builder: (column) => column);

  GeneratedColumn<bool> get isFrontmatter => $composableBuilder(
    column: $table.isFrontmatter,
    builder: (column) => column,
  );
}

class $$NoteTagsTableTableManager
    extends
        RootTableManager<
          _$CopistDatabase,
          $NoteTagsTable,
          NoteTag,
          $$NoteTagsTableFilterComposer,
          $$NoteTagsTableOrderingComposer,
          $$NoteTagsTableAnnotationComposer,
          $$NoteTagsTableCreateCompanionBuilder,
          $$NoteTagsTableUpdateCompanionBuilder,
          (NoteTag, BaseReferences<_$CopistDatabase, $NoteTagsTable, NoteTag>),
          NoteTag,
          PrefetchHooks Function()
        > {
  $$NoteTagsTableTableManager(_$CopistDatabase db, $NoteTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tag = const Value.absent(),
                Value<int> noteId = const Value.absent(),
                Value<bool> isFrontmatter = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteTagsCompanion(
                tag: tag,
                noteId: noteId,
                isFrontmatter: isFrontmatter,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tag,
                required int noteId,
                required bool isFrontmatter,
                Value<int> rowid = const Value.absent(),
              }) => NoteTagsCompanion.insert(
                tag: tag,
                noteId: noteId,
                isFrontmatter: isFrontmatter,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NoteTagsTable, NoteTag>(table),
                  BaseReferences<_$CopistDatabase, $NoteTagsTable, NoteTag>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NoteTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$CopistDatabase,
      $NoteTagsTable,
      NoteTag,
      $$NoteTagsTableFilterComposer,
      $$NoteTagsTableOrderingComposer,
      $$NoteTagsTableAnnotationComposer,
      $$NoteTagsTableCreateCompanionBuilder,
      $$NoteTagsTableUpdateCompanionBuilder,
      (NoteTag, BaseReferences<_$CopistDatabase, $NoteTagsTable, NoteTag>),
      NoteTag,
      PrefetchHooks Function()
    >;
typedef $$NoteLinksTableCreateCompanionBuilder = NoteLinksCompanion Function({
  required int fromNote,
  required int toNote,
  required String kind,
  Value<int> rowid,
});
typedef $$NoteLinksTableUpdateCompanionBuilder = NoteLinksCompanion Function({
  Value<int> fromNote,
  Value<int> toNote,
  Value<String> kind,
  Value<int> rowid,
});

class $$NoteLinksTableFilterComposer
    extends Composer<_$CopistDatabase, $NoteLinksTable> {
  $$NoteLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get fromNote => $composableBuilder(
    column: $table.fromNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toNote => $composableBuilder(
    column: $table.toNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NoteLinksTableOrderingComposer
    extends Composer<_$CopistDatabase, $NoteLinksTable> {
  $$NoteLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get fromNote => $composableBuilder(
    column: $table.fromNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toNote => $composableBuilder(
    column: $table.toNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NoteLinksTableAnnotationComposer
    extends Composer<_$CopistDatabase, $NoteLinksTable> {
  $$NoteLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get fromNote =>
      $composableBuilder(column: $table.fromNote, builder: (column) => column);

  GeneratedColumn<int> get toNote =>
      $composableBuilder(column: $table.toNote, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);
}

class $$NoteLinksTableTableManager
    extends
        RootTableManager<
          _$CopistDatabase,
          $NoteLinksTable,
          NoteLink,
          $$NoteLinksTableFilterComposer,
          $$NoteLinksTableOrderingComposer,
          $$NoteLinksTableAnnotationComposer,
          $$NoteLinksTableCreateCompanionBuilder,
          $$NoteLinksTableUpdateCompanionBuilder,
          (
            NoteLink,
            BaseReferences<_$CopistDatabase, $NoteLinksTable, NoteLink>,
          ),
          NoteLink,
          PrefetchHooks Function()
        > {
  $$NoteLinksTableTableManager(_$CopistDatabase db, $NoteLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> fromNote = const Value.absent(),
                Value<int> toNote = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteLinksCompanion(
                fromNote: fromNote,
                toNote: toNote,
                kind: kind,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int fromNote,
                required int toNote,
                required String kind,
                Value<int> rowid = const Value.absent(),
              }) => NoteLinksCompanion.insert(
                fromNote: fromNote,
                toNote: toNote,
                kind: kind,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NoteLinksTable, NoteLink>(table),
                  BaseReferences<_$CopistDatabase, $NoteLinksTable, NoteLink>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NoteLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$CopistDatabase,
      $NoteLinksTable,
      NoteLink,
      $$NoteLinksTableFilterComposer,
      $$NoteLinksTableOrderingComposer,
      $$NoteLinksTableAnnotationComposer,
      $$NoteLinksTableCreateCompanionBuilder,
      $$NoteLinksTableUpdateCompanionBuilder,
      (NoteLink, BaseReferences<_$CopistDatabase, $NoteLinksTable, NoteLink>),
      NoteLink,
      PrefetchHooks Function()
    >;

class $CopistDatabaseManager {
  final _$CopistDatabase _db;
  $CopistDatabaseManager(this._db);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$NoteStemsTableTableManager get noteStems =>
      $$NoteStemsTableTableManager(_db, _db.noteStems);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$NoteTagsTableTableManager get noteTags =>
      $$NoteTagsTableTableManager(_db, _db.noteTags);
  $$NoteLinksTableTableManager get noteLinks =>
      $$NoteLinksTableTableManager(_db, _db.noteLinks);
}
