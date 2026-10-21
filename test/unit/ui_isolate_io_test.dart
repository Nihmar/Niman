// No synchronous file call on the UI isolate (AGENTS.md, #1143): on Android
// every `statSync` or `listSync` is a round trip through FUSE, and the frame
// waits for it. The rule had exceptions nobody had listed; this lists where
// the synchronous calls are allowed — files whose calls all run on a
// background isolate — and says where each runs. A synchronous call in any
// other file is either moved off the UI isolate (the asynchronous call, or
// the `Isolate.run` its caller makes) or its file joins this list, with the
// isolate it runs on: a decision, not an accident.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// The files whose synchronous file calls run off the UI isolate, and where.
const Map<String, String> _offTheUiIsolate = {
  'annotations/companion_notes.dart': "the listing in freshIn's Isolate.run",
  'calendar/calendar_store.dart': 'the reads its Isolate.run calls',
  'core/download/download_files.dart': 'the scan and deletes it Isolate.runs',
  'core/download/file_download.dart': "the download's spawned isolate",
  'core/files.dart':
      'the sweep, the name check and the hash run in isolates; '
      'DiskStamp.of is the synchronous form for them (ofAsync for the UI)',
  'core/library_state_file.dart': 'the load its Isolate.run calls',
  'db/index_note_content.dart': 'the note reads of the reader isolate',
  'db/index_scan.dart': 'the walk, the listing and the probes, in isolates',
  'epub/epub_document.dart': 'readEpub, in its Isolate.run',
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
  'home/note_preview.dart': 'the preview read, in Isolate.run',
  'library/attachment_store.dart': 'the copy its Isolate.run calls',
  'library/audio_import.dart': 'the copy and the rename, in Isolate.run',
  'library/markdown_import.dart': 'the import, in IsolateGauge.run',
  'library/note_ops.dart': 'the outline and preview reads, in isolates',
  'library/note_tidy.dart': 'the tidy read, in Isolate.run',
  'library/note_write_stream.dart': "the stream writer's spawned isolate",
  'library/note_writer.dart': 'replaceFileFrom and writeNoteFile, isolates',
  'library/wav_duration.dart': 'the probe, in Isolate.run',
  'links/link_spot_slices.dart': 'the slice read, in Isolate.run',
  'markdown/note_load.dart': 'loadNoteSync, in Isolate.run',
  'search/replace.dart': 'the preview and replace chunks, in Isolate.run',
  'spellcheck/hunspell_spell_checker.dart':
      'the dictionary search and load, in Isolate.run',
  'sync/sync_scanner.dart': 'scanLocalFiles, in Isolate.run',
  'sync/sync_service.dart': "the watcher batch's probe, in Isolate.run",
  'sync/sync_sides.dart': 'hashLocalFiles, in Isolate.run',
  'todo/todo_store.dart': 'the reads and probes its Isolate.run calls',
  'ui/drop_target.dart': 'foldersAmong, in Isolate.run',
  'ui/file_tree_context.dart': 'the exists check, in Isolate.run',
  'ui/kinds/flashcards/review_run.dart': 'the deck reads, in Isolate.run',
  'ui/known_library_list.dart': 'the folder checks, in Isolate.run',
  'ui/theme/theme_files.dart': 'the theme read, in Isolate.run',
  'widget/widget_note_ops.dart': 'the note read, in Isolate.run',
};

final RegExp _syncCall = RegExp(
  r'\.(existsSync|statSync|listSync|readAsStringSync|readAsBytesSync|'
  'readAsLinesSync|writeAsStringSync|writeAsBytesSync|createSync|'
  'deleteSync|renameSync|copySync|lengthSync|lastModifiedSync|'
  'setLastModifiedSync|openSync|resolveSymbolicLinksSync|typeSync|'
  r'isDirectorySync|isFileSync|isLinkSync|identicalSync)\(',
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
