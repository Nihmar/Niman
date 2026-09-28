/// Where an `![[…]]` embed points on disk (#24), one rule for the read view
/// and for the export.
///
/// The lookup order is the layout's, and stays it: the library root (where
/// `Attachments/` and `assets/` sit), then the note's own folder, then —
/// for a bare name — the note index's unique match, the Obsidian layout.
/// Null when nothing is there; the caller shows the note's own text.
///
/// Every probe is confined to the library: a target that walks out of
/// [resolveEmbedPath]'s root with `..` — `![[../../private/shot.png]]`, in
/// a note that arrived by sync — resolves to nothing there either, so the
/// read view draws no file of the user's and an export inlines none of its
/// bytes (#385).
//
// The probes are the async dart:io forms on purpose: the lint prefers the
// sync ones, and a stat on Android is a FUSE round trip the UI isolate must
// not wait on (`AGENTS.md`). Callers that read many targets in a row — an
// export — resolve them together, on a background isolate.
// ignore_for_file: avoid_slow_async_io
library;

import 'dart:io';

import 'package:niman/src/links/resolver.dart';
import 'package:path/path.dart' as p;

/// Resolves the embed [target] against [root] and [notePath] (both
/// absolute), then the link index.
Future<String?> resolveEmbedPath(
  String target,
  String notePath,
  String root,
  LinkSource? linkSource,
) async {
  if (target.isEmpty) return null;
  final library = p.normalize(root);
  final atRoot = await _inLibrary(p.join(library, target), library);
  if (atRoot != null) return atRoot;
  final beside = await _inLibrary(p.join(p.dirname(notePath), target), library);
  if (beside != null) return beside;
  if (linkSource == null) return null;
  final resolved = await linkSource.resolveWiki(target);
  if (resolved is! ResolvedNote) return null;
  return await _inLibrary(p.join(library, resolved.note.path), library);
}

/// The file [candidate] is, when it is one inside [library]; null otherwise.
///
/// The path is normalized before the boundary is drawn, so a `..` segment
/// cannot leave the library and be read — or exported — anyway; a target
/// that stays inside is returned normalized, one shape for every caller.
Future<String?> _inLibrary(String candidate, String library) async {
  final path = p.normalize(candidate);
  if (!p.isWithin(library, path)) return null;
  return await File(path).exists() ? path : null;
}
