/// The `audio` note kind's body format (issue #56).
///
/// A clip is an audio embed on its own line, in the library's link
/// format: `![](assets/a1b2.wav)` for Markdown libraries,
/// `![[assets/a1b2.wav]]` for wikilink ones. What makes an embed a clip
/// is the target's audio extension. Parsing follows the shared editor
/// tokenizer ([HighlightDocument]), so embeds inside code fences, math
/// blocks and the frontmatter itself are never clips — exactly what the
/// editor paints as images and wikilinks.
library;

import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/links/attachment_embed.dart';
import 'package:niman/src/links/parser.dart' show parseWikiRef;
import 'package:niman/src/ui/kinds/audio_clip.dart';

/// Audio file extensions (lowercased, with dot) that count as clips.
///
/// `wav` is what Niman records (PCM 16-bit: playable on Android, Linux
/// and Windows with no extra codec); the rest is what a person may attach
/// from disk.
const Set<String> audioExtensions = {
  '.wav',
  '.mp3',
  '.m4a',
  '.ogg',
  '.oga',
  '.opus',
  '.aac',
  '.flac',
  '.3gp',
  '.webm',
};

/// Whether [target] points at an audio file (extension match, case
/// insensitive; query strings and fragments are ignored).
bool isAudioTarget(String target) {
  var t = target.trim();
  final hash = t.indexOf('#');
  if (hash >= 0) t = t.substring(0, hash);
  final query = t.indexOf('?');
  if (query >= 0) t = t.substring(0, query);
  if (t.startsWith('<') && t.endsWith('>') && t.length >= 2) {
    t = t.substring(1, t.length - 1);
  }
  final dot = t.lastIndexOf('.');
  if (dot < 0) return false;
  return audioExtensions.contains(t.substring(dot).toLowerCase());
}

/// The audio clips of [text], in document order.
List<AudioClip> parseAudioClips(String text) {
  final out = <AudioClip>[];
  final doc = HighlightDocument.fromText(text);
  for (var i = 0; i < doc.lines.length; i++) {
    final line = doc.lines[i];
    for (final token in line.tokens) {
      if (token.kind == TokenKind.image) {
        final raw = line.text.substring(token.start, token.end);
        final target = _embedTarget(raw);
        if (target.isEmpty || !isAudioTarget(target)) continue;
        out.add(AudioClip(line: i, start: token.start, target: target));
      } else if (token.kind == TokenKind.wikilink &&
          token.start > 0 &&
          line.text.codeUnitAt(token.start - 1) == 0x21) {
        // A `![[…]]` embed: the tokenizer marks the brackets, the `!`
        // sits one char before the token.
        final inner = line.text.substring(token.start + 2, token.end - 2);
        final target = parseWikiRef(inner).target;
        if (target.isEmpty || !isAudioTarget(target)) continue;
        out.add(AudioClip(line: i, start: token.start - 1, target: target));
      }
    }
  }
  return out;
}

/// The note text with [relativePath] appended as a new clip line
/// (byte-stable otherwise), in the library's link format.
String appendAudioClip(
  String text,
  String relativePath, {
  required LinkType linkType,
  String label = '',
}) {
  final prefix = text.isEmpty || text.endsWith('\n') ? text : '$text\n';
  final embed = attachmentEmbed(
    relativePath: relativePath,
    label: label,
    linkType: linkType,
  );
  return '$prefix$embed\n';
}

/// The note text with [clip]'s embed removed.
///
/// Only the embed goes: surrounding text on the same line keeps its
/// bytes, and a line left blank by the removal is dropped so the body
/// does not fill with empty lines.
String removeAudioClip(String text, AudioClip clip) {
  final lines = text.split('\n');
  if (clip.line < 0 || clip.line >= lines.length) return text;
  final line = lines[clip.line];
  final int end;
  // A `![[…]]` embed opens with `![[`; a `![…](…)` one with `![`.
  if (clip.start + 2 < line.length &&
      line.codeUnitAt(clip.start + 1) == 0x5B &&
      line.codeUnitAt(clip.start + 2) == 0x5B) {
    // A `![[…]]` embed closes with `]]`.
    final close = line.indexOf(']]', clip.start);
    if (close < 0) return text;
    end = close + 2;
  } else {
    final close = line.indexOf(')', clip.start);
    if (close < 0 || close >= line.length) return text;
    end = close + 1;
  }
  final next = '${line.substring(0, clip.start)}${line.substring(end)}';
  if (next.trim().isEmpty) {
    lines.removeAt(clip.line);
  } else {
    lines[clip.line] = next;
  }
  return lines.join('\n');
}

/// The `src` of a `![alt](src "title")` embed.
String _embedTarget(String raw) {
  final sep = raw.indexOf('](');
  if (sep < 0 || !raw.endsWith(')')) return '';
  var inner = raw.substring(sep + 2, raw.length - 1).trim();
  if (inner.startsWith('<')) {
    final close = inner.indexOf('>');
    if (close > 0) inner = inner.substring(1, close);
  } else {
    final space = inner.indexOf(RegExp(r'\s'));
    if (space >= 0) inner = inner.substring(0, space);
  }
  if (inner.length >= 2 &&
      ((inner.startsWith('"') && inner.endsWith('"')) ||
          (inner.startsWith("'") && inner.endsWith("'")))) {
    inner = inner.substring(1, inner.length - 1);
  }
  return inner.trim();
}
