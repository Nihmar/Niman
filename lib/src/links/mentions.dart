/// The notes that link to a note, and the line each one says it on (#842):
/// what "Links to this note" lists.
///
/// The index already holds the edges — `note_links`, one row per resolved
/// `from → to` and kind, answered in the reverse direction by `links_to` — so
/// *who* links here is one indexed lookup (`NoteDao.referrersOf`). *Where*
/// each one says it is not in the index, and is read when a row is drawn, not
/// before: the referrer's text is read off the UI isolate, its links read
/// with the index's own engine ([noteReferencesOf]), the ones that name the
/// note found by the resolver's own rules, and the line around the first of
/// them cut ([Mention]). Only the rows
/// a list scrolls to are read, and the answers are kept by the revision of the
/// referrer, bounded.
///
/// Only linked mentions: a note's name written without a link is not one
/// (docs/user/links.md says so). A link to a note that is not there is no edge,
/// so it names no one.
library;

import 'package:niman/src/links/link_path.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/note_load.dart' show normalizedLineEndings;
import 'package:niman/src/markdown/note_references.dart';

/// A note that links to another, as the index knows it.
final class Referrer {
  /// Creates the referrer at library-relative [path], whose links to the note
  /// are of these [kinds] (`wiki`, `md`).
  const new({required this.path, required this.kinds});

  /// The referrer's library-relative path.
  final String path;

  /// The link forms it uses to name the note, sorted: `md`, `wiki`.
  final List<String> kinds;
}

/// The notes that link to one note: the first [items] in path order, and
/// whether there are more than the lookup was asked for.
final class Referrers {
  /// Creates the list.
  const new(this.items, {this.truncated = false});

  /// No one links to the note.
  static const Referrers none = Referrers(<Referrer>[]);

  /// The referrers, by path.
  final List<Referrer> items;

  /// Whether [items] stops short: more notes link here than were asked for.
  final bool truncated;
}

/// What one referrer says about the note it links to.
final class Mention {
  /// Creates a mention.
  const new({
    required this.context,
    required this.line,
    required this.embed,
    required this.count,
  });

  /// The referrer says nothing readable about the note: its text changed
  /// since the index read it, or it cannot be read now.
  static const Mention unread = Mention(
    context: '',
    line: -1,
    embed: false,
    count: 0,
  );

  /// The line the first mention is on, trimmed and cut to a row's width,
  /// with the link in it; empty when [unread].
  final String context;

  /// The 0-based line of that mention, or -1.
  final int line;

  /// Whether the mention is an embed (`![[note]]`, `![](note.md)`): the note
  /// is shown there rather than linked. A referrer that links *and* embeds
  /// is shown by its link.
  final bool embed;

  /// How many times the referrer names the note (links and embeds).
  final int count;
}

/// One link of a note, as the list of mentions reads it: what it targets (as
/// written), its form, the line it is on and that line cut for a row.
typedef LinkSpot = ({
  String target,
  bool markdown,
  bool embed,
  int line,
  String context,
});

/// How wide a mention's context is cut, in characters.
const int mentionContextWidth = 140;

/// The links and embeds of [raw] as the mentions list reads them: in
/// document order, each with its line and the context around it.
///
/// A link with no target (`[[#heading]]`) names the note it is in, and a
/// Markdown href that is a URL or an anchor names no note: both are left out.
///
/// The links are the ones the index keeps ([noteReferencesOf], the engine
/// that draws the note), read block by block: a note of any size is not
/// tokenized whole, and a reference-style link (`[text][ref]`) is a mention
/// with its line like the others.
List<LinkSpot> linkSpotsOf(String raw) {
  final text = normalizedLineEndings(raw);
  final references = noteReferencesOf(text);
  final links = <ParsedLink>[...references.links, ...references.embeds]
    ..sort((a, b) => a.start.compareTo(b.start));
  if (links.isEmpty) return const <LinkSpot>[];
  final spots = <LinkSpot>[];
  var line = 0;
  var from = 0;
  for (final link in links) {
    // The lines passed since the last link, counted once between the two.
    var at = text.indexOf('\n', from);
    while (at != -1 && at < link.start) {
      line++;
      from = at + 1;
      at = text.indexOf('\n', from);
    }
    final String target;
    final bool markdown;
    switch (link) {
      case WikiLink(:final ref):
        if (ref.target.isEmpty) continue;
        target = ref.target;
        markdown = false;
      case MarkdownLink(:final href):
        final written = href.trim();
        if (written.isEmpty ||
            written.startsWith('#') ||
            LinkPaths.hasScheme(written)) {
          continue;
        }
        target = written;
        markdown = true;
    }
    spots.add((
      target: target,
      markdown: markdown,
      embed: switch (link) {
        WikiLink(:final embed) => embed,
        MarkdownLink(:final embed) => embed,
      },
      line: line,
      context: contextAround(text, link.start, link.end),
    ));
  }
  return spots;
}

final RegExp _lineMarkers = RegExp(
  r'^\s*(?:>\s*)*(?:(?:[-*+]|\d{1,9}[.)])\s+(?:\[[ xX]\]\s+)?)?',
);

/// The line of [text] holding `[start, end)`, cleaned for a row: a list or
/// quote marker off its head, whitespace runs one space, trimmed, and — if it
/// is longer than [width] — cut to a window around the link with `…` where it
/// was cut.
String contextAround(
  String text,
  int start,
  int end, {
  int width = mentionContextWidth,
}) {
  final lineStart = start <= 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
  var lineEnd = text.indexOf('\n', end < start ? start : end);
  if (lineEnd == -1) lineEnd = text.length;
  var line = text.substring(lineStart, lineEnd);
  var from = start - lineStart;
  var to = (end > lineEnd ? lineEnd : end) - lineStart;
  // The marker comes off the head, and what the link's offsets were against.
  final marker = _lineMarkers.firstMatch(line)?.end ?? 0;
  if (marker > 0 && marker <= from) {
    line = line.substring(marker);
    from -= marker;
    to -= marker;
  }
  line = line.trimRight();
  if (to > line.length) to = line.length;
  if (line.length <= width) return _collapsed(line);
  // A window of the line around the link, the link kept whole when it fits.
  final linkLength = to - from;
  var head = from - (width - linkLength) ~/ 2;
  if (head < 0) head = 0;
  var tail = head + width;
  if (tail > line.length) {
    tail = line.length;
    head = tail - width;
    if (head < 0) head = 0;
  }
  final cut = _collapsed(line.substring(head, tail));
  final before = head > 0 ? '…' : '';
  final after = tail < line.length ? '…' : '';
  return '$before$cut$after';
}

String _collapsed(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
