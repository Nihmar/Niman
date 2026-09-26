/// Where an `![[…]]` embed points on disk (#24), one rule for the read view
/// and for the export.
///
/// The lookup order is the layout's, and stays it: the library root (where
/// `Attachments/` and `assets/` sit), then the note's own folder, then —
/// for a bare name — the note index's unique match, the Obsidian layout.
/// Null when nothing is there; the caller shows the note's own text.
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
  var candidate = File(p.join(root, target));
  if (await candidate.exists()) return candidate.path;
  candidate = File(p.join(p.dirname(notePath), target));
  if (await candidate.exists()) return candidate.path;
  if (linkSource == null) return null;
  final resolved = await linkSource.resolveWiki(target);
  if (resolved is! ResolvedNote) return null;
  final viaIndex = File(p.join(root, resolved.note.path));
  return await viaIndex.exists() ? viaIndex.path : null;
}
