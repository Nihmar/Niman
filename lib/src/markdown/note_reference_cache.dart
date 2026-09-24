/// A note's tags and links, kept block by block while it is edited, so a
/// save hands them to the index instead of the index reading the whole
/// note for them.
///
/// Reading them is 5.1 s of the 247 MB stress note's reindex
/// (`docs/dev/huge-notes.md`, item 8), and a save changes a few blocks of
/// its 2 M. So the references are kept per block, in step with the
/// editor's block scan: its record of what the edits did to the block list
/// ([BlockScanner.takeChanges], a reader of its own) says which entries
/// are gone and which are new, the new ones are read when asked, and every
/// other one is what it was.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_changes.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart' show BlockScanner;
import 'package:niman/src/markdown/note_references.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The references of each block of a note, in the block list's order.
final class NoteReferenceCache {
  /// Holds nothing: [references] answers null until [adopt].
  new();

  /// One entry per block, null where the block is new since it was read;
  /// null as a whole when there is nothing to keep up with.
  List<BlockReferences?>? _entries;

  /// Whether the references are being kept.
  bool get kept => _entries != null;

  /// Takes [entries], the references of the block list as it stands when
  /// the record of its changes starts — a list of its own, which the
  /// changes splice.
  void adopt(Iterable<BlockReferences?> entries) =>
      _entries = List<BlockReferences?>.of(entries);

  /// Stops keeping them: the edits changed more than is worth following
  /// ([BlockChanges.limit]), and the reindex reads the note instead.
  void drop() => _entries = null;

  /// Follows [changes], what the edits did to the block list since the
  /// last call: the entries of the blocks they replaced go, and the blocks
  /// that replaced them have none until they are read.
  void follow(BlockChanges changes) {
    final entries = _entries;
    if (entries == null) return;
    final stretches = changes.stretches;
    if (stretches == null) {
      drop();
      return;
    }
    for (final stretch in stretches) {
      entries.replaceRange(
        stretch.start,
        stretch.start + stretch.removed,
        List<BlockReferences?>.filled(stretch.inserted, null),
      );
    }
  }

  /// Forgets what the note's link definitions decided: the blocks whose
  /// Markdown links were parsed with them are read again.
  void definitionsChanged() {
    final entries = _entries;
    if (entries == null) return;
    for (var at = 0; at < entries.length; at++) {
      if (entries[at]?.scoped ?? false) entries[at] = null;
    }
  }

  /// The note's references, with the blocks [blocks] of [buffer] — the list
  /// the changes followed so far lead to — or null when they are not kept
  /// or do not match it.
  ///
  /// Reads the blocks that are new since they were last read, and no other.
  NoteReferences? references(
    List<Block> blocks,
    SourceBuffer buffer,
    BlockParser parser,
    DocumentScope Function() scope,
  ) {
    final entries = _entries;
    if (entries == null) return null;
    if (entries.length != blocks.length) {
      // A record that does not lead to the list is no record of it.
      drop();
      return null;
    }
    for (var at = 0; at < entries.length; at++) {
      if (entries[at] != null) continue;
      entries[at] = blockReferencesOf(blocks[at], buffer, parser, scope);
      blocksRead++;
    }
    return collectReferences(entries.cast<BlockReferences>());
  }

  /// How many blocks [references] has read, for the test that proves a
  /// save reads the blocks the edits changed and not the note.
  @visibleForTesting
  int blocksRead = 0;

  /// The references of every one of [blocks], read now: what a note's
  /// cache starts with. O(note) — on an isolate, for the notes it is kept
  /// for.
  static List<BlockReferences?> readAll(
    List<Block> blocks,
    SourceBuffer buffer,
    DocumentScope scope,
  ) {
    final parser = BlockParser();
    return [
      for (final block in blocks)
        blockReferencesOf(block, buffer, parser, () => scope),
    ];
  }
}
