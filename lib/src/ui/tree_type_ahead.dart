import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/name_sort_key.dart';
import 'package:niman/src/ui/tree_name_search.dart';
import 'package:niman/src/ui/tree_walk.dart';

/// What looking for a name through the rows loaded found.
enum _Held {
  /// A row has it, and the cursor moved there.
  found,

  /// Every row has been looked at and none has it.
  none,

  /// A row in a page that is not loaded was reached: the index has to say.
  unsure,
}

/// The tree's jump to a row by its name (#712): letters typed move the
/// keyboard's cursor to the next row whose name starts with them.
final class TreeTypeAhead {
  /// Jumps through [walk], putting the cursor on a row with [move]; the
  /// cursor's place is [cursorAt], and nothing lands once [mounted] says the
  /// tree is gone.
  new({
    required this.walk,
    required this.move,
    required this.cursorAt,
    required this.mounted,
  });

  /// The rows looked through.
  final TreeWalk walk;

  /// Puts the cursor on the walk's row at an index.
  final void Function(int index) move;

  /// The cursor's place in the walk, asking the index for a row whose page
  /// is not loaded.
  final Future<int> Function() cursorAt;

  /// Whether the tree is still on screen.
  final bool Function() mounted;

  /// What has been typed to jump to a row by its name, and when the last
  /// letter came: a pause starts a new name (#712).
  String _typed = '';
  DateTime _typedAt = DateTime(0);

  /// The letters typed that the index is answering, one after the other: the
  /// next one starts from where the one before landed. [_typingPending]
  /// counts the ones still out.
  Future<void> _typing = Future<void>.value();
  int _typingPending = 0;

  /// The character [event] types, when it is a letter or a mark to jump to
  /// a name by; null for a space, a control character or no character.
  static String? letterOf(KeyEvent event) {
    final typed = event.character;
    if (typed != null &&
        typed.length == 1 &&
        typed.trim().isNotEmpty &&
        typed.codeUnitAt(0) >= 0x20 &&
        typed.codeUnitAt(0) != 0x7f) {
      return typed;
    }
    return null;
  }

  /// Jumps to the next row, from the cursor's, whose name starts with what
  /// has been typed: a second letter within a second narrows the name, the
  /// same letter again moves to the next row that starts with it, and a
  /// letter that narrows it to nothing starts a name of its own.
  ///
  /// The rows in memory answer when they can, at once. When the walk comes to
  /// a page that is not loaded it is the index that answers, and the jump
  /// lands when it does; the letters typed meanwhile wait their turn.
  KeyEventResult type(String letter, int at) {
    final now = DateTime.now();
    final fresh = now.difference(_typedAt) > const Duration(seconds: 1);
    _typedAt = now;
    if (_typingPending == 0 && _typeHeld(letter, at, fresh: fresh)) {
      return KeyEventResult.handled;
    }
    _typingPending++;
    _typing = _typing.then((_) => _typeOne(letter, fresh: fresh)).whenComplete(
      () {
        _typingPending--;
      },
    );
    return KeyEventResult.handled;
  }

  /// [type] over the rows loaded alone: false, with nothing changed,
  /// when a row it needs to look at is in a page that is not.
  bool _typeHeld(String letter, int at, {required bool fresh}) {
    final repeat = !fresh && _typed == letter;
    if (!fresh && !repeat) {
      final narrowed = _jumpHeld('$_typed$letter', at, from: 0);
      if (narrowed == _Held.unsure) return false;
      if (narrowed == _Held.found) {
        _typed += letter;
        return true;
      }
    }
    // A letter on its own looks past the cursor's row.
    if (_jumpHeld(letter, at, from: 1) == _Held.unsure) return false;
    _typed = letter;
    return true;
  }

  /// One letter of [type], answered by the index, once the ones before
  /// it are done.
  Future<void> _typeOne(String letter, {required bool fresh}) async {
    try {
      final repeat = !fresh && _typed == letter;
      if (!fresh && !repeat && await _jumpTo('$_typed$letter', from: 0)) {
        _typed += letter;
        return;
      }
      _typed = letter;
      // A letter on its own looks past the cursor's row.
      await _jumpTo(letter, from: 1);
    } on Object catch (error) {
      // A library closed under the question has no row to jump to.
      const AppLogger(name: 'tree.ui').warning('type-ahead: $error');
    }
  }

  /// Moves to the first row from [at] + [from] on, wrapping, whose name
  /// starts with [name], looking at the rows loaded alone.
  _Held _jumpHeld(String name, int at, {required int from}) {
    // The tree's own comparison of names (#1070): case and marks do not
    // count, so the letter typed finds the row the order puts it in.
    final wanted = foldName(name);
    final length = walk.length;
    for (var step = from; step < length + from; step++) {
      final index = (at + step) % length;
      final held = walk.nameAt(index);
      if (held == null) return _Held.unsure;
      if (foldName(held).startsWith(wanted)) {
        move(index);
        return _Held.found;
      }
    }
    return _Held.none;
  }

  /// Moves to the first row from the cursor's + [from] on, wrapping, whose
  /// name starts with [name]; false when none does.
  ///
  /// The pinned notes are looked through here, and the tree's rows are asked
  /// of the index, segment by segment in the order they are drawn (see
  /// [TreeNameSearch]).
  Future<bool> _jumpTo(String name, {required int from}) async {
    // The tree's own comparison of names (#1070): case and marks do not
    // count, so the letter typed finds the row the order puts it in.
    final wanted = foldName(name);
    final listing = walk.rows?.listing;
    if (listing == null) return false;
    final length = walk.length;
    if (length == 0) return false;
    final start = (await cursorAt() + from) % length;
    if (!mounted() || !identical(walk.rows?.listing, listing)) return false;
    final pinned = walk.pinnedWalked;
    final search = TreeNameSearch(listing);

    // The first walk index from [first] up to [end] that has the name.
    Future<int?> within(int first, int end) async {
      final notes = walk.rows!.pinned;
      for (var at = first; at < math.min(end, pinned); at++) {
        if (foldName(notes[at].name).startsWith(wanted)) return at;
      }
      final treeFirst = math.max(first, pinned) - pinned;
      if (treeFirst >= end - pinned) return null;
      final found = await search.firstIn(wanted, treeFirst, end - pinned);
      if (found == null) return null;
      final at = await listing.modelIndexOfNote(found);
      return at == null ? null : pinned + at;
    }

    final index = await within(start, length) ?? await within(0, start);
    if (index == null ||
        !mounted() ||
        !identical(walk.rows?.listing, listing)) {
      return false;
    }
    move(index);
    return true;
  }
}
