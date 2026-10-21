// No synchronous file call on the UI isolate (AGENTS.md, #1143): on Android
// every `statSync` or `listSync` is a round trip through FUSE, and the frame
// waits for it. This lists where the synchronous calls are allowed: files
// whose calls all run on a background isolate, and where each runs.
//
// The list is per file, so a file on it must be isolate-only: a file that
// also holds code the UI isolate runs would let a new `existsSync()` pass
// there. Such a file keeps its blocking helpers in a `<name>_blocking.dart`
// beside it (`files_blocking.dart`, `note_ops_blocking.dart`, ...) and the
// list names that. A synchronous call in any other file is either moved off
// the UI isolate (the asynchronous call, or the `Isolate.run` its caller
// makes) or goes into such a file, with the isolate it runs on: a decision,
// not an accident.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// The files whose synchronous file calls run off the UI isolate, and where.
const Map<String, String> _offTheUiIsolate = {
  'annotations/companion_notes.dart': "the listing in freshIn's Isolate.run",
  'calendar/calendar_store.dart': 'the reads its Isolate.run calls',
  'core/download/download_files.dart': 'the scan and deletes it Isolate.runs',
  'core/download/file_download.dart': "the download's spawned isolate",
  'core/disk_stamp.dart':
      'DiskStamp.of and matches, the synchronous form for isolates '
      '(ofAsync for the UI): the one file here that mixes, a value class '
      'with nothing else in it',
  'core/files_blocking.dart':
      'the hash and the name check, in isolates (files.dart is not allowed)',
  'core/library_state_file.dart': 'the load its Isolate.run calls',
  'core/temp_sweep_blocking.dart': "the sweep's walk, in Isolate.run",
  'db/index_note_content.dart': 'the note reads of the reader isolate',
  'db/index_scan.dart': 'the walk, the listing and the probes, in isolates',
  'epub/epub_document.dart': 'readEpub, in its Isolate.run',
  'epub/epub_convert_job.dart': "the conversion's spawned isolate",
  'export/export_sources.dart': 'the image reads, in Isolate.run',
  'export/export_tree.dart': "the export's spawned isolate",
  'export/export_tree_book.dart': "the metadata check's Isolate.run",
  'export/export_tree_pages.dart': "the export's spawned isolate",
  'export/export_tree_printer.dart': "the export's spawned isolate",
  'flashcards/deck_catalog.dart': 'the deck reads, in Isolate.run',
  'flashcards/review_store.dart': 'the reads its Isolate.run calls',
  'frontmatter/edit_in_file.dart': 'editFrontmatterKeyInFile, in Isolate.run',
  'history/external_write_check.dart': 'the snapshot, in the writer isolates',
  'history/history_store.dart': "every call, from NoteHistory's isolates",
  'history/history_legacy.dart': 'the old history moved in, by the store',
  'history/history_log.dart': 'the log, read and written by the store',
  'history/history_objects.dart': 'the objects, read and written by the store',
  'history/history_upkeep.dart': "the upkeep, in NoteHistory's isolates",
  'history/history_access.dart': 'the log, read and written by the store',
  'history/history_lock_file.dart': "the note's lock, taken by the store",
  'history/history_moves.dart':
      "moves and deletes, from NoteHistory's isolates",
  'history/history_pins.dart': "pins, from NoteHistory's isolates",
  'home/note_preview.dart': 'the preview read, in Isolate.run',
  'library/attachment_store.dart': 'the copy its Isolate.run calls',
  'library/audio_import.dart': 'the copy and the rename, in Isolate.run',
  'library/markdown_import.dart': 'the import, in IsolateGauge.run',
  'library/note_ops_blocking.dart':
      'the listing, the outline and the preview reads, in isolates',
  'library/note_tidy.dart': 'the tidy read, in Isolate.run',
  'library/note_write_stream.dart': "the stream writer's spawned isolate",
  'library/note_writer_blocking.dart':
      'replaceFileFrom and writeNoteFile, in the writer isolates',
  'library/wav_duration.dart': 'the probe, in Isolate.run',
  'links/link_spot_slices.dart': 'the slice read, in Isolate.run',
  'markdown/note_load.dart': 'loadNoteSync, in Isolate.run',
  'search/replace.dart': 'the preview and replace chunks, in Isolate.run',
  'spellcheck/hunspell_spell_checker.dart':
      'the dictionary search and load, in Isolate.run',
  'sync/sync_probe.dart': "the watcher batch's probe, in Isolate.run",
  'sync/sync_scanner_blocking.dart': 'scanLocalFiles, in Isolate.run',
  'sync/sync_sides.dart': 'hashLocalFiles, in Isolate.run',
  'todo/todo_store_blocking.dart': 'the reads and probes, in Isolate.run',
  'ui/drop_target.dart': 'foldersAmong, in Isolate.run',
  'ui/file_tree_context.dart': 'the exists check, in Isolate.run',
  'ui/kinds/flashcards/review_run.dart': 'the deck reads, in Isolate.run',
  'ui/known_library_list.dart': 'the folder checks, in Isolate.run',
  'ui/theme/theme_files.dart': 'the theme read, in Isolate.run',
  'widget/widget_note_ops.dart': 'the note read, in Isolate.run',
};

/// The blocking calls of `dart:io`'s files, directories, links and
/// processes — every method that has an asynchronous twin, listed by name:
/// a pattern for any `...Sync(` would catch `changedBySync` and the like.
final RegExp _syncCall = RegExp(
  r'(\.(existsSync|statSync|listSync|readAsStringSync|readAsBytesSync|'
  'readAsLinesSync|writeAsStringSync|writeAsBytesSync|createSync|'
  'createTempSync|deleteSync|renameSync|copySync|lengthSync|'
  'lastModifiedSync|lastAccessedSync|setLastModifiedSync|setLastAccessedSync|'
  'openSync|resolveSymbolicLinksSync|typeSync|isDirectorySync|isFileSync|'
  'isLinkSync|identicalSync|readSync|readIntoSync|readByteSync|writeFromSync|'
  'writeByteSync|setPositionSync|positionSync|truncateSync|flushSync|'
  r'closeSync|lockSync|unlockSync|targetSync|updateSync)\('
  r'|Process\.runSync\()',
);

void main() {
  final sources = p.join('lib', 'src');
  final calls = <String, List<String>>{};
  for (final entity in Directory(sources).listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart')) continue;
    final rel = p.posix.joinAll(
      p.split(p.relative(entity.path, from: sources)),
    );
    for (final (i, line) in entity.readAsLinesSync().indexed) {
      if (line.trimLeft().startsWith('//')) continue;
      if (_syncCall.hasMatch(line)) {
        (calls[rel] ??= []).add('lib/src/$rel:${i + 1}: ${line.trim()}');
      }
    }
  }

  test('no synchronous file call outside the files that run them on a '
      'background isolate', () {
    final offenders = [
      for (final MapEntry(key: file, value: lines) in calls.entries)
        if (!_offTheUiIsolate.containsKey(file)) ...lines,
    ];
    expect(
      offenders,
      isEmpty,
      reason:
          'a synchronous file call blocks the UI isolate on a FUSE round '
          "trip (#1143): use the asynchronous call or the caller's "
          'Isolate.run — or, when it runs on a background isolate, list its '
          'file in this test with where it runs',
    );
  });

  test('every file on the list still makes a synchronous call', () {
    final stale = [
      for (final file in _offTheUiIsolate.keys)
        if (!calls.containsKey(file)) file,
    ];
    expect(stale, isEmpty, reason: 'take the files that no longer do off');
  });
}
