import 'dart:async';

import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/mentions.dart';
import 'package:niman/src/links/resolver.dart';

/// In-memory [LinkSource] for widget tests: resolves wiki targets and md
/// hrefs against a note list, in library-relative paths.
///
/// `target.md` and `dir/target.md` styles resolve against [notes]; a target
/// whose basename matches several notes is ambiguous; everything else is
/// unresolved. External URLs stay external.
final class FakeLinkSource implements LinkSource {
  /// Creates a fake source over [notes] (library-relative paths).
  new({List<String>? notes}) : notes = notes ?? [];

  /// The known note paths (library-relative, `.md` included).
  List<String> notes;

  /// Records every resolution, in order (for tap assertions).
  final List<String> queries = [];

  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// The library's index moved: what a test announces after it changes
  /// [notes], so the links drawn dead are resolved again.
  void announceChange() => _changes.add(null);

  /// How many batches [deadAmong] has been asked for.
  int deadChecks = 0;

  /// The notes that link to a note, by its path: what [referrersOf] answers.
  final Map<String, List<String>> referrers = <String, List<String>>{};

  /// What a referrer says about a note, by `referrer -> note`: what
  /// [mentionIn] answers (nothing readable for a pair not given).
  final Map<String, Mention> mentions = <String, Mention>{};

  /// Every `referrer -> note` pair [mentionIn] was asked for, in order.
  final List<String> mentionReads = <String>[];

  /// While set, [mentionIn] waits for it: a row still being read.
  Completer<void>? mentionGate;

  @override
  Future<Referrers> referrersOf(String path) async {
    final found = referrers[path] ?? const <String>[];
    return Referrers([
      for (final referrer in found)
        Referrer(path: referrer, kinds: const <String>['wiki']),
    ]);
  }

  @override
  Future<Mention> mentionIn(String referrerPath, String path) async {
    mentionReads.add('$referrerPath -> $path');
    await mentionGate?.future;
    return mentions['$referrerPath -> $path'] ?? Mention.unread;
  }

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<Set<LinkQuery>> deadAmong(Iterable<LinkQuery> queries) async {
    deadChecks++;
    final dead = <LinkQuery>{};
    for (final query in queries) {
      final target = query.target.trim();
      if (target.isEmpty) continue;
      if (query.markdown &&
          (target.startsWith('#') ||
              target.contains('://') ||
              !target.contains('.'))) {
        continue;
      }
      final result = query.markdown
          ? await resolveMarkdown(target, from: query.from)
          : await resolveWiki(target, from: query.from);
      if (result is UnresolvedNote) dead.add(query);
    }
    return dead;
  }

  Note _noteFor(String path) => Note(
    id: path.hashCode & 0x7fffffff,
    path: path,
    parent: 0,
    name: path.split('/').last,
    isDir: false,
    size: 0,
    modified: DateTime.fromMillisecondsSinceEpoch(0),
    created: DateTime.fromMillisecondsSinceEpoch(0),
    pinned: false,
  );

  @override
  Future<ResolveResult> resolveWiki(String target, {String? from}) async {
    queries.add('wiki:$target');
    final t = target.trim().toLowerCase();
    if (t.isEmpty) return UnresolvedNote(target: target);
    final stem = t.contains('/') ? t.substring(t.lastIndexOf('/') + 1) : t;
    final matches = [
      for (final path in notes)
        if (_stemOf(path) == stem) path,
    ];
    if (matches.length == 1) {
      return ResolvedNote(note: _noteFor(matches.single));
    }
    if (matches.length > 1) {
      return AmbiguousNote(candidates: [for (final m in matches) _noteFor(m)]);
    }
    return UnresolvedNote(target: target);
  }

  @override
  Future<ResolveResult> resolveMarkdown(String href, {String? from}) async {
    queries.add('md:$href');
    final h = href.trim();
    if (h.startsWith('http://') || h.startsWith('https://')) {
      return ExternalLink(url: h);
    }
    if (h.startsWith('#')) return LocalAnchor(heading: h.substring(1));
    final hash = h.indexOf('#');
    if (hash > 0) {
      // The fragment rides on the note it follows, as the resolver has it.
      final path = await resolveWiki(
        h.substring(0, hash).replaceAll('.md', ''),
      );
      return path is ResolvedNote
          ? ResolvedNote(note: path.note, heading: h.substring(hash + 1))
          : path;
    }
    return await resolveWiki(h.replaceAll('.md', ''));
  }

  static String _stemOf(String path) {
    final name = path.split('/').last.toLowerCase();
    return name.endsWith('.md') ? name.substring(0, name.length - 3) : name;
  }
}
