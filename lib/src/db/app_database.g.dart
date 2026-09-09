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
