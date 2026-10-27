/// A note's tags as its panel shows them: the frontmatter's, then the inline
/// `#tags` the index keeps, each once (#175, #1197).
///
/// Read off the note's lines, never off the note joined into one string: a
/// panel that asked for the text after every pause in the typing joined a
/// 247 MB note anew each time, and the editor kept the copy
/// (`docs/records/memory-usage.md`, finding 4).
library;

import 'dart:isolate';

import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/ui/note_frontmatter_head.dart';

/// Past this many characters, reading a note's inline tags runs on an
/// isolate: the read is O(the note).
const int noteTagsSyncLimit = 64 * 1024;

/// [frontmatter]'s tags, normalized, then [inline]'s, each once.
List<String> noteTagsFrom({
  required List<String>? frontmatter,
  required List<String> inline,
}) => {...?frontmatter?.map(normalizeTag), ...inline}.toList();

/// The tags of [text]: its frontmatter's, then its inline `#tags` as the
/// index reads them ([noteReferencesOf]).
List<String> noteTagsOf(String text) => noteTagsFrom(
  frontmatter: parseFrontmatter(text)?.tags,
  inline: noteReferencesOf(text).tags,
);

/// The tags of the note [buffer] holds, read off its lines.
///
/// [references] are its inline tags and links when the editor keeps them
/// already — a long note's scan does, block by block — and then nothing of
/// the note is read again. Otherwise its lines are read, on an isolate past
/// [noteTagsSyncLimit] characters: the buffer goes there as it is, its lines
/// shared, not copied.
Future<List<String>> noteTagsOfBuffer(
  SourceBuffer buffer, {
  NoteReferences? references,
}) async {
  final head = frontmatterHeadOf(buffer);
  final inline = switch (references) {
    final kept? => kept,
    null when buffer.length > noteTagsSyncLimit => await Isolate.run(
      () => noteReferencesOfBuffer(buffer),
    ),
    null => noteReferencesOfBuffer(buffer),
  };
  return noteTagsFrom(
    frontmatter: head == null ? null : parseFrontmatter(head)?.tags,
    inline: inline.tags,
  );
}
