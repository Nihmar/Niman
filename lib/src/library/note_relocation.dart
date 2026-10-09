import 'dart:io';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/history/note_history.dart';
import 'package:niman/src/home/home_file.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/library/note_op_seams.dart';
import 'package:niman/src/library/note_writer.dart';
import 'package:niman/src/links/link_moves.dart';
import 'package:niman/src/links/rewrite.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:path/path.dart' as p;

/// Moves a note or a folder on disk and carries along everything that
/// named it by its path: the history, the reading positions, the settings,
/// the Home, what lies outside the library, the index and the links in the
/// notes that pointed at it (#281, #506, #507, #535).
///
/// It does not serialize: `NoteOps.rename` and `NoteOps.move` call it from
/// inside their own turn of the op chain.
final class NoteRelocator {
  /// Creates the relocator of the library at [root].
  new({
    required this.root,
    required this.dao,
    required this.indexer,
    required this.history,
    required this.config,
    required this.writer,
    required this.hint,
    required this.find,
    required this.readNote,
    this.carryOutside,
  });

  /// Absolute path of the library root.
  final String root;

  /// The library's index, read for the links that point at what moves.
  final NoteDao dao;

  /// The shared indexer; the move reaches the index through it.
  final Indexer indexer;

  /// The library's `.history/`, which follows what moves.
  final NoteHistory history;

  /// The library settings, whose paths follow what moves.
  final LibraryConfigRepo config;

  /// The note-text write path, through which a rewritten link is saved.
  final NoteWriter writer;

  /// Where the relocator reports the paths it changed.
  final SyncHintSink hint;

  /// The indexed row at a path; throws when there is none.
  final Future<Note> Function(String path) find;

  /// The text of the note at a path, as `NoteOps.readNote` reads it.
  final Future<String> Function(String path) readNote;

  /// What else, outside the library's own files, names a note by its path
  /// and has to follow a rename or a move (#506); null carries nothing
  /// further.
  final Future<void> Function(String from, String to, {required bool isDir})?
  carryOutside;

  /// The absolute path for library-relative [rel] ('' = root).
  String _abs(String rel) => p.join(root, rel);

  /// Renames what [row] holds at [path] to [newRel] on disk, and carries
  /// everything that named it along: the sync hint, the history, the
  /// reading positions, the settings, the Home, what lies outside the
  /// library, the index and the links in the notes that pointed at it.
  /// The shared tail of `NoteOps.rename` and `NoteOps.move`; returns the
  /// updated row.
  Future<Note> relocate(Note row, String path, String newRel) async {
    final oldAbs = _abs(path);
    if (row.isDir) {
      await Directory(oldAbs).rename(_abs(newRel));
    } else {
      await File(oldAbs).rename(_abs(newRel));
    }
    hint(newRel, SyncOpKind.moved, fromPath: path);
    await history.moved(path, newRel, isDir: row.isDir);
    await _carryReading(path, newRel, isDir: row.isDir);
    await _carrySettings(path, newRel, isDir: row.isDir);
    await _carryHome(path, newRel, isDir: row.isDir);
    await _carryOutside(path, newRel, isDir: row.isDir);
    // Before the index hears of the move: a folder's reindex re-creates
    // its notes, and the edges that named them would be gone (#507).
    final links = await _linksToMove(path, isDir: row.isDir);
    await indexer.applyEvents(root, [oldAbs, _abs(newRel)]);
    await _rewriteLinks(
      path,
      newRel,
      isDir: row.isDir,
      oldPaths: links.oldPaths,
      referrers: links.referrers,
    );
    return await find(newRel);
  }

  /// Rewrites every setting that pointed at what moved from [from] to [to]
  /// (#506): the quick note, the list, template, attachments and annotations
  /// folders, and the journal's folder and template. A folder carries its
  /// subtree; a note only itself. Nothing pointed at it means no write.
  Future<void> _carrySettings(String from, String to, {required bool isDir}) {
    return config.update((c) => c.renamed(from, to, isDir: isDir));
  }

  /// Rewrites the Home actions that named what moved from [from] to [to]
  /// (#535): the library's file and this device's own Home. The move is
  /// already done on disk: a failure here is logged and leaves it standing.
  Future<void> _carryHome(String from, String to, {required bool isDir}) async {
    try {
      if (await HomeFile(root).moved(from, to, isDir: isDir)) {
        hint(HomeFile.filePath, SyncOpKind.changed);
      }
      await config.update((c) {
        final device = c.deviceHome;
        if (device == null) return c;
        final layout = HomeLayout.fromJson(device);
        if (layout == null) return c;
        final next = layout.renamed(from, to, isDir: isDir);
        return identical(next, layout)
            ? c
            : c.copyWith(deviceHome: next.toJson());
      });
    } on Object catch (error) {
      const AppLogger(name: 'home')
          .warning('could not carry the Home past "$from" -> "$to": $error');
    }
  }

  /// Hands the move to [carryOutside] (#506). The move is already done on
  /// disk: a failure there is logged and leaves the rename standing.
  Future<void> _carryOutside(
    String from,
    String to, {
    required bool isDir,
  }) async {
    final carry = carryOutside;
    if (carry == null) return;
    try {
      await carry(from, to, isDir: isDir);
    } on Object catch (error) {
      const AppLogger(
        name: 'notes',
      ).warning('could not carry "$from" -> "$to" outside the library: $error');
    }
  }

  /// The referrers of what is about to move from [from] (#507), read from
  /// the index *before* the move: the index's resolved link edges
  /// (`note_links`, answered by its `links_to` index) and the moved files'
  /// own old paths.
  ///
  /// Read first because a folder's rename re-creates the notes under it with
  /// new ids, and the edges that pointed at them would be gone by the time
  /// the move is done; the referrer's own path is what the rewrite needs, and
  /// it is unchanged for anyone outside the subtree.
  Future<({List<String> oldPaths, List<String> referrers})> _linksToMove(
    String from, {
    required bool isDir,
  }) async {
    final oldPaths = isDir ? await dao.filePathsUnder(from) : <String>[from];
    if (oldPaths.isEmpty) {
      return (oldPaths: oldPaths, referrers: const <String>[]);
    }
    final rows = await dao.byPaths(oldPaths);
    if (rows.isEmpty) {
      return (oldPaths: oldPaths, referrers: const <String>[]);
    }
    final referrers = await dao.referrerPaths([
      for (final row in rows.values) row.id,
    ]);
    return (oldPaths: oldPaths, referrers: referrers);
  }

  /// Rewrites the links in every note that pointed at what moved from [from]
  /// to [to] (#507).
  ///
  /// [oldPaths] are the moved files' old library-relative paths and
  /// [referrers] their referring notes' paths, as [_linksToMove] read them
  /// before the move. Each changed note is written through the writer — the
  /// normal save path — so its edit is a save with its own history version
  /// and sync hint. The rewrite itself reads no index: it maps the written
  /// targets through the old->new paths alone ([rewriteMovedLinks]).
  Future<void> _rewriteLinks(
    String from,
    String to, {
    required bool isDir,
    required List<String> oldPaths,
    required List<String> referrers,
  }) async {
    if (oldPaths.isEmpty || referrers.isEmpty) return;
    // Indexed once for every referrer: a link is a lookup, not a walk of
    // everything that moved.
    final moves = LinkMoves({
      for (final old in oldPaths)
        old: pathAfterMove(old, from, to, isDir: isDir)!,
    });
    // A renamed file is the one case a bare-name wikilink follows.
    String? renamedFrom;
    String? renamedTo;
    if (!isDir) {
      final oldName = p.basename(from);
      final newName = p.basename(to);
      if (oldName != newName) {
        renamedFrom = oldName;
        renamedTo = newName;
      }
    }
    var updated = 0;
    final seen = <String>{};
    for (final oldReferrer in referrers) {
      // A referrer inside the moved subtree moved with it.
      final path = pathAfterMove(oldReferrer, from, to, isDir: isDir)!;
      if (!seen.add(path)) continue;
      // One referrer that cannot be read or written must not stop the rest:
      // the move is already done, and the others still need their links fixed.
      try {
        final text = await readNote(path);
        final next = rewriteMovedLinks(
          text,
          // Its links were written where it stood; a relative one is
          // written back from where it stands now.
          from: oldReferrer,
          at: path,
          moves: moves,
          renamedFrom: renamedFrom,
          renamedTo: renamedTo,
        );
        if (next == text) continue;
        await writer.save(path, next);
        hint(path, SyncOpKind.changed);
        updated++;
      } on Object catch (error) {
        const AppLogger(name: 'links')
            .warning('could not rewrite links in "$path": $error');
      }
    }
    if (updated > 0) {
      const AppLogger(name: 'links')
          .info('$updated note(s) updated after "$from" -> "$to"');
    }
  }

  /// Carries the reading positions of what moved from [from] to [to]
  /// (#281): a book or a PDF, or a folder that may hold some. A note
  /// keeps none, and costs no read of the file.
  Future<void> _carryReading(String from, String to, {required bool isDir}) {
    if (!isDir && isMarkdownNote(from)) return Future<void>.value();
    return ReadingPositions(root).moved(from, to);
  }
}
