import 'dart:async';

import 'package:niman/src/workspace/workspace.dart';

/// The tree's expanded folders (#1069): the set the tree reads, kept right
/// as folders are renamed, moved and deleted, and handed on to be saved with
/// the library's workspace, so a restart or a switch of library finds the
/// tree as it was left.
///
/// The paths are library-relative and `/`-separated, as every path the
/// library hands out. The set keeps the order they were opened in and holds
/// [Workspace.maxExpanded] at most, the oldest going first.
final class ExpandedFolders {
  /// The folders the tree draws open; the tree reads this set itself, so it
  /// is changed here and not by whoever has it.
  final Set<String> folders = <String>{};

  /// Told the folders, the most recently opened last, a moment after they
  /// change: the workspace keeps them. Null until the saved ones are read
  /// back ([persistTo]), so nothing is written over them before.
  void Function(List<String> folders)? _persist;
  bool _scheduled = false;

  /// Whether the folder at [path] is expanded.
  bool contains(String path) => folders.contains(path);

  /// Expands the folder at [path].
  void add(String path) {
    if (path.isEmpty || !folders.add(path)) return;
    _changed();
  }

  /// Collapses the folder at [path].
  void remove(String path) {
    if (folders.remove(path)) _changed();
  }

  /// Expands [folder] and every folder above it: what makes a row visible.
  void addWithAncestors(String folder) {
    var at = folder;
    var changed = false;
    while (at.isNotEmpty && at != '.') {
      changed |= folders.add(at);
      final slash = at.lastIndexOf('/');
      at = slash < 0 ? '' : at.substring(0, slash);
    }
    if (changed) _changed();
  }

  /// Expands the folders a saved workspace remembers.
  void addAll(Iterable<String> saved) {
    var changed = false;
    for (final path in saved) {
      if (path.isNotEmpty) changed |= folders.add(path);
    }
    if (changed) _changed();
  }

  /// [from] is now at [to], a folder or a note: the folders at or under it
  /// stay expanded at their new places.
  void moved(String from, String to) {
    if (from == to) return;
    final prefix = '$from/';
    final remapped = <String>[];
    var changed = false;
    for (final path in folders) {
      if (path == from) {
        remapped.add(to);
        changed = true;
      } else if (path.startsWith(prefix)) {
        remapped.add('$to/${path.substring(prefix.length)}');
        changed = true;
      } else {
        remapped.add(path);
      }
    }
    if (!changed) return;
    folders
      ..clear()
      ..addAll(remapped);
    _changed();
  }

  /// [path] is gone, a folder with the ones under it or a note: they leave
  /// the set, and a folder made later under the same name starts closed.
  void deleted(String path) {
    final prefix = '$path/';
    final before = folders.length;
    folders.removeWhere(
      (folder) => folder == path || folder.startsWith(prefix),
    );
    if (folders.length != before) _changed();
  }

  /// From now on the folders are handed to [persist] as they change, and
  /// once now: what was restored, with what was opened since the library did.
  void persistTo(void Function(List<String> folders) persist) {
    _persist = persist;
    _changed();
  }

  void _changed() {
    while (folders.length > Workspace.maxExpanded) {
      folders.remove(folders.first);
    }
    if (_persist == null || _scheduled) return;
    // Coalesced and deferred: a click expands a folder inside a setState,
    // and a rename can remap several in a row.
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      _persist?.call(List.of(folders));
    });
  }

  /// Stops handing the folders on: the library the shell was made for is
  /// closed.
  void dispose() => _persist = null;
}
