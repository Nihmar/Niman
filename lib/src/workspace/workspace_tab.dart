import 'package:flutter/foundation.dart';
import 'package:niman/src/workspace/note_memento.dart';

/// One open note in a pane (issue #23).
@immutable
final class WorkspaceTab {
  /// The tab for the note at [path].
  const new(
    this.path, {
    this.memento = const NoteMemento(),
    this.missing = false,
  });

  /// The note's library-relative path, `/`-separated like every path the
  /// library hands out.
  final String path;

  /// Where the note was left.
  final NoteMemento memento;

  /// The file went away from outside the app (a sync, another program):
  /// the tab stays, saying so, rather than vanishing under the reader.
  /// Never persisted — it is found again, or not, on the next look.
  final bool missing;

  /// A copy with the given fields replaced.
  WorkspaceTab copyWith({String? path, NoteMemento? memento, bool? missing}) =>
      WorkspaceTab(
        path ?? this.path,
        memento: memento ?? this.memento,
        missing: missing ?? this.missing,
      );

  @override
  bool operator ==(Object other) =>
      other is WorkspaceTab &&
      other.path == path &&
      other.memento == memento &&
      other.missing == missing;

  @override
  int get hashCode => Object.hash(path, memento, missing);

  @override
  String toString() => 'WorkspaceTab($path${missing ? ', missing' : ''})';
}
