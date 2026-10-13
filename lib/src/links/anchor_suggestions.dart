/// The headings and block ids the wikilink panel offers after `#`, `#^`,
/// `##` and `^^` (#844, #845).
///
/// A named note's own are read off its file — outlined or scanned off the UI
/// isolate, once per revision of it (#491) — and the whole library's come from
/// the word index (`AnchorIndex`), never a scan of the notes.
library;

import 'package:niman/src/db/anchor_index.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/links/note_names.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/links/revision_cache.dart';
import 'package:niman/src/links/suggestion.dart';

/// Headings and block ids, a note's and the library's.
final class AnchorSuggestions {
  /// Reads a note named by [_source], its file through [readHeadings] and
  /// [readBlocks] (the session's own, off the UI isolate; null when the note
  /// is gone, or no block read at all); the library's through [_index], their
  /// notes named by [_names].
  new(
    this._source,
    this._index,
    this._names, {
    required this.readHeadings,
    this.readBlocks,
  });

  final LinkSource _source;
  final AnchorIndex _index;
  final NoteNames _names;

  /// The headings of a library-relative note path, in document order, or
  /// null when it is gone. The whole note is read, decoded and walked, so
  /// the implementation runs it off the UI isolate.
  final Future<List<String>?> Function(String path) readHeadings;

  /// The block anchors of a library-relative note path, in line order, or
  /// null when it is gone: read the way [readHeadings] reads.
  final Future<List<BlockAnchor>?> Function(String path)? readBlocks;

  /// The headings already read, by note and revision. A run of keystrokes
  /// after `#` names the same target each time and the panel filters the
  /// list locally, so one read answers them all; only the note's own
  /// revision (its mtime and size, as the index records it) can make the
  /// list stale.
  final RevisionCache<HeadingSuggestion> _headingsByNote =
      RevisionCache<HeadingSuggestion>();

  /// The block ids already read, by the same key.
  final RevisionCache<BlockIdSuggestion> _blocksByNote =
      RevisionCache<BlockIdSuggestion>();

  /// The headings of the note the wiki [target] names.
  Future<List<HeadingSuggestion>> headings(String target) async {
    final note = await noteNamed(_source, target);
    if (note == null) return const <HeadingSuggestion>[];
    return await _headingsByNote.of(note, () async {
      final texts = await readHeadings(note.path);
      return texts == null ? null : HeadingSuggestion.linkable(texts);
    });
  }

  /// The block ids of the note the wiki [target] names.
  Future<List<BlockIdSuggestion>> blocks(String target) async {
    final note = await noteNamed(_source, target);
    final read = readBlocks;
    if (note == null || read == null) return const <BlockIdSuggestion>[];
    return await _blocksByNote.of(note, () async {
      final anchors = await read(note.path);
      return anchors == null
          ? null
          : [
              for (final anchor in anchors)
                BlockIdSuggestion(anchor.id, excerpt: anchor.excerpt),
            ];
    });
  }

  /// The headings of the whole library that match [query], each with the
  /// note it is in.
  Future<List<HeadingSuggestion>> headingsAcross(String query) async {
    final hits = await _index.headings(query, limit: NoteNames.limit * 2);
    final targets = await _names.targetsOf({for (final hit in hits) hit.path});
    return [
      for (final hit in hits)
        if (HeadingSuggestion.readsBack(hit.heading) &&
            targets[hit.path] != null)
          HeadingSuggestion(
            hit.heading,
            path: hit.path,
            target: targets[hit.path],
          ),
    ].take(NoteNames.limit).toList(growable: false);
  }

  /// The block ids of the whole library that match [query].
  Future<List<BlockIdSuggestion>> blocksAcross(String query) async {
    final hits = await _index.blocks(query, limit: NoteNames.limit * 2);
    final targets = await _names.targetsOf({for (final hit in hits) hit.path});
    return [
      for (final hit in hits)
        if (targets[hit.path] != null)
          BlockIdSuggestion(
            hit.blockId,
            excerpt: hit.excerpt,
            path: hit.path,
            target: targets[hit.path],
          ),
    ].take(NoteNames.limit).toList(growable: false);
  }
}
