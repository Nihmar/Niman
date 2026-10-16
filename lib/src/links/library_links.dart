/// What the open library's links offer the UI, as one object (#842, #846,
/// #847).
///
/// Four focused readers over one index — resolution, dead links, the notes
/// that link to a note, previews — each behind its own interface, so a
/// surface asks for only the one it uses; [LibraryLinks] is the bundle the
/// session hands out, one per open library, so the caches the readers keep
/// are shared by every surface that asks.
library;

import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/dead_link_checker.dart';
import 'package:niman/src/links/link_preview.dart';
import 'package:niman/src/links/link_spot_slices.dart';
import 'package:niman/src/links/mention_reader.dart';
import 'package:niman/src/links/mentions.dart';
import 'package:niman/src/links/preview_reader.dart';
import 'package:niman/src/links/resolver.dart';

/// The library's links: the four readers in one.
abstract interface class LibraryLinks
    implements LinkSource, DeadLinkSource, MentionSource, PreviewSource;

/// [LibraryLinks] over the library's index; each call goes to the reader
/// that owns it.
final class IndexLibraryLinks implements LibraryLinks {
  /// Bundles the readers over [db]. [changes] is the library's announcement
  /// that its index moved; [readSpots] and [readPreview] read a note's links
  /// and its first bytes off the UI isolate (null reads none).
  factory(
    IndexDatabase db, {
    Stream<void>? changes,
    Future<SpotSlice?> Function(String path, SpotCursor from)? readSpots,
    Future<NotePreviewText?> Function(String path)? readPreview,
  }) {
    final resolver = LinkResolver(db);
    return IndexLibraryLinks.of(
      resolver: resolver,
      dead: DeadLinkChecker(resolver, changes: changes),
      mentions: MentionReader(
        db,
        resolver,
        readSpots: readSpots,
        changes: changes,
      ),
      previews: PreviewReader(db, read: readPreview),
    );
  }

  /// Bundles readers made apart (a test's).
  const new of({
    required this._resolver,
    required this._dead,
    required this._mentions,
    required this._previews,
  });

  final LinkResolver _resolver;
  final DeadLinkChecker _dead;
  final MentionReader _mentions;
  final PreviewReader _previews;

  @override
  Future<ResolveResult> resolveWiki(String target, {String? from}) =>
      _resolver.resolveWiki(target, from: from);

  @override
  Future<ResolveResult> resolveMarkdown(String href, {String? from}) =>
      _resolver.resolveMarkdown(href, from: from);

  @override
  Stream<void> get changes => _dead.changes;

  @override
  Future<Set<LinkQuery>> deadAmong(Iterable<LinkQuery> queries) =>
      _dead.deadAmong(queries);

  @override
  Future<Referrers> referrersOf(String path, {int? after}) =>
      _mentions.referrersOf(path, after: after);

  @override
  Future<Mention> mentionIn(String referrerPath, String path) =>
      _mentions.mentionIn(referrerPath, path);

  @override
  Future<NotePreviewText?> previewText(String path) =>
      _previews.previewText(path);
}
