import 'dart:io';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/frontmatter/edit_in_file.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/library/note_op_seams.dart';
import 'package:niman/src/library/note_writer.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:path/path.dart' as p;

/// Pins and unpins notes, through the `pinned` key of their frontmatter,
/// in a turn of the op chain [serialize] hands it of its own.
final class NotePins {
  /// Creates the pins of the library at [root].
  new({
    required this.root,
    required this.indexer,
    required this.writer,
    required this.serialize,
    required this.hint,
    required this.find,
  });

  /// Absolute path of the library root.
  final String root;

  /// The shared indexer, which records the new frontmatter at once.
  final Indexer indexer;

  /// The note-text write path, which reads the pinned note back later.
  final NoteWriter writer;

  /// The op chain of the library's operations.
  final Serializer serialize;

  /// Where the pins report the notes they changed.
  final SyncHintSink hint;

  /// The indexed row at a path; throws when there is none.
  final Future<Note> Function(String path) find;

  /// The absolute path for library-relative [rel] ('' = root).
  String _abs(String rel) => p.join(root, rel);

  /// Pins or unpins the note at [path] by editing its frontmatter.
  ///
  /// Unpinning removes the key rather than writing `pinned: false`: the
  /// file goes back to what it looked like before, instead of collecting
  /// a line that says nothing.
  ///
  /// The index records the new frontmatter at once, from the head the edit
  /// wrote ([Indexer.applyFrontmatter]); the note itself is read back later,
  /// as a save's is ([NoteWriter.reindexWhenQuiet]). Read back before the
  /// pin was answered, the 247 MB stress note kept the pin on screen for
  /// the 15 to 34 s a phone takes to read it — or for good, when the app
  /// was closed first (device log, 2026-09-24).
  Future<Note> setPinned(String path, {required bool pinned}) {
    return serialize(() async {
      final row = await find(path);
      // The pin lives in the note's frontmatter, so only a note can carry
      // one. Pinning a `todo.txt` wrote a YAML block into a file that has
      // no such thing, and every todo.txt reader — this app's included —
      // then read the three lines as tasks. Unpinning stays allowed
      // whatever the file is, so a block already written can be taken
      // back out.
      if (row.isDir || (pinned && !isMarkdownNote(row.name))) {
        throw ArgumentError('Only Markdown notes can be pinned, not "$path"');
      }
      final file = File(_abs(path));
      // The head of the note, not the note: off the UI isolate, the rest
      // of the file copied behind the edited frontmatter as it is.
      final head = await editFrontmatterKeyOnIsolate(
        file.path,
        'pinned',
        pinned ? 'true' : null,
      );
      if (head == null) return row;
      hint(path, SyncOpKind.changed);
      // Scheduled first: from here the watcher's report of this very write
      // leaves the note to the writer, and the pin below may wait behind a
      // scan already running.
      writer.reindexWhenQuiet(path, bytes: row.size);
      await indexer.applyFrontmatter(path, parseFrontmatter(head));
      return await find(path);
    });
  }
}
