/// The notes that link to a note and what each says (#842), over the index.
library;

import 'package:meta/meta.dart' show visibleForTesting;
import 'package:niman/src/core/lru_cache.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/index_changes.dart';
import 'package:niman/src/links/mentions.dart';
import 'package:niman/src/links/resolver.dart';

/// Lists who links to a note and reads what they say.
abstract interface class MentionSource implements IndexChanges {
  /// The notes that link to the note at library-relative [path] (#842): who
  /// names it, by a link or an embed, a page at a time in path order — the
  /// page after the cursor [after] (null for the first). Empty when the note
  /// is not in the index; [Referrers.next] says where the next page starts.
  Future<Referrers> referrersOf(String path, {int? after});

  /// What the note at [referrerPath] says about the note at [path]: the line
  /// of its first mention, whether that is an embed, and how many there are.
  /// Read from the referrer's text when asked, once for each revision of it;
  /// [Mention.unread] when the text no longer names the note.
  Future<Mention> mentionIn(String referrerPath, String path);
}

/// [MentionSource] over the `note_links` edges and the referrers' files.
final class MentionReader implements MentionSource {
  /// Reads the edges of [_db], finds mentions with [_resolver] in the links
  /// [_readSpots] gives for a note (off the UI isolate; null reads none), and
  /// forwards the library's [_changes].
  new(this._db, this._resolver, {this._readSpots, this._changes});

  final IndexDatabase _db;
  final LinkResolver _resolver;
  final Future<List<LinkSpot>?> Function(String path)? _readSpots;
  final Stream<void>? _changes;

  /// How many mentions are kept: a list scrolled through a long way, once
  /// each, and no more than this many.
  static const int kept = 256;

  /// How many referrers one page of the notes that link to a note holds.
  static const int referrersShown = 200;

  /// The mentions read, by the referrer, the note it names and the
  /// referrer's revision (its mtime and size, as the index records it).
  final LruCache<(int, int, DateTime, int), Mention> _mentions =
      LruCache<(int, int, DateTime, int), Mention>(kept);

  /// How many mentions are kept now, for the test that holds the cache to
  /// [kept].
  @visibleForTesting
  int get held => _mentions.length;

  @override
  Stream<void> get changes => _changes ?? const Stream<void>.empty();

  @override
  Future<Referrers> referrersOf(String path, {int? after}) async {
    final dao = NoteDao(_db);
    final target = await dao.find(path);
    if (target == null) return Referrers.none;
    final found = await dao.referrers.page(
      target.id,
      limit: referrersShown,
      after: after ?? 0,
    );
    return Referrers([
      for (final r in found.items)
        Referrer(
          path: r.path,
          kinds: r.kinds,
          modified: r.modified,
          size: r.size,
        ),
    ], next: found.next);
  }

  @override
  Future<Mention> mentionIn(String referrerPath, String path) async {
    final read = _readSpots;
    final dao = NoteDao(_db);
    final referrer = await dao.find(referrerPath);
    final target = await dao.find(path);
    if (read == null || referrer == null || target == null) {
      return Mention.unread;
    }
    final key = (referrer.id, target.id, referrer.modified, referrer.size);
    final kept = _mentions[key];
    if (kept != null) return kept;
    final spots = await read(referrerPath);
    if (spots == null) return Mention.unread;
    final resolved = await _resolver.resolveQueries({
      for (final spot in spots)
        (target: spot.target, from: referrerPath, markdown: spot.markdown),
    });
    final named = <LinkSpot>[
      for (final spot in spots)
        if (resolved[(
              target: spot.target,
              from: referrerPath,
              markdown: spot.markdown,
            )]
            case ResolvedNote(:final note) when note.id == target.id)
          spot,
    ];
    final Mention mention;
    if (named.isEmpty) {
      mention = Mention.unread;
    } else {
      // A link shows the referrer before an embed does.
      final shown = named.firstWhere(
        (s) => !s.embed,
        orElse: () => named.first,
      );
      mention = Mention(
        context: shown.context,
        line: shown.line,
        embed: shown.embed,
        count: named.length,
      );
    }
    _mentions[key] = mention;
    return mention;
  }
}
