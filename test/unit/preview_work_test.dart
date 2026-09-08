// PreviewWork: the off-isolate parse + stats entry — the whole-document
// passes never run on the UI thread (and the top-level entry is sendable,
// unlike a closure over a widget State).
import 'dart:io';

import 'package:copist/src/preview/preview_work.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

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

  test('read returns content + stats from one isolate', () async {
    final dir = await Directory.systemTemp.createTemp('copist_pw_');
    final file = File('${dir.path}/note.md');
    await file.writeAsString('# Alpha\n\nwords here\n\n## Beta\n');
    final result = await PreviewWork.run('read', file.path);
    expect(result, isA<(String, int, List<String>)>());
    final loaded = result! as (String, int, List<String>);
    expect(loaded.$1, contains('# Alpha'));
    expect(loaded.$2, 6);
    expect(loaded.$3, hasLength(2));
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
