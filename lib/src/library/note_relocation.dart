import 'dart:io';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkUpdate;
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/history/note_history.dart';
import 'package:niman/src/home/home_file.dart';
import 'package:niman/src/library/device_home_carry.dart';
import 'package:niman/src/library/note_op_seams.dart';
import 'package:niman/src/library/note_writer.dart';
import 'package:niman/src/links/link_moves.dart';
import 'package:niman/src/links/rewrite.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:path/path.dart' as p;

/// Asks whether the links in [notes] notes, which pointed at what has just
/// moved, are to be rewritten (the library's [LinkUpdate.ask], #848). The
/// library does not draw the question: the shell does.
typedef LinkUpdateConfirm = Future<bool> Function(int notes);

/// The rewrite of links a relocation leaves for after its turn of the op
/// chain, under [LinkUpdate.ask] (#848): the question is a dialog a person
/// may leave open, and a dialog must not hold the chain every other op and
/// every sync write waits in.
final class PendingLinkRewrite {
  /// A rewrite of the links in the notes [count] finds changing, done by
  /// [apply].
  const new({required this.count, required this.apply});

  /// How many notes the rewrite would change, found by reading each
  /// referrer and rewriting it in memory (#866). Takes no turn of the op
  /// chain: it is the caller's to run once the move's turn is over, so a
  /// library of thousands of referrers is not held up by it.
  final Future<int> Function() count;

  /// Rewrites the links. It reads each note again, so an edit made since
  /// the count (or while the question was open) is kept; it must run in a
  /// turn of the op chain of its own.
  final Future<void> Function() apply;
}

/// What a relocation did: the moved row, and the link rewrite still to ask
/// about, if any.
typedef Relocated = ({Note row, PendingLinkRewrite? pending});

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
  final CarryOutside? carryOutside;

  /// The absolute path for library-relative [rel] ('' = root).
  String _abs(String rel) => p.join(root, rel);

  /// Renames what [row] holds at [path] to [newRel] on disk, and carries
  /// everything that named it along: the sync hint, the history, the
  /// reading positions, the settings, the Home, what lies outside the
  /// library, the index and the links in the notes that pointed at it —
  /// those as the [LinkUpdate] setting says (#848): rewritten here under
  /// [LinkUpdate.automatic], left alone under [LinkUpdate.never], and under
  /// [LinkUpdate.ask] returned as a [PendingLinkRewrite] for the caller to
  /// ask about once its turn is over.
  /// The shared tail of `NoteOps.rename` and `NoteOps.move`; returns the
  /// updated row.
  Future<Relocated> relocate(Note row, String path, String newRel) async {
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
    await carryOutsideLibrary(carryOutside, path, newRel, isDir: row.isDir);
    // Before the index hears of the move: a folder's reindex re-creates
    // its notes, and the edges that named them would be gone (#507).
    final links = await _linksToMove(path, isDir: row.isDir);
    await indexer.applyEvents(root, [oldAbs, _abs(newRel)]);
    final pending = await _rewriteLinks(
      path,
      newRel,
      isDir: row.isDir,
      oldPaths: links.oldPaths,
      referrers: links.referrers,
    );
    return (row: await find(newRel), pending: pending);
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
    } on Object catch (error) {
      const AppLogger(name: 'home')
          .warning('could not carry the Home past "$from" -> "$to": $error');
    }
    await carryDeviceHome(config, from, to, isDir: isDir);
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
    final referrers = await dao.referrers.pathsOf([
      for (final row in rows.values) row.id,
    ]);
    return (oldPaths: oldPaths, referrers: referrers);
  }

  /// Rewrites the links in every note that pointed at what moved from [from]
  /// to [to] (#507), as the library's [LinkUpdate] setting says (#848):
  /// at once, or not at all, or — under [LinkUpdate.ask] — not yet: the
  /// number of notes that would change comes back with the rewrite to run
  /// once it is agreed to. Nothing else that followed the move depends on
  /// the answer.
  ///
  /// [oldPaths] are the moved files' old library-relative paths and
  /// [referrers] their referring notes' paths, as [_linksToMove] read them
  /// before the move. Each changed note is written through the writer — the
  /// normal save path — so its edit is a save with its own history version
  /// and sync hint. The rewrite itself reads no index: it maps the written
  /// targets through the old->new paths alone ([rewriteMovedLinks]).
  Future<PendingLinkRewrite?> _rewriteLinks(
    String from,
    String to, {
    required bool isDir,
    required List<String> oldPaths,
    required List<String> referrers,
  }) async {
    if (oldPaths.isEmpty || referrers.isEmpty) return null;
    final mode = (await config.config).linkUpdate;
    if (mode == LinkUpdate.never) return null;
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
    // A referrer inside the moved subtree moved with it; one note is
    // rewritten once however many of its old paths were referrers.
    final targets = <(String oldReferrer, String path)>[];
    final seen = <String>{};
    for (final oldReferrer in referrers) {
      final path = pathAfterMove(oldReferrer, from, to, isDir: isDir)!;
      if (seen.add(path)) targets.add((oldReferrer, path));
    }
    Future<String?> rewritten(String oldReferrer, String path) async {
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
      return next == text ? null : next;
    }

    Future<void> write() async {
      var updated = 0;
      for (final (oldReferrer, path) in targets) {
        // One referrer that cannot be read or written must not stop the
        // rest: the move is already done, and the others still need their
        // links fixed.
        try {
          final next = await rewritten(oldReferrer, path);
          if (next == null) continue;
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

    if (mode == LinkUpdate.automatic) {
      await write();
      return null;
    }
    Future<int> count() async {
      var changing = 0;
      for (final (oldReferrer, path) in targets) {
        try {
          if (await rewritten(oldReferrer, path) != null) changing++;
        } on Object catch (error) {
          const AppLogger(name: 'links')
              .warning('could not read links in "$path": $error');
        }
      }
      return changing;
    }

    return PendingLinkRewrite(count: count, apply: write);
  }

  /// Carries the reading positions of what moved from [from] to [to]
  /// (#281): a book or a PDF, or a folder that may hold some. A note
  /// keeps none, and costs no read of the file.
  Future<void> _carryReading(String from, String to, {required bool isDir}) {
    if (!isDir && isMarkdownNote(from)) return Future<void>.value();
    return ReadingPositions(root).moved(from, to);
  }
}
