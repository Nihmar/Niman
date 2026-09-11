// T-M2-07: the heading chunk analyzer — fold ranges from the tokenizer's
// outline; nothing inside fences/math/frontmatter becomes a fold anchor.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/markdown_chunks.dart';
import 'package:re_editor/re_editor.dart';

List<CodeChunk> _chunks(String text) {
  final controller = CodeLineEditingController.fromText(text);
  final chunks = const MarkdownChunkAnalyzer().run(controller.codeLines);
  controller.dispose();
  return chunks;
}

void main() {
  test('a heading section folds up to the next same-level heading', () {
    final chunks = _chunks('# One\n\na\nb\n\n# Two\n\nc');
    expect(chunks, hasLength(2));
    // 'One' covers lines 1..4 (up to 'Two' at 5); 'Two' hides 6..7.
    expect(chunks[0].index, 0);
    expect(chunks[0].end, 5);
    expect(chunks[1].index, 5);
    expect(chunks[1].end, 8);
  });

  test('a child heading stays inside its parent section (nested folds)', () {
    final chunks = _chunks('# A\n\n## B\n\nx\n\ny');
    expect(chunks, hasLength(2), reason: 'both sections fold');
    expect(chunks[0].index, 0);
    expect(chunks[0].end, 7);
    expect(chunks[1].index, 2);
    expect(chunks[1].end, 7);
  });

  test('a heading with only a following heading is not foldable', () {
    final chunks = _chunks('# A\n\n# B');
    expect(chunks, isEmpty, reason: 'only a blank line between them');
  });

  test('a hash in a code fence is never a fold anchor', () {
    final chunks = _chunks('```\n# not a heading\n```\n\nreal\n');
    expect(chunks, isEmpty);
  });

  test('heading chunks keep working with inline math content', () {
    final chunks = _chunks('# Math\n\n\$x^2\$ and \$y^2\$ here.');
    expect(chunks, hasLength(1));
    expect(chunks.single.index, 0);
    expect(chunks.single.end, 3);
  });
}
