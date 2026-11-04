import 'dart:async';

import 'package:niman/src/db/index_change.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/tree_moves.dart';

/// What a library session announces: its revisions and the streams that
/// carry them, the index's writes, the paths a re-index pruned and the ones
/// the watcher reported.
final class SessionEvents {
  /// Events at revision 0, nothing announced yet.
  new();

  final StreamController<int> _events = StreamController<int>.broadcast();

  /// Fires on an index write only ([indexChanged]), not on the session's
  /// own bumps (a setting, a phase, a progress report): what the links
  /// re-resolve on (#867).
  final StreamController<void> _indexEvents =
      StreamController<void>.broadcast();

  /// Fires when the tree's rows may have moved ([IndexChange.tree]).
  final StreamController<int> _treeEvents = StreamController<int>.broadcast();

  /// Fires with the paths a re-index pruned ([Indexer.onRemoved]); what
  /// the shell holds open on them closes.
  final StreamController<Set<String>> _removals =
      StreamController<Set<String>>.broadcast();

  /// The paths the watcher reported ([externalChanges]).
  final StreamController<Set<String>> _externalChanges =
      StreamController<Set<String>>.broadcast();
  int _revision = 0;
  int _treeRevision = 0;

  /// What the recent revisions moved in the tree ([foldersMovedSince]).
  final TreeMoves _moves = TreeMoves();

  /// Bumped after every index change.
  int get revision => _revision;

  /// Bumped after an index change that can move the tree's rows: a row
  /// added, removed or reshaped, a pin, a folder synced — not a save's new
  /// size and time, which only the field orders draw (#751).
  int get treeRevision => _treeRevision;

  /// Fires with the new [revision] after every index change.
  Stream<int> get events => _events.stream;

  /// Fires on an index write only, not on the session's own bumps.
  Stream<void> get indexChanges => _indexEvents.stream;

  /// Fires with the new [treeRevision] after a change that may move the
  /// tree's rows (#751).
  Stream<int> get treeEvents => _treeEvents.stream;

  /// Fires with the library-relative paths a re-index pruned from the tree.
  Stream<Set<String>> get removals => _removals.stream;

  /// Fires with the paths the watcher reported.
  Stream<Set<String>> get externalChanges => _externalChanges.stream;

  /// Whether [close] has run.
  bool get isClosed => _removals.isClosed;

  /// The folders whose rows moved since [since], by row id, or null when
  /// any may have.
  Set<int>? foldersMovedSince(int since, {required bool tree}) =>
      _moves.since(since, tree: tree);

  /// A new revision — and a new tree revision when [tree] — which moved rows
  /// in [folders] alone, or anywhere when null ([foldersMovedSince]).
  void bump({bool tree = true, Set<int>? folders}) {
    _revision++;
    if (tree) _treeRevision++;
    _moves.record(
      revision: _revision,
      treeRevision: tree ? _treeRevision : null,
      folders: folders,
    );
    if (!_events.isClosed) {
      _events.add(_revision);
    }
    if (!tree) return;
    if (!_treeEvents.isClosed) {
      _treeEvents.add(_treeRevision);
    }
  }

  /// An index write landed: everything that reads the index hears of it,
  /// and — when the rows' shape moved, and not for a save's new size and
  /// time (#751) — the tree hears that it has rows to read again. Every
  /// other bump is the session's own (the phase, a progress report, a
  /// setting): all of them may move what the tree draws. [folders] are the
  /// ones the write moved rows in, when the indexer says
  /// ([Indexer.changedFolders]).
  void indexChanged(IndexChange change, {Set<int>? folders}) {
    bump(tree: change == IndexChange.tree, folders: folders);
    if (!_indexEvents.isClosed) _indexEvents.add(null);
  }

  /// Fires [removals] with [paths]; the caller checks [isClosed] first.
  void removed(Set<String> paths) => _removals.add(paths);

  /// Fires [externalChanges] with [paths], unless closed.
  void externalChanged(Set<String> paths) {
    if (!_externalChanges.isClosed) _externalChanges.add(paths);
  }

  /// Closes every stream.
  Future<void> close() async {
    if (!_events.isClosed) {
      await _events.close();
    }
    if (!_indexEvents.isClosed) {
      await _indexEvents.close();
    }
    if (!_treeEvents.isClosed) {
      await _treeEvents.close();
    }
    if (!_removals.isClosed) {
      await _removals.close();
    }
    if (!_externalChanges.isClosed) {
      await _externalChanges.close();
    }
  }
}
