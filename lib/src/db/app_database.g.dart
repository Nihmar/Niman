// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
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
  static const VerificationMeta _themeBrightnessMeta = const VerificationMeta(
    'themeBrightness',
  );
  @override
  late final GeneratedColumn<String> themeBrightness = GeneratedColumn<String>(
    'theme_brightness',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _themePaletteMeta = const VerificationMeta(
    'themePalette',
  );
  @override
  late final GeneratedColumn<String> themePalette = GeneratedColumn<String>(
    'theme_palette',
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
    previewMode,
    splitRatio,
    language,
    themeBrightness,
    themePalette,
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
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('theme_brightness')) {
      context.handle(
        _themeBrightnessMeta,
        themeBrightness.isAcceptableOrUnknown(
          data['theme_brightness']!,
          _themeBrightnessMeta,
        ),
      );
    }
    if (data.containsKey('theme_palette')) {
      context.handle(
        _themePaletteMeta,
        themePalette.isAcceptableOrUnknown(
          data['theme_palette']!,
          _themePaletteMeta,
        ),
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
      previewMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preview_mode'],
      )!,
      splitRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}split_ratio'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      themeBrightness: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_brightness'],
      )!,
      themePalette: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_palette'],
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

  /// The preview layout mode: `auto` (width-based), `split` or `switch`
  /// (forced; default `auto`).
  ///
  /// App-wide, with the split ratio: unlike the editor settings T-ML-10
  /// moved into the library folder, these two follow the screen. Carrying
  /// them in the folder would move a tablet's layout onto a phone.
  final String previewMode;

  /// The editor|preview split fraction (0..1; default 0.55).
  final double splitRatio;

  /// The UI language: `system` (follow the OS, the default), `en` or
  /// `it`.
  final String language;

  /// How bright the app is: `system` (follow the device, the default),
  /// `day` or `night` (T-M6-05).
  ///
  /// App-wide, like the language and unlike the two text sizes: the
  /// screen is the screen whichever library is open on it.
  final String themeBrightness;

  /// The palette: `system` (the device's own colors), `catppuccin`,
  /// `solarized` or `gruvbox`.
  final String themePalette;

  /// The settings waiting to reach the libraries they belong to: the
  /// dropped `library_settings` rows (T-ML-02) and the editor settings
  /// that used to be one value for every library (T-ML-10).
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
    required this.previewMode,
    required this.splitRatio,
    required this.language,
    required this.themeBrightness,
    required this.themePalette,
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
    map['preview_mode'] = Variable<String>(previewMode);
    map['split_ratio'] = Variable<double>(splitRatio);
    map['language'] = Variable<String>(language);
    map['theme_brightness'] = Variable<String>(themeBrightness);
    map['theme_palette'] = Variable<String>(themePalette);
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
      previewMode: Value(previewMode),
      splitRatio: Value(splitRatio),
      language: Value(language),
      themeBrightness: Value(themeBrightness),
      themePalette: Value(themePalette),
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
      previewMode: serializer.fromJson<String>(json['previewMode']),
      splitRatio: serializer.fromJson<double>(json['splitRatio']),
      language: serializer.fromJson<String>(json['language']),
      themeBrightness: serializer.fromJson<String>(json['themeBrightness']),
      themePalette: serializer.fromJson<String>(json['themePalette']),
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
      'previewMode': serializer.toJson<String>(previewMode),
      'splitRatio': serializer.toJson<double>(splitRatio),
      'language': serializer.toJson<String>(language),
      'themeBrightness': serializer.toJson<String>(themeBrightness),
      'themePalette': serializer.toJson<String>(themePalette),
      'legacyLibrarySettings': serializer.toJson<String>(legacyLibrarySettings),
    };
  }

  AppSetting copyWith({
    int? id,
    Value<String?> libraryPath = const Value.absent(),
    bool? debugLogsEnabled,
    String? previewMode,
    double? splitRatio,
    String? language,
    String? themeBrightness,
    String? themePalette,
    String? legacyLibrarySettings,
  }) => AppSetting(
    id: id ?? this.id,
    libraryPath: libraryPath.present ? libraryPath.value : this.libraryPath,
    debugLogsEnabled: debugLogsEnabled ?? this.debugLogsEnabled,
    previewMode: previewMode ?? this.previewMode,
    splitRatio: splitRatio ?? this.splitRatio,
    language: language ?? this.language,
    themeBrightness: themeBrightness ?? this.themeBrightness,
    themePalette: themePalette ?? this.themePalette,
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
      previewMode: data.previewMode.present
          ? data.previewMode.value
          : this.previewMode,
      splitRatio: data.splitRatio.present
          ? data.splitRatio.value
          : this.splitRatio,
      language: data.language.present ? data.language.value : this.language,
      themeBrightness: data.themeBrightness.present
          ? data.themeBrightness.value
          : this.themeBrightness,
      themePalette: data.themePalette.present
          ? data.themePalette.value
          : this.themePalette,
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
          ..write('previewMode: $previewMode, ')
          ..write('splitRatio: $splitRatio, ')
          ..write('language: $language, ')
          ..write('themeBrightness: $themeBrightness, ')
          ..write('themePalette: $themePalette, ')
          ..write('legacyLibrarySettings: $legacyLibrarySettings')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    libraryPath,
    debugLogsEnabled,
    previewMode,
    splitRatio,
    language,
    themeBrightness,
    themePalette,
    legacyLibrarySettings,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.libraryPath == this.libraryPath &&
          other.debugLogsEnabled == this.debugLogsEnabled &&
          other.previewMode == this.previewMode &&
          other.splitRatio == this.splitRatio &&
          other.language == this.language &&
          other.themeBrightness == this.themeBrightness &&
          other.themePalette == this.themePalette &&
          other.legacyLibrarySettings == this.legacyLibrarySettings);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String?> libraryPath;
  final Value<bool> debugLogsEnabled;
  final Value<String> previewMode;
  final Value<double> splitRatio;
  final Value<String> language;
  final Value<String> themeBrightness;
  final Value<String> themePalette;
  final Value<String> legacyLibrarySettings;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.libraryPath = const Value.absent(),
    this.debugLogsEnabled = const Value.absent(),
    this.previewMode = const Value.absent(),
    this.splitRatio = const Value.absent(),
    this.language = const Value.absent(),
    this.themeBrightness = const Value.absent(),
    this.themePalette = const Value.absent(),
    this.legacyLibrarySettings = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.libraryPath = const Value.absent(),
    this.debugLogsEnabled = const Value.absent(),
    this.previewMode = const Value.absent(),
    this.splitRatio = const Value.absent(),
    this.language = const Value.absent(),
    this.themeBrightness = const Value.absent(),
    this.themePalette = const Value.absent(),
    this.legacyLibrarySettings = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? libraryPath,
    Expression<bool>? debugLogsEnabled,
    Expression<String>? previewMode,
    Expression<double>? splitRatio,
    Expression<String>? language,
    Expression<String>? themeBrightness,
    Expression<String>? themePalette,
    Expression<String>? legacyLibrarySettings,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (libraryPath != null) 'library_path': libraryPath,
      if (debugLogsEnabled != null) 'debug_logs_enabled': debugLogsEnabled,
      if (previewMode != null) 'preview_mode': previewMode,
      if (splitRatio != null) 'split_ratio': splitRatio,
      if (language != null) 'language': language,
      if (themeBrightness != null) 'theme_brightness': themeBrightness,
      if (themePalette != null) 'theme_palette': themePalette,
      if (legacyLibrarySettings != null)
        'legacy_library_settings': legacyLibrarySettings,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? libraryPath,
    Value<bool>? debugLogsEnabled,
    Value<String>? previewMode,
    Value<double>? splitRatio,
    Value<String>? language,
    Value<String>? themeBrightness,
    Value<String>? themePalette,
    Value<String>? legacyLibrarySettings,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      libraryPath: libraryPath ?? this.libraryPath,
      debugLogsEnabled: debugLogsEnabled ?? this.debugLogsEnabled,
      previewMode: previewMode ?? this.previewMode,
      splitRatio: splitRatio ?? this.splitRatio,
      language: language ?? this.language,
      themeBrightness: themeBrightness ?? this.themeBrightness,
      themePalette: themePalette ?? this.themePalette,
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
    if (previewMode.present) {
      map['preview_mode'] = Variable<String>(previewMode.value);
    }
    if (splitRatio.present) {
      map['split_ratio'] = Variable<double>(splitRatio.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (themeBrightness.present) {
      map['theme_brightness'] = Variable<String>(themeBrightness.value);
    }
    if (themePalette.present) {
      map['theme_palette'] = Variable<String>(themePalette.value);
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
          ..write('previewMode: $previewMode, ')
          ..write('splitRatio: $splitRatio, ')
          ..write('language: $language, ')
          ..write('themeBrightness: $themeBrightness, ')
          ..write('themePalette: $themePalette, ')
          ..write('legacyLibrarySettings: $legacyLibrarySettings')
          ..write(')'))
        .toString();
  }
}

class $KnownLibrariesTable extends KnownLibraries
    with TableInfo<$KnownLibrariesTable, KnownLibrary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KnownLibrariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _lastOpenedMeta = const VerificationMeta(
    'lastOpened',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpened = GeneratedColumn<DateTime>(
    'last_opened',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [path, name, lastOpened];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'known_libraries';
  @override
  VerificationContext validateIntegrity(
    Insertable<KnownLibrary> instance, {
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('last_opened')) {
      context.handle(
        _lastOpenedMeta,
        lastOpened.isAcceptableOrUnknown(data['last_opened']!, _lastOpenedMeta),
      );
    } else if (isInserting) {
      context.missing(_lastOpenedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {path};
  @override
  KnownLibrary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KnownLibrary(
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      lastOpened: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened'],
      )!,
    );
  }

  @override
  $KnownLibrariesTable createAlias(String alias) {
    return $KnownLibrariesTable(attachedDatabase, alias);
  }
}

class KnownLibrary extends DataClass implements Insertable<KnownLibrary> {
  /// Absolute, normalized path of the library root; the primary key.
  final String path;

  /// Display name; the folder's own name unless the user renames it.
  final String name;

  /// When the library was last opened.
  final DateTime lastOpened;
  const KnownLibrary({
    required this.path,
    required this.name,
    required this.lastOpened,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    map['name'] = Variable<String>(name);
    map['last_opened'] = Variable<DateTime>(lastOpened);
    return map;
  }

  KnownLibrariesCompanion toCompanion(bool nullToAbsent) {
    return KnownLibrariesCompanion(
      path: Value(path),
      name: Value(name),
      lastOpened: Value(lastOpened),
    );
  }

  factory KnownLibrary.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KnownLibrary(
      path: serializer.fromJson<String>(json['path']),
      name: serializer.fromJson<String>(json['name']),
      lastOpened: serializer.fromJson<DateTime>(json['lastOpened']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'path': serializer.toJson<String>(path),
      'name': serializer.toJson<String>(name),
      'lastOpened': serializer.toJson<DateTime>(lastOpened),
    };
  }

  KnownLibrary copyWith({String? path, String? name, DateTime? lastOpened}) =>
      KnownLibrary(
        path: path ?? this.path,
        name: name ?? this.name,
        lastOpened: lastOpened ?? this.lastOpened,
      );
  KnownLibrary copyWithCompanion(KnownLibrariesCompanion data) {
    return KnownLibrary(
      path: data.path.present ? data.path.value : this.path,
      name: data.name.present ? data.name.value : this.name,
      lastOpened: data.lastOpened.present
          ? data.lastOpened.value
          : this.lastOpened,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KnownLibrary(')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('lastOpened: $lastOpened')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(path, name, lastOpened);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KnownLibrary &&
          other.path == this.path &&
          other.name == this.name &&
          other.lastOpened == this.lastOpened);
}

class KnownLibrariesCompanion extends UpdateCompanion<KnownLibrary> {
  final Value<String> path;
  final Value<String> name;
  final Value<DateTime> lastOpened;
  final Value<int> rowid;
  const KnownLibrariesCompanion({
    this.path = const Value.absent(),
    this.name = const Value.absent(),
    this.lastOpened = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KnownLibrariesCompanion.insert({
    required String path,
    required String name,
    required DateTime lastOpened,
    this.rowid = const Value.absent(),
  }) : path = Value(path),
       name = Value(name),
       lastOpened = Value(lastOpened);
  static Insertable<KnownLibrary> custom({
    Expression<String>? path,
    Expression<String>? name,
    Expression<DateTime>? lastOpened,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (name != null) 'name': name,
      if (lastOpened != null) 'last_opened': lastOpened,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KnownLibrariesCompanion copyWith({
    Value<String>? path,
    Value<String>? name,
    Value<DateTime>? lastOpened,
    Value<int>? rowid,
  }) {
    return KnownLibrariesCompanion(
      path: path ?? this.path,
      name: name ?? this.name,
      lastOpened: lastOpened ?? this.lastOpened,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lastOpened.present) {
      map['last_opened'] = Variable<DateTime>(lastOpened.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KnownLibrariesCompanion(')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('lastOpened: $lastOpened, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $KnownLibrariesTable knownLibraries = $KnownLibrariesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    knownLibraries,
  ];
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String?> libraryPath,
      Value<bool> debugLogsEnabled,
      Value<String> previewMode,
      Value<double> splitRatio,
      Value<String> language,
      Value<String> themeBrightness,
      Value<String> themePalette,
      Value<String> legacyLibrarySettings,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String?> libraryPath,
      Value<bool> debugLogsEnabled,
      Value<String> previewMode,
      Value<double> splitRatio,
      Value<String> language,
      Value<String> themeBrightness,
      Value<String> themePalette,
      Value<String> legacyLibrarySettings,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
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

  ColumnFilters<String> get previewMode => $composableBuilder(
    column: $table.previewMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get splitRatio => $composableBuilder(
    column: $table.splitRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeBrightness => $composableBuilder(
    column: $table.themeBrightness,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themePalette => $composableBuilder(
    column: $table.themePalette,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legacyLibrarySettings => $composableBuilder(
    column: $table.legacyLibrarySettings,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
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

  ColumnOrderings<String> get previewMode => $composableBuilder(
    column: $table.previewMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get splitRatio => $composableBuilder(
    column: $table.splitRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeBrightness => $composableBuilder(
    column: $table.themeBrightness,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themePalette => $composableBuilder(
    column: $table.themePalette,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legacyLibrarySettings => $composableBuilder(
    column: $table.legacyLibrarySettings,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
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

  GeneratedColumn<String> get previewMode => $composableBuilder(
    column: $table.previewMode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get splitRatio => $composableBuilder(
    column: $table.splitRatio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get themeBrightness => $composableBuilder(
    column: $table.themeBrightness,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themePalette => $composableBuilder(
    column: $table.themePalette,
    builder: (column) => column,
  );

  GeneratedColumn<String> get legacyLibrarySettings => $composableBuilder(
    column: $table.legacyLibrarySettings,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
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
                Value<String> previewMode = const Value.absent(),
                Value<double> splitRatio = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> themeBrightness = const Value.absent(),
                Value<String> themePalette = const Value.absent(),
                Value<String> legacyLibrarySettings = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                libraryPath: libraryPath,
                debugLogsEnabled: debugLogsEnabled,
                previewMode: previewMode,
                splitRatio: splitRatio,
                language: language,
                themeBrightness: themeBrightness,
                themePalette: themePalette,
                legacyLibrarySettings: legacyLibrarySettings,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> libraryPath = const Value.absent(),
                Value<bool> debugLogsEnabled = const Value.absent(),
                Value<String> previewMode = const Value.absent(),
                Value<double> splitRatio = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> themeBrightness = const Value.absent(),
                Value<String> themePalette = const Value.absent(),
                Value<String> legacyLibrarySettings = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                libraryPath: libraryPath,
                debugLogsEnabled: debugLogsEnabled,
                previewMode: previewMode,
                splitRatio: splitRatio,
                language: language,
                themeBrightness: themeBrightness,
                themePalette: themePalette,
                legacyLibrarySettings: legacyLibrarySettings,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
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

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$KnownLibrariesTableCreateCompanionBuilder =
    KnownLibrariesCompanion Function({
      required String path,
      required String name,
      required DateTime lastOpened,
      Value<int> rowid,
    });
typedef $$KnownLibrariesTableUpdateCompanionBuilder =
    KnownLibrariesCompanion Function({
      Value<String> path,
      Value<String> name,
      Value<DateTime> lastOpened,
      Value<int> rowid,
    });

class $$KnownLibrariesTableFilterComposer
    extends Composer<_$AppDatabase, $KnownLibrariesTable> {
  $$KnownLibrariesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOpened => $composableBuilder(
    column: $table.lastOpened,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KnownLibrariesTableOrderingComposer
    extends Composer<_$AppDatabase, $KnownLibrariesTable> {
  $$KnownLibrariesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpened => $composableBuilder(
    column: $table.lastOpened,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KnownLibrariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KnownLibrariesTable> {
  $$KnownLibrariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpened => $composableBuilder(
    column: $table.lastOpened,
    builder: (column) => column,
  );
}

class $$KnownLibrariesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KnownLibrariesTable,
          KnownLibrary,
          $$KnownLibrariesTableFilterComposer,
          $$KnownLibrariesTableOrderingComposer,
          $$KnownLibrariesTableAnnotationComposer,
          $$KnownLibrariesTableCreateCompanionBuilder,
          $$KnownLibrariesTableUpdateCompanionBuilder,
          (
            KnownLibrary,
            BaseReferences<_$AppDatabase, $KnownLibrariesTable, KnownLibrary>,
          ),
          KnownLibrary,
          PrefetchHooks Function()
        > {
  $$KnownLibrariesTableTableManager(
    _$AppDatabase db,
    $KnownLibrariesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KnownLibrariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KnownLibrariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KnownLibrariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> path = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> lastOpened = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KnownLibrariesCompanion(
                path: path,
                name: name,
                lastOpened: lastOpened,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String path,
                required String name,
                required DateTime lastOpened,
                Value<int> rowid = const Value.absent(),
              }) => KnownLibrariesCompanion.insert(
                path: path,
                name: name,
                lastOpened: lastOpened,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KnownLibrariesTable, KnownLibrary>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $KnownLibrariesTable,
                    KnownLibrary
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KnownLibrariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KnownLibrariesTable,
      KnownLibrary,
      $$KnownLibrariesTableFilterComposer,
      $$KnownLibrariesTableOrderingComposer,
      $$KnownLibrariesTableAnnotationComposer,
      $$KnownLibrariesTableCreateCompanionBuilder,
      $$KnownLibrariesTableUpdateCompanionBuilder,
      (
        KnownLibrary,
        BaseReferences<_$AppDatabase, $KnownLibrariesTable, KnownLibrary>,
      ),
      KnownLibrary,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$KnownLibrariesTableTableManager get knownLibraries =>
      $$KnownLibrariesTableTableManager(_db, _db.knownLibraries);
}
