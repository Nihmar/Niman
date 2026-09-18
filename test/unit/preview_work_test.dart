// PreviewWork: the off-isolate parse + stats entry — the whole-document
// passes never run on the UI thread (and the top-level entry is sendable,
// unlike a closure over a widget State).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/preview/block_parse.dart';
import 'package:niman/src/preview/preview_work.dart';
import 'package:niman/src/preview/preview_work_failure.dart';
import 'package:path/path.dart' as p;

const String _note =
    '# Alpha\n\ntext \$x^\$ in prose\n\n'
    '# Beta\n\nmore\n\n### Deep\n';

void main() {
  test('parse returns the block-phase AST over an isolate', () async {
    final result = await PreviewWork.run('parse', _note);
    expect(result, isA<BlockPhase>());
    final phase = result! as BlockPhase;
    final nodes = phase.nodes;
    expect(nodes, isNotEmpty);
    // The inlines stay raw: the paragraph's text is an UnparsedContent
    // leaf (the inline phase is per-block, block_parse.withInlines).
    final para = nodes.whereType<md.Element>().firstWhere((e) => e.tag == 'p');
    expect(para.children, isNotNull);
    expect(para.children!.single, isA<md.UnparsedContent>());
  });

  test(
    'read returns the content alone, without paying for the stats',
    () async {
      // The stats are deliberately not bundled here: computing them costs an
      // order of magnitude more than the read, and the note can be shown
      // without them (see PreviewWork's `read`).
      final dir = await Directory.systemTemp.createTemp('niman_pw_');
      final file = File('${dir.path}/note.md');
      await file.writeAsString('# Alpha\n\nwords here\n\n## Beta\n');
      final result = await PreviewWork.run('read', file.path);
      expect(result, isA<String>());
      expect(result! as String, contains('# Alpha'));
      await dir.delete(recursive: true);
    },
  );

  // Issue #156: a failed read came back as an `__error__|` string, which
  // the note view took for the note's text.
  test('read of a file that is not UTF-8 is a failure, not text', () async {
    final dir = await Directory.systemTemp.createTemp('niman_pw_');
    final file = File(p.join(dir.path, 'photo.jpg'));
    await file.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0xC3]);
    final result = await PreviewWork.run('read', file.path);
    expect(result, isA<PreviewWorkFailure>());
    expect((result! as PreviewWorkFailure).notText, isTrue);
    await dir.delete(recursive: true);
  });

  test('read of a missing file is a failure, and not a text one', () async {
    final dir = await Directory.systemTemp.createTemp('niman_pw_');
    final result = await PreviewWork.run('read', p.join(dir.path, 'gone.md'));
    expect(result, isA<PreviewWorkFailure>());
    expect((result! as PreviewWorkFailure).notText, isFalse);
    await dir.delete(recursive: true);
  });

  test('stats returns words and the outline', () async {
    final result = await PreviewWork.run('stats', _note);
    final stats = PreviewWork.statsOf(result);
    expect(stats, isNotNull);
    expect(stats!.words, greaterThan(0));
    expect(stats.outline, hasLength(3));
    expect(stats.outline[0], startsWith('0|1|Alpha'));
    expect(stats.outline[2], startsWith('8|3|Deep'));
  });
}
