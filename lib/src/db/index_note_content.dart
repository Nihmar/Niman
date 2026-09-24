/// What a scan reads out of one note (#51): the digest, the full text
/// (the FTS body copy) and everything the index derives from it — parsed
/// on a background isolate, so a scan costs one read per changed note
/// and no more.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:path/path.dart' as p;

/// One note's content after a read on the index isolate: the digest, the
/// full text (the FTS body copy) and everything the index derives from it
/// (title, tags, aliases, links) — parsed off the UI isolate and off the
/// main flow, so a scan costs one read per changed note and no more.
final class NoteContent {
  /// Creates a parsed note content.
  const new({
    required this.rel,
    required this.sha256,
    required this.text,
    required this.title,
    required this.frontmatterTags,
    required this.inlineTags,
    required this.aliases,
    required this.links,
    this.fields = const {},
    this.date,
    this.pinned = false,
    this.frontmatterError,
  });

  /// Library-relative note path.
  final String rel;

  /// Content sha256 (hex).
  final String sha256;

  /// The full note text (FTS `body` copy).
  final String text;

  /// The search title: frontmatter `title`, else the filename without
  /// `.md` (case preserved).
  final String title;

  /// Normalized tags from frontmatter `tags:`.
  final List<String> frontmatterTags;

  /// Normalized inline `#tags`.
  final List<String> inlineTags;

  /// Raw frontmatter `aliases:` values.
  final List<String> aliases;

  /// The note's links, in document order.
  final List<ParsedLink> links;

  /// Every frontmatter key mapped to its values as text — what the
  /// `frontmatter_fields` rows are written from (T-M4-02).
  final Map<String, List<String>> fields;

  /// The frontmatter `date:`, or null.
  final DateTime? date;

  /// Whether the frontmatter says `pinned: true`.
  final bool pinned;

  /// Why the frontmatter block did not parse, or null when it did.
  ///
  /// Carried so the scan can say which note is broken; the index keeps no
  /// fields for it, because it has none to keep.
  final String? frontmatterError;
}

/// What the app knows of a note it has just written, so its reindex does
/// not work it out again from the file: the digest of the bytes it wrote —
/// computed as they were written — the tags and links of the text, when
/// the editor keeps them, and the file as the write left it, which says
/// whether it is still that file.
typedef KnownContent = ({
  String sha256,
  int size,
  DateTime modified,
  NoteReferences? references,
});

/// Reads and parses the notes at [rels] (library-relative, under [root]) —
/// one file read per note returning digest **and** text, with frontmatter,
/// inline tags and links extracted on this (index) isolate.
///
/// Top-level for Isolate.run; batched by the caller (a few hundred per
/// call). A note that cannot be read (deleted or replaced mid-scan) is left
/// out; the next scan picks it up.
///
/// [progress] receives each library-relative path as it comes up, so a
/// first index can name what it is reading. A `SendPort` is sendable, so
/// the isolate closure can carry one.
Future<List<NoteContent>> readNoteContents(
  String root,
  List<String> rels, {
  SendPort? progress,
  Map<String, KnownContent> known = const {},
}) async {
  final out = <NoteContent>[];
  for (final rel in rels) {
    // Posted before the read, so what the screen names is the note being
    // worked on rather than the one just finished.
    progress?.send(rel);
    try {
      final file = File(p.join(root, rel));
      final wrote = known[rel];
      final before = wrote == null ? null : file.statSync();
      final bytes = await file.readAsBytes();
      var text = utf8.decode(bytes, allowMalformed: true);
      // A UTF-8 BOM is content for FTS but noise for matching the editor.
      if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
        text = text.substring(1);
      }
      // The digest the write made, when the file is still the one it
      // wrote — as it was before the read and after it, so a file swapped
      // in between is not taken for it: 1.9 s of hashing on the 247 MB
      // stress note (`docs/dev/huge-notes.md`, item 8), for bytes that were
      // hashed as they were written.
      // And the tags and links the editor kept, block by block: 5.1 s of
      // that reindex, for blocks it had read as they were written.
      final asWritten =
          wrote != null &&
          _isAsWritten(before!, wrote) &&
          _isAsWritten(file.statSync(), wrote);
      final sha = asWritten ? wrote.sha256 : sha256.convert(bytes).toString();
      out.add(
        _extractContent(
          rel,
          sha,
          text,
          references: asWritten ? wrote.references : null,
        ),
      );
    } on FileSystemException {
      continue;
    }
  }
  return out;
}

bool _isAsWritten(FileStat stat, KnownContent wrote) =>
    stat.type == FileSystemEntityType.file &&
    stat.size == wrote.size &&
    stat.modified == wrote.modified;

/// Runs one [readNoteContents] batch on a background isolate.
///
/// Public for the indexer's batched reads: top-level so the Isolate.run
/// closure captures only these three sendable values. Inlined in a method
/// it captures that method's context, which holds the async body's
/// future — unsendable, and the open failed with it.
Future<List<NoteContent>> readBatchOnIsolate(
  String root,
  List<String> batch,
  SendPort? progress, [
  Map<String, KnownContent> known = const {},
]) {
  return Isolate.run(
    () => readNoteContents(root, batch, progress: progress, known: known),
  );
}

/// Parses [text] into a [NoteContent] (pure: frontmatter, tags, links);
/// [references] are its tags and links when they are known already.
NoteContent _extractContent(
  String rel,
  String sha,
  String text, {
  NoteReferences? references,
}) {
  // Read by the unified engine, and only where a tag or a link can be: a
  // whole-note tokenize was two minutes of a first index on a 247 MB note
  // (`docs/dev/huge-notes.md`, item 8).
  references ??= noteReferencesOf(text);
  final fm = parseFrontmatter(text);
  return NoteContent(
    rel: rel,
    sha256: sha,
    text: text,
    title: fm?.title ?? _titleFromName(rel),
    frontmatterTags: fm?.tags ?? const [],
    inlineTags: references.tags,
    aliases: fm?.aliases ?? const [],
    links: references.links,
    fields: fm?.fields ?? const {},
    date: fm?.date,
    pinned: fm?.pinned ?? false,
    frontmatterError: fm?.error,
  );
}

/// The filename without the `.md` extension, case preserved.
String _titleFromName(String rel) {
  final name = p.basename(rel);
  return name.endsWith('.md') ? name.substring(0, name.length - 3) : name;
}
