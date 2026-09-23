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
  static const VerificationMeta _autoUpdateEnabledMeta = const VerificationMeta(
    'autoUpdateEnabled',
  );
  @override
  late final GeneratedColumn<bool> autoUpdateEnabled = GeneratedColumn<bool>(
    'auto_update_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_update_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _closeToTrayMeta = const VerificationMeta(
    'closeToTray',
  );
  @override
  late final GeneratedColumn<bool> closeToTray = GeneratedColumn<bool>(
    'close_to_tray',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("close_to_tray" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastUpdateCheckMsMeta = const VerificationMeta(
    'lastUpdateCheckMs',
  );
  @override
  late final GeneratedColumn<int> lastUpdateCheckMs = GeneratedColumn<int>(
    'last_update_check_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    defaultValue: const Constant('niman'),
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
  static const VerificationMeta _changelogSeenVersionMeta =
      const VerificationMeta('changelogSeenVersion');
  @override
  late final GeneratedColumn<String> changelogSeenVersion =
      GeneratedColumn<String>(
        'changelog_seen_version',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _keyMapMeta = const VerificationMeta('keyMap');
  @override
  late final GeneratedColumn<String> keyMap = GeneratedColumn<String>(
    'key_map',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinnedCommandsMeta = const VerificationMeta(
    'pinnedCommands',
  );
  @override
  late final GeneratedColumn<String> pinnedCommands = GeneratedColumn<String>(
    'pinned_commands',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    libraryPath,
    debugLogsEnabled,
    autoUpdateEnabled,
    closeToTray,
    lastUpdateCheckMs,
    previewMode,
    splitRatio,
    language,
    themeBrightness,
    themePalette,
    legacyLibrarySettings,
    changelogSeenVersion,
    keyMap,
    pinnedCommands,
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
    if (data.containsKey('auto_update_enabled')) {
      context.handle(
        _autoUpdateEnabledMeta,
        autoUpdateEnabled.isAcceptableOrUnknown(
          data['auto_update_enabled']!,
          _autoUpdateEnabledMeta,
        ),
      );
    }
    if (data.containsKey('close_to_tray')) {
      context.handle(
        _closeToTrayMeta,
        closeToTray.isAcceptableOrUnknown(
          data['close_to_tray']!,
          _closeToTrayMeta,
        ),
      );
    }
    if (data.containsKey('last_update_check_ms')) {
      context.handle(
        _lastUpdateCheckMsMeta,
        lastUpdateCheckMs.isAcceptableOrUnknown(
          data['last_update_check_ms']!,
          _lastUpdateCheckMsMeta,
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
    if (data.containsKey('changelog_seen_version')) {
      context.handle(
        _changelogSeenVersionMeta,
        changelogSeenVersion.isAcceptableOrUnknown(
          data['changelog_seen_version']!,
          _changelogSeenVersionMeta,
        ),
      );
    }
    if (data.containsKey('key_map')) {
      context.handle(
        _keyMapMeta,
        keyMap.isAcceptableOrUnknown(data['key_map']!, _keyMapMeta),
      );
    }
    if (data.containsKey('pinned_commands')) {
      context.handle(
        _pinnedCommandsMeta,
        pinnedCommands.isAcceptableOrUnknown(
          data['pinned_commands']!,
          _pinnedCommandsMeta,
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
      autoUpdateEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_update_enabled'],
      )!,
      closeToTray: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}close_to_tray'],
      )!,
      lastUpdateCheckMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_update_check_ms'],
      ),
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
      changelogSeenVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}changelog_seen_version'],
      ),
      keyMap: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_map'],
      ),
      pinnedCommands: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pinned_commands'],
      ),
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

  /// Whether the app checks GitHub Releases for updates (issue #81).
  ///
  /// Off by default: the user opts into the launch + six-hourly check.
  /// The manual "Check for updates" row in Settings works regardless.
  final bool autoUpdateEnabled;

  /// Whether the window's × hides Niman to the tray and leaves it
  /// running (#209), instead of quitting.
  ///
  /// On by default on the desktops: the desktop reminders need the
  /// process alive to fire, and the tray icon is how you get the window
  /// back. The tray's Quit, and the × with this off, quit for real.
  final bool closeToTray;

  /// Last update-check time, milliseconds since epoch; null until the
  /// first check runs (issue #81).
  final int? lastUpdateCheckMs;

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

  /// The palette: `niman` (the app's own colors, and what a fresh install
  /// wears), `system` (the device's own colors), `catppuccin`,
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

  /// The app version whose changelog the user last saw (issue #80);
  /// null until the first launch has written it, which is what turns the
  /// update dialog off on a fresh install.
  final String? changelogSeenVersion;

  /// The keyboard shortcuts the user changed (#159), as `KeyMap.toJson`
  /// writes them; null while none was. The device's, never a library's:
  /// a shortcut belongs to the keyboard.
  final String? keyMap;

  /// The commands pinned in the palette (#208), as a JSON array of their
  /// names, in pinning order; null while none was. The device's, like the
  /// key map: a pin is about how this machine is used.
  final String? pinnedCommands;
  const AppSetting({
    required this.id,
    this.libraryPath,
    required this.debugLogsEnabled,
    required this.autoUpdateEnabled,
    required this.closeToTray,
    this.lastUpdateCheckMs,
    required this.previewMode,
    required this.splitRatio,
    required this.language,
    required this.themeBrightness,
    required this.themePalette,
    required this.legacyLibrarySettings,
    this.changelogSeenVersion,
    this.keyMap,
    this.pinnedCommands,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || libraryPath != null) {
      map['library_path'] = Variable<String>(libraryPath);
    }
    map['debug_logs_enabled'] = Variable<bool>(debugLogsEnabled);
    map['auto_update_enabled'] = Variable<bool>(autoUpdateEnabled);
    map['close_to_tray'] = Variable<bool>(closeToTray);
    if (!nullToAbsent || lastUpdateCheckMs != null) {
      map['last_update_check_ms'] = Variable<int>(lastUpdateCheckMs);
    }
    map['preview_mode'] = Variable<String>(previewMode);
    map['split_ratio'] = Variable<double>(splitRatio);
    map['language'] = Variable<String>(language);
    map['theme_brightness'] = Variable<String>(themeBrightness);
    map['theme_palette'] = Variable<String>(themePalette);
    map['legacy_library_settings'] = Variable<String>(legacyLibrarySettings);
    if (!nullToAbsent || changelogSeenVersion != null) {
      map['changelog_seen_version'] = Variable<String>(changelogSeenVersion);
    }
    if (!nullToAbsent || keyMap != null) {
      map['key_map'] = Variable<String>(keyMap);
    }
    if (!nullToAbsent || pinnedCommands != null) {
      map['pinned_commands'] = Variable<String>(pinnedCommands);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      libraryPath: libraryPath == null && nullToAbsent
          ? const Value.absent()
          : Value(libraryPath),
      debugLogsEnabled: Value(debugLogsEnabled),
      autoUpdateEnabled: Value(autoUpdateEnabled),
      closeToTray: Value(closeToTray),
      lastUpdateCheckMs: lastUpdateCheckMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdateCheckMs),
      previewMode: Value(previewMode),
      splitRatio: Value(splitRatio),
      language: Value(language),
      themeBrightness: Value(themeBrightness),
      themePalette: Value(themePalette),
      legacyLibrarySettings: Value(legacyLibrarySettings),
      changelogSeenVersion: changelogSeenVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(changelogSeenVersion),
      keyMap: keyMap == null && nullToAbsent
          ? const Value.absent()
          : Value(keyMap),
      pinnedCommands: pinnedCommands == null && nullToAbsent
          ? const Value.absent()
          : Value(pinnedCommands),
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
      autoUpdateEnabled: serializer.fromJson<bool>(json['autoUpdateEnabled']),
      closeToTray: serializer.fromJson<bool>(json['closeToTray']),
      lastUpdateCheckMs: serializer.fromJson<int?>(json['lastUpdateCheckMs']),
      previewMode: serializer.fromJson<String>(json['previewMode']),
      splitRatio: serializer.fromJson<double>(json['splitRatio']),
      language: serializer.fromJson<String>(json['language']),
      themeBrightness: serializer.fromJson<String>(json['themeBrightness']),
      themePalette: serializer.fromJson<String>(json['themePalette']),
      legacyLibrarySettings: serializer.fromJson<String>(
        json['legacyLibrarySettings'],
      ),
      changelogSeenVersion: serializer.fromJson<String?>(
        json['changelogSeenVersion'],
      ),
      keyMap: serializer.fromJson<String?>(json['keyMap']),
      pinnedCommands: serializer.fromJson<String?>(json['pinnedCommands']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'libraryPath': serializer.toJson<String?>(libraryPath),
      'debugLogsEnabled': serializer.toJson<bool>(debugLogsEnabled),
      'autoUpdateEnabled': serializer.toJson<bool>(autoUpdateEnabled),
      'closeToTray': serializer.toJson<bool>(closeToTray),
      'lastUpdateCheckMs': serializer.toJson<int?>(lastUpdateCheckMs),
      'previewMode': serializer.toJson<String>(previewMode),
      'splitRatio': serializer.toJson<double>(splitRatio),
      'language': serializer.toJson<String>(language),
      'themeBrightness': serializer.toJson<String>(themeBrightness),
      'themePalette': serializer.toJson<String>(themePalette),
      'legacyLibrarySettings': serializer.toJson<String>(legacyLibrarySettings),
      'changelogSeenVersion': serializer.toJson<String?>(changelogSeenVersion),
      'keyMap': serializer.toJson<String?>(keyMap),
      'pinnedCommands': serializer.toJson<String?>(pinnedCommands),
    };
  }

  AppSetting copyWith({
    int? id,
    Value<String?> libraryPath = const Value.absent(),
    bool? debugLogsEnabled,
    bool? autoUpdateEnabled,
    bool? closeToTray,
    Value<int?> lastUpdateCheckMs = const Value.absent(),
    String? previewMode,
    double? splitRatio,
    String? language,
    String? themeBrightness,
    String? themePalette,
    String? legacyLibrarySettings,
    Value<String?> changelogSeenVersion = const Value.absent(),
    Value<String?> keyMap = const Value.absent(),
    Value<String?> pinnedCommands = const Value.absent(),
  }) => AppSetting(
    id: id ?? this.id,
    libraryPath: libraryPath.present ? libraryPath.value : this.libraryPath,
    debugLogsEnabled: debugLogsEnabled ?? this.debugLogsEnabled,
    autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
    closeToTray: closeToTray ?? this.closeToTray,
    lastUpdateCheckMs: lastUpdateCheckMs.present
        ? lastUpdateCheckMs.value
        : this.lastUpdateCheckMs,
    previewMode: previewMode ?? this.previewMode,
    splitRatio: splitRatio ?? this.splitRatio,
    language: language ?? this.language,
    themeBrightness: themeBrightness ?? this.themeBrightness,
    themePalette: themePalette ?? this.themePalette,
    legacyLibrarySettings: legacyLibrarySettings ?? this.legacyLibrarySettings,
    changelogSeenVersion: changelogSeenVersion.present
        ? changelogSeenVersion.value
        : this.changelogSeenVersion,
    keyMap: keyMap.present ? keyMap.value : this.keyMap,
    pinnedCommands: pinnedCommands.present
        ? pinnedCommands.value
        : this.pinnedCommands,
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
      autoUpdateEnabled: data.autoUpdateEnabled.present
          ? data.autoUpdateEnabled.value
          : this.autoUpdateEnabled,
      closeToTray: data.closeToTray.present
          ? data.closeToTray.value
          : this.closeToTray,
      lastUpdateCheckMs: data.lastUpdateCheckMs.present
          ? data.lastUpdateCheckMs.value
          : this.lastUpdateCheckMs,
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
      changelogSeenVersion: data.changelogSeenVersion.present
          ? data.changelogSeenVersion.value
          : this.changelogSeenVersion,
      keyMap: data.keyMap.present ? data.keyMap.value : this.keyMap,
      pinnedCommands: data.pinnedCommands.present
          ? data.pinnedCommands.value
          : this.pinnedCommands,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('libraryPath: $libraryPath, ')
          ..write('debugLogsEnabled: $debugLogsEnabled, ')
          ..write('autoUpdateEnabled: $autoUpdateEnabled, ')
          ..write('closeToTray: $closeToTray, ')
          ..write('lastUpdateCheckMs: $lastUpdateCheckMs, ')
          ..write('previewMode: $previewMode, ')
          ..write('splitRatio: $splitRatio, ')
          ..write('language: $language, ')
          ..write('themeBrightness: $themeBrightness, ')
          ..write('themePalette: $themePalette, ')
          ..write('legacyLibrarySettings: $legacyLibrarySettings, ')
          ..write('changelogSeenVersion: $changelogSeenVersion, ')
          ..write('keyMap: $keyMap, ')
          ..write('pinnedCommands: $pinnedCommands')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    libraryPath,
    debugLogsEnabled,
    autoUpdateEnabled,
    closeToTray,
    lastUpdateCheckMs,
    previewMode,
    splitRatio,
    language,
    themeBrightness,
    themePalette,
    legacyLibrarySettings,
    changelogSeenVersion,
    keyMap,
    pinnedCommands,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.libraryPath == this.libraryPath &&
          other.debugLogsEnabled == this.debugLogsEnabled &&
          other.autoUpdateEnabled == this.autoUpdateEnabled &&
          other.closeToTray == this.closeToTray &&
          other.lastUpdateCheckMs == this.lastUpdateCheckMs &&
          other.previewMode == this.previewMode &&
          other.splitRatio == this.splitRatio &&
          other.language == this.language &&
          other.themeBrightness == this.themeBrightness &&
          other.themePalette == this.themePalette &&
          other.legacyLibrarySettings == this.legacyLibrarySettings &&
          other.changelogSeenVersion == this.changelogSeenVersion &&
          other.keyMap == this.keyMap &&
          other.pinnedCommands == this.pinnedCommands);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String?> libraryPath;
  final Value<bool> debugLogsEnabled;
  final Value<bool> autoUpdateEnabled;
  final Value<bool> closeToTray;
  final Value<int?> lastUpdateCheckMs;
  final Value<String> previewMode;
  final Value<double> splitRatio;
  final Value<String> language;
  final Value<String> themeBrightness;
  final Value<String> themePalette;
  final Value<String> legacyLibrarySettings;
  final Value<String?> changelogSeenVersion;
  final Value<String?> keyMap;
  final Value<String?> pinnedCommands;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.libraryPath = const Value.absent(),
    this.debugLogsEnabled = const Value.absent(),
    this.autoUpdateEnabled = const Value.absent(),
    this.closeToTray = const Value.absent(),
    this.lastUpdateCheckMs = const Value.absent(),
    this.previewMode = const Value.absent(),
    this.splitRatio = const Value.absent(),
    this.language = const Value.absent(),
    this.themeBrightness = const Value.absent(),
    this.themePalette = const Value.absent(),
    this.legacyLibrarySettings = const Value.absent(),
    this.changelogSeenVersion = const Value.absent(),
    this.keyMap = const Value.absent(),
    this.pinnedCommands = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.libraryPath = const Value.absent(),
    this.debugLogsEnabled = const Value.absent(),
    this.autoUpdateEnabled = const Value.absent(),
    this.closeToTray = const Value.absent(),
    this.lastUpdateCheckMs = const Value.absent(),
    this.previewMode = const Value.absent(),
    this.splitRatio = const Value.absent(),
    this.language = const Value.absent(),
    this.themeBrightness = const Value.absent(),
    this.themePalette = const Value.absent(),
    this.legacyLibrarySettings = const Value.absent(),
    this.changelogSeenVersion = const Value.absent(),
    this.keyMap = const Value.absent(),
    this.pinnedCommands = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? libraryPath,
    Expression<bool>? debugLogsEnabled,
    Expression<bool>? autoUpdateEnabled,
    Expression<bool>? closeToTray,
    Expression<int>? lastUpdateCheckMs,
    Expression<String>? previewMode,
    Expression<double>? splitRatio,
    Expression<String>? language,
    Expression<String>? themeBrightness,
    Expression<String>? themePalette,
    Expression<String>? legacyLibrarySettings,
    Expression<String>? changelogSeenVersion,
    Expression<String>? keyMap,
    Expression<String>? pinnedCommands,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (libraryPath != null) 'library_path': libraryPath,
      if (debugLogsEnabled != null) 'debug_logs_enabled': debugLogsEnabled,
      if (autoUpdateEnabled != null) 'auto_update_enabled': autoUpdateEnabled,
      if (closeToTray != null) 'close_to_tray': closeToTray,
      if (lastUpdateCheckMs != null) 'last_update_check_ms': lastUpdateCheckMs,
      if (previewMode != null) 'preview_mode': previewMode,
      if (splitRatio != null) 'split_ratio': splitRatio,
      if (language != null) 'language': language,
      if (themeBrightness != null) 'theme_brightness': themeBrightness,
      if (themePalette != null) 'theme_palette': themePalette,
      if (legacyLibrarySettings != null)
        'legacy_library_settings': legacyLibrarySettings,
      if (changelogSeenVersion != null)
        'changelog_seen_version': changelogSeenVersion,
      if (keyMap != null) 'key_map': keyMap,
      if (pinnedCommands != null) 'pinned_commands': pinnedCommands,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? libraryPath,
    Value<bool>? debugLogsEnabled,
    Value<bool>? autoUpdateEnabled,
    Value<bool>? closeToTray,
    Value<int?>? lastUpdateCheckMs,
    Value<String>? previewMode,
    Value<double>? splitRatio,
    Value<String>? language,
    Value<String>? themeBrightness,
    Value<String>? themePalette,
    Value<String>? legacyLibrarySettings,
    Value<String?>? changelogSeenVersion,
    Value<String?>? keyMap,
    Value<String?>? pinnedCommands,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      libraryPath: libraryPath ?? this.libraryPath,
      debugLogsEnabled: debugLogsEnabled ?? this.debugLogsEnabled,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
      closeToTray: closeToTray ?? this.closeToTray,
      lastUpdateCheckMs: lastUpdateCheckMs ?? this.lastUpdateCheckMs,
      previewMode: previewMode ?? this.previewMode,
      splitRatio: splitRatio ?? this.splitRatio,
      language: language ?? this.language,
      themeBrightness: themeBrightness ?? this.themeBrightness,
      themePalette: themePalette ?? this.themePalette,
      legacyLibrarySettings:
          legacyLibrarySettings ?? this.legacyLibrarySettings,
      changelogSeenVersion: changelogSeenVersion ?? this.changelogSeenVersion,
      keyMap: keyMap ?? this.keyMap,
      pinnedCommands: pinnedCommands ?? this.pinnedCommands,
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
    if (autoUpdateEnabled.present) {
      map['auto_update_enabled'] = Variable<bool>(autoUpdateEnabled.value);
    }
    if (closeToTray.present) {
      map['close_to_tray'] = Variable<bool>(closeToTray.value);
    }
    if (lastUpdateCheckMs.present) {
      map['last_update_check_ms'] = Variable<int>(lastUpdateCheckMs.value);
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
    if (changelogSeenVersion.present) {
      map['changelog_seen_version'] = Variable<String>(
        changelogSeenVersion.value,
      );
    }
    if (keyMap.present) {
      map['key_map'] = Variable<String>(keyMap.value);
    }
    if (pinnedCommands.present) {
      map['pinned_commands'] = Variable<String>(pinnedCommands.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('libraryPath: $libraryPath, ')
          ..write('debugLogsEnabled: $debugLogsEnabled, ')
          ..write('autoUpdateEnabled: $autoUpdateEnabled, ')
          ..write('closeToTray: $closeToTray, ')
          ..write('lastUpdateCheckMs: $lastUpdateCheckMs, ')
          ..write('previewMode: $previewMode, ')
          ..write('splitRatio: $splitRatio, ')
          ..write('language: $language, ')
          ..write('themeBrightness: $themeBrightness, ')
          ..write('themePalette: $themePalette, ')
          ..write('legacyLibrarySettings: $legacyLibrarySettings, ')
          ..write('changelogSeenVersion: $changelogSeenVersion, ')
          ..write('keyMap: $keyMap, ')
          ..write('pinnedCommands: $pinnedCommands')
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

class $WidgetConfigsTable extends WidgetConfigs
    with TableInfo<$WidgetConfigsTable, WidgetConfig> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WidgetConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _androidWidgetIdMeta = const VerificationMeta(
    'androidWidgetId',
  );
  @override
  late final GeneratedColumn<int> androidWidgetId = GeneratedColumn<int>(
    'android_widget_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _libraryPathMeta = const VerificationMeta(
    'libraryPath',
  );
  @override
  late final GeneratedColumn<String> libraryPath = GeneratedColumn<String>(
    'library_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notePathMeta = const VerificationMeta(
    'notePath',
  );
  @override
  late final GeneratedColumn<String> notePath = GeneratedColumn<String>(
    'note_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    androidWidgetId,
    provider,
    libraryPath,
    notePath,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'widget_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<WidgetConfig> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('android_widget_id')) {
      context.handle(
        _androidWidgetIdMeta,
        androidWidgetId.isAcceptableOrUnknown(
          data['android_widget_id']!,
          _androidWidgetIdMeta,
        ),
      );
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('library_path')) {
      context.handle(
        _libraryPathMeta,
        libraryPath.isAcceptableOrUnknown(
          data['library_path']!,
          _libraryPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_libraryPathMeta);
    }
    if (data.containsKey('note_path')) {
      context.handle(
        _notePathMeta,
        notePath.isAcceptableOrUnknown(data['note_path']!, _notePathMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {androidWidgetId};
  @override
  WidgetConfig map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WidgetConfig(
      androidWidgetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}android_widget_id'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      libraryPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_path'],
      )!,
      notePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_path'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WidgetConfigsTable createAlias(String alias) {
    return $WidgetConfigsTable(attachedDatabase, alias);
  }
}

class WidgetConfig extends DataClass implements Insertable<WidgetConfig> {
  /// The Android widget instance id; the primary key.
  final int androidWidgetId;

  /// Which widget this is: `todo` or `note`.
  final String provider;

  /// Absolute, normalized path of the library root this instance reads.
  final String libraryPath;

  /// Library-relative path of the pinned note (`note` widgets only).
  final String? notePath;

  /// When the instance was last (re)configured.
  final DateTime updatedAt;
  const WidgetConfig({
    required this.androidWidgetId,
    required this.provider,
    required this.libraryPath,
    this.notePath,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['android_widget_id'] = Variable<int>(androidWidgetId);
    map['provider'] = Variable<String>(provider);
    map['library_path'] = Variable<String>(libraryPath);
    if (!nullToAbsent || notePath != null) {
      map['note_path'] = Variable<String>(notePath);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WidgetConfigsCompanion toCompanion(bool nullToAbsent) {
    return WidgetConfigsCompanion(
      androidWidgetId: Value(androidWidgetId),
      provider: Value(provider),
      libraryPath: Value(libraryPath),
      notePath: notePath == null && nullToAbsent
          ? const Value.absent()
          : Value(notePath),
      updatedAt: Value(updatedAt),
    );
  }

  factory WidgetConfig.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WidgetConfig(
      androidWidgetId: serializer.fromJson<int>(json['androidWidgetId']),
      provider: serializer.fromJson<String>(json['provider']),
      libraryPath: serializer.fromJson<String>(json['libraryPath']),
      notePath: serializer.fromJson<String?>(json['notePath']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'androidWidgetId': serializer.toJson<int>(androidWidgetId),
      'provider': serializer.toJson<String>(provider),
      'libraryPath': serializer.toJson<String>(libraryPath),
      'notePath': serializer.toJson<String?>(notePath),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WidgetConfig copyWith({
    int? androidWidgetId,
    String? provider,
    String? libraryPath,
    Value<String?> notePath = const Value.absent(),
    DateTime? updatedAt,
  }) => WidgetConfig(
    androidWidgetId: androidWidgetId ?? this.androidWidgetId,
    provider: provider ?? this.provider,
    libraryPath: libraryPath ?? this.libraryPath,
    notePath: notePath.present ? notePath.value : this.notePath,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WidgetConfig copyWithCompanion(WidgetConfigsCompanion data) {
    return WidgetConfig(
      androidWidgetId: data.androidWidgetId.present
          ? data.androidWidgetId.value
          : this.androidWidgetId,
      provider: data.provider.present ? data.provider.value : this.provider,
      libraryPath: data.libraryPath.present
          ? data.libraryPath.value
          : this.libraryPath,
      notePath: data.notePath.present ? data.notePath.value : this.notePath,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WidgetConfig(')
          ..write('androidWidgetId: $androidWidgetId, ')
          ..write('provider: $provider, ')
          ..write('libraryPath: $libraryPath, ')
          ..write('notePath: $notePath, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(androidWidgetId, provider, libraryPath, notePath, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WidgetConfig &&
          other.androidWidgetId == this.androidWidgetId &&
          other.provider == this.provider &&
          other.libraryPath == this.libraryPath &&
          other.notePath == this.notePath &&
          other.updatedAt == this.updatedAt);
}

class WidgetConfigsCompanion extends UpdateCompanion<WidgetConfig> {
  final Value<int> androidWidgetId;
  final Value<String> provider;
  final Value<String> libraryPath;
  final Value<String?> notePath;
  final Value<DateTime> updatedAt;
  const WidgetConfigsCompanion({
    this.androidWidgetId = const Value.absent(),
    this.provider = const Value.absent(),
    this.libraryPath = const Value.absent(),
    this.notePath = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  WidgetConfigsCompanion.insert({
    this.androidWidgetId = const Value.absent(),
    required String provider,
    required String libraryPath,
    this.notePath = const Value.absent(),
    required DateTime updatedAt,
  }) : provider = Value(provider),
       libraryPath = Value(libraryPath),
       updatedAt = Value(updatedAt);
  static Insertable<WidgetConfig> custom({
    Expression<int>? androidWidgetId,
    Expression<String>? provider,
    Expression<String>? libraryPath,
    Expression<String>? notePath,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (androidWidgetId != null) 'android_widget_id': androidWidgetId,
      if (provider != null) 'provider': provider,
      if (libraryPath != null) 'library_path': libraryPath,
      if (notePath != null) 'note_path': notePath,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  WidgetConfigsCompanion copyWith({
    Value<int>? androidWidgetId,
    Value<String>? provider,
    Value<String>? libraryPath,
    Value<String?>? notePath,
    Value<DateTime>? updatedAt,
  }) {
    return WidgetConfigsCompanion(
      androidWidgetId: androidWidgetId ?? this.androidWidgetId,
      provider: provider ?? this.provider,
      libraryPath: libraryPath ?? this.libraryPath,
      notePath: notePath ?? this.notePath,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (androidWidgetId.present) {
      map['android_widget_id'] = Variable<int>(androidWidgetId.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (libraryPath.present) {
      map['library_path'] = Variable<String>(libraryPath.value);
    }
    if (notePath.present) {
      map['note_path'] = Variable<String>(notePath.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WidgetConfigsCompanion(')
          ..write('androidWidgetId: $androidWidgetId, ')
          ..write('provider: $provider, ')
          ..write('libraryPath: $libraryPath, ')
          ..write('notePath: $notePath, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncDestinationsTable extends SyncDestinations
    with TableInfo<$SyncDestinationsTable, SyncDestination> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncDestinationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _libraryPathMeta = const VerificationMeta(
    'libraryPath',
  );
  @override
  late final GeneratedColumn<String> libraryPath = GeneratedColumn<String>(
    'library_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _autoSyncMeta = const VerificationMeta(
    'autoSync',
  );
  @override
  late final GeneratedColumn<bool> autoSync = GeneratedColumn<bool>(
    'auto_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _intervalSecondsMeta = const VerificationMeta(
    'intervalSeconds',
  );
  @override
  late final GeneratedColumn<int> intervalSeconds = GeneratedColumn<int>(
    'interval_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
  );
  static const VerificationMeta _wifiOnlyMeta = const VerificationMeta(
    'wifiOnly',
  );
  @override
  late final GeneratedColumn<bool> wifiOnly = GeneratedColumn<bool>(
    'wifi_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("wifi_only" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _capabilitiesMeta = const VerificationMeta(
    'capabilities',
  );
  @override
  late final GeneratedColumn<String> capabilities = GeneratedColumn<String>(
    'capabilities',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _lastSyncAtMsMeta = const VerificationMeta(
    'lastSyncAtMs',
  );
  @override
  late final GeneratedColumn<int> lastSyncAtMs = GeneratedColumn<int>(
    'last_sync_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    libraryPath,
    url,
    username,
    enabled,
    autoSync,
    intervalSeconds,
    wifiOnly,
    capabilities,
    lastSyncAtMs,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_destinations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncDestination> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('library_path')) {
      context.handle(
        _libraryPathMeta,
        libraryPath.isAcceptableOrUnknown(
          data['library_path']!,
          _libraryPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_libraryPathMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('auto_sync')) {
      context.handle(
        _autoSyncMeta,
        autoSync.isAcceptableOrUnknown(data['auto_sync']!, _autoSyncMeta),
      );
    }
    if (data.containsKey('interval_seconds')) {
      context.handle(
        _intervalSecondsMeta,
        intervalSeconds.isAcceptableOrUnknown(
          data['interval_seconds']!,
          _intervalSecondsMeta,
        ),
      );
    }
    if (data.containsKey('wifi_only')) {
      context.handle(
        _wifiOnlyMeta,
        wifiOnly.isAcceptableOrUnknown(data['wifi_only']!, _wifiOnlyMeta),
      );
    }
    if (data.containsKey('capabilities')) {
      context.handle(
        _capabilitiesMeta,
        capabilities.isAcceptableOrUnknown(
          data['capabilities']!,
          _capabilitiesMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_at_ms')) {
      context.handle(
        _lastSyncAtMsMeta,
        lastSyncAtMs.isAcceptableOrUnknown(
          data['last_sync_at_ms']!,
          _lastSyncAtMsMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {libraryPath};
  @override
  SyncDestination map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncDestination(
      libraryPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_path'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      autoSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_sync'],
      )!,
      intervalSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_seconds'],
      )!,
      wifiOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}wifi_only'],
      )!,
      capabilities: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}capabilities'],
      )!,
      lastSyncAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_sync_at_ms'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncDestinationsTable createAlias(String alias) {
    return $SyncDestinationsTable(attachedDatabase, alias);
  }
}

class SyncDestination extends DataClass implements Insertable<SyncDestination> {
  /// Absolute, normalized path of the library root; the primary key.
  final String libraryPath;

  /// The remote folder the library maps to, always ending with `/`.
  final String url;

  /// The WebDAV user; empty for no authentication.
  final String username;

  /// Off stops every trigger; the state rows stay.
  final bool enabled;

  /// Whether the automatic triggers (after an edit, on resume, periodic)
  /// run; manual sync always works.
  final bool autoSync;

  /// The periodic trigger while the app is open, in seconds; 0 = off.
  final int intervalSeconds;

  /// Whether the automatic triggers skip mobile data.
  final bool wifiOnly;

  /// The capability probe's JSON (`WebDavCapabilities`); `{}` = never
  /// probed.
  final String capabilities;

  /// The last full sync that ended without errors, ms since epoch.
  final int? lastSyncAtMs;

  /// The last failure, short and user-readable; never a secret.
  final String? lastError;
  const SyncDestination({
    required this.libraryPath,
    required this.url,
    required this.username,
    required this.enabled,
    required this.autoSync,
    required this.intervalSeconds,
    required this.wifiOnly,
    required this.capabilities,
    this.lastSyncAtMs,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['library_path'] = Variable<String>(libraryPath);
    map['url'] = Variable<String>(url);
    map['username'] = Variable<String>(username);
    map['enabled'] = Variable<bool>(enabled);
    map['auto_sync'] = Variable<bool>(autoSync);
    map['interval_seconds'] = Variable<int>(intervalSeconds);
    map['wifi_only'] = Variable<bool>(wifiOnly);
    map['capabilities'] = Variable<String>(capabilities);
    if (!nullToAbsent || lastSyncAtMs != null) {
      map['last_sync_at_ms'] = Variable<int>(lastSyncAtMs);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncDestinationsCompanion toCompanion(bool nullToAbsent) {
    return SyncDestinationsCompanion(
      libraryPath: Value(libraryPath),
      url: Value(url),
      username: Value(username),
      enabled: Value(enabled),
      autoSync: Value(autoSync),
      intervalSeconds: Value(intervalSeconds),
      wifiOnly: Value(wifiOnly),
      capabilities: Value(capabilities),
      lastSyncAtMs: lastSyncAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAtMs),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncDestination.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncDestination(
      libraryPath: serializer.fromJson<String>(json['libraryPath']),
      url: serializer.fromJson<String>(json['url']),
      username: serializer.fromJson<String>(json['username']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      autoSync: serializer.fromJson<bool>(json['autoSync']),
      intervalSeconds: serializer.fromJson<int>(json['intervalSeconds']),
      wifiOnly: serializer.fromJson<bool>(json['wifiOnly']),
      capabilities: serializer.fromJson<String>(json['capabilities']),
      lastSyncAtMs: serializer.fromJson<int?>(json['lastSyncAtMs']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'libraryPath': serializer.toJson<String>(libraryPath),
      'url': serializer.toJson<String>(url),
      'username': serializer.toJson<String>(username),
      'enabled': serializer.toJson<bool>(enabled),
      'autoSync': serializer.toJson<bool>(autoSync),
      'intervalSeconds': serializer.toJson<int>(intervalSeconds),
      'wifiOnly': serializer.toJson<bool>(wifiOnly),
      'capabilities': serializer.toJson<String>(capabilities),
      'lastSyncAtMs': serializer.toJson<int?>(lastSyncAtMs),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncDestination copyWith({
    String? libraryPath,
    String? url,
    String? username,
    bool? enabled,
    bool? autoSync,
    int? intervalSeconds,
    bool? wifiOnly,
    String? capabilities,
    Value<int?> lastSyncAtMs = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => SyncDestination(
    libraryPath: libraryPath ?? this.libraryPath,
    url: url ?? this.url,
    username: username ?? this.username,
    enabled: enabled ?? this.enabled,
    autoSync: autoSync ?? this.autoSync,
    intervalSeconds: intervalSeconds ?? this.intervalSeconds,
    wifiOnly: wifiOnly ?? this.wifiOnly,
    capabilities: capabilities ?? this.capabilities,
    lastSyncAtMs: lastSyncAtMs.present ? lastSyncAtMs.value : this.lastSyncAtMs,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncDestination copyWithCompanion(SyncDestinationsCompanion data) {
    return SyncDestination(
      libraryPath: data.libraryPath.present
          ? data.libraryPath.value
          : this.libraryPath,
      url: data.url.present ? data.url.value : this.url,
      username: data.username.present ? data.username.value : this.username,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      autoSync: data.autoSync.present ? data.autoSync.value : this.autoSync,
      intervalSeconds: data.intervalSeconds.present
          ? data.intervalSeconds.value
          : this.intervalSeconds,
      wifiOnly: data.wifiOnly.present ? data.wifiOnly.value : this.wifiOnly,
      capabilities: data.capabilities.present
          ? data.capabilities.value
          : this.capabilities,
      lastSyncAtMs: data.lastSyncAtMs.present
          ? data.lastSyncAtMs.value
          : this.lastSyncAtMs,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncDestination(')
          ..write('libraryPath: $libraryPath, ')
          ..write('url: $url, ')
          ..write('username: $username, ')
          ..write('enabled: $enabled, ')
          ..write('autoSync: $autoSync, ')
          ..write('intervalSeconds: $intervalSeconds, ')
          ..write('wifiOnly: $wifiOnly, ')
          ..write('capabilities: $capabilities, ')
          ..write('lastSyncAtMs: $lastSyncAtMs, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    libraryPath,
    url,
    username,
    enabled,
    autoSync,
    intervalSeconds,
    wifiOnly,
    capabilities,
    lastSyncAtMs,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncDestination &&
          other.libraryPath == this.libraryPath &&
          other.url == this.url &&
          other.username == this.username &&
          other.enabled == this.enabled &&
          other.autoSync == this.autoSync &&
          other.intervalSeconds == this.intervalSeconds &&
          other.wifiOnly == this.wifiOnly &&
          other.capabilities == this.capabilities &&
          other.lastSyncAtMs == this.lastSyncAtMs &&
          other.lastError == this.lastError);
}

class SyncDestinationsCompanion extends UpdateCompanion<SyncDestination> {
  final Value<String> libraryPath;
  final Value<String> url;
  final Value<String> username;
  final Value<bool> enabled;
  final Value<bool> autoSync;
  final Value<int> intervalSeconds;
  final Value<bool> wifiOnly;
  final Value<String> capabilities;
  final Value<int?> lastSyncAtMs;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncDestinationsCompanion({
    this.libraryPath = const Value.absent(),
    this.url = const Value.absent(),
    this.username = const Value.absent(),
    this.enabled = const Value.absent(),
    this.autoSync = const Value.absent(),
    this.intervalSeconds = const Value.absent(),
    this.wifiOnly = const Value.absent(),
    this.capabilities = const Value.absent(),
    this.lastSyncAtMs = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncDestinationsCompanion.insert({
    required String libraryPath,
    required String url,
    this.username = const Value.absent(),
    this.enabled = const Value.absent(),
    this.autoSync = const Value.absent(),
    this.intervalSeconds = const Value.absent(),
    this.wifiOnly = const Value.absent(),
    this.capabilities = const Value.absent(),
    this.lastSyncAtMs = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : libraryPath = Value(libraryPath),
       url = Value(url);
  static Insertable<SyncDestination> custom({
    Expression<String>? libraryPath,
    Expression<String>? url,
    Expression<String>? username,
    Expression<bool>? enabled,
    Expression<bool>? autoSync,
    Expression<int>? intervalSeconds,
    Expression<bool>? wifiOnly,
    Expression<String>? capabilities,
    Expression<int>? lastSyncAtMs,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (libraryPath != null) 'library_path': libraryPath,
      if (url != null) 'url': url,
      if (username != null) 'username': username,
      if (enabled != null) 'enabled': enabled,
      if (autoSync != null) 'auto_sync': autoSync,
      if (intervalSeconds != null) 'interval_seconds': intervalSeconds,
      if (wifiOnly != null) 'wifi_only': wifiOnly,
      if (capabilities != null) 'capabilities': capabilities,
      if (lastSyncAtMs != null) 'last_sync_at_ms': lastSyncAtMs,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncDestinationsCompanion copyWith({
    Value<String>? libraryPath,
    Value<String>? url,
    Value<String>? username,
    Value<bool>? enabled,
    Value<bool>? autoSync,
    Value<int>? intervalSeconds,
    Value<bool>? wifiOnly,
    Value<String>? capabilities,
    Value<int?>? lastSyncAtMs,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return SyncDestinationsCompanion(
      libraryPath: libraryPath ?? this.libraryPath,
      url: url ?? this.url,
      username: username ?? this.username,
      enabled: enabled ?? this.enabled,
      autoSync: autoSync ?? this.autoSync,
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      capabilities: capabilities ?? this.capabilities,
      lastSyncAtMs: lastSyncAtMs ?? this.lastSyncAtMs,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (libraryPath.present) {
      map['library_path'] = Variable<String>(libraryPath.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (autoSync.present) {
      map['auto_sync'] = Variable<bool>(autoSync.value);
    }
    if (intervalSeconds.present) {
      map['interval_seconds'] = Variable<int>(intervalSeconds.value);
    }
    if (wifiOnly.present) {
      map['wifi_only'] = Variable<bool>(wifiOnly.value);
    }
    if (capabilities.present) {
      map['capabilities'] = Variable<String>(capabilities.value);
    }
    if (lastSyncAtMs.present) {
      map['last_sync_at_ms'] = Variable<int>(lastSyncAtMs.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncDestinationsCompanion(')
          ..write('libraryPath: $libraryPath, ')
          ..write('url: $url, ')
          ..write('username: $username, ')
          ..write('enabled: $enabled, ')
          ..write('autoSync: $autoSync, ')
          ..write('intervalSeconds: $intervalSeconds, ')
          ..write('wifiOnly: $wifiOnly, ')
          ..write('capabilities: $capabilities, ')
          ..write('lastSyncAtMs: $lastSyncAtMs, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncItemsTable extends SyncItems
    with TableInfo<$SyncItemsTable, SyncItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _libraryPathMeta = const VerificationMeta(
    'libraryPath',
  );
  @override
  late final GeneratedColumn<String> libraryPath = GeneratedColumn<String>(
    'library_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localSha256Meta = const VerificationMeta(
    'localSha256',
  );
  @override
  late final GeneratedColumn<String> localSha256 = GeneratedColumn<String>(
    'local_sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localSizeMeta = const VerificationMeta(
    'localSize',
  );
  @override
  late final GeneratedColumn<int> localSize = GeneratedColumn<int>(
    'local_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localMtimeMsMeta = const VerificationMeta(
    'localMtimeMs',
  );
  @override
  late final GeneratedColumn<int> localMtimeMs = GeneratedColumn<int>(
    'local_mtime_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteEtagMeta = const VerificationMeta(
    'remoteEtag',
  );
  @override
  late final GeneratedColumn<String> remoteEtag = GeneratedColumn<String>(
    'remote_etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteSizeMeta = const VerificationMeta(
    'remoteSize',
  );
  @override
  late final GeneratedColumn<int> remoteSize = GeneratedColumn<int>(
    'remote_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteMtimeMsMeta = const VerificationMeta(
    'remoteMtimeMs',
  );
  @override
  late final GeneratedColumn<int> remoteMtimeMs = GeneratedColumn<int>(
    'remote_mtime_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteUnverifiedMeta = const VerificationMeta(
    'remoteUnverified',
  );
  @override
  late final GeneratedColumn<bool> remoteUnverified = GeneratedColumn<bool>(
    'remote_unverified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("remote_unverified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _remoteFileIdMeta = const VerificationMeta(
    'remoteFileId',
  );
  @override
  late final GeneratedColumn<String> remoteFileId = GeneratedColumn<String>(
    'remote_file_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baseVersionMeta = const VerificationMeta(
    'baseVersion',
  );
  @override
  late final GeneratedColumn<int> baseVersion = GeneratedColumn<int>(
    'base_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baseTextMeta = const VerificationMeta(
    'baseText',
  );
  @override
  late final GeneratedColumn<String> baseText = GeneratedColumn<String>(
    'base_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMsMeta = const VerificationMeta(
    'syncedAtMs',
  );
  @override
  late final GeneratedColumn<int> syncedAtMs = GeneratedColumn<int>(
    'synced_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    libraryPath,
    path,
    localSha256,
    localSize,
    localMtimeMs,
    remoteEtag,
    remoteSize,
    remoteMtimeMs,
    remoteUnverified,
    remoteFileId,
    baseVersion,
    baseText,
    syncedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('library_path')) {
      context.handle(
        _libraryPathMeta,
        libraryPath.isAcceptableOrUnknown(
          data['library_path']!,
          _libraryPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_libraryPathMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('local_sha256')) {
      context.handle(
        _localSha256Meta,
        localSha256.isAcceptableOrUnknown(
          data['local_sha256']!,
          _localSha256Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localSha256Meta);
    }
    if (data.containsKey('local_size')) {
      context.handle(
        _localSizeMeta,
        localSize.isAcceptableOrUnknown(data['local_size']!, _localSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_localSizeMeta);
    }
    if (data.containsKey('local_mtime_ms')) {
      context.handle(
        _localMtimeMsMeta,
        localMtimeMs.isAcceptableOrUnknown(
          data['local_mtime_ms']!,
          _localMtimeMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localMtimeMsMeta);
    }
    if (data.containsKey('remote_etag')) {
      context.handle(
        _remoteEtagMeta,
        remoteEtag.isAcceptableOrUnknown(data['remote_etag']!, _remoteEtagMeta),
      );
    }
    if (data.containsKey('remote_size')) {
      context.handle(
        _remoteSizeMeta,
        remoteSize.isAcceptableOrUnknown(data['remote_size']!, _remoteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteSizeMeta);
    }
    if (data.containsKey('remote_mtime_ms')) {
      context.handle(
        _remoteMtimeMsMeta,
        remoteMtimeMs.isAcceptableOrUnknown(
          data['remote_mtime_ms']!,
          _remoteMtimeMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteMtimeMsMeta);
    }
    if (data.containsKey('remote_unverified')) {
      context.handle(
        _remoteUnverifiedMeta,
        remoteUnverified.isAcceptableOrUnknown(
          data['remote_unverified']!,
          _remoteUnverifiedMeta,
        ),
      );
    }
    if (data.containsKey('remote_file_id')) {
      context.handle(
        _remoteFileIdMeta,
        remoteFileId.isAcceptableOrUnknown(
          data['remote_file_id']!,
          _remoteFileIdMeta,
        ),
      );
    }
    if (data.containsKey('base_version')) {
      context.handle(
        _baseVersionMeta,
        baseVersion.isAcceptableOrUnknown(
          data['base_version']!,
          _baseVersionMeta,
        ),
      );
    }
    if (data.containsKey('base_text')) {
      context.handle(
        _baseTextMeta,
        baseText.isAcceptableOrUnknown(data['base_text']!, _baseTextMeta),
      );
    }
    if (data.containsKey('synced_at_ms')) {
      context.handle(
        _syncedAtMsMeta,
        syncedAtMs.isAcceptableOrUnknown(
          data['synced_at_ms']!,
          _syncedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {libraryPath, path};
  @override
  SyncItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncItem(
      libraryPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_path'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      localSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_sha256'],
      )!,
      localSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_size'],
      )!,
      localMtimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_mtime_ms'],
      )!,
      remoteEtag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_etag'],
      ),
      remoteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_size'],
      )!,
      remoteMtimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_mtime_ms'],
      )!,
      remoteUnverified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}remote_unverified'],
      )!,
      remoteFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_file_id'],
      ),
      baseVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_version'],
      ),
      baseText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_text'],
      ),
      syncedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_at_ms'],
      )!,
    );
  }

  @override
  $SyncItemsTable createAlias(String alias) {
    return $SyncItemsTable(attachedDatabase, alias);
  }
}

class SyncItem extends DataClass implements Insertable<SyncItem> {
  /// Absolute, normalized library root.
  final String libraryPath;

  /// Library-relative, `/`-separated file path.
  final String path;

  /// Hex sha256 of the agreed content.
  final String localSha256;

  /// Size of the agreed content in bytes.
  final int localSize;

  /// Disk mtime right after the sync wrote or read the file, ms.
  final int localMtimeMs;

  /// The remote ETag as sent; null when the server has none.
  final String? remoteEtag;

  /// The remote size in bytes.
  final int remoteSize;

  /// The remote `getlastmodified`, ms (one-second resolution).
  final int remoteMtimeMs;

  /// Whether the listing this row was recorded from could not rule out a
  /// second write within the same second: a server without ETags whose
  /// `getlastmodified` was the server's current second. The next
  /// reconcile hashes the remote instead of trusting size and mtime.
  final bool remoteUnverified;

  /// The remote `oc:fileid`, when the server has one.
  final String? remoteFileId;

  /// The `.history` version pinned as the merge base; null for
  /// attachments and when history is off.
  final int? baseVersion;

  /// For the library state files (`.niman/settings.json`, `counters.json`),
  /// which keep no history: the agreed content itself, the base of their
  /// key-by-key merge. Null for every other file.
  final String? baseText;

  /// When this agreement was recorded, ms.
  final int syncedAtMs;
  const SyncItem({
    required this.libraryPath,
    required this.path,
    required this.localSha256,
    required this.localSize,
    required this.localMtimeMs,
    this.remoteEtag,
    required this.remoteSize,
    required this.remoteMtimeMs,
    required this.remoteUnverified,
    this.remoteFileId,
    this.baseVersion,
    this.baseText,
    required this.syncedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['library_path'] = Variable<String>(libraryPath);
    map['path'] = Variable<String>(path);
    map['local_sha256'] = Variable<String>(localSha256);
    map['local_size'] = Variable<int>(localSize);
    map['local_mtime_ms'] = Variable<int>(localMtimeMs);
    if (!nullToAbsent || remoteEtag != null) {
      map['remote_etag'] = Variable<String>(remoteEtag);
    }
    map['remote_size'] = Variable<int>(remoteSize);
    map['remote_mtime_ms'] = Variable<int>(remoteMtimeMs);
    map['remote_unverified'] = Variable<bool>(remoteUnverified);
    if (!nullToAbsent || remoteFileId != null) {
      map['remote_file_id'] = Variable<String>(remoteFileId);
    }
    if (!nullToAbsent || baseVersion != null) {
      map['base_version'] = Variable<int>(baseVersion);
    }
    if (!nullToAbsent || baseText != null) {
      map['base_text'] = Variable<String>(baseText);
    }
    map['synced_at_ms'] = Variable<int>(syncedAtMs);
    return map;
  }

  SyncItemsCompanion toCompanion(bool nullToAbsent) {
    return SyncItemsCompanion(
      libraryPath: Value(libraryPath),
      path: Value(path),
      localSha256: Value(localSha256),
      localSize: Value(localSize),
      localMtimeMs: Value(localMtimeMs),
      remoteEtag: remoteEtag == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteEtag),
      remoteSize: Value(remoteSize),
      remoteMtimeMs: Value(remoteMtimeMs),
      remoteUnverified: Value(remoteUnverified),
      remoteFileId: remoteFileId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteFileId),
      baseVersion: baseVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseVersion),
      baseText: baseText == null && nullToAbsent
          ? const Value.absent()
          : Value(baseText),
      syncedAtMs: Value(syncedAtMs),
    );
  }

  factory SyncItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncItem(
      libraryPath: serializer.fromJson<String>(json['libraryPath']),
      path: serializer.fromJson<String>(json['path']),
      localSha256: serializer.fromJson<String>(json['localSha256']),
      localSize: serializer.fromJson<int>(json['localSize']),
      localMtimeMs: serializer.fromJson<int>(json['localMtimeMs']),
      remoteEtag: serializer.fromJson<String?>(json['remoteEtag']),
      remoteSize: serializer.fromJson<int>(json['remoteSize']),
      remoteMtimeMs: serializer.fromJson<int>(json['remoteMtimeMs']),
      remoteUnverified: serializer.fromJson<bool>(json['remoteUnverified']),
      remoteFileId: serializer.fromJson<String?>(json['remoteFileId']),
      baseVersion: serializer.fromJson<int?>(json['baseVersion']),
      baseText: serializer.fromJson<String?>(json['baseText']),
      syncedAtMs: serializer.fromJson<int>(json['syncedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'libraryPath': serializer.toJson<String>(libraryPath),
      'path': serializer.toJson<String>(path),
      'localSha256': serializer.toJson<String>(localSha256),
      'localSize': serializer.toJson<int>(localSize),
      'localMtimeMs': serializer.toJson<int>(localMtimeMs),
      'remoteEtag': serializer.toJson<String?>(remoteEtag),
      'remoteSize': serializer.toJson<int>(remoteSize),
      'remoteMtimeMs': serializer.toJson<int>(remoteMtimeMs),
      'remoteUnverified': serializer.toJson<bool>(remoteUnverified),
      'remoteFileId': serializer.toJson<String?>(remoteFileId),
      'baseVersion': serializer.toJson<int?>(baseVersion),
      'baseText': serializer.toJson<String?>(baseText),
      'syncedAtMs': serializer.toJson<int>(syncedAtMs),
    };
  }

  SyncItem copyWith({
    String? libraryPath,
    String? path,
    String? localSha256,
    int? localSize,
    int? localMtimeMs,
    Value<String?> remoteEtag = const Value.absent(),
    int? remoteSize,
    int? remoteMtimeMs,
    bool? remoteUnverified,
    Value<String?> remoteFileId = const Value.absent(),
    Value<int?> baseVersion = const Value.absent(),
    Value<String?> baseText = const Value.absent(),
    int? syncedAtMs,
  }) => SyncItem(
    libraryPath: libraryPath ?? this.libraryPath,
    path: path ?? this.path,
    localSha256: localSha256 ?? this.localSha256,
    localSize: localSize ?? this.localSize,
    localMtimeMs: localMtimeMs ?? this.localMtimeMs,
    remoteEtag: remoteEtag.present ? remoteEtag.value : this.remoteEtag,
    remoteSize: remoteSize ?? this.remoteSize,
    remoteMtimeMs: remoteMtimeMs ?? this.remoteMtimeMs,
    remoteUnverified: remoteUnverified ?? this.remoteUnverified,
    remoteFileId: remoteFileId.present ? remoteFileId.value : this.remoteFileId,
    baseVersion: baseVersion.present ? baseVersion.value : this.baseVersion,
    baseText: baseText.present ? baseText.value : this.baseText,
    syncedAtMs: syncedAtMs ?? this.syncedAtMs,
  );
  SyncItem copyWithCompanion(SyncItemsCompanion data) {
    return SyncItem(
      libraryPath: data.libraryPath.present
          ? data.libraryPath.value
          : this.libraryPath,
      path: data.path.present ? data.path.value : this.path,
      localSha256: data.localSha256.present
          ? data.localSha256.value
          : this.localSha256,
      localSize: data.localSize.present ? data.localSize.value : this.localSize,
      localMtimeMs: data.localMtimeMs.present
          ? data.localMtimeMs.value
          : this.localMtimeMs,
      remoteEtag: data.remoteEtag.present
          ? data.remoteEtag.value
          : this.remoteEtag,
      remoteSize: data.remoteSize.present
          ? data.remoteSize.value
          : this.remoteSize,
      remoteMtimeMs: data.remoteMtimeMs.present
          ? data.remoteMtimeMs.value
          : this.remoteMtimeMs,
      remoteUnverified: data.remoteUnverified.present
          ? data.remoteUnverified.value
          : this.remoteUnverified,
      remoteFileId: data.remoteFileId.present
          ? data.remoteFileId.value
          : this.remoteFileId,
      baseVersion: data.baseVersion.present
          ? data.baseVersion.value
          : this.baseVersion,
      baseText: data.baseText.present ? data.baseText.value : this.baseText,
      syncedAtMs: data.syncedAtMs.present
          ? data.syncedAtMs.value
          : this.syncedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncItem(')
          ..write('libraryPath: $libraryPath, ')
          ..write('path: $path, ')
          ..write('localSha256: $localSha256, ')
          ..write('localSize: $localSize, ')
          ..write('localMtimeMs: $localMtimeMs, ')
          ..write('remoteEtag: $remoteEtag, ')
          ..write('remoteSize: $remoteSize, ')
          ..write('remoteMtimeMs: $remoteMtimeMs, ')
          ..write('remoteUnverified: $remoteUnverified, ')
          ..write('remoteFileId: $remoteFileId, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('baseText: $baseText, ')
          ..write('syncedAtMs: $syncedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    libraryPath,
    path,
    localSha256,
    localSize,
    localMtimeMs,
    remoteEtag,
    remoteSize,
    remoteMtimeMs,
    remoteUnverified,
    remoteFileId,
    baseVersion,
    baseText,
    syncedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncItem &&
          other.libraryPath == this.libraryPath &&
          other.path == this.path &&
          other.localSha256 == this.localSha256 &&
          other.localSize == this.localSize &&
          other.localMtimeMs == this.localMtimeMs &&
          other.remoteEtag == this.remoteEtag &&
          other.remoteSize == this.remoteSize &&
          other.remoteMtimeMs == this.remoteMtimeMs &&
          other.remoteUnverified == this.remoteUnverified &&
          other.remoteFileId == this.remoteFileId &&
          other.baseVersion == this.baseVersion &&
          other.baseText == this.baseText &&
          other.syncedAtMs == this.syncedAtMs);
}

class SyncItemsCompanion extends UpdateCompanion<SyncItem> {
  final Value<String> libraryPath;
  final Value<String> path;
  final Value<String> localSha256;
  final Value<int> localSize;
  final Value<int> localMtimeMs;
  final Value<String?> remoteEtag;
  final Value<int> remoteSize;
  final Value<int> remoteMtimeMs;
  final Value<bool> remoteUnverified;
  final Value<String?> remoteFileId;
  final Value<int?> baseVersion;
  final Value<String?> baseText;
  final Value<int> syncedAtMs;
  final Value<int> rowid;
  const SyncItemsCompanion({
    this.libraryPath = const Value.absent(),
    this.path = const Value.absent(),
    this.localSha256 = const Value.absent(),
    this.localSize = const Value.absent(),
    this.localMtimeMs = const Value.absent(),
    this.remoteEtag = const Value.absent(),
    this.remoteSize = const Value.absent(),
    this.remoteMtimeMs = const Value.absent(),
    this.remoteUnverified = const Value.absent(),
    this.remoteFileId = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.baseText = const Value.absent(),
    this.syncedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncItemsCompanion.insert({
    required String libraryPath,
    required String path,
    required String localSha256,
    required int localSize,
    required int localMtimeMs,
    this.remoteEtag = const Value.absent(),
    required int remoteSize,
    required int remoteMtimeMs,
    this.remoteUnverified = const Value.absent(),
    this.remoteFileId = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.baseText = const Value.absent(),
    required int syncedAtMs,
    this.rowid = const Value.absent(),
  }) : libraryPath = Value(libraryPath),
       path = Value(path),
       localSha256 = Value(localSha256),
       localSize = Value(localSize),
       localMtimeMs = Value(localMtimeMs),
       remoteSize = Value(remoteSize),
       remoteMtimeMs = Value(remoteMtimeMs),
       syncedAtMs = Value(syncedAtMs);
  static Insertable<SyncItem> custom({
    Expression<String>? libraryPath,
    Expression<String>? path,
    Expression<String>? localSha256,
    Expression<int>? localSize,
    Expression<int>? localMtimeMs,
    Expression<String>? remoteEtag,
    Expression<int>? remoteSize,
    Expression<int>? remoteMtimeMs,
    Expression<bool>? remoteUnverified,
    Expression<String>? remoteFileId,
    Expression<int>? baseVersion,
    Expression<String>? baseText,
    Expression<int>? syncedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (libraryPath != null) 'library_path': libraryPath,
      if (path != null) 'path': path,
      if (localSha256 != null) 'local_sha256': localSha256,
      if (localSize != null) 'local_size': localSize,
      if (localMtimeMs != null) 'local_mtime_ms': localMtimeMs,
      if (remoteEtag != null) 'remote_etag': remoteEtag,
      if (remoteSize != null) 'remote_size': remoteSize,
      if (remoteMtimeMs != null) 'remote_mtime_ms': remoteMtimeMs,
      if (remoteUnverified != null) 'remote_unverified': remoteUnverified,
      if (remoteFileId != null) 'remote_file_id': remoteFileId,
      if (baseVersion != null) 'base_version': baseVersion,
      if (baseText != null) 'base_text': baseText,
      if (syncedAtMs != null) 'synced_at_ms': syncedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncItemsCompanion copyWith({
    Value<String>? libraryPath,
    Value<String>? path,
    Value<String>? localSha256,
    Value<int>? localSize,
    Value<int>? localMtimeMs,
    Value<String?>? remoteEtag,
    Value<int>? remoteSize,
    Value<int>? remoteMtimeMs,
    Value<bool>? remoteUnverified,
    Value<String?>? remoteFileId,
    Value<int?>? baseVersion,
    Value<String?>? baseText,
    Value<int>? syncedAtMs,
    Value<int>? rowid,
  }) {
    return SyncItemsCompanion(
      libraryPath: libraryPath ?? this.libraryPath,
      path: path ?? this.path,
      localSha256: localSha256 ?? this.localSha256,
      localSize: localSize ?? this.localSize,
      localMtimeMs: localMtimeMs ?? this.localMtimeMs,
      remoteEtag: remoteEtag ?? this.remoteEtag,
      remoteSize: remoteSize ?? this.remoteSize,
      remoteMtimeMs: remoteMtimeMs ?? this.remoteMtimeMs,
      remoteUnverified: remoteUnverified ?? this.remoteUnverified,
      remoteFileId: remoteFileId ?? this.remoteFileId,
      baseVersion: baseVersion ?? this.baseVersion,
      baseText: baseText ?? this.baseText,
      syncedAtMs: syncedAtMs ?? this.syncedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (libraryPath.present) {
      map['library_path'] = Variable<String>(libraryPath.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (localSha256.present) {
      map['local_sha256'] = Variable<String>(localSha256.value);
    }
    if (localSize.present) {
      map['local_size'] = Variable<int>(localSize.value);
    }
    if (localMtimeMs.present) {
      map['local_mtime_ms'] = Variable<int>(localMtimeMs.value);
    }
    if (remoteEtag.present) {
      map['remote_etag'] = Variable<String>(remoteEtag.value);
    }
    if (remoteSize.present) {
      map['remote_size'] = Variable<int>(remoteSize.value);
    }
    if (remoteMtimeMs.present) {
      map['remote_mtime_ms'] = Variable<int>(remoteMtimeMs.value);
    }
    if (remoteUnverified.present) {
      map['remote_unverified'] = Variable<bool>(remoteUnverified.value);
    }
    if (remoteFileId.present) {
      map['remote_file_id'] = Variable<String>(remoteFileId.value);
    }
    if (baseVersion.present) {
      map['base_version'] = Variable<int>(baseVersion.value);
    }
    if (baseText.present) {
      map['base_text'] = Variable<String>(baseText.value);
    }
    if (syncedAtMs.present) {
      map['synced_at_ms'] = Variable<int>(syncedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncItemsCompanion(')
          ..write('libraryPath: $libraryPath, ')
          ..write('path: $path, ')
          ..write('localSha256: $localSha256, ')
          ..write('localSize: $localSize, ')
          ..write('localMtimeMs: $localMtimeMs, ')
          ..write('remoteEtag: $remoteEtag, ')
          ..write('remoteSize: $remoteSize, ')
          ..write('remoteMtimeMs: $remoteMtimeMs, ')
          ..write('remoteUnverified: $remoteUnverified, ')
          ..write('remoteFileId: $remoteFileId, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('baseText: $baseText, ')
          ..write('syncedAtMs: $syncedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOpsTable extends SyncOps with TableInfo<$SyncOpsTable, SyncOp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOpsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _libraryPathMeta = const VerificationMeta(
    'libraryPath',
  );
  @override
  late final GeneratedColumn<String> libraryPath = GeneratedColumn<String>(
    'library_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _fromPathMeta = const VerificationMeta(
    'fromPath',
  );
  @override
  late final GeneratedColumn<String> fromPath = GeneratedColumn<String>(
    'from_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMsMeta = const VerificationMeta(
    'nextAttemptAtMs',
  );
  @override
  late final GeneratedColumn<int> nextAttemptAtMs = GeneratedColumn<int>(
    'next_attempt_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    libraryPath,
    path,
    kind,
    fromPath,
    attempts,
    nextAttemptAtMs,
    lastError,
    createdAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_ops';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOp> instance, {
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
    } else if (isInserting) {
      context.missing(_libraryPathMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('from_path')) {
      context.handle(
        _fromPathMeta,
        fromPath.isAcceptableOrUnknown(data['from_path']!, _fromPathMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at_ms')) {
      context.handle(
        _nextAttemptAtMsMeta,
        nextAttemptAtMs.isAcceptableOrUnknown(
          data['next_attempt_at_ms']!,
          _nextAttemptAtMsMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {libraryPath, path},
  ];
  @override
  SyncOp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOp(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      libraryPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_path'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      fromPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_path'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at_ms'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
    );
  }

  @override
  $SyncOpsTable createAlias(String alias) {
    return $SyncOpsTable(attachedDatabase, alias);
  }
}

class SyncOp extends DataClass implements Insertable<SyncOp> {
  /// Row id.
  final int id;

  /// Absolute, normalized library root.
  final String libraryPath;

  /// Library-relative, `/`-separated path (a file, or a folder for a
  /// folder move or delete).
  final String path;

  /// `changed`, `deleted` or `moved` (`SyncOpKind`).
  final String kind;

  /// Where a `moved` path came from.
  final String? fromPath;

  /// Failed runs so far.
  final int attempts;

  /// Not retried before this time, ms; 0 = due now.
  final int nextAttemptAtMs;

  /// The last failure, short; never a secret.
  final String? lastError;

  /// When the hint was last written, ms. Strictly increases on every
  /// rewrite, so a sync that finishes an older hint can tell it was
  /// replaced meanwhile and leave the new one alone.
  final int createdAtMs;
  const SyncOp({
    required this.id,
    required this.libraryPath,
    required this.path,
    required this.kind,
    this.fromPath,
    required this.attempts,
    required this.nextAttemptAtMs,
    this.lastError,
    required this.createdAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['library_path'] = Variable<String>(libraryPath);
    map['path'] = Variable<String>(path);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || fromPath != null) {
      map['from_path'] = Variable<String>(fromPath);
    }
    map['attempts'] = Variable<int>(attempts);
    map['next_attempt_at_ms'] = Variable<int>(nextAttemptAtMs);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  SyncOpsCompanion toCompanion(bool nullToAbsent) {
    return SyncOpsCompanion(
      id: Value(id),
      libraryPath: Value(libraryPath),
      path: Value(path),
      kind: Value(kind),
      fromPath: fromPath == null && nullToAbsent
          ? const Value.absent()
          : Value(fromPath),
      attempts: Value(attempts),
      nextAttemptAtMs: Value(nextAttemptAtMs),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory SyncOp.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOp(
      id: serializer.fromJson<int>(json['id']),
      libraryPath: serializer.fromJson<String>(json['libraryPath']),
      path: serializer.fromJson<String>(json['path']),
      kind: serializer.fromJson<String>(json['kind']),
      fromPath: serializer.fromJson<String?>(json['fromPath']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAtMs: serializer.fromJson<int>(json['nextAttemptAtMs']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'libraryPath': serializer.toJson<String>(libraryPath),
      'path': serializer.toJson<String>(path),
      'kind': serializer.toJson<String>(kind),
      'fromPath': serializer.toJson<String?>(fromPath),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAtMs': serializer.toJson<int>(nextAttemptAtMs),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
    };
  }

  SyncOp copyWith({
    int? id,
    String? libraryPath,
    String? path,
    String? kind,
    Value<String?> fromPath = const Value.absent(),
    int? attempts,
    int? nextAttemptAtMs,
    Value<String?> lastError = const Value.absent(),
    int? createdAtMs,
  }) => SyncOp(
    id: id ?? this.id,
    libraryPath: libraryPath ?? this.libraryPath,
    path: path ?? this.path,
    kind: kind ?? this.kind,
    fromPath: fromPath.present ? fromPath.value : this.fromPath,
    attempts: attempts ?? this.attempts,
    nextAttemptAtMs: nextAttemptAtMs ?? this.nextAttemptAtMs,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAtMs: createdAtMs ?? this.createdAtMs,
  );
  SyncOp copyWithCompanion(SyncOpsCompanion data) {
    return SyncOp(
      id: data.id.present ? data.id.value : this.id,
      libraryPath: data.libraryPath.present
          ? data.libraryPath.value
          : this.libraryPath,
      path: data.path.present ? data.path.value : this.path,
      kind: data.kind.present ? data.kind.value : this.kind,
      fromPath: data.fromPath.present ? data.fromPath.value : this.fromPath,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAtMs: data.nextAttemptAtMs.present
          ? data.nextAttemptAtMs.value
          : this.nextAttemptAtMs,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOp(')
          ..write('id: $id, ')
          ..write('libraryPath: $libraryPath, ')
          ..write('path: $path, ')
          ..write('kind: $kind, ')
          ..write('fromPath: $fromPath, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAtMs: $nextAttemptAtMs, ')
          ..write('lastError: $lastError, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    libraryPath,
    path,
    kind,
    fromPath,
    attempts,
    nextAttemptAtMs,
    lastError,
    createdAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOp &&
          other.id == this.id &&
          other.libraryPath == this.libraryPath &&
          other.path == this.path &&
          other.kind == this.kind &&
          other.fromPath == this.fromPath &&
          other.attempts == this.attempts &&
          other.nextAttemptAtMs == this.nextAttemptAtMs &&
          other.lastError == this.lastError &&
          other.createdAtMs == this.createdAtMs);
}

class SyncOpsCompanion extends UpdateCompanion<SyncOp> {
  final Value<int> id;
  final Value<String> libraryPath;
  final Value<String> path;
  final Value<String> kind;
  final Value<String?> fromPath;
  final Value<int> attempts;
  final Value<int> nextAttemptAtMs;
  final Value<String?> lastError;
  final Value<int> createdAtMs;
  const SyncOpsCompanion({
    this.id = const Value.absent(),
    this.libraryPath = const Value.absent(),
    this.path = const Value.absent(),
    this.kind = const Value.absent(),
    this.fromPath = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAtMs = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAtMs = const Value.absent(),
  });
  SyncOpsCompanion.insert({
    this.id = const Value.absent(),
    required String libraryPath,
    required String path,
    required String kind,
    this.fromPath = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAtMs = const Value.absent(),
    this.lastError = const Value.absent(),
    required int createdAtMs,
  }) : libraryPath = Value(libraryPath),
       path = Value(path),
       kind = Value(kind),
       createdAtMs = Value(createdAtMs);
  static Insertable<SyncOp> custom({
    Expression<int>? id,
    Expression<String>? libraryPath,
    Expression<String>? path,
    Expression<String>? kind,
    Expression<String>? fromPath,
    Expression<int>? attempts,
    Expression<int>? nextAttemptAtMs,
    Expression<String>? lastError,
    Expression<int>? createdAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (libraryPath != null) 'library_path': libraryPath,
      if (path != null) 'path': path,
      if (kind != null) 'kind': kind,
      if (fromPath != null) 'from_path': fromPath,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAtMs != null) 'next_attempt_at_ms': nextAttemptAtMs,
      if (lastError != null) 'last_error': lastError,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
    });
  }

  SyncOpsCompanion copyWith({
    Value<int>? id,
    Value<String>? libraryPath,
    Value<String>? path,
    Value<String>? kind,
    Value<String?>? fromPath,
    Value<int>? attempts,
    Value<int>? nextAttemptAtMs,
    Value<String?>? lastError,
    Value<int>? createdAtMs,
  }) {
    return SyncOpsCompanion(
      id: id ?? this.id,
      libraryPath: libraryPath ?? this.libraryPath,
      path: path ?? this.path,
      kind: kind ?? this.kind,
      fromPath: fromPath ?? this.fromPath,
      attempts: attempts ?? this.attempts,
      nextAttemptAtMs: nextAttemptAtMs ?? this.nextAttemptAtMs,
      lastError: lastError ?? this.lastError,
      createdAtMs: createdAtMs ?? this.createdAtMs,
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
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (fromPath.present) {
      map['from_path'] = Variable<String>(fromPath.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAtMs.present) {
      map['next_attempt_at_ms'] = Variable<int>(nextAttemptAtMs.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOpsCompanion(')
          ..write('id: $id, ')
          ..write('libraryPath: $libraryPath, ')
          ..write('path: $path, ')
          ..write('kind: $kind, ')
          ..write('fromPath: $fromPath, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAtMs: $nextAttemptAtMs, ')
          ..write('lastError: $lastError, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }
}

class $WorkspacesTable extends Workspaces
    with TableInfo<$WorkspacesTable, WorkspaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkspacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _libraryPathMeta = const VerificationMeta(
    'libraryPath',
  );
  @override
  late final GeneratedColumn<String> libraryPath = GeneratedColumn<String>(
    'library_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [libraryPath, state, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspaceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('library_path')) {
      context.handle(
        _libraryPathMeta,
        libraryPath.isAcceptableOrUnknown(
          data['library_path']!,
          _libraryPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_libraryPathMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {libraryPath};
  @override
  WorkspaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceRow(
      libraryPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_path'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WorkspacesTable createAlias(String alias) {
    return $WorkspacesTable(attachedDatabase, alias);
  }
}

class WorkspaceRow extends DataClass implements Insertable<WorkspaceRow> {
  /// Absolute, normalized path of the library root; the primary key.
  final String libraryPath;

  /// The workspace, as `Workspace.toJson` writes it.
  final String state;

  /// When it was last written.
  final DateTime updatedAt;
  const WorkspaceRow({
    required this.libraryPath,
    required this.state,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['library_path'] = Variable<String>(libraryPath);
    map['state'] = Variable<String>(state);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WorkspacesCompanion toCompanion(bool nullToAbsent) {
    return WorkspacesCompanion(
      libraryPath: Value(libraryPath),
      state: Value(state),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorkspaceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceRow(
      libraryPath: serializer.fromJson<String>(json['libraryPath']),
      state: serializer.fromJson<String>(json['state']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'libraryPath': serializer.toJson<String>(libraryPath),
      'state': serializer.toJson<String>(state),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WorkspaceRow copyWith({
    String? libraryPath,
    String? state,
    DateTime? updatedAt,
  }) => WorkspaceRow(
    libraryPath: libraryPath ?? this.libraryPath,
    state: state ?? this.state,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WorkspaceRow copyWithCompanion(WorkspacesCompanion data) {
    return WorkspaceRow(
      libraryPath: data.libraryPath.present
          ? data.libraryPath.value
          : this.libraryPath,
      state: data.state.present ? data.state.value : this.state,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceRow(')
          ..write('libraryPath: $libraryPath, ')
          ..write('state: $state, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(libraryPath, state, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceRow &&
          other.libraryPath == this.libraryPath &&
          other.state == this.state &&
          other.updatedAt == this.updatedAt);
}

class WorkspacesCompanion extends UpdateCompanion<WorkspaceRow> {
  final Value<String> libraryPath;
  final Value<String> state;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WorkspacesCompanion({
    this.libraryPath = const Value.absent(),
    this.state = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspacesCompanion.insert({
    required String libraryPath,
    required String state,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : libraryPath = Value(libraryPath),
       state = Value(state),
       updatedAt = Value(updatedAt);
  static Insertable<WorkspaceRow> custom({
    Expression<String>? libraryPath,
    Expression<String>? state,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (libraryPath != null) 'library_path': libraryPath,
      if (state != null) 'state': state,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspacesCompanion copyWith({
    Value<String>? libraryPath,
    Value<String>? state,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WorkspacesCompanion(
      libraryPath: libraryPath ?? this.libraryPath,
      state: state ?? this.state,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (libraryPath.present) {
      map['library_path'] = Variable<String>(libraryPath.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspacesCompanion(')
          ..write('libraryPath: $libraryPath, ')
          ..write('state: $state, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LibraryDeviceSettingsTable extends LibraryDeviceSettings
    with TableInfo<$LibraryDeviceSettingsTable, LibraryDeviceSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryDeviceSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _libraryPathMeta = const VerificationMeta(
    'libraryPath',
  );
  @override
  late final GeneratedColumn<String> libraryPath = GeneratedColumn<String>(
    'library_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _settingsMeta = const VerificationMeta(
    'settings',
  );
  @override
  late final GeneratedColumn<String> settings = GeneratedColumn<String>(
    'settings',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [libraryPath, settings, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_device_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryDeviceSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('library_path')) {
      context.handle(
        _libraryPathMeta,
        libraryPath.isAcceptableOrUnknown(
          data['library_path']!,
          _libraryPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_libraryPathMeta);
    }
    if (data.containsKey('settings')) {
      context.handle(
        _settingsMeta,
        settings.isAcceptableOrUnknown(data['settings']!, _settingsMeta),
      );
    } else if (isInserting) {
      context.missing(_settingsMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {libraryPath};
  @override
  LibraryDeviceSettingsRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryDeviceSettingsRow(
      libraryPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}library_path'],
      )!,
      settings: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settings'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LibraryDeviceSettingsTable createAlias(String alias) {
    return $LibraryDeviceSettingsTable(attachedDatabase, alias);
  }
}

class LibraryDeviceSettingsRow extends DataClass
    implements Insertable<LibraryDeviceSettingsRow> {
  /// Absolute, normalized path of the library root; the primary key.
  final String libraryPath;

  /// The device keys, as a JSON object in the `settings.json` format.
  final String settings;

  /// When it was last written.
  final DateTime updatedAt;
  const LibraryDeviceSettingsRow({
    required this.libraryPath,
    required this.settings,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['library_path'] = Variable<String>(libraryPath);
    map['settings'] = Variable<String>(settings);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LibraryDeviceSettingsCompanion toCompanion(bool nullToAbsent) {
    return LibraryDeviceSettingsCompanion(
      libraryPath: Value(libraryPath),
      settings: Value(settings),
      updatedAt: Value(updatedAt),
    );
  }

  factory LibraryDeviceSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryDeviceSettingsRow(
      libraryPath: serializer.fromJson<String>(json['libraryPath']),
      settings: serializer.fromJson<String>(json['settings']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'libraryPath': serializer.toJson<String>(libraryPath),
      'settings': serializer.toJson<String>(settings),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LibraryDeviceSettingsRow copyWith({
    String? libraryPath,
    String? settings,
    DateTime? updatedAt,
  }) => LibraryDeviceSettingsRow(
    libraryPath: libraryPath ?? this.libraryPath,
    settings: settings ?? this.settings,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LibraryDeviceSettingsRow copyWithCompanion(
    LibraryDeviceSettingsCompanion data,
  ) {
    return LibraryDeviceSettingsRow(
      libraryPath: data.libraryPath.present
          ? data.libraryPath.value
          : this.libraryPath,
      settings: data.settings.present ? data.settings.value : this.settings,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryDeviceSettingsRow(')
          ..write('libraryPath: $libraryPath, ')
          ..write('settings: $settings, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(libraryPath, settings, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryDeviceSettingsRow &&
          other.libraryPath == this.libraryPath &&
          other.settings == this.settings &&
          other.updatedAt == this.updatedAt);
}

class LibraryDeviceSettingsCompanion
    extends UpdateCompanion<LibraryDeviceSettingsRow> {
  final Value<String> libraryPath;
  final Value<String> settings;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LibraryDeviceSettingsCompanion({
    this.libraryPath = const Value.absent(),
    this.settings = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibraryDeviceSettingsCompanion.insert({
    required String libraryPath,
    required String settings,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : libraryPath = Value(libraryPath),
       settings = Value(settings),
       updatedAt = Value(updatedAt);
  static Insertable<LibraryDeviceSettingsRow> custom({
    Expression<String>? libraryPath,
    Expression<String>? settings,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (libraryPath != null) 'library_path': libraryPath,
      if (settings != null) 'settings': settings,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibraryDeviceSettingsCompanion copyWith({
    Value<String>? libraryPath,
    Value<String>? settings,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LibraryDeviceSettingsCompanion(
      libraryPath: libraryPath ?? this.libraryPath,
      settings: settings ?? this.settings,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (libraryPath.present) {
      map['library_path'] = Variable<String>(libraryPath.value);
    }
    if (settings.present) {
      map['settings'] = Variable<String>(settings.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryDeviceSettingsCompanion(')
          ..write('libraryPath: $libraryPath, ')
          ..write('settings: $settings, ')
          ..write('updatedAt: $updatedAt, ')
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
  late final $WidgetConfigsTable widgetConfigs = $WidgetConfigsTable(this);
  late final $SyncDestinationsTable syncDestinations = $SyncDestinationsTable(
    this,
  );
  late final $SyncItemsTable syncItems = $SyncItemsTable(this);
  late final $SyncOpsTable syncOps = $SyncOpsTable(this);
  late final $WorkspacesTable workspaces = $WorkspacesTable(this);
  late final $LibraryDeviceSettingsTable libraryDeviceSettings =
      $LibraryDeviceSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    knownLibraries,
    widgetConfigs,
    syncDestinations,
    syncItems,
    syncOps,
    workspaces,
    libraryDeviceSettings,
  ];
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String?> libraryPath,
      Value<bool> debugLogsEnabled,
      Value<bool> autoUpdateEnabled,
      Value<bool> closeToTray,
      Value<int?> lastUpdateCheckMs,
      Value<String> previewMode,
      Value<double> splitRatio,
      Value<String> language,
      Value<String> themeBrightness,
      Value<String> themePalette,
      Value<String> legacyLibrarySettings,
      Value<String?> changelogSeenVersion,
      Value<String?> keyMap,
      Value<String?> pinnedCommands,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String?> libraryPath,
      Value<bool> debugLogsEnabled,
      Value<bool> autoUpdateEnabled,
      Value<bool> closeToTray,
      Value<int?> lastUpdateCheckMs,
      Value<String> previewMode,
      Value<double> splitRatio,
      Value<String> language,
      Value<String> themeBrightness,
      Value<String> themePalette,
      Value<String> legacyLibrarySettings,
      Value<String?> changelogSeenVersion,
      Value<String?> keyMap,
      Value<String?> pinnedCommands,
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

  ColumnFilters<bool> get autoUpdateEnabled => $composableBuilder(
    column: $table.autoUpdateEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get closeToTray => $composableBuilder(
    column: $table.closeToTray,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUpdateCheckMs => $composableBuilder(
    column: $table.lastUpdateCheckMs,
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

  ColumnFilters<String> get changelogSeenVersion => $composableBuilder(
    column: $table.changelogSeenVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keyMap => $composableBuilder(
    column: $table.keyMap,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinnedCommands => $composableBuilder(
    column: $table.pinnedCommands,
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

  ColumnOrderings<bool> get autoUpdateEnabled => $composableBuilder(
    column: $table.autoUpdateEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get closeToTray => $composableBuilder(
    column: $table.closeToTray,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUpdateCheckMs => $composableBuilder(
    column: $table.lastUpdateCheckMs,
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

  ColumnOrderings<String> get changelogSeenVersion => $composableBuilder(
    column: $table.changelogSeenVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keyMap => $composableBuilder(
    column: $table.keyMap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinnedCommands => $composableBuilder(
    column: $table.pinnedCommands,
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

  GeneratedColumn<bool> get autoUpdateEnabled => $composableBuilder(
    column: $table.autoUpdateEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get closeToTray => $composableBuilder(
    column: $table.closeToTray,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastUpdateCheckMs => $composableBuilder(
    column: $table.lastUpdateCheckMs,
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

  GeneratedColumn<String> get changelogSeenVersion => $composableBuilder(
    column: $table.changelogSeenVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keyMap =>
      $composableBuilder(column: $table.keyMap, builder: (column) => column);

  GeneratedColumn<String> get pinnedCommands => $composableBuilder(
    column: $table.pinnedCommands,
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
                Value<bool> autoUpdateEnabled = const Value.absent(),
                Value<bool> closeToTray = const Value.absent(),
                Value<int?> lastUpdateCheckMs = const Value.absent(),
                Value<String> previewMode = const Value.absent(),
                Value<double> splitRatio = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> themeBrightness = const Value.absent(),
                Value<String> themePalette = const Value.absent(),
                Value<String> legacyLibrarySettings = const Value.absent(),
                Value<String?> changelogSeenVersion = const Value.absent(),
                Value<String?> keyMap = const Value.absent(),
                Value<String?> pinnedCommands = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                libraryPath: libraryPath,
                debugLogsEnabled: debugLogsEnabled,
                autoUpdateEnabled: autoUpdateEnabled,
                closeToTray: closeToTray,
                lastUpdateCheckMs: lastUpdateCheckMs,
                previewMode: previewMode,
                splitRatio: splitRatio,
                language: language,
                themeBrightness: themeBrightness,
                themePalette: themePalette,
                legacyLibrarySettings: legacyLibrarySettings,
                changelogSeenVersion: changelogSeenVersion,
                keyMap: keyMap,
                pinnedCommands: pinnedCommands,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> libraryPath = const Value.absent(),
                Value<bool> debugLogsEnabled = const Value.absent(),
                Value<bool> autoUpdateEnabled = const Value.absent(),
                Value<bool> closeToTray = const Value.absent(),
                Value<int?> lastUpdateCheckMs = const Value.absent(),
                Value<String> previewMode = const Value.absent(),
                Value<double> splitRatio = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> themeBrightness = const Value.absent(),
                Value<String> themePalette = const Value.absent(),
                Value<String> legacyLibrarySettings = const Value.absent(),
                Value<String?> changelogSeenVersion = const Value.absent(),
                Value<String?> keyMap = const Value.absent(),
                Value<String?> pinnedCommands = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                libraryPath: libraryPath,
                debugLogsEnabled: debugLogsEnabled,
                autoUpdateEnabled: autoUpdateEnabled,
                closeToTray: closeToTray,
                lastUpdateCheckMs: lastUpdateCheckMs,
                previewMode: previewMode,
                splitRatio: splitRatio,
                language: language,
                themeBrightness: themeBrightness,
                themePalette: themePalette,
                legacyLibrarySettings: legacyLibrarySettings,
                changelogSeenVersion: changelogSeenVersion,
                keyMap: keyMap,
                pinnedCommands: pinnedCommands,
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
typedef $$WidgetConfigsTableCreateCompanionBuilder =
    WidgetConfigsCompanion Function({
      Value<int> androidWidgetId,
      required String provider,
      required String libraryPath,
      Value<String?> notePath,
      required DateTime updatedAt,
    });
typedef $$WidgetConfigsTableUpdateCompanionBuilder =
    WidgetConfigsCompanion Function({
      Value<int> androidWidgetId,
      Value<String> provider,
      Value<String> libraryPath,
      Value<String?> notePath,
      Value<DateTime> updatedAt,
    });

class $$WidgetConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $WidgetConfigsTable> {
  $$WidgetConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get androidWidgetId => $composableBuilder(
    column: $table.androidWidgetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notePath => $composableBuilder(
    column: $table.notePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WidgetConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $WidgetConfigsTable> {
  $$WidgetConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get androidWidgetId => $composableBuilder(
    column: $table.androidWidgetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notePath => $composableBuilder(
    column: $table.notePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WidgetConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WidgetConfigsTable> {
  $$WidgetConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get androidWidgetId => $composableBuilder(
    column: $table.androidWidgetId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notePath =>
      $composableBuilder(column: $table.notePath, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WidgetConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WidgetConfigsTable,
          WidgetConfig,
          $$WidgetConfigsTableFilterComposer,
          $$WidgetConfigsTableOrderingComposer,
          $$WidgetConfigsTableAnnotationComposer,
          $$WidgetConfigsTableCreateCompanionBuilder,
          $$WidgetConfigsTableUpdateCompanionBuilder,
          (
            WidgetConfig,
            BaseReferences<_$AppDatabase, $WidgetConfigsTable, WidgetConfig>,
          ),
          WidgetConfig,
          PrefetchHooks Function()
        > {
  $$WidgetConfigsTableTableManager(_$AppDatabase db, $WidgetConfigsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WidgetConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WidgetConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WidgetConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> androidWidgetId = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String> libraryPath = const Value.absent(),
                Value<String?> notePath = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => WidgetConfigsCompanion(
                androidWidgetId: androidWidgetId,
                provider: provider,
                libraryPath: libraryPath,
                notePath: notePath,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> androidWidgetId = const Value.absent(),
                required String provider,
                required String libraryPath,
                Value<String?> notePath = const Value.absent(),
                required DateTime updatedAt,
              }) => WidgetConfigsCompanion.insert(
                androidWidgetId: androidWidgetId,
                provider: provider,
                libraryPath: libraryPath,
                notePath: notePath,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WidgetConfigsTable, WidgetConfig>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $WidgetConfigsTable,
                    WidgetConfig
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WidgetConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WidgetConfigsTable,
      WidgetConfig,
      $$WidgetConfigsTableFilterComposer,
      $$WidgetConfigsTableOrderingComposer,
      $$WidgetConfigsTableAnnotationComposer,
      $$WidgetConfigsTableCreateCompanionBuilder,
      $$WidgetConfigsTableUpdateCompanionBuilder,
      (
        WidgetConfig,
        BaseReferences<_$AppDatabase, $WidgetConfigsTable, WidgetConfig>,
      ),
      WidgetConfig,
      PrefetchHooks Function()
    >;
typedef $$SyncDestinationsTableCreateCompanionBuilder =
    SyncDestinationsCompanion Function({
      required String libraryPath,
      required String url,
      Value<String> username,
      Value<bool> enabled,
      Value<bool> autoSync,
      Value<int> intervalSeconds,
      Value<bool> wifiOnly,
      Value<String> capabilities,
      Value<int?> lastSyncAtMs,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$SyncDestinationsTableUpdateCompanionBuilder =
    SyncDestinationsCompanion Function({
      Value<String> libraryPath,
      Value<String> url,
      Value<String> username,
      Value<bool> enabled,
      Value<bool> autoSync,
      Value<int> intervalSeconds,
      Value<bool> wifiOnly,
      Value<String> capabilities,
      Value<int?> lastSyncAtMs,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$SyncDestinationsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncDestinationsTable> {
  $$SyncDestinationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoSync => $composableBuilder(
    column: $table.autoSync,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalSeconds => $composableBuilder(
    column: $table.intervalSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wifiOnly => $composableBuilder(
    column: $table.wifiOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get capabilities => $composableBuilder(
    column: $table.capabilities,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncAtMs => $composableBuilder(
    column: $table.lastSyncAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncDestinationsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncDestinationsTable> {
  $$SyncDestinationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoSync => $composableBuilder(
    column: $table.autoSync,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalSeconds => $composableBuilder(
    column: $table.intervalSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wifiOnly => $composableBuilder(
    column: $table.wifiOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get capabilities => $composableBuilder(
    column: $table.capabilities,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncAtMs => $composableBuilder(
    column: $table.lastSyncAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncDestinationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncDestinationsTable> {
  $$SyncDestinationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<bool> get autoSync =>
      $composableBuilder(column: $table.autoSync, builder: (column) => column);

  GeneratedColumn<int> get intervalSeconds => $composableBuilder(
    column: $table.intervalSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wifiOnly =>
      $composableBuilder(column: $table.wifiOnly, builder: (column) => column);

  GeneratedColumn<String> get capabilities => $composableBuilder(
    column: $table.capabilities,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSyncAtMs => $composableBuilder(
    column: $table.lastSyncAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncDestinationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncDestinationsTable,
          SyncDestination,
          $$SyncDestinationsTableFilterComposer,
          $$SyncDestinationsTableOrderingComposer,
          $$SyncDestinationsTableAnnotationComposer,
          $$SyncDestinationsTableCreateCompanionBuilder,
          $$SyncDestinationsTableUpdateCompanionBuilder,
          (
            SyncDestination,
            BaseReferences<
              _$AppDatabase,
              $SyncDestinationsTable,
              SyncDestination
            >,
          ),
          SyncDestination,
          PrefetchHooks Function()
        > {
  $$SyncDestinationsTableTableManager(
    _$AppDatabase db,
    $SyncDestinationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncDestinationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncDestinationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncDestinationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> libraryPath = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> autoSync = const Value.absent(),
                Value<int> intervalSeconds = const Value.absent(),
                Value<bool> wifiOnly = const Value.absent(),
                Value<String> capabilities = const Value.absent(),
                Value<int?> lastSyncAtMs = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncDestinationsCompanion(
                libraryPath: libraryPath,
                url: url,
                username: username,
                enabled: enabled,
                autoSync: autoSync,
                intervalSeconds: intervalSeconds,
                wifiOnly: wifiOnly,
                capabilities: capabilities,
                lastSyncAtMs: lastSyncAtMs,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String libraryPath,
                required String url,
                Value<String> username = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> autoSync = const Value.absent(),
                Value<int> intervalSeconds = const Value.absent(),
                Value<bool> wifiOnly = const Value.absent(),
                Value<String> capabilities = const Value.absent(),
                Value<int?> lastSyncAtMs = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncDestinationsCompanion.insert(
                libraryPath: libraryPath,
                url: url,
                username: username,
                enabled: enabled,
                autoSync: autoSync,
                intervalSeconds: intervalSeconds,
                wifiOnly: wifiOnly,
                capabilities: capabilities,
                lastSyncAtMs: lastSyncAtMs,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncDestinationsTable, SyncDestination>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncDestinationsTable,
                    SyncDestination
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncDestinationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncDestinationsTable,
      SyncDestination,
      $$SyncDestinationsTableFilterComposer,
      $$SyncDestinationsTableOrderingComposer,
      $$SyncDestinationsTableAnnotationComposer,
      $$SyncDestinationsTableCreateCompanionBuilder,
      $$SyncDestinationsTableUpdateCompanionBuilder,
      (
        SyncDestination,
        BaseReferences<_$AppDatabase, $SyncDestinationsTable, SyncDestination>,
      ),
      SyncDestination,
      PrefetchHooks Function()
    >;
typedef $$SyncItemsTableCreateCompanionBuilder = SyncItemsCompanion Function({
  required String libraryPath,
  required String path,
  required String localSha256,
  required int localSize,
  required int localMtimeMs,
  Value<String?> remoteEtag,
  required int remoteSize,
  required int remoteMtimeMs,
  Value<bool> remoteUnverified,
  Value<String?> remoteFileId,
  Value<int?> baseVersion,
  Value<String?> baseText,
  required int syncedAtMs,
  Value<int> rowid,
});
typedef $$SyncItemsTableUpdateCompanionBuilder = SyncItemsCompanion Function({
  Value<String> libraryPath,
  Value<String> path,
  Value<String> localSha256,
  Value<int> localSize,
  Value<int> localMtimeMs,
  Value<String?> remoteEtag,
  Value<int> remoteSize,
  Value<int> remoteMtimeMs,
  Value<bool> remoteUnverified,
  Value<String?> remoteFileId,
  Value<int?> baseVersion,
  Value<String?> baseText,
  Value<int> syncedAtMs,
  Value<int> rowid,
});

class $$SyncItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncItemsTable> {
  $$SyncItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localSha256 => $composableBuilder(
    column: $table.localSha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localSize => $composableBuilder(
    column: $table.localSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localMtimeMs => $composableBuilder(
    column: $table.localMtimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteEtag => $composableBuilder(
    column: $table.remoteEtag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteSize => $composableBuilder(
    column: $table.remoteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteMtimeMs => $composableBuilder(
    column: $table.remoteMtimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remoteUnverified => $composableBuilder(
    column: $table.remoteUnverified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteFileId => $composableBuilder(
    column: $table.remoteFileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseText => $composableBuilder(
    column: $table.baseText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedAtMs => $composableBuilder(
    column: $table.syncedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncItemsTable> {
  $$SyncItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localSha256 => $composableBuilder(
    column: $table.localSha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localSize => $composableBuilder(
    column: $table.localSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localMtimeMs => $composableBuilder(
    column: $table.localMtimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteEtag => $composableBuilder(
    column: $table.remoteEtag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteSize => $composableBuilder(
    column: $table.remoteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteMtimeMs => $composableBuilder(
    column: $table.remoteMtimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remoteUnverified => $composableBuilder(
    column: $table.remoteUnverified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteFileId => $composableBuilder(
    column: $table.remoteFileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseText => $composableBuilder(
    column: $table.baseText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedAtMs => $composableBuilder(
    column: $table.syncedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncItemsTable> {
  $$SyncItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get localSha256 => $composableBuilder(
    column: $table.localSha256,
    builder: (column) => column,
  );

  GeneratedColumn<int> get localSize =>
      $composableBuilder(column: $table.localSize, builder: (column) => column);

  GeneratedColumn<int> get localMtimeMs => $composableBuilder(
    column: $table.localMtimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteEtag => $composableBuilder(
    column: $table.remoteEtag,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remoteSize => $composableBuilder(
    column: $table.remoteSize,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remoteMtimeMs => $composableBuilder(
    column: $table.remoteMtimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get remoteUnverified => $composableBuilder(
    column: $table.remoteUnverified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteFileId => $composableBuilder(
    column: $table.remoteFileId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get baseText =>
      $composableBuilder(column: $table.baseText, builder: (column) => column);

  GeneratedColumn<int> get syncedAtMs => $composableBuilder(
    column: $table.syncedAtMs,
    builder: (column) => column,
  );
}

class $$SyncItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncItemsTable,
          SyncItem,
          $$SyncItemsTableFilterComposer,
          $$SyncItemsTableOrderingComposer,
          $$SyncItemsTableAnnotationComposer,
          $$SyncItemsTableCreateCompanionBuilder,
          $$SyncItemsTableUpdateCompanionBuilder,
          (SyncItem, BaseReferences<_$AppDatabase, $SyncItemsTable, SyncItem>),
          SyncItem,
          PrefetchHooks Function()
        > {
  $$SyncItemsTableTableManager(_$AppDatabase db, $SyncItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> libraryPath = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> localSha256 = const Value.absent(),
                Value<int> localSize = const Value.absent(),
                Value<int> localMtimeMs = const Value.absent(),
                Value<String?> remoteEtag = const Value.absent(),
                Value<int> remoteSize = const Value.absent(),
                Value<int> remoteMtimeMs = const Value.absent(),
                Value<bool> remoteUnverified = const Value.absent(),
                Value<String?> remoteFileId = const Value.absent(),
                Value<int?> baseVersion = const Value.absent(),
                Value<String?> baseText = const Value.absent(),
                Value<int> syncedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncItemsCompanion(
                libraryPath: libraryPath,
                path: path,
                localSha256: localSha256,
                localSize: localSize,
                localMtimeMs: localMtimeMs,
                remoteEtag: remoteEtag,
                remoteSize: remoteSize,
                remoteMtimeMs: remoteMtimeMs,
                remoteUnverified: remoteUnverified,
                remoteFileId: remoteFileId,
                baseVersion: baseVersion,
                baseText: baseText,
                syncedAtMs: syncedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String libraryPath,
                required String path,
                required String localSha256,
                required int localSize,
                required int localMtimeMs,
                Value<String?> remoteEtag = const Value.absent(),
                required int remoteSize,
                required int remoteMtimeMs,
                Value<bool> remoteUnverified = const Value.absent(),
                Value<String?> remoteFileId = const Value.absent(),
                Value<int?> baseVersion = const Value.absent(),
                Value<String?> baseText = const Value.absent(),
                required int syncedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => SyncItemsCompanion.insert(
                libraryPath: libraryPath,
                path: path,
                localSha256: localSha256,
                localSize: localSize,
                localMtimeMs: localMtimeMs,
                remoteEtag: remoteEtag,
                remoteSize: remoteSize,
                remoteMtimeMs: remoteMtimeMs,
                remoteUnverified: remoteUnverified,
                remoteFileId: remoteFileId,
                baseVersion: baseVersion,
                baseText: baseText,
                syncedAtMs: syncedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncItemsTable, SyncItem>(table),
                  BaseReferences<_$AppDatabase, $SyncItemsTable, SyncItem>(
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

typedef $$SyncItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncItemsTable,
      SyncItem,
      $$SyncItemsTableFilterComposer,
      $$SyncItemsTableOrderingComposer,
      $$SyncItemsTableAnnotationComposer,
      $$SyncItemsTableCreateCompanionBuilder,
      $$SyncItemsTableUpdateCompanionBuilder,
      (SyncItem, BaseReferences<_$AppDatabase, $SyncItemsTable, SyncItem>),
      SyncItem,
      PrefetchHooks Function()
    >;
typedef $$SyncOpsTableCreateCompanionBuilder = SyncOpsCompanion Function({
  Value<int> id,
  required String libraryPath,
  required String path,
  required String kind,
  Value<String?> fromPath,
  Value<int> attempts,
  Value<int> nextAttemptAtMs,
  Value<String?> lastError,
  required int createdAtMs,
});
typedef $$SyncOpsTableUpdateCompanionBuilder = SyncOpsCompanion Function({
  Value<int> id,
  Value<String> libraryPath,
  Value<String> path,
  Value<String> kind,
  Value<String?> fromPath,
  Value<int> attempts,
  Value<int> nextAttemptAtMs,
  Value<String?> lastError,
  Value<int> createdAtMs,
});

class $$SyncOpsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOpsTable> {
  $$SyncOpsTableFilterComposer({
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

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromPath => $composableBuilder(
    column: $table.fromPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAtMs => $composableBuilder(
    column: $table.nextAttemptAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOpsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOpsTable> {
  $$SyncOpsTableOrderingComposer({
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

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromPath => $composableBuilder(
    column: $table.fromPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAtMs => $composableBuilder(
    column: $table.nextAttemptAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOpsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOpsTable> {
  $$SyncOpsTableAnnotationComposer({
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

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get fromPath =>
      $composableBuilder(column: $table.fromPath, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get nextAttemptAtMs => $composableBuilder(
    column: $table.nextAttemptAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );
}

class $$SyncOpsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOpsTable,
          SyncOp,
          $$SyncOpsTableFilterComposer,
          $$SyncOpsTableOrderingComposer,
          $$SyncOpsTableAnnotationComposer,
          $$SyncOpsTableCreateCompanionBuilder,
          $$SyncOpsTableUpdateCompanionBuilder,
          (SyncOp, BaseReferences<_$AppDatabase, $SyncOpsTable, SyncOp>),
          SyncOp,
          PrefetchHooks Function()
        > {
  $$SyncOpsTableTableManager(_$AppDatabase db, $SyncOpsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOpsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOpsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOpsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> libraryPath = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> fromPath = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> nextAttemptAtMs = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
              }) => SyncOpsCompanion(
                id: id,
                libraryPath: libraryPath,
                path: path,
                kind: kind,
                fromPath: fromPath,
                attempts: attempts,
                nextAttemptAtMs: nextAttemptAtMs,
                lastError: lastError,
                createdAtMs: createdAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String libraryPath,
                required String path,
                required String kind,
                Value<String?> fromPath = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> nextAttemptAtMs = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required int createdAtMs,
              }) => SyncOpsCompanion.insert(
                id: id,
                libraryPath: libraryPath,
                path: path,
                kind: kind,
                fromPath: fromPath,
                attempts: attempts,
                nextAttemptAtMs: nextAttemptAtMs,
                lastError: lastError,
                createdAtMs: createdAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncOpsTable, SyncOp>(table),
                  BaseReferences<_$AppDatabase, $SyncOpsTable, SyncOp>(
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

typedef $$SyncOpsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOpsTable,
      SyncOp,
      $$SyncOpsTableFilterComposer,
      $$SyncOpsTableOrderingComposer,
      $$SyncOpsTableAnnotationComposer,
      $$SyncOpsTableCreateCompanionBuilder,
      $$SyncOpsTableUpdateCompanionBuilder,
      (SyncOp, BaseReferences<_$AppDatabase, $SyncOpsTable, SyncOp>),
      SyncOp,
      PrefetchHooks Function()
    >;
typedef $$WorkspacesTableCreateCompanionBuilder = WorkspacesCompanion Function({
  required String libraryPath,
  required String state,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$WorkspacesTableUpdateCompanionBuilder = WorkspacesCompanion Function({
  Value<String> libraryPath,
  Value<String> state,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$WorkspacesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkspacesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkspacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WorkspacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkspacesTable,
          WorkspaceRow,
          $$WorkspacesTableFilterComposer,
          $$WorkspacesTableOrderingComposer,
          $$WorkspacesTableAnnotationComposer,
          $$WorkspacesTableCreateCompanionBuilder,
          $$WorkspacesTableUpdateCompanionBuilder,
          (
            WorkspaceRow,
            BaseReferences<_$AppDatabase, $WorkspacesTable, WorkspaceRow>,
          ),
          WorkspaceRow,
          PrefetchHooks Function()
        > {
  $$WorkspacesTableTableManager(_$AppDatabase db, $WorkspacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkspacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkspacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkspacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> libraryPath = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion(
                libraryPath: libraryPath,
                state: state,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String libraryPath,
                required String state,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion.insert(
                libraryPath: libraryPath,
                state: state,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkspacesTable, WorkspaceRow>(table),
                  BaseReferences<_$AppDatabase, $WorkspacesTable, WorkspaceRow>(
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

typedef $$WorkspacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkspacesTable,
      WorkspaceRow,
      $$WorkspacesTableFilterComposer,
      $$WorkspacesTableOrderingComposer,
      $$WorkspacesTableAnnotationComposer,
      $$WorkspacesTableCreateCompanionBuilder,
      $$WorkspacesTableUpdateCompanionBuilder,
      (
        WorkspaceRow,
        BaseReferences<_$AppDatabase, $WorkspacesTable, WorkspaceRow>,
      ),
      WorkspaceRow,
      PrefetchHooks Function()
    >;
typedef $$LibraryDeviceSettingsTableCreateCompanionBuilder =
    LibraryDeviceSettingsCompanion Function({
      required String libraryPath,
      required String settings,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LibraryDeviceSettingsTableUpdateCompanionBuilder =
    LibraryDeviceSettingsCompanion Function({
      Value<String> libraryPath,
      Value<String> settings,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LibraryDeviceSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryDeviceSettingsTable> {
  $$LibraryDeviceSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settings => $composableBuilder(
    column: $table.settings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LibraryDeviceSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryDeviceSettingsTable> {
  $$LibraryDeviceSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settings => $composableBuilder(
    column: $table.settings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibraryDeviceSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryDeviceSettingsTable> {
  $$LibraryDeviceSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get libraryPath => $composableBuilder(
    column: $table.libraryPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settings =>
      $composableBuilder(column: $table.settings, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LibraryDeviceSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryDeviceSettingsTable,
          LibraryDeviceSettingsRow,
          $$LibraryDeviceSettingsTableFilterComposer,
          $$LibraryDeviceSettingsTableOrderingComposer,
          $$LibraryDeviceSettingsTableAnnotationComposer,
          $$LibraryDeviceSettingsTableCreateCompanionBuilder,
          $$LibraryDeviceSettingsTableUpdateCompanionBuilder,
          (
            LibraryDeviceSettingsRow,
            BaseReferences<
              _$AppDatabase,
              $LibraryDeviceSettingsTable,
              LibraryDeviceSettingsRow
            >,
          ),
          LibraryDeviceSettingsRow,
          PrefetchHooks Function()
        > {
  $$LibraryDeviceSettingsTableTableManager(
    _$AppDatabase db,
    $LibraryDeviceSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryDeviceSettingsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LibraryDeviceSettingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LibraryDeviceSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> libraryPath = const Value.absent(),
                Value<String> settings = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibraryDeviceSettingsCompanion(
                libraryPath: libraryPath,
                settings: settings,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String libraryPath,
                required String settings,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LibraryDeviceSettingsCompanion.insert(
                libraryPath: libraryPath,
                settings: settings,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LibraryDeviceSettingsTable,
                    LibraryDeviceSettingsRow
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LibraryDeviceSettingsTable,
                    LibraryDeviceSettingsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LibraryDeviceSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryDeviceSettingsTable,
      LibraryDeviceSettingsRow,
      $$LibraryDeviceSettingsTableFilterComposer,
      $$LibraryDeviceSettingsTableOrderingComposer,
      $$LibraryDeviceSettingsTableAnnotationComposer,
      $$LibraryDeviceSettingsTableCreateCompanionBuilder,
      $$LibraryDeviceSettingsTableUpdateCompanionBuilder,
      (
        LibraryDeviceSettingsRow,
        BaseReferences<
          _$AppDatabase,
          $LibraryDeviceSettingsTable,
          LibraryDeviceSettingsRow
        >,
      ),
      LibraryDeviceSettingsRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$KnownLibrariesTableTableManager get knownLibraries =>
      $$KnownLibrariesTableTableManager(_db, _db.knownLibraries);
  $$WidgetConfigsTableTableManager get widgetConfigs =>
      $$WidgetConfigsTableTableManager(_db, _db.widgetConfigs);
  $$SyncDestinationsTableTableManager get syncDestinations =>
      $$SyncDestinationsTableTableManager(_db, _db.syncDestinations);
  $$SyncItemsTableTableManager get syncItems =>
      $$SyncItemsTableTableManager(_db, _db.syncItems);
  $$SyncOpsTableTableManager get syncOps =>
      $$SyncOpsTableTableManager(_db, _db.syncOps);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db, _db.workspaces);
  $$LibraryDeviceSettingsTableTableManager get libraryDeviceSettings =>
      $$LibraryDeviceSettingsTableTableManager(_db, _db.libraryDeviceSettings);
}
