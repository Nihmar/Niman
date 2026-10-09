/// The first lines of a note, for the Home's journal tile (#535).
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/frontmatter/parser.dart';
import 'package:path/path.dart' as p;

/// The opening text of the note at [path] in the library at [root]: its
/// frontmatter and a leading heading left out, whole lines only.
///
/// Only the first [bytes] are read, so a novel-length note costs what a
/// short one does; the read runs on a background isolate, as every open
/// is a FUSE round trip on Android (#688). Empty when the note cannot be
/// read.
Future<String> notePreview(String root, String path, {int bytes = 4096}) {
  final file = p.join(root, path);
  return Isolate.run(() => _preview(file, bytes));
}

String _preview(String path, int bytes) {
  final List<int> head;
  try {
    final file = File(path).openSync();
    try {
      head = file.readSync(bytes);
    } finally {
      file.closeSync();
    }
  } on FileSystemException {
    return '';
  }
  var text = utf8.decode(head, allowMalformed: true);
  if (head.length == bytes) {
    // Cut at the last whole line: the read may have stopped mid-word.
    final last = text.lastIndexOf('\n');
    if (last > 0) text = text.substring(0, last);
  }
  final block = frontmatterBlock(text);
  if (block != null) {
    final lines = text.split('\n');
    text = lines.skip(block.endLine + 1).join('\n');
  } else if (head.length == bytes && text.split('\n').first.trim() == '---') {
    // A frontmatter longer than what was read: its fence is past the end,
    // and nothing read is the note's text (#687).
    return '';
  }
  final lines = text.split('\n').skipWhile((l) => l.trim().isEmpty).toList();
  if (lines.isNotEmpty && lines.first.startsWith('# ')) lines.removeAt(0);
  return lines.join('\n').trim();
}
