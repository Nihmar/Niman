/// Setting and clearing a frontmatter key of a note on disk, without
/// reading the note.
///
/// Pinning edits one line at the top of a file, and it read the whole file
/// to do it: the bytes, the text they decode to, the edited copy and its
/// bytes again, on the UI isolate. The 247 MB stress note ran a phone out of
/// memory the moment it was unpinned (2026-09-24 report). So the file is
/// read up to the end of its frontmatter and no further; the edit is made
/// on that head with the functions every other frontmatter edit uses
/// (`edit.dart`), and the rest of the file is copied behind the new head as
/// the bytes it is, into a temp file renamed over the note — the atomic
/// write `writeFileAtomically` makes.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/frontmatter/edit.dart';

/// Sets the top-level frontmatter [key] of the note at [path] to [value],
/// or removes it when [value] is null.
///
/// Answers the note's new head — its frontmatter block as the file now
/// opens, empty when the edit took the block out — or null when the note
/// did not change. The head is all a caller needs to know what the
/// frontmatter now says: the body was copied, not changed.
///
/// Top-level for `Isolate.run`: the paths and the key are all it carries.
Future<String?> editFrontmatterKeyInFile(
  String path,
  String key,
  String? value,
) async {
  final file = File(path);
  final head = await _headOf(file);
  final text = utf8.decode(head.bytes, allowMalformed: true);
  final String edited;
  var skip = head.bytes.length;
  if (head.block) {
    edited = value == null
        ? removeFrontmatterKey(text, key)
        : setFrontmatterKey(text, key, value);
  } else {
    // No block: nothing to remove, and a new one goes on top, the body a
    // blank line below it with its leading blank space gone — as
    // `setFrontmatterKey` shapes a whole note.
    if (value == null) return null;
    final eol = head.crlf ? '\r\n' : '\n';
    edited = '---$eol$key: $value$eol---$eol$eol';
    skip = head.leadingBlank;
  }
  if (head.block && edited == text) return null;
  final tmp = atomicTempPath(file, DateTime.now().microsecondsSinceEpoch);
  try {
    final sink = tmp.openWrite();
    if (head.bom) sink.add(const <int>[0xEF, 0xBB, 0xBF]);
    sink.add(utf8.encode(edited));
    await sink.addStream(file.openRead(head.bom ? skip + 3 : skip));
    await sink.flush();
    await sink.close();
    await tmp.rename(file.path);
  } catch (_) {
    if (tmp.existsSync()) await tmp.delete();
    rethrow;
  }
  return edited;
}

/// [editFrontmatterKeyInFile] on a background isolate, off the UI's.
///
/// Top-level so the `Isolate.run` closure captures only these three
/// sendable values: inlined in a method it captures the method's context,
/// which holds the caller's future chain, and cannot be sent.
Future<String?> editFrontmatterKeyOnIsolate(
  String path,
  String key,
  String? value,
) => Isolate.run(() => editFrontmatterKeyInFile(path, key, value));

/// The head of a note: its frontmatter block through the closing fence's
/// line, and the blank line after it when there is one (what removing the
/// block's last key takes with it) — or, for a note with no block, nothing,
/// with where its first character past blank space is.
typedef _Head = ({
  List<int> bytes,
  bool block,
  bool bom,
  bool crlf,
  int leadingBlank,
});

/// How much of a file is read at a time while looking for the head.
const int _chunk = 64 * 1024;

/// How far a closing fence is looked for. A frontmatter block is a few
/// lines; a file that opens `---` and has not closed it this far is refused
/// rather than read whole, which is what this file is here to not do.
const int _maxHead = 4 * 1024 * 1024;

Future<_Head> _headOf(File file) async {
  final raf = await file.open();
  try {
    final bytes = <int>[];
    var eof = false;
    Future<void> more() async {
      final chunk = await raf.read(_chunk);
      if (chunk.isEmpty) {
        eof = true;
      } else {
        bytes.addAll(chunk);
      }
    }

    await more();
    final bom =
        bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF;
    final start = bom ? 3 : 0;
    // The lines of the head, found a newline at a time: the fences are
    // ASCII, so the bytes can be searched without decoding them.
    Future<int?> lineEnd(int start) async {
      var from = start;
      while (true) {
        for (var at = from; at < bytes.length; at++) {
          if (bytes[at] == 0x0A) return at + 1;
        }
        if (eof) return bytes.length > start ? bytes.length : null;
        if (bytes.length > _maxHead) {
          throw StateError(
            'no end to the frontmatter in the first '
            '${_maxHead ~/ (1024 * 1024)} MB of ${file.path}',
          );
        }
        from = bytes.length;
        await more();
      }
    }

    String lineAt(int from, int to) =>
        latin1.decode(bytes.sublist(from, to), allowInvalid: true).trim();

    final crlf = _hasCrlf(bytes);
    final first = await lineEnd(start);
    if (first == null || lineAt(start, first) != '---') {
      return await _noBlock(
        bytes,
        start,
        bom: bom,
        crlf: crlf,
        eof: eof,
        more: more,
      );
    }
    var at = first;
    while (true) {
      final end = await lineEnd(at);
      if (end == null) {
        // Never closed: not a block, as the parser reads it.
        return await _noBlock(
          bytes,
          start,
          bom: bom,
          crlf: crlf,
          eof: eof,
          more: more,
        );
      }
      final line = lineAt(at, end);
      if (line == '---' || line == '...') {
        var close = end;
        final next = await lineEnd(close);
        if (next != null && lineAt(close, next).isEmpty) close = next;
        return (
          bytes: bytes.sublist(start, close),
          block: true,
          bom: bom,
          crlf: crlf,
          leadingBlank: 0,
        );
      }
      at = end;
    }
  } finally {
    await raf.close();
  }
}

/// A note with no block: its blank space before the first character, read
/// as far as it goes.
Future<_Head> _noBlock(
  List<int> bytes,
  int start, {
  required bool bom,
  required bool crlf,
  required bool eof,
  required Future<void> Function() more,
}) async {
  var at = start;
  var ended = eof;
  while (true) {
    while (at < bytes.length && _blank(bytes[at])) {
      at++;
    }
    if (at < bytes.length || ended) break;
    final before = bytes.length;
    await more();
    ended = bytes.length == before;
  }
  return (
    bytes: const <int>[],
    block: false,
    bom: bom,
    crlf: crlf,
    leadingBlank: at - start,
  );
}

bool _blank(int byte) =>
    byte == 0x20 || byte == 0x09 || byte == 0x0A || byte == 0x0D;

/// Whether the head read so far is written with CRLF: a note edited on
/// Windows should not gain a lone LF line.
bool _hasCrlf(List<int> bytes) {
  for (var at = 1; at < bytes.length; at++) {
    if (bytes[at] == 0x0A && bytes[at - 1] == 0x0D) return true;
  }
  return false;
}
