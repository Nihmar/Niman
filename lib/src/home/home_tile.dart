/// One tile of a library's Home (#535): what it shows, where the desktop
/// grid places it, where the phone's column puts it, and whether it is
/// shown at all.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/home/home_action.dart';

/// What a tile shows. The names are the file's.
enum HomeTileKind {
  /// Buttons that run [HomeAction]s.
  actions,

  /// Today's journal entry.
  journalToday,

  /// The open tasks, due soonest first.
  tasksDue,

  /// The notes modified last.
  recent,

  /// The pinned notes.
  pinned,

  /// The journal's month, its entry days marked.
  journalCalendar,

  /// The tags most used.
  topTags,

  /// A note picked at random.
  randomNote,

  /// A search query and its first results.
  search;

  /// Whether a Home may hold several: each actions tile is its own group
  /// of buttons, each search tile its own query. The others show the
  /// same thing however often they appear, so there is one of each.
  bool get repeats => this == actions || this == search;

  /// The cells a new tile of this kind takes on the grid.
  ({int w, int h}) get defaultSize => switch (this) {
    journalToday => (w: 2, h: 2),
    tasksDue || recent || journalCalendar => (w: 1, h: 2),
    actions || search => (w: 2, h: 1),
    pinned || topTags || randomNote => (w: 1, h: 1),
  };
}

/// A tile's rectangle on the desktop grid, in cells.
typedef HomeCell = ({int x, int y, int w, int h});

/// One tile.
@immutable
final class HomeTile {
  /// Creates a tile; [kind] null is one a later build wrote, kept in
  /// [extra] and never drawn.
  const new({
    required this.id,
    required this.kind,
    required this.cell,
    required this.at,
    this.hidden = false,
    this.title = '',
    this.query = '',
    this.actions = const [],
    this.extra = const {},
  });

  /// Reads the tile [id] holds in the file; null when it is not an object.
  static HomeTile? fromJson(String id, Object? json) {
    if (json is! Map) return null;
    final map = {for (final e in json.entries) e.key.toString(): e.value};
    final kindName = map['kind'];
    final kind = HomeTileKind.values
        .where((k) => k.name == kindName)
        .firstOrNull;
    final phone = map['phone'];
    final at = phone is Map ? phone['at'] : null;
    final actions = map['actions'];
    final title = map['title'];
    final query = map['query'];
    return HomeTile(
      id: id,
      kind: kind,
      cell: _cell(map['grid'], kind),
      at: at is int ? at : unplaced,
      hidden: map['hidden'] == true,
      title: title is String ? title : '',
      query: query is String ? query : '',
      actions: [
        if (actions is List)
          for (final entry in actions) ?HomeAction.fromJson(entry),
      ],
      extra: {
        for (final e in map.entries)
          if (!_known.contains(e.key) || (e.key == 'kind' && kind == null))
            e.key: e.value,
      },
    );
  }

  static const Set<String> _known = {
    'kind',
    'grid',
    'phone',
    'hidden',
    'title',
    'query',
    'actions',
  };

  /// The place a tile takes when it has none: after every other one.
  /// The grid's settling moves it up to the first free row.
  static const int unplaced = 1 << 20;

  /// The grid's columns; also the widest and tallest a tile can be.
  static const int columns = 4;

  /// The tile's key in the file.
  final String id;

  /// What it shows; null for a kind this build does not know.
  final HomeTileKind? kind;

  /// Where the desktop grid places it.
  final HomeCell cell;

  /// Its place in the phone's column.
  final int at;

  /// Hidden on every device; it keeps everything else, so showing it
  /// again brings it back as it was.
  final bool hidden;

  /// A search tile's name; empty for the query itself.
  final String title;

  /// A search tile's query.
  final String query;

  /// An actions tile's buttons, in order.
  final List<HomeAction> actions;

  /// Keys this build does not know, written back untouched.
  final Map<String, Object?> extra;

  /// Whether a Home draws it: a known kind, not hidden.
  bool get shown => kind != null && !hidden;

  /// A copy with the given values replaced.
  HomeTile copyWith({
    HomeCell? cell,
    int? at,
    bool? hidden,
    String? title,
    String? query,
    List<HomeAction>? actions,
  }) => HomeTile(
    id: id,
    kind: kind,
    cell: cell ?? this.cell,
    at: at ?? this.at,
    hidden: hidden ?? this.hidden,
    title: title ?? this.title,
    query: query ?? this.query,
    actions: actions ?? this.actions,
    extra: extra,
  );

  /// The JSON [fromJson] reads back.
  Map<String, Object?> toJson() => {
    if (kind case final kind?) 'kind': kind.name,
    'grid': [cell.x, cell.y, cell.w, cell.h],
    'phone': {'at': at},
    if (hidden) 'hidden': true,
    if (title.isNotEmpty) 'title': title,
    if (query.isNotEmpty) 'query': query,
    if (actions.isNotEmpty) 'actions': [for (final a in actions) a.toJson()],
    ...extra,
  };
}

/// Reads `[x, y, w, h]`, clamped onto the grid; a missing or broken one
/// is the kind's default size, after every other tile.
HomeCell _cell(Object? json, HomeTileKind? kind) {
  final size = kind?.defaultSize ?? (w: 1, h: 1);
  if (json is! List || json.length != 4 || json.any((v) => v is! int)) {
    return (x: 0, y: HomeTile.unplaced, w: size.w, h: size.h);
  }
  final [x as int, y as int, w as int, h as int] = json;
  const max = HomeTile.columns;
  final width = w.clamp(1, max);
  return (
    x: x.clamp(0, max - width),
    y: y < 0 ? 0 : y,
    w: width,
    h: h.clamp(1, max),
  );
}
