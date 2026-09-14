/// The chat model of an `type: audio` note.
///
/// A voice note reads as a chat: recordings on the left, written notes on
/// the right, and each recording's description as a blockquote bubble
/// under its vocal. On disk everything stays plain Markdown:
///
/// ```text
/// ![](assets/a.wav)
/// > what was said
/// a written note
/// ```
///
/// An audio embed line (Markdown or wikilink, per [parseAudioClips]) is a
/// vocal; the `> ` lines directly after it are its description; any other
/// non-blank line run is a written note. Blank lines are separators only.
/// Edits are byte-stable: untouched lines keep their bytes.
///
/// Pure Dart, no I/O: the view renames the audio file itself.
library;

import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/ui/kinds/audio_clip.dart';
import 'package:niman/src/ui/kinds/audio_parser.dart';

/// A vocal bubble: [clip] with its blockquote [description].
final class AudioChatMessage {
  /// Creates a vocal message.
  const new({required this.clip, required this.description});

  /// The recording embed.
  final AudioClip clip;

  /// The description without the `> ` markers (may be empty).
  final String description;
}

/// A written-note bubble: raw body lines [start]..[end] (exclusive).
final class TextChatMessage {
  /// Creates a written-note message.
  const new({required this.start, required this.end, required this.text});

  /// The first absolute file line of the note.
  final int start;

  /// One past the last absolute file line of the note.
  final int end;

  /// The note text as written (may span lines).
  final String text;
}

/// One chat row: a vocal on the left or a written note on the right.
typedef AudioChatItem = Object;

/// Whether [line] is a blockquote line (`> ...`, leading space allowed).
bool isQuoteLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('>') &&
      (trimmed.length == 1 ||
          trimmed.codeUnitAt(1) == 0x20 ||
          trimmed.codeUnitAt(1) == 0x09);
}

/// The quote body of [line] without its `> ` marker.
String stripQuoteMarker(String line) {
  final trimmed = line.trimLeft();
  var rest = trimmed.substring(1);
  if (rest.startsWith(' ') || rest.startsWith('\t')) {
    rest = rest.substring(1);
  }
  return rest;
}

/// The chat rows of [text] in document order.
List<AudioChatItem> parseAudioChat(String text) {
  final lines = text.split('\n');
  final first = frontmatterLineCount(lines);
  final clips = <int, AudioClip>{};
  for (final clip in parseAudioClips(text)) {
    clips.putIfAbsent(clip.line, () => clip);
  }
  final out = <AudioChatItem>[];
  var i = first;
  while (i < lines.length) {
    final clip = clips[i];
    if (clip != null) {
      final description = <String>[];
      var j = i + 1;
      while (j < lines.length && isQuoteLine(lines[j])) {
        description.add(stripQuoteMarker(lines[j]));
        j++;
      }
      out.add(
        AudioChatMessage(clip: clip, description: description.join('\n')),
      );
      i = j;
      continue;
    }
    if (lines[i].trim().isEmpty) {
      i++;
      continue;
    }
    if (isQuoteLine(lines[i])) {
      // A stray quote with no vocal above it is a written note that
      // keeps its markers.
      final start = i;
      while (i < lines.length &&
          lines[i].trim().isNotEmpty &&
          clips[i] == null) {
        i++;
      }
      out.add(
        TextChatMessage(
          start: start,
          end: i,
          text: lines.sublist(start, i).join('\n'),
        ),
      );
      continue;
    }
    final start = i;
    while (i < lines.length &&
        lines[i].trim().isNotEmpty &&
        clips[i] == null &&
        !isQuoteLine(lines[i])) {
      i++;
    }
    out.add(
      TextChatMessage(
        start: start,
        end: i,
        text: lines.sublist(start, i).join('\n'),
      ),
    );
  }
  return out;
}

/// The note text with [message] appended as written-note lines: its own
/// paragraph, blank-line separated from the previous bubble.
String appendTextNote(String text, String message) {
  final clean = message.trim();
  if (clean.isEmpty) return text;
  return '${chatParagraphPrefix(text)}$clean\n';
}

/// The note text with [clip]'s description replaced by [description].
///
/// The description lives in the `> ` lines directly after the embed;
/// an empty [description] removes them.
String setClipDescription(String text, AudioClip clip, String description) {
  final lines = text.split('\n');
  if (clip.line < 0 || clip.line >= lines.length) return text;
  var end = clip.line + 1;
  while (end < lines.length && isQuoteLine(lines[end])) {
    end++;
  }
  final clean = description.trim();
  final replacement = <String>[
    if (clean.isNotEmpty)
      for (final line in clean.split('\n')) '> $line',
  ];
  lines.replaceRange(clip.line + 1, end, replacement);
  return lines.join('\n');
}

/// The note text with the written note on lines [start]..[end] removed.
String removeTextNote(String text, int start, int end) {
  final lines = text.split('\n');
  final safeStart = start.clamp(0, lines.length);
  final safeEnd = end.clamp(safeStart, lines.length);
  lines.removeRange(safeStart, safeEnd);
  return lines.join('\n');
}

/// The note text with the written note on lines [start]..[end] replaced
/// by [message].
String editTextNote(String text, int start, int end, String message) {
  final lines = text.split('\n');
  final safeStart = start.clamp(0, lines.length);
  final safeEnd = end.clamp(safeStart, lines.length);
  final clean = message.trim();
  lines.replaceRange(
    safeStart,
    safeEnd,
    clean.isEmpty ? const <String>[] : clean.split('\n'),
  );
  return lines.join('\n');
}

/// The note text with [clip]'s vocal (embed plus its `> ` description
/// lines) removed.
String removeAudioMessage(String text, AudioClip clip) {
  return removeAudioClip(setClipDescription(text, clip, ''), clip);
}

/// The note text with [clip]'s embed target renamed to [newTarget].
///
/// Only the first occurrence on the clip line is touched, so an alias
/// or title around it keeps its bytes.
String renameAudioClipTarget(String text, AudioClip clip, String newTarget) {
  final lines = text.split('\n');
  if (clip.line < 0 || clip.line >= lines.length) return text;
  lines[clip.line] = lines[clip.line].replaceFirst(clip.target, newTarget);
  return lines.join('\n');
}
