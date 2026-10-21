/// How a link target is read: the text a wikilink or a Markdown link was
/// written with, turned into the path it names (design.md: links/resolver.dart).
///
/// Pure functions over text, no index: the resolver asks the index what they
/// say, the indexer and the suggester use the same rules to write and to read
/// a target, so what one writes is what the other resolves.
library;

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/percent.dart';
import 'package:path/path.dart' as p;

/// A link target read: `t` the normalized path (lowercased, `.md` dropped,
/// `.` and `..` walked), `heading` its `#fragment`, and how `t` is matched.
///
/// `exact` — the target names one whole path, from the root (a leading `/`
/// or a `..`); otherwise it is a tail, matched wherever it sits. `near` — a
/// whole path to try first, the one beside the note a Markdown link is
/// written in. An empty `t` is the note itself (`#heading`).
typedef LinkSpec = ({String t, String? heading, bool exact, String? near});

/// A Markdown href read: the file it names, percent-decoded, and the
/// `#fragment` after it (without the `#`), null when absent: a note's
/// heading percent-decoded as the path is, any other file's place as
/// written.
///
/// Kept apart, never joined in one string: a decoded `%23` is a `#` of the
/// file's name, and a string that was split again would cut inside it.
typedef MarkdownTarget = ({String path, String? fragment});

/// The link-path rules, in one place.
abstract final class LinkPaths {
  /// The href [h] (trimmed, no scheme, not an anchor) as a target to
  /// resolve: split at its first `#` as written, then its path percent-
  /// decoded, as Obsidian writes a Markdown link (`My%20Note.md`, and
  /// `C%23%20tips.md` for `C# tips.md`).
  ///
  /// The fragment of a link to a note is a heading, and is percent-decoded
  /// like the path (`#The%20Storm`, as Obsidian and the EPUB conversion
  /// write one): the heading lookup slugs it, and an escape would never
  /// match. Any other file's fragment is a place in it (#282), left as
  /// written for `BookLocation.fromFragment` to decode its own parts —
  /// decoded here, a `%26` in a chapter's name would split the place.
  /// Null when it names no file (no extension). Opening a link and
  /// indexing it read it through this one function.
  static MarkdownTarget? markdownTarget(String h) {
    final hash = h.indexOf('#');
    final path = percentDecoded(hash == -1 ? h : h.substring(0, hash));
    if (p.url.extension(path).isEmpty) return null;
    if (hash == -1) return (path: path, fragment: null);
    final fragment = h.substring(hash + 1);
    return (
      path: path,
      fragment: isMarkdownNote(path) ? percentDecoded(fragment) : fragment,
    );
  }

  /// The heading a Markdown `#fragment`-only href [h] (`#The%20Storm`, its
  /// `#` included) names in the note it is written in: percent-decoded, as
  /// the fragment of a link to another note is ([markdownTarget]).
  static String localHeading(String h) => percentDecoded(h.substring(1));

  /// Whether the note at [path] is one a target naming [target] — already
  /// normalized, `.md` dropped (`folder/note`) — qualifies among the notes
  /// that share its stem: the whole path, or its tail after a `/`.
  ///
  /// For a `.md` note the target's extension was stripped, so the note is
  /// matched as `$target.md`; a non-md target (an embed, `foo.png`) keeps
  /// its extension and matches as it is. The suggester (#475) writes the
  /// shortest target this admits for exactly one note, so what it writes is
  /// what this resolves.
  ///
  /// A Windows device stem answers as it is and as `sanitizeName` moved it
  /// aside: the note `[[Aux]]` creates is `_Aux.md`, and the link has to
  /// find it (#491).
  ///
  /// With [exact] the target is the whole path and nothing else qualifies:
  /// what a leading `/` or a `..` names (#491).
  static bool pathMatches(String path, String target, {bool exact = false}) {
    final lower = path.toLowerCase();
    for (final t in _targetVariants(target)) {
      final withMd = '$t.md';
      if (lower == t || lower == withMd) return true;
      if (!exact && (lower.endsWith('/$t') || lower.endsWith('/$withMd'))) {
        return true;
      }
    }
    return false;
  }

  /// [target] and, when its last segment's stem names a Windows device, the
  /// same target with that segment moved aside (`Aux` → `_Aux`): the name
  /// the file the app created for it has.
  static Iterable<String> _targetVariants(String target) sync* {
    yield target;
    final cut = target.lastIndexOf('/');
    final segment = cut == -1 ? target : target.substring(cut + 1);
    final moved = withoutReservedStem(segment);
    if (moved != segment) {
      yield cut == -1 ? moved : '${target.substring(0, cut + 1)}$moved';
    }
  }

  /// Whether [s] starts with a URI scheme: `https://`, but `mailto:` and
  /// `tel:` too, which carry no `//` (#970). Such a link leaves the library:
  /// it is never looked up as a file, never drawn dead, and is opened by the
  /// system.
  ///
  /// A scheme is two letters or more before the colon, which keeps a Windows
  /// drive (`C:\`, `C:/`) a path: RFC 3986 allows one letter, but no scheme
  /// is written with one, and a drive is.
  static bool hasScheme(String s) => _scheme.hasMatch(s);

  static final RegExp _scheme = RegExp('^[a-zA-Z][a-zA-Z0-9+.-]+:');

  /// Normalizes a target for matching: backslashes to slashes, `./` and
  /// whitespace trimmed, lowercased. The `.md` extension and any
  /// `#fragment` are handled by the resolver, in that order.
  static String normalizeTarget(String target) => clean(target).toLowerCase();

  /// Whether [target], written in a note, names something that depends on
  /// the folder the note is in: a Markdown path is tried beside the note
  /// first, and a wiki target that starts with `/`, or has a `.` or `..`
  /// segment, is walked from it (#491). A bare wiki name is not: it is found
  /// by its name wherever the note is.
  static bool dependsOnLocation(String target, {required bool markdown}) {
    if (markdown) return true;
    final kept = clean(target);
    final hash = kept.indexOf('#');
    final path = hash == -1 ? kept : kept.substring(0, hash);
    return path.startsWith('/') ||
        path.split('/').any((s) => s == '.' || s == '..');
  }

  /// [target] trimmed, its backslashes slashes, its leading `./` gone.
  static String clean(String target) {
    var t = target.trim().replaceAll(r'\', '/');
    while (t.startsWith('./')) {
      t = t.substring(2);
    }
    return t;
  }

  /// [raw] read into what it names ([LinkSpec]): its target normalized
  /// ([normalizeTarget], `.md` dropped, its path walked by `walk`) and its
  /// `#fragment`, null when empty. The fragment keeps its case: a heading is
  /// found by its slug whatever its case, and a place in a book (#282) names
  /// a file in it, whose name has one.
  ///
  /// [from] is the linking note's path when it is known, and [beside] asks
  /// a plain path to be tried next to it first (Markdown links; a wiki
  /// target is a name, not a path). Null when the target names nothing: it
  /// climbs out of the library.
  static LinkSpec? read(String raw, {required bool beside, String? from}) {
    final kept = clean(raw);
    final hash = kept.indexOf('#');
    return readPath(
      hash == -1 ? kept : kept.substring(0, hash),
      fragment: hash == -1 ? null : kept.substring(hash + 1),
      beside: beside,
      from: from,
    );
  }

  /// [path] and [fragment], already apart, read into what they name
  /// ([LinkSpec]): [read] without the split at a `#`, for a path whose
  /// name may hold one (a Markdown href's `%23`, [markdownTarget]). An empty
  /// [fragment] is none.
  static LinkSpec? readPath(
    String path, {
    required bool beside,
    String? fragment,
    String? from,
  }) {
    var target = clean(path).toLowerCase();
    if (target.endsWith('.md')) target = target.substring(0, target.length - 3);
    final heading = fragment == null || fragment.isEmpty ? null : fragment;
    if (target.isEmpty) {
      return (t: '', heading: heading, exact: false, near: null);
    }
    final segments = target.split('/');
    if (!target.startsWith('/') &&
        !segments.any((s) => s == '.' || s == '..')) {
      // A plain path: found as its tail wherever it sits, and — for a
      // Markdown link — first exactly where the note beside it would have it.
      final folder = beside ? folderOf(from) : null;
      return (
        t: target,
        heading: heading,
        exact: false,
        near: folder == null ? null : [...folder, target].join('/'),
      );
    }
    final walked = walk(segments, from, rooted: target.startsWith('/'));
    if (walked == null) return null;
    return (t: walked, heading: heading, exact: true, near: null);
  }

  /// The folder segments of the note at library-relative [from], lowercased
  /// (a target is); null when [from] is not known.
  static List<String>? folderOf(String? from) {
    if (from == null) return null;
    final segments = [
      for (final s in from.replaceAll(r'\', '/').toLowerCase().split('/'))
        if (s.isNotEmpty && s != '.') s,
    ];
    if (segments.isNotEmpty) segments.removeLast();
    return segments;
  }

  /// The library-relative path [segments] name (#491): a leading `/` starts
  /// at the library root, anything else at the folder of the note at [from].
  /// `.` stays where it is and `..` goes up a folder. Null when the path
  /// names nothing: it climbs out of the library, or ends at the root
  /// itself.
  ///
  /// With no [from] a relative path starts at the root and what climbs past
  /// it is dropped, as it always was: there is no note to walk from.
  static String? walk(
    List<String> segments,
    String? from, {
    required bool rooted,
  }) {
    final path = <String>[if (!rooted) ...?folderOf(from)];
    for (final segment in segments) {
      if (segment.isEmpty || segment == '.') continue;
      if (segment != '..') {
        path.add(segment);
        continue;
      }
      if (path.isNotEmpty) {
        path.removeLast();
      } else if (rooted || from != null) {
        return null;
      }
    }
    return path.isEmpty ? null : path.join('/');
  }

  /// The stems [segment] — a target's last segment — can be indexed under:
  /// itself, and the reserved-stem name `sanitizeName` would have given the
  /// file ([withoutReservedStem], #491).
  static Set<String> stemVariants(String segment) {
    final moved = withoutReservedStem(segment);
    return moved == segment ? {segment} : {segment, moved};
  }
}
