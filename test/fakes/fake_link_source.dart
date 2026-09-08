import 'package:copist/src/db/database.dart';
import 'package:copist/src/links/resolver.dart';

/// In-memory [LinkSource] for widget tests: resolves wiki targets and md
/// hrefs against a note list, in library-relative paths.
///
/// `target.md` and `dir/target.md` styles resolve against [notes]; a target
/// whose basename matches several notes is ambiguous; everything else is
/// unresolved. External URLs stay external.
final class FakeLinkSource implements LinkSource {
  /// Creates a fake source over [notes] (library-relative paths).
  FakeLinkSource({List<String>? notes}) : notes = notes ?? [];

  /// The known note paths (library-relative, `.md` included).
  List<String> notes;

  /// Records every resolution, in order (for tap assertions).
  final List<String> queries = [];

  Note _noteFor(String path) => Note(
    id: path.hashCode & 0x7fffffff,
    path: path,
    parent: 0,
    name: path.split('/').last,
    isDir: false,
    size: 0,
    modified: DateTime.fromMillisecondsSinceEpoch(0),
  );

  @override
  Future<ResolveResult> resolveWiki(String target) async {
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
  Future<ResolveResult> resolveMarkdown(String href) async {
    queries.add('md:$href');
    final h = href.trim();
    if (h.startsWith('http://') || h.startsWith('https://')) {
      return ExternalLink(url: h);
    }
    if (h.startsWith('#')) return LocalAnchor(heading: h.substring(1));
    return resolveWiki(h.replaceAll('.md', ''));
  }

  static String _stemOf(String path) {
    final name = path.split('/').last.toLowerCase();
    return name.endsWith('.md') ? name.substring(0, name.length - 3) : name;
  }
}
