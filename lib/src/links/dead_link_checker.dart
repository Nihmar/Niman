/// Which links name nothing (#847), asked a batch at a time.
library;

import 'package:niman/src/links/index_changes.dart';
import 'package:niman/src/links/link_path.dart';
import 'package:niman/src/links/resolver.dart';

/// Tells which of a note's links are dead.
abstract interface class DeadLinkSource implements IndexChanges {
  /// The links among [queries] that name nothing (#847): a wiki target or a
  /// Markdown path to a file the library does not hold. Judged at the note
  /// (or file) level only — what follows a `#` is not asked — and in one
  /// batch ([LinkResolver.resolveQueries]), however many links there are.
  ///
  /// A link that is not a path to a file is never dead: a URL, a `#anchor`,
  /// an href with no extension (which is not followed either). A name that
  /// several notes share is not dead; it is ambiguous.
  Future<Set<LinkQuery>> deadAmong(Iterable<LinkQuery> queries);
}

/// [DeadLinkSource] over the resolver's batched lookups.
final class DeadLinkChecker implements DeadLinkSource {
  /// Asks [_resolver]; [_changes] is the library's announcement that its
  /// index moved.
  const new(this._resolver, {this._changes});

  final LinkResolver _resolver;
  final Stream<void>? _changes;

  @override
  Stream<void> get changes => _changes ?? const Stream<void>.empty();

  @override
  Future<Set<LinkQuery>> deadAmong(Iterable<LinkQuery> queries) async {
    final asked = <LinkQuery>{
      for (final query in queries)
        if (_namesAFile(query)) query,
    };
    if (asked.isEmpty) return const <LinkQuery>{};
    final resolved = await _resolver.resolveQueries(asked);
    return {
      for (final MapEntry(:key, :value) in resolved.entries)
        if (value is UnresolvedNote) key,
    };
  }

  /// Whether [query] is a link to a file the library could hold: a wiki
  /// target with something in it, or a Markdown path that is not a URL, an
  /// anchor or an extension-less href.
  static bool _namesAFile(LinkQuery query) {
    final target = query.target.trim();
    if (target.isEmpty) return false;
    if (!query.markdown) return true;
    return !LinkPaths.hasScheme(target) &&
        !target.startsWith('#') &&
        LinkPaths.markdownPath(target) != null;
  }
}
