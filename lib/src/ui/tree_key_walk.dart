import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/tree_type_ahead.dart';
import 'package:niman/src/ui/tree_walk.dart';
import 'package:niman/src/ui/tree_walk_row.dart';

/// What a plain key does on the tree's rows (#727): the arrows walk them,
/// `Home`/`End` and `PgUp`/`PgDn` jump, `Enter` opens, the left and right
/// arrows close and open folders or step out and in, and `F2` and `Delete`
/// act on the cursor's row.
final class TreeKeyWalk {
  /// Walks [walk], [scroll] saying how tall a page is, putting the cursor on
  /// a row with [move]; nothing moves once [mounted] says the tree is gone.
  new({
    required this.walk,
    required this.scroll,
    required this.move,
    required this.mounted,
  });

  /// The rows walked.
  final TreeWalk walk;

  /// The tree's scroll: its viewport is a page.
  final ScrollController scroll;

  /// Puts the cursor on the walk's row at an index.
  final KeyEventResult Function(int index) move;

  /// Whether the tree is still on screen.
  final bool Function() mounted;

  /// Runs [then] with the walk's row at [index]: at once when it is loaded,
  /// else when its page has landed.
  void _whenRow(int index, void Function(TreeWalkRow row) then) {
    final row = walk.rowAt(index);
    if (row != null) {
      then(row);
      return;
    }
    unawaited(
      walk.rowAtAsync(index).then((row) {
        if (row != null && mounted()) then(row);
      }),
    );
  }

  /// The keys the walk may take, whatever the rows: a superset of what it
  /// does take, so that a key that is not one of them is left to the app
  /// before the cursor's row is looked for.
  static final Set<LogicalKeyboardKey> _walkKeys = {
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.home,
    LogicalKeyboardKey.end,
    LogicalKeyboardKey.pageUp,
    LogicalKeyboardKey.pageDown,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.escape,
    LogicalKeyboardKey.delete,
    LogicalKeyboardKey.f2,
    LogicalKeyboardKey.f10,
    LogicalKeyboardKey.contextMenu,
  };

  /// Whether the walk may take [event], by the key and the modifiers alone.
  static bool owns(KeyEvent event) {
    final keys = HardwareKeyboard.instance;
    final key = event.logicalKey;
    if (keys.isAltPressed) return false;
    if (keys.isControlPressed || keys.isMetaPressed) {
      return key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter;
    }
    if (_walkKeys.contains(key)) return true;
    return !keys.isShiftPressed && TreeTypeAhead.letterOf(event) != null;
  }

  /// One key of the walk: [cursor] is the cursor's place in it, and what the
  /// key does is decided here. [expanded] are the folders open; [select]
  /// opens a row's note, [toggle] opens or closes a folder, and [rename] and
  /// [delete], when there are, act on the cursor's row.
  KeyEventResult handle(
    TreeWalkCursor cursor,
    LogicalKeyboardKey key, {
    required Set<String> expanded,
    required void Function(Note note) select,
    required ValueChanged<String> toggle,
    ValueChanged<String>? rename,
    ValueChanged<String>? delete,
  }) {
    final (:at, :row) = cursor;
    final length = walk.length;
    if (key == LogicalKeyboardKey.arrowUp) return move(at - 1);
    if (key == LogicalKeyboardKey.arrowDown) return move(at + 1);
    if (key == LogicalKeyboardKey.home) return move(0);
    if (key == LogicalKeyboardKey.end) return move(length - 1);
    if (key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.pageDown) {
      final viewport = scroll.hasClients
          ? scroll.position.viewportDimension
          : 0.0;
      final page = math.max(1, viewport ~/ math.max(1.0, row.height));
      return move(at + (key == LogicalKeyboardKey.pageUp ? -page : page));
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      select(row.note);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      // A closed folder opens; anything else steps into the rows drawn
      // under it, as a file manager's right arrow does.
      if (row.note.isDir && !expanded.contains(row.path)) {
        toggle(row.path);
        return KeyEventResult.handled;
      }
      if (!row.pinned && at + 1 < length) {
        _whenRow(at + 1, (next) {
          if (next.depth > row.depth) move(at + 1);
        });
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      // An open folder closes; anything else steps out to the row that
      // holds it.
      if (row.note.isDir && expanded.contains(row.path)) {
        toggle(row.path);
        return KeyEventResult.handled;
      }
      if (!row.pinned) _stepOut(at, row);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.f2) {
      if (rename == null) return KeyEventResult.ignored;
      rename(row.path);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete) {
      if (delete == null) return KeyEventResult.ignored;
      delete(row.path);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// The left arrow on a tree row that is not an open folder: to the file a
  /// sidecar is drawn under, else to the folder row that holds the row — the
  /// model knows where it is without any row loaded. The tree's own rows
  /// only: the pinned block above them is no folder of theirs.
  void _stepOut(int at, TreeWalkRow row) {
    final pinned = walk.pinnedWalked;
    if (row.sidecar) {
      // Nested within the page, right under its file: the nearest row above
      // that is not a sidecar.
      for (var up = at - 1; up >= pinned; up--) {
        final above = walk.rowAt(up);
        if (above == null) return;
        if (!above.sidecar) {
          move(up);
          return;
        }
      }
      return;
    }
    final folder = walk.rows?.listing.model.rowIndexOf(row.note.parent);
    if (folder != null) move(pinned + folder);
  }
}
