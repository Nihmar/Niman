import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/editor/word_count.dart';
import 'package:niman/src/preview/block_parse.dart';

/// Off-isolate work for the preview (T-M2-04/05/08): the markdown block
/// phase and the note stats (word count + heading outline) run in a
/// spawned isolate so a 931K note never blocks the UI. The inline phase is
/// not here: it is the 96 % of the old whole-document parse, and the
/// preview pays it per block as each block builds (block_parse.dart);
///
/// Deliberately NOT `Isolate.run`: its wrapper closes over the calling
/// zone, and a closure created inside a widget State carries the State's
/// element with it — the isolate rejects that (`Illegal argument in isolate
/// message: object is unsendable`). Here the isolate entry is a top-level
/// function and the message is nothing but strings, so both directions are
/// sendable by construction.
///
/// Results (task → returned message):
///
/// * parse: `run('parse', source)` → the top-level blocks (`List` of
///   `md.Node`s) with inlines left raw ([parseBlocks]);
/// * stats: `run('stats', source)` → a record `(int words,
///   outline rows)` where rows are `List` of strings;
/// * read: `run('read', path)` → the note's text, and deliberately not its
///   stats with it. Reading a 931K note costs 44 ms; computing its stats
///   costs ~1.1 s, because the outline comes from the tokenizer and so
///   pays a full-document highlight ([statsFor]). Nothing on screen needs
///   either number to show the text, so carrying them here only bought a
///   1.2 s spinner in front of a note whose first frame paints in 0.4 ms
///   (device log, 2026-09-11). The editor asks for them separately once
///   the note is up;
/// * unknown task or a thrown error → a `'__error__|detail'` string.
///
/// Outline rows encode `'line|level|text'`.
final class PreviewWork {
  new _();

  /// Runs [task] ('parse' | 'stats' | 'read') over [source].
  static Future<Object?> run(String task, String source) {
    final receive = ReceivePort();
    final done = Completer<Object?>();
    receive.listen((message) {
      if (!done.isCompleted) done.complete(message);
      receive.close();
    });
    unawaited(
      Isolate.spawn<({SendPort reply, String task, String source})>(_entry, (
        reply: receive.sendPort,
        task: task,
        source: source,
      )),
    );
    return done.future;
  }

  /// Decodes a stats outline record into entries.
  static ({int words, List<String> outline})? statsOf(Object? result) {
    if (result is! (int, List<String>)) return null;
    return (words: result.$1, outline: result.$2);
  }

  @pragma('vm:entry-point')
  static void _entry(_Work message) {
    try {
      switch (message.task) {
        case 'parse':
          message.reply.send(_parseSource(message.source));
        case 'stats':
          final stats = statsFor(message.source);
          message.reply.send(stats);
        case 'read':
          message.reply.send(File(message.source).readAsStringSync());
        default:
          message.reply.send('__error__|unknown task: ${message.task}');
      }
    } on Object catch (error) {
      message.reply.send('__error__|$error');
    }
  }
}

typedef _Work = ({SendPort reply, String task, String source});

/// Word count + heading outline of [text] (the row encoding
/// `'line|level|text'`).
///
/// Both are O(n) passes over the text, and neither tokenizes it: the
/// outline used to come from `HighlightDocument.fromText(text).lines`,
/// which on a 931K maths-dense note spent ~1.07 s of a ~1.16 s total
/// inline-scanning 10,406 lines to find 84 headings. [outlineOfText] walks
/// the block state machine alone for the same answer.
(int, List<String>) statsFor(String text) {
  return (
    countWords(text),
    outlineOfText(text).map((e) => '${e.line}|${e.level}|${e.text}').toList(),
  );
}

/// The preview's block phase for [source] (the isolate task): the
/// top-level blocks with inlines left raw. The inline phase runs per block
/// on the render side (block_parse.dart) — measured on the 931K note the
/// old whole-document parse split 14 ms of blocks and 378 ms of inlines.
List<md.Node> _parseSource(String source) => parseBlocks(source);
