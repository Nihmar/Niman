/// What a scan reads out of one note (#51): the digest, the full text
/// (the FTS body copy) and everything the index derives from it — parsed
/// on a background isolate, so a scan costs one read per changed note
/// and no more.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:niman/src/db/killable_note_read.dart';
import 'package:niman/src/db/read_cancel.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/note_bytes.dart';
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
    this.embeds = const <ParsedLink>[],
    this.headings = const <OutlineEntry>[],
    this.blocks = const <BlockAnchor>[],
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

  /// The note's embeds (`![[…]]`) and Markdown images (`![…](…)`), which a
  /// rename or move must carry too (#507).
  final List<ParsedLink> embeds;

  /// The note's headings, in line order: what the `note_headings` rows are
  /// written from (#845).
  final List<OutlineEntry> headings;

  /// The note's blocks that end with a ` ^id`, in line order: what the
  /// `note_blocks` rows are written from (#844).
  final List<BlockAnchor> blocks;

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

/// A note's bytes as [readRawNote] left them: read and closed, not yet
/// parsed.
///
/// The read and the parse of a note are two steps because only the first
/// touches the disk: an isolate may be stopped at any point of the second,
/// and at none of the first (`readNoteContentsKillable`).
final class RawNote {
  /// Creates a note's bytes.
  const new({required this.rel, required this.bytes, this.asWritten});

  /// Library-relative note path.
  final String rel;

  /// The file's bytes.
  final List<int> bytes;

  /// What the app knew of the note, when the file is still the one it wrote
  /// — as it was before the read and after it, so a file swapped in between
  /// is not taken for it — or null.
  final KnownContent? asWritten;
}

/// Reads the note at [rel] under [root], the file closed when this answers;
/// null when it cannot be read (deleted or replaced mid-scan: the next scan
/// picks it up).
///
/// [known] is what the app knows of the note, if it wrote it.
Future<RawNote?> readRawNote(
  String root,
  String rel,
  KnownContent? known,
) async {
  try {
    final file = File(p.join(root, rel));
    final before = known == null ? null : file.statSync();
    final bytes = await file.readAsBytes();
    // The digest the write made, when the file is still the one it wrote:
    // 1.9 s of hashing on the 247 MB stress note
    // (`docs/records/huge-notes.md`, item 8), for bytes that were hashed as
    // they were written. And the tags and links the editor kept, block by
    // block: 5.1 s of that reindex, for blocks it had read as they were
    // written.
    final asWritten =
        known != null &&
        _isAsWritten(before!, known) &&
        _isAsWritten(file.statSync(), known);
    return RawNote(rel: rel, bytes: bytes, asWritten: asWritten ? known : null);
  } on FileSystemException {
    return null;
  }
}

/// Parses [raw]: the digest, the text, and what the index derives from it.
/// Pure — no disk, so it can be interrupted anywhere.
NoteContent parseRawNote(RawNote raw) {
  var text = decodeNoteText(raw.bytes);
  // A UTF-8 BOM is content for FTS but noise for matching the editor.
  if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
    text = text.substring(1);
  }
  final wrote = raw.asWritten;
  final sha = wrote != null
      ? wrote.sha256
      : sha256.convert(raw.bytes).toString();
  return _extractContent(raw.rel, sha, text, references: wrote?.references);
}

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
    final raw = await readRawNote(root, rel, known[rel]);
    if (raw != null) out.add(parseRawNote(raw));
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
///
/// With [cancel], the batch answers empty when it is cancelled, and stops
/// at once if it is parsing: a reindex of a 1.5 MB note parsed it for 894
/// ms on a tablet, and the save that fell inside it wrote in 480 ms against
/// 123 (device log, 2026-10-20) — for a read the save had made obsolete.
/// The isolate is stopped without a file open (`readNoteContentsKillable`).
Future<List<NoteContent>> readBatchOnIsolate(
  String root,
  List<String> batch,
  SendPort? progress, [
  Map<String, KnownContent> known = const {},
  ReadCancel? cancel,
]) {
  if (cancel == null) {
    return Isolate.run(
      () => readNoteContents(root, batch, progress: progress, known: known),
    );
  }
  return readNoteContentsKillable(root, batch, progress, known, cancel);
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
  // (`docs/records/huge-notes.md`, item 8).
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
    embeds: references.embeds,
    // The headings and the block ids come off the block state machine, not
    // the inline scan: a few milliseconds on a long note, which the pass is
    // already reading whole (the outline's own rule, `outlineOfText`).
    headings: outlineOfText(text),
    blocks: blockAnchorsOfText(text),
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
