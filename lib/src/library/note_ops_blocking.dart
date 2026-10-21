import 'dart:io';
import 'dart:typed_data';

import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/links/note_preview_text.dart';
import 'package:niman/src/links/preview_limits.dart';
import 'package:niman/src/markdown/note_bytes.dart';
import 'package:path/path.dart' as p;

// The reads of `NoteOps` that block: each runs on a background isolate
// (every `existsSync`, `listSync` or `readSync` is a FUSE round trip on
// Android, #1143), which `ui_isolate_io_test.dart` holds this file to.

/// [NoteOperations.markdownOnDisk]'s listing, for a background isolate: the
/// existence check, the listing and a stat per file are each a FUSE round
/// trip on Android (#1143).
List<DiskNoteStamp> markdownFilesIn(String root, String folder) {
  final dir = Directory(folder.isEmpty ? root : p.join(root, folder));
  if (!dir.existsSync()) return const [];
  return [
    for (final entry in dir.listSync())
      if (entry is File && entry.path.toLowerCase().endsWith('.md'))
        if (entry.statSync() case final stat)
          (
            path: p.relative(entry.path, from: root).replaceAll(r'\', '/'),
            size: stat.size,
            modified: stat.modified,
          ),
  ];
}

String _noteTextAt(String path) {
  final bytes = File(path).readAsBytesSync();
  var text = decodeNoteText(bytes);
  if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
    text = text.substring(1);
  }
  return text;
}

/// The heading texts of the note file at absolute [path], read as it lies.
///
/// The whole file is read, decoded — leniently, without its BOM, as
/// `NoteOps.readNote` does — and walked for its headings, so this is work
/// for a background isolate (`IsolateGauge.run`), never the UI's (#491).
List<String> headingsOfNoteFile(String path) {
  return [for (final heading in outlineOfText(_noteTextAt(path))) heading.text];
}

/// The block anchors of the note file at absolute [path] (#844), read as
/// [headingsOfNoteFile] reads: work for a background isolate.
List<BlockAnchor> blocksOfNoteFile(String path) =>
    blockAnchorsOfText(_noteTextAt(path));

/// The first [PreviewLimits.bytes] bytes of the note file at absolute [path],
/// decoded as a note is, its BOM off and its line endings `\n` (#846): work
/// for a background isolate.
NotePreviewText previewTextOfNoteFile(String path) {
  final file = File(path).openSync();
  List<int> head;
  final bool truncated;
  try {
    head = file.readSync(PreviewLimits.bytes);
    truncated = file.lengthSync() > PreviewLimits.bytes;
  } finally {
    file.closeSync();
  }
  // A cut inside a UTF-8 sequence would send the whole head to the
  // Latin-1-mixed decoder: it is backed up to the last whole one.
  if (truncated) head = head.sublist(0, utf8CompleteUpTo(head));
  var text = decodeNoteText(Uint8List.fromList(head));
  if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
    text = text.substring(1);
  }
  return NotePreviewText(
    text: text.replaceAll('\r\n', '\n').replaceAll('\r', '\n'),
    truncated: truncated,
  );
}
