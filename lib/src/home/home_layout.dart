/// A library's Home (#535): its tiles, as `.niman/home.json` keeps them.
///
/// One key per tile, the tile's id: the sync merges the file key by key
/// (`mergeSettingsJson`), so two devices that change different tiles never
/// undo each other, and one tile changed on both keeps the newer side.
///
/// That merge can leave two tiles on the same cells — each moved on
/// another device. `HomeLayout.settled` resolves it when the grid is
/// drawn; nothing is written until the user next edits the Home.
library;

import 'dart:convert';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/home/home_tile.dart';

/// The tiles of one Home.
@immutable
final class HomeLayout {
  /// A layout of [tiles], in file order.
  const new(this.tiles);

  /// Reads the file's object; null when [json] is not one, which a reader
  /// treats as no file at all.
  static HomeLayout? fromJson(Object? json) {
    if (json is! Map) return null;
    return HomeLayout([
      for (final e in json.entries)
        ?HomeTile.fromJson(e.key.toString(), e.value),
    ]);
  }

  /// The Home of a library that never edited its own: written to the file
  /// only once it is.
  static const HomeLayout defaults = HomeLayout([
    HomeTile(
      id: 'actions',
      kind: HomeTileKind.actions,
      cell: (x: 0, y: 0, w: 2, h: 1),
      at: 0,
      actions: [
        HomeAction(id: 'note', label: '', kind: HomeActionKind.newNote),
        HomeAction(id: 'journal', label: '', kind: HomeActionKind.journal),
        HomeAction(id: 'task', label: '', kind: HomeActionKind.addTask),
      ],
    ),
    HomeTile(
      id: 'journalToday',
      kind: HomeTileKind.journalToday,
      cell: (x: 2, y: 0, w: 2, h: 2),
      at: 1,
    ),
    HomeTile(
      id: 'tasksDue',
      kind: HomeTileKind.tasksDue,
      cell: (x: 0, y: 1, w: 1, h: 2),
      at: 2,
    ),
    HomeTile(
      id: 'recent',
      kind: HomeTileKind.recent,
      cell: (x: 1, y: 1, w: 1, h: 2),
      at: 3,
    ),
    HomeTile(
      id: 'pinned',
      kind: HomeTileKind.pinned,
      cell: (x: 2, y: 2, w: 2, h: 1),
      at: 4,
    ),
  ]);

  /// Every tile the file holds, hidden and unknown ones included.
  final List<HomeTile> tiles;

  /// The tiles a Home draws, in the phone's order: by place, then by id
  /// so two tiles a merge gave one place keep a stable order.
  List<HomeTile> get column =>
      tiles.where((t) => t.shown).toList()..sort(_byPlace);

  /// Every tile of a known kind in the phone's order, hidden ones too:
  /// the list the phone's editor shows.
  List<HomeTile> get editable =>
      tiles.where((t) => t.kind != null).toList()..sort(_byPlace);

  static int _byPlace(HomeTile a, HomeTile b) {
    final byAt = a.at.compareTo(b.at);
    return byAt != 0 ? byAt : a.id.compareTo(b.id);
  }

  /// The tile [id], or null.
  HomeTile? operator [](String id) =>
      tiles.where((t) => t.id == id).firstOrNull;

  /// This layout with [tile] in place of the one with its id, or added
  /// after the others.
  HomeLayout put(HomeTile tile) {
    final at = tiles.indexWhere((t) => t.id == tile.id);
    return HomeLayout(at < 0 ? [...tiles, tile] : ([...tiles]..[at] = tile));
  }

  /// This layout without the tile [id].
  HomeLayout remove(String id) => HomeLayout([
    for (final t in tiles)
      if (t.id != id) t,
  ]);

  /// This layout with [kind] added, or shown again when it is a kind of
  /// which a Home holds one and that one is hidden: at the foot of the
  /// grid and of the column.
  HomeLayout add(HomeTileKind kind, {Random? random}) {
    final hidden = kind.repeats
        ? null
        : tiles.where((t) => t.kind == kind).firstOrNull;
    final size = kind.defaultSize;
    final cell = (x: 0, y: bottom, w: size.w, h: size.h);
    final at = tiles.isEmpty ? 0 : tiles.map((t) => t.at).reduce(max) + 1;
    if (hidden != null) {
      if (!hidden.hidden) return this;
      return put(hidden.copyWith(hidden: false, cell: cell, at: at));
    }
    return put(
      HomeTile(
        id: freshId(kind, random: random),
        kind: kind,
        cell: cell,
        at: at,
      ),
    );
  }

  /// The first free row under the shown tiles.
  int get bottom => tiles
      .where((t) => t.shown)
      .fold(0, (lowest, t) => max(lowest, t.cell.y + t.cell.h));

  /// An id no tile here has: the kind's name for one a Home holds once,
  /// with a short random suffix for one it may hold several of.
  String freshId(HomeTileKind kind, {Random? random}) {
    if (!kind.repeats && this[kind.name] == null) return kind.name;
    final rng = random ?? Random();
    const letters = 'abcdefghijklmnopqrstuvwxyz0123456789';
    while (true) {
      final suffix = String.fromCharCodes([
        for (var i = 0; i < 4; i++) letters.codeUnitAt(rng.nextInt(36)),
      ]);
      final id = '${kind.name}-$suffix';
      if (this[id] == null) return id;
    }
  }

  /// This layout with the column reordered to [ids] (the shown tiles, or
  /// every editable one): places renumbered from 0, the others after.
  HomeLayout ordered(List<String> ids) {
    final rest = [
      for (final t in editable)
        if (!ids.contains(t.id)) t.id,
    ];
    final places = {
      for (final (i, id) in [...ids, ...rest].indexed) id: i,
    };
    return HomeLayout([
      for (final t in tiles)
        if (places[t.id] case final at?) t.copyWith(at: at) else t,
    ]);
  }

  /// The grid with no two shown tiles on the same cell and none floating
  /// over a gap: in reading order — [first] before the rest, it being
  /// the one the user just placed — each moves down past whatever it
  /// overlaps, then everything rises as far as it can.
  HomeLayout settled({String? first}) {
    final order = tiles.where((t) => t.shown).toList()
      ..sort((a, b) {
        if (a.id == first) return -1;
        if (b.id == first) return 1;
        final byRow = a.cell.y.compareTo(b.cell.y);
        if (byRow != 0) return byRow;
        final byColumn = a.cell.x.compareTo(b.cell.x);
        return byColumn != 0 ? byColumn : a.id.compareTo(b.id);
      });
    final placed = <HomeCell>[];
    final cells = <String, HomeCell>{};
    for (final tile in order) {
      var cell = tile.cell;
      // ponytail: O(n²) over the shown tiles, a dozen at most.
      while (placed.any((c) => _overlap(c, cell))) {
        cell = (x: cell.x, y: cell.y + 1, w: cell.w, h: cell.h);
      }
      placed.add(cell);
      cells[tile.id] = cell;
    }
    final rising = order.map((t) => t.id).toList()
      ..sort((a, b) {
        final byRow = cells[a]!.y.compareTo(cells[b]!.y);
        return byRow != 0 ? byRow : cells[a]!.x.compareTo(cells[b]!.x);
      });
    for (final id in rising) {
      var cell = cells[id]!;
      while (cell.y > 0) {
        final up = (x: cell.x, y: cell.y - 1, w: cell.w, h: cell.h);
        if (cells.entries.any((e) => e.key != id && _overlap(e.value, up))) {
          break;
        }
        cell = up;
      }
      cells[id] = cell;
    }
    return HomeLayout([
      for (final t in tiles)
        if (cells[t.id] case final cell? when cell != t.cell)
          t.copyWith(cell: cell)
        else
          t,
    ]);
  }

  static bool _overlap(HomeCell a, HomeCell b) =>
      a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;

  /// This layout with every action's paths rewritten after the item at
  /// [from] moved to [to]; the same instance when none pointed there.
  HomeLayout renamed(String from, String to, {required bool isDir}) {
    var changed = false;
    final next = [
      for (final tile in tiles)
        if (tile.actions.isEmpty)
          tile
        else
          () {
            final actions = [
              for (final a in tile.actions) a.renamed(from, to, isDir: isDir),
            ];
            if (actions.indexed.every(
              (e) => identical(e.$2, tile.actions[e.$1]),
            )) {
              return tile;
            }
            changed = true;
            return tile.copyWith(actions: actions);
          }(),
    ];
    return changed ? HomeLayout(next) : this;
  }

  /// The file's object: one key per tile, in [tiles] order.
  Map<String, Object?> toJson() => {for (final t in tiles) t.id: t.toJson()};

  @override
  bool operator ==(Object other) =>
      other is HomeLayout && jsonEncode(toJson()) == jsonEncode(other.toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}
