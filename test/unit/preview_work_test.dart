// PreviewWork: the off-isolate parse + stats entry — the whole-document
// passes never run on the UI thread (and the top-level entry is sendable,
// unlike a closure over a widget State).
import 'package:copist/src/preview/preview_work.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

const String _note = '# Alpha\n\ntext \$x^\$ in prose\n\n'
    '# Beta\n\nmore\n\n### Deep\n';

void main() {
  test('parse returns the AST over an isolate', () async {
    final result = await PreviewWork.run('parse', _note);
    expect(result, isA<List<md.Node>>());
    final nodes = result! as List<md.Node>;
    expect(nodes, isNotEmpty);
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
