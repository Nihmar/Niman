/// One button of a Home actions tile (#535): a function the app already
/// has, with its parameters set in advance — a new note of a type, from a
/// template, in a folder, with some fields already filled.
///
/// Plain data read from and written to `.niman/home.json`; running it is
/// the UI's business (`ui/home/action_runner.dart`).
library;

import 'package:meta/meta.dart';
import 'package:niman/src/core/files.dart';

/// What an action does.
enum HomeActionKind {
  /// A new note: from a template or empty, in a folder, fields preset.
  newNote,

  /// A task added to the todo list, its project and context preset.
  addTask,

  /// A note opened.
  openNote,

  /// Today's journal entry opened (or made).
  journal,

  /// A web page captured into a folder (#531).
  capture,
}

/// How an action fills one value: a fixed text, or a question asked when
/// the button is pressed.
@immutable
final class FieldPreset {
  /// The value [value], template commands (`{{date}}`) allowed.
  const new value(String value) : fixed = value;

  /// Asked for on every use.
  const new ask() : fixed = null;

  /// Reads `{"fixed": "…"}` or `{"ask": true}`; anything else is null.
  static FieldPreset? fromJson(Object? json) {
    if (json is! Map) return null;
    final fixed = json['fixed'];
    if (fixed is String) return FieldPreset.value(fixed);
    if (json['ask'] == true) return const FieldPreset.ask();
    return null;
  }

  /// The fixed value; null when the value is asked for.
  final String? fixed;

  /// Whether the value is asked for.
  bool get asks => fixed == null;

  /// The JSON [fromJson] reads back.
  Map<String, Object?> toJson() =>
      asks ? const {'ask': true} : {'fixed': fixed};

  @override
  bool operator ==(Object other) =>
      other is FieldPreset && other.fixed == fixed;

  @override
  int get hashCode => fixed.hashCode;
}

/// One configured action.
@immutable
final class HomeAction {
  /// Creates an action; [kind] null is one a later build wrote, kept
  /// in [extra] and never run.
  const new({
    required this.id,
    required this.label,
    required this.kind,
    this.icon = '',
    this.template,
    this.folder,
    this.name = const FieldPreset.ask(),
    this.fields = const {},
    this.open = true,
    this.project,
    this.context,
    this.path,
    this.extra = const {},
  });

  /// Reads one entry of a tile's `actions`; null when it is not an object
  /// with an id.
  static HomeAction? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = {for (final e in json.entries) e.key.toString(): e.value};
    final id = map['id'];
    if (id is! String || id.isEmpty) return null;
    final kindName = map['do'];
    final kind = HomeActionKind.values
        .where((k) => k.name == kindName)
        .firstOrNull;
    final fieldsJson = map['fields'];
    return HomeAction(
      id: id,
      label: _string(map['label']) ?? '',
      kind: kind,
      icon: _string(map['icon']) ?? '',
      template: _string(map['template']),
      folder: _string(map['folder']),
      name: FieldPreset.fromJson(map['name']) ?? const FieldPreset.ask(),
      fields: {
        if (fieldsJson is Map)
          for (final e in fieldsJson.entries)
            e.key.toString(): ?FieldPreset.fromJson(e.value),
      },
      open: map['open'] != false,
      project: _string(map['project']),
      context: _string(map['context']),
      path: _string(map['path']),
      extra: {
        for (final e in map.entries)
          if (!_known.contains(e.key) || (e.key == 'do' && kind == null))
            e.key: e.value,
      },
    );
  }

  static const Set<String> _known = {
    'id',
    'label',
    'do',
    'icon',
    'template',
    'folder',
    'name',
    'fields',
    'open',
    'project',
    'context',
    'path',
  };

  /// Unique within its tile.
  final String id;

  /// The button's text.
  final String label;

  /// What it does; null for a kind this build does not know.
  final HomeActionKind? kind;

  /// The icon's name (`ui/home/home_icons.dart` maps it); empty for the
  /// kind's own.
  final String icon;

  /// [HomeActionKind.newNote]: the template, library-relative; null for
  /// an empty note.
  final String? template;

  /// [HomeActionKind.newNote], [HomeActionKind.capture]: the folder,
  /// library-relative; null or empty for the default one.
  final String? folder;

  /// [HomeActionKind.newNote]: the note's name. A template that names
  /// its own notes (`niman: filename:`) leaves it unused.
  final FieldPreset name;

  /// [HomeActionKind.newNote]: frontmatter keys to fill, and template
  /// questions (`{{ask:Label}}`) answered by the same label.
  final Map<String, FieldPreset> fields;

  /// [HomeActionKind.newNote]: whether the note opens once made.
  final bool open;

  /// [HomeActionKind.addTask]: the `+project` the task gets.
  final String? project;

  /// [HomeActionKind.addTask]: the `@context` the task gets.
  final String? context;

  /// [HomeActionKind.openNote]: the note, library-relative.
  final String? path;

  /// Keys this build does not know, written back untouched.
  final Map<String, Object?> extra;

  /// Whether pressing it asks something first: the `…` its name carries
  /// in the palette. A template's own questions are not known until it is
  /// read, so a template counts as one.
  bool get asks => switch (kind) {
    HomeActionKind.newNote =>
      template != null || name.asks || fields.values.any((f) => f.asks),
    HomeActionKind.addTask || HomeActionKind.capture => true,
    _ => false,
  };

  /// The library paths it depends on: what has to exist for it to run.
  /// A folder is not among them — a missing one is made.
  List<String> get requiredPaths => [
    if (kind == HomeActionKind.newNote && template != null) template!,
    if (kind == HomeActionKind.openNote && path != null) path!,
  ];

  /// This action with its paths rewritten after the item at [from]
  /// moved to [to]; the same instance when none pointed there.
  HomeAction renamed(String from, String to, {required bool isDir}) {
    final t = pathAfterMove(template, from, to, isDir: isDir);
    final f = pathAfterMove(folder, from, to, isDir: isDir);
    final p = pathAfterMove(path, from, to, isDir: isDir);
    if (t == template && f == folder && p == path) return this;
    return copyWith(template: t, folder: f, path: p);
  }

  /// A copy with the given values replaced.
  HomeAction copyWith({
    String? label,
    HomeActionKind? kind,
    String? icon,
    String? template,
    bool clearTemplate = false,
    String? folder,
    FieldPreset? name,
    Map<String, FieldPreset>? fields,
    bool? open,
    String? project,
    String? context,
    String? path,
  }) => HomeAction(
    id: id,
    label: label ?? this.label,
    kind: kind ?? this.kind,
    icon: icon ?? this.icon,
    template: clearTemplate ? null : template ?? this.template,
    folder: folder ?? this.folder,
    name: name ?? this.name,
    fields: fields ?? this.fields,
    open: open ?? this.open,
    project: project ?? this.project,
    context: context ?? this.context,
    path: path ?? this.path,
    extra: extra,
  );

  /// The JSON [fromJson] reads back: the known keys that hold something,
  /// then [extra].
  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    if (kind case final kind?) 'do': kind.name,
    if (icon.isNotEmpty) 'icon': icon,
    'template': ?template,
    'folder': ?folder,
    if (!name.asks) 'name': name.toJson(),
    if (fields.isNotEmpty)
      'fields': {for (final e in fields.entries) e.key: e.value.toJson()},
    if (!open) 'open': false,
    'project': ?project,
    'context': ?context,
    'path': ?path,
    ...extra,
  };
}

String? _string(Object? value) => value is String ? value : null;
