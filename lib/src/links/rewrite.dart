/// Rewriting the links that point at a note or folder that moved (#507).
///
/// One note's text in, the same text with those links retargeted; no index,
/// no I/O. The caller finds the notes to feed it through the index's
/// `note_links` edges (never a scan) and writes the changed ones back
/// through the writer, the normal save path.
///
/// The rules, and the settlements behind them:
///
/// * **A wikilink by name** (`[[Note]]`) follows a *rename* — the stem is
///   the one thing that changed — and is left alone by a move: a bare name
///   is found wherever the note sits, so moving it changes nothing.
/// * **A wikilink by path** (`[[Docs/Note]]`) follows both: the old path is
///   recognized whether it is written whole or as the tail the resolver
///   matches anywhere, and is replaced by the new path in the same form.
/// * **A Markdown href** likewise: its library-relative path (or the one
///   beside the linking note, which the resolver tries first) is mapped, and
///   the href is written back as the new library-relative path, the way the
///   app writes a Markdown link.
/// * **An embed** (`![[…]]` or `![…](…)`) follows the same rules as the link
///   it is, its `!` kept (#507): attachments are cited this way, and a moved
///   attachments folder must carry them.
/// * A `#fragment` and a `|alias` are carried through untouched; only the
///   target is rewritten.
library;

import 'package:niman/src/core/percent.dart';
import 'package:niman/src/links/parser.dart';

/// The links of [source] retargeted for a move.
///
/// [moves] maps every file that moved, old library-relative path -> new,
/// with its extension (notes and attachments alike). [from] is the linking
/// note's own library-relative path (a Markdown href is tried beside it
/// first), or null when unknown. [renamedFrom] / [renamedTo] are the old and
/// new base names of a renamed *file* (`Old.md` -> `New.md`), for the
/// bare-name wikilinks; null for a move, or a folder, whose members keep
/// their names.
///
/// Answers [source] itself when no link moved, so a caller can compare for
/// equality and skip the write.
String rewriteMovedLinks(
  String source, {
  required String? from,
  required Map<String, String> moves,
  String? renamedFrom,
  String? renamedTo,
}) {
  if (moves.isEmpty) return source;
  final replacements = <(int, int, String)>[];
  for (final link in parseLinks(source, includeEmbeds: true)) {
    switch (link) {
      case WikiLink(:final start, :final end, :final ref, :final embed):
        final target = _wikiTarget(
          ref.target,
          from: from,
          moves: moves,
          renamedFrom: renamedFrom,
          renamedTo: renamedTo,
        );
        if (target != null) {
          replacements.add((start, end, _wikiText(target, ref, embed: embed)));
        }
      case MarkdownLink(
        :final start,
        :final end,
        :final text,
        :final href,
        :final embed,
      ):
        final rewritten = _markdownHref(href, from, moves);
        if (rewritten != null) {
          final bang = embed ? '!' : '';
          replacements.add((start, end, '$bang[$text]($rewritten)'));
        }
    }
  }
  if (replacements.isEmpty) return source;
  final buffer = StringBuffer();
  var at = 0;
  for (final (start, end, text) in replacements) {
    buffer
      ..write(source.substring(at, start))
      ..write(text);
    at = end;
  }
  buffer.write(source.substring(at));
  return buffer.toString();
}

/// The new target of the wikilink [target], or null when it did not move.
String? _wikiTarget(
  String target, {
  required String? from,
  required Map<String, String> moves,
  required String? renamedFrom,
  required String? renamedTo,
}) {
  if (target.isEmpty) return null;
  if (_isBareName(target)) {
    return _renamedBareName(target, renamedFrom, renamedTo);
  }
  final newPath = _movedPath(target, from: from, moves: moves);
  if (newPath == null) return null;
  final rooted = target.startsWith('/');
  final keepMd = target.toLowerCase().endsWith('.md');
  final path = keepMd ? newPath : _withoutMd(newPath);
  return rooted ? '/$path' : path;
}

/// The new target of a bare wikilink that named a renamed file, or null.
String? _renamedBareName(String target, String? from, String? to) {
  if (from == null || to == null) return null;
  final written = _clean(target);
  if (!_nameVariants(from).contains(written.toLowerCase())) return null;
  return written.toLowerCase().endsWith('.md') ? to : _withoutMd(to);
}

/// The whole `[[…]]` of [target] with [ref]'s heading and alias, as an embed
/// (`![[…]]`) when it was written as one.
String _wikiText(String target, WikiRef ref, {required bool embed}) {
  final heading = ref.heading == null ? '' : '#${ref.heading}';
  final alias = ref.alias == null ? '' : '|${ref.alias}';
  return '${embed ? '!' : ''}[[$target$heading$alias]]';
}

/// The new href for the Markdown link [href], or null when it did not move
/// (or is not a path at all: an anchor, a URL, a scheme).
String? _markdownHref(String href, String? from, Map<String, String> moves) {
  final trimmed = href.trim();
  if (trimmed.isEmpty || trimmed.startsWith('#') || _hasScheme(trimmed)) {
    return null;
  }
  final hash = trimmed.indexOf('#');
  final rawPath = hash == -1 ? trimmed : trimmed.substring(0, hash);
  final fragment = hash == -1 ? '' : trimmed.substring(hash);
  // Read as opening it reads it: percent-decoded, as Obsidian writes a link.
  final newPath = _movedPath(
    percentDecoded(rawPath),
    from: from,
    moves: moves,
    beside: true,
  );
  if (newPath == null) return null;
  return '${_encodeHref(newPath)}$fragment';
}

/// The new library-relative path the written target named, or null when it
/// named nothing that moved.
///
/// [beside] asks a plain path to be tried next to the linking note first, as
/// a Markdown href does. A target the resolver matches as a tail — no `/`,
/// or a plain path — is also matched against the tail of every moved path.
String? _movedPath(
  String target, {
  required String? from,
  required Map<String, String> moves,
  bool beside = false,
}) {
  final cleaned = _clean(target);
  if (cleaned.isEmpty) return null;
  final candidates = <String>[];
  if (cleaned.startsWith('/')) {
    candidates.add(_normalize(cleaned.substring(1)));
  } else {
    final segments = cleaned.split('/');
    if (segments.any((s) => s == '.' || s == '..')) {
      final walked = _walk(segments, from);
      if (walked != null) candidates.add(walked);
    } else {
      if (beside && from != null) {
        final folder = _folderOf(from);
        candidates.add(folder.isEmpty ? cleaned : '$folder/$cleaned');
      }
      candidates.add(cleaned);
    }
  }
  return _lookup(moves, candidates);
}

/// The new path of the first of [candidates] that names a moved file, or
/// null. Matching is case-insensitive, with or without `.md`, whole or as a
/// tail — the same ways the resolver finds a note.
String? _lookup(Map<String, String> moves, List<String> candidates) {
  final keys = [for (final k in moves.keys) (k.toLowerCase(), moves[k]!)];
  for (final candidate in candidates) {
    final c = candidate.toLowerCase();
    final withMd = '$c.md';
    for (final (key, value) in keys) {
      if (key == c || key == withMd) return value;
    }
    for (final (key, value) in keys) {
      if (key.endsWith('/$c') || key.endsWith('/$withMd')) return value;
    }
  }
  return null;
}

/// The names [base] answers to as a bare link: as written, and — for a
/// Markdown note — without its `.md`.
Set<String> _nameVariants(String base) {
  final lower = base.toLowerCase();
  if (lower.endsWith('.md')) {
    return {lower, lower.substring(0, lower.length - 3)};
  }
  return {lower};
}

/// Whether [target] is a bare name: no `/` at all (so no path, no walking).
bool _isBareName(String target) =>
    !target.startsWith('/') && !target.contains('/');

String _withoutMd(String path) => path.toLowerCase().endsWith('.md')
    ? path.substring(0, path.length - 3)
    : path;

/// [target] trimmed, its backslashes slashes, its leading `./` gone.
String _clean(String target) {
  var t = target.trim().replaceAll(r'\', '/');
  while (t.startsWith('./')) {
    t = t.substring(2);
  }
  return t;
}

/// [path] lowercased, for matching.
String _normalize(String path) => path.toLowerCase();

/// The folder segments of [from], or an empty list when it is at the root.
String _folderOf(String from) {
  final idx = from.lastIndexOf('/');
  return idx < 0 ? '' : from.substring(0, idx);
}

/// [segments] walked from the folder of [from] (`.` stays, `..` up), or null
/// when it climbs out of the library. A leading `/` is handled by the
/// caller, which is the only place a rooted path exists here.
String? _walk(List<String> segments, String? from) {
  final path = <String>[
    for (final s in _folderOf(from ?? '').split('/'))
      if (s.isNotEmpty) s,
  ];
  for (final segment in segments) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment != '..') {
      path.add(segment);
      continue;
    }
    if (path.isEmpty) return null;
    path.removeLast();
  }
  return path.isEmpty ? null : path.join('/');
}

/// Whether [href] is a URL rather than a path.
bool _hasScheme(String href) =>
    RegExp('^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(href);

/// What a Markdown href cannot hold as written: a space ends it, a `#`
/// begins its fragment, a `%` would read as an escape.
final RegExp _unsafeInHref = RegExp('[%\x20()<>#]');

String _encodeHref(String path) => path.replaceAllMapped(
  _unsafeInHref,
  (m) => '%${m[0]!.codeUnitAt(0).toRadixString(16).toUpperCase()}',
);
