import 'package:niman/src/frontmatter/edit.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// How much of a note's head the frontmatter is looked for in: a note that
/// opens `---` and never closes it costs this much, and not the file.
const int frontmatterLookahead = 8 * 1024;

/// The note's leading frontmatter block as text — the fences included, and
/// the blank line after it — or null when [buffer] has no such block.
///
/// The same head the other frontmatter edits work on: the closing fence's
/// line, plus the blank line the block's last key takes with it
/// (`frontmatter/edit.dart`). Only as far as the closing fence is read, and
/// never past [frontmatterLookahead], so a huge note that opens `---` and
/// never closes it costs a few lines and not the file.
String? frontmatterHeadOf(SourceBuffer? buffer) {
  if (buffer == null || buffer.lineCount == 0) return null;
  if (buffer.lineAt(0).trim() != '---') return null;
  final head = StringBuffer();
  for (var line = 0; line < buffer.lineCount; line++) {
    final text = buffer.lineAt(line);
    head
      ..write(text)
      ..write(buffer.terminatorAt(line));
    if (head.length > frontmatterLookahead) return null;
    if (line > 0 && (text.trim() == '---' || text.trim() == '...')) {
      final next = line + 1;
      if (next < buffer.lineCount && buffer.lineAt(next).trim().isEmpty) {
        head
          ..write(buffer.lineAt(next))
          ..write(buffer.terminatorAt(next));
      }
      return head.toString();
    }
  }
  return null;
}

/// How many rows the note's head takes in the source pane (#157): one per
/// terminator in [frontmatterHeadOf], and none without a head.
int frontmatterHeadRows(SourceBuffer? buffer) {
  if (buffer == null || buffer.lineCount == 0) return 0;
  final head = frontmatterHeadOf(buffer);
  if (head == null) return 0;
  return '\n'.allMatches(head).length;
}

/// Whether the caret on 1-based [caretLine] is on one of the note's head
/// lines (#522): with no caret reported yet — a note just opened — the head
/// counts as shown, as a pane not yet laid out does.
bool caretInFrontmatterHead(SourceBuffer? buffer, int? caretLine) {
  if (caretLine == null) return true;
  final head = frontmatterHeadOf(buffer);
  if (buffer == null || head == null || head.isEmpty) return false;
  // The head's last line, as the buffer counts it: the line its last
  // character — a terminator, or the closing fence of a note that ends
  // there — belongs to. Counting `\n`s instead missed that last fence, and
  // any line a lone `\r` ends.
  return caretLine <= buffer.lineOf(head.length - 1) + 1;
}

/// One frontmatter field set to [value] — removed when it is null — as the
/// text that replaces the note's first `end` characters,
/// or null when [buffer] has no head or the field already reads so.
///
/// The named key's line only, so the rest of the block — its key order, its
/// comments, its quoting — does not move.
FrontmatterFieldEdit? frontmatterFieldEdit(
  SourceBuffer buffer,
  String key,
  String? value,
) {
  final head = frontmatterHeadOf(buffer);
  if (head == null) return null;
  final edited = value == null
      ? removeFrontmatterKey(head, key)
      : setFrontmatterKey(head, key, value);
  if (edited == head) return null;
  return (end: head.length, text: edited);
}

/// The replacement [frontmatterFieldEdit] makes: `text` in place of the
/// note's characters from 0 to `end`.
typedef FrontmatterFieldEdit = ({int end, String text});

/// Why the note's frontmatter does not parse, from its first lines only, or
/// null when it does (or when there is no block).
///
/// [frontmatterErrorIn] reads the leading block and stops; a note's
/// frontmatter is its first handful of lines, so it is handed those rather
/// than the joined note.
String? frontmatterErrorOf(SourceBuffer buffer) {
  if (buffer.lineCount == 0) return null;
  final lead = StringBuffer();
  for (
    var line = 0;
    line < buffer.lineCount && lead.length < frontmatterLookahead;
    line++
  ) {
    lead
      ..write(buffer.lineAt(line))
      ..write(buffer.terminatorAt(line));
  }
  return frontmatterErrorIn(lead.toString());
}
