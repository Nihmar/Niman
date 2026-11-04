import 'dart:io';
import 'dart:typed_data';

import 'package:niman/src/core/isolate_gauge.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/note_ops_blocking.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/links/link_preview.dart';
import 'package:niman/src/links/link_spot_slices.dart';
import 'package:niman/src/markdown/note_bytes.dart';
import 'package:path/path.dart' as p;

/// Reads the notes of the library: the text and the bytes whole, and the
/// parts a panel or a card shows — headings, block anchors, a preview, the
/// links of a slice — read where the note lies, off the UI isolate.
///
/// Each read asks the index for the note first ([find]), so a path the
/// library does not hold throws rather than reading whatever is on disk.
final class NoteReads {
  /// Creates the reads of the library at [root].
  new({required this.root, required this.find});

  /// Absolute path of the library root.
  final String root;

  /// The indexed row at a path; throws when there is none.
  final Future<Note> Function(String path) find;

  /// The absolute path for library-relative [rel] ('' = root).
  String _abs(String rel) => p.join(root, rel);

  /// The text of the note at [path], decoded leniently (a note with a
  /// broken byte is still a note) and without its BOM.
  Future<String> readNote(String path) async {
    final bytes = await readNoteBytes(path);
    final text = decodeNoteText(bytes);
    return text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF
        ? text.substring(1)
        : text;
  }

  /// The note's bytes as the file holds them.
  Future<Uint8List> readNoteBytes(String path) async {
    await find(path);
    return await File(_abs(path)).readAsBytes();
  }

  /// The headings of the note at [path], read and outlined where the note
  /// lies — off the UI isolate (#491).
  ///
  /// The wikilink panel's rows after `#` are the note's whole outline, and
  /// getting them means reading, decoding and walking the file: seconds on
  /// a novel-length note, per keystroke if the panel paid it on the UI
  /// isolate. The panel keeps the answer per revision, so this runs once
  /// per target and not once per key.
  Future<List<String>> noteHeadings(String path) async {
    await find(path);
    final abs = _abs(path);
    return await IsolateGauge.run(
      () => headingsOfNoteFile(abs),
      'headings "$path"',
    );
  }

  /// The block anchors of the note at [path] — its blocks that end with a
  /// ` ^id` (#844) — read and walked where the note lies, off the UI isolate,
  /// as [noteHeadings] reads the headings.
  Future<List<BlockAnchor>> noteBlocks(String path) async {
    await find(path);
    final abs = _abs(path);
    return await IsolateGauge.run(
      () => blocksOfNoteFile(abs),
      'blocks "$path"',
    );
  }

  /// The beginning of the note at [path] for a preview card (#846): its first
  /// [PreviewLimits.bytes] bytes, read and decoded where the note lies, off
  /// the UI isolate. A novel-length note is not read whole to show a card.
  Future<NotePreviewText> notePreview(String path) async {
    await find(path);
    final abs = _abs(path);
    return await IsolateGauge.run(
      () => previewTextOfNoteFile(abs),
      'preview "$path"',
    );
  }

  /// The links and embeds of the slice of the note at [path] that starts at
  /// [from] — what a list of the notes that link to another reads a mention
  /// from (#842) — read, decoded and parsed where the note lies, off the UI
  /// isolate. A slice at a time, so the first mention costs a slice and not
  /// the note (#1040).
  Future<SpotSlice> noteLinkSpotSlice(String path, SpotCursor from) async {
    await find(path);
    final abs = _abs(path);
    return await IsolateGauge.run(
      () => linkSpotSliceOfFile(abs, from),
      'link spots "$path"',
    );
  }
}
