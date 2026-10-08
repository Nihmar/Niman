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
/// * **A Markdown href** keeps the form it was written in: a path beside the
///   linking note or one that walks (`../assets/pic.png`) stays relative to
///   the note, a rooted one (`/Docs/x.md`) stays rooted, and a
///   library-relative one stays library-relative — so the note still reads
///   right in any other Markdown tool, not only here.
/// * **A tail that still matches is left alone**: a link written by the end
///   of a path (`[[sub/Note]]`, `[x](Note.md)`) that the new path still ends
///   with finds the note as it did, and is not lengthened into a full path.
/// * **An embed** (`![[…]]` or `![…](…)`) follows the same rules as the link
///   it is, its `!` kept (#507): attachments are cited this way, and a moved
///   attachments folder must carry them.
/// * A `#fragment` and a `|alias` are carried through untouched; only the
///   target is rewritten.
library;

import 'dart:convert';

import 'package:niman/src/core/percent.dart';
import 'package:niman/src/links/link_moves.dart';
import 'package:niman/src/links/parser.dart';

/// The links of [source] retargeted for a move.
///
/// [moves] holds every file that moved ([LinkMoves]). [from] is the linking
/// note's own library-relative path *before* the move — what its links were
/// written against — or null when unknown; [at] is where it is now, when it
/// moved too (a note inside a renamed folder), and [from] otherwise.
/// [renamedFrom] / [renamedTo] are the old and new base names of a renamed
/// *file* (`Old.md` -> `New.md`), for the bare-name wikilinks; null for a
/// move, or a folder, whose members keep their names.
///
/// Answers [source] itself when no link moved, so a caller can compare for
/// equality and skip the write.
String rewriteMovedLinks(
  String source, {
  required String? from,
  required LinkMoves moves,
  String? at,
  String? renamedFrom,
  String? renamedTo,
}) {
  if (moves.isEmpty) return source;
  final here = at ?? from;
  final replacements = <(int, int, String)>[];
  for (final link in parseLinks(source, includeEmbeds: true)) {
    switch (link) {
      case WikiLink(:final start, :final end, :final ref, :final embed):
        final target = _wikiTarget(
          ref.target,
          from: from,
          here: here,
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
        :final angled,
      ):
        final rewritten = _markdownHref(href, from, here, moves);
        if (rewritten != null) {
          final bang = embed ? '!' : '';
          final target = angled ? '<$rewritten>' : rewritten;
          replacements.add((start, end, '$bang[$text]($target)'));
        }
    }
  }
  if (replacements.isEmpty) return source;
  final buffer = StringBuffer();
  var cursor = 0;
  for (final (start, end, text) in replacements) {
    buffer
      ..write(source.substring(cursor, start))
      ..write(text);
    cursor = end;
  }
  buffer.write(source.substring(cursor));
  return buffer.toString();
}

/// How a written target named a file: the forms a link can be written in,
/// each written back in its own form.
enum _Form {
  /// From the library's root, with a leading `/`.
  rooted,

  /// From the linking note's folder: beside it, or walking with `.`/`..`.
  relative,

  /// From the library's root, without a leading `/`.
  library,
}

/// The new target of the wikilink [target], or null when it need not change.
String? _wikiTarget(
  String target, {
  required String? from,
  required String? here,
  required LinkMoves moves,
  required String? renamedFrom,
  required String? renamedTo,
}) {
  if (target.isEmpty) return null;
  if (_isBareName(target)) {
    return _renamedBareName(target, renamedFrom, renamedTo);
  }
  final keepMd = target.toLowerCase().endsWith('.md');
  final written = _movedPath(target, from: from, here: here, moves: moves);
  if (written == null) return null;
  final path = keepMd ? written : _withoutMd(written);
  return path == _asWritten(target) ? null : path;
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

/// The new href for the Markdown link [href], or null when it need not
/// change (or is not a path at all: an anchor, a URL, a scheme).
String? _markdownHref(
  String href,
  String? from,
  String? here,
  LinkMoves moves,
) {
  final trimmed = href.trim();
  if (trimmed.isEmpty || trimmed.startsWith('#') || _hasScheme(trimmed)) {
    return null;
  }
  final hash = trimmed.indexOf('#');
  final rawPath = hash == -1 ? trimmed : trimmed.substring(0, hash);
  final fragment = hash == -1 ? '' : trimmed.substring(hash);
  // Read as opening it reads it: percent-decoded, as Obsidian writes a link.
  final decoded = percentDecoded(rawPath);
  final written = _movedPath(
    decoded,
    from: from,
    here: here,
    moves: moves,
    beside: true,
  );
  if (written == null || written == _asWritten(decoded)) return null;
  return '${_encodeHref(written)}$fragment';
}

/// The target as it is to be written after the move, in the form it was
/// written in — or null when it named nothing that moved, or still names it
/// as written.
///
/// [from] resolves the target (the linking note's old place: what the link
/// was written against); [here] writes a relative one back (its place now).
/// [beside] asks a plain path to be tried next to the linking note first, as
/// a Markdown href does.
String? _movedPath(
  String target, {
  required String? from,
  required String? here,
  required LinkMoves moves,
  bool beside = false,
}) {
  final cleaned = _clean(target);
  if (cleaned.isEmpty) return null;
  final dotted = _asWritten(target).startsWith('./');
  final candidates = <(String, _Form)>[];
  if (cleaned.startsWith('/')) {
    candidates.add((cleaned.substring(1), _Form.rooted));
  } else {
    final segments = cleaned.split('/');
    if (segments.any((s) => s == '.' || s == '..')) {
      final walked = _walk(segments, from);
      if (walked != null) candidates.add((walked, _Form.relative));
    } else {
      if (beside && from != null) {
        final folder = _folderOf(from);
        if (folder.isNotEmpty) {
          candidates.add(('$folder/$cleaned', _Form.relative));
        }
      }
      candidates.add((cleaned, _Form.library));
    }
  }
  for (final (candidate, form) in candidates) {
    // Only a path written from the root is looked for by its tail as well:
    // the resolver takes a rooted, a walked or a beside path as it stands.
    final found = moves.find(candidate, tail: form == _Form.library);
    if (found == null) continue;
    final moved = found.path;
    if (found.match == MoveMatch.tail) {
      // Found by the end of its path: if the new path still ends that way,
      // the link finds it as it did, and stays as short as it was written.
      final lower = moved.toLowerCase();
      final tail = candidate.toLowerCase();
      if (lower.endsWith('/$tail') || lower.endsWith('/$tail.md')) {
        return null;
      }
      return moved;
    }
    return switch (form) {
      _Form.rooted => '/$moved',
      _Form.library => moved,
      _Form.relative => _relative(moved, here, dotted: dotted),
    };
  }
  return null;
}

/// [path] written from the folder of [here]: `../` up to the folders the two
/// share, then down. A leading `./` is kept when the link had one.
String _relative(String path, String? here, {required bool dotted}) {
  final base = [
    for (final s in _folderOf(here ?? '').split('/'))
      if (s.isNotEmpty) s,
  ];
  final parts = path.split('/');
  var shared = 0;
  while (shared < base.length &&
      shared < parts.length - 1 &&
      base[shared] == parts[shared]) {
    shared++;
  }
  final up = List.filled(base.length - shared, '..');
  final relative = [...up, ...parts.sublist(shared)].join('/');
  return dotted && up.isEmpty ? './$relative' : relative;
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

/// [target] as it was written, for comparing: trimmed, its backslashes
/// slashes.
String _asWritten(String target) => target.trim().replaceAll(r'\', '/');

/// [target] trimmed, its backslashes slashes, its leading `./` gone.
String _clean(String target) {
  var t = target.trim().replaceAll(r'\', '/');
  while (t.startsWith('./')) {
    t = t.substring(2);
  }
  return t;
}

/// The folder of [from], or an empty string when it is at the root.
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

final RegExp _scheme = RegExp('^[a-zA-Z][a-zA-Z0-9+.-]*://');

/// Whether [href] is a URL rather than a path.
bool _hasScheme(String href) => _scheme.hasMatch(href);

/// Whether [rune] can sit in a Markdown href as written.
///
/// A space ends an href, `#` begins its fragment, `%` would read as an
/// escape, and `()` `<>` delimit it. Anything outside printable ASCII — an
/// accented letter, a CJK name — is written as its UTF-8 bytes, the inverse
/// of [percentDecoded], so the app reads back what it writes.
bool _hrefSafe(int rune) {
  if (rune <= 0x20 || rune > 0x7E) return false;
  return switch (rune) {
    0x25 || 0x23 || 0x28 || 0x29 || 0x3C || 0x3E => false, // % # ( ) < >
    _ => true,
  };
}

String _encodeHref(String path) {
  final out = StringBuffer();
  for (final rune in path.runes) {
    if (_hrefSafe(rune)) {
      out.writeCharCode(rune);
      continue;
    }
    for (final byte in utf8.encode(String.fromCharCode(rune))) {
      out.write('%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}');
    }
  }
  return out.toString();
}
