// PreviewWork: the off-isolate parse + stats entry — the whole-document
// passes never run on the UI thread (and the top-level entry is sendable,
// unlike a closure over a widget State).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/preview/preview_work.dart';

const String _note =
    '# Alpha\n\ntext \$x^\$ in prose\n\n'
    '# Beta\n\nmore\n\n### Deep\n';

void main() {
  test('parse returns the AST over an isolate', () async {
    final result = await PreviewWork.run('parse', _note);
    expect(result, isA<List<md.Node>>());
    final nodes = result! as List<md.Node>;
    expect(nodes, isNotEmpty);
  });

  test('read returns the content alone, without paying for the stats',
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
