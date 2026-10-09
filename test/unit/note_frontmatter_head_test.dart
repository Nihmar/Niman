// The note view's frontmatter head, read off a buffer (issue #710): the
// block with its blank line, the rows it takes, the caret in it, one field
// edited, and the parse error from the first lines.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/ui/note_frontmatter_head.dart';

void main() {
  SourceBuffer note(String text) => SourceBuffer.fromText(text);

  test('the head is the block, fences and the blank line after it', () {
    const head = '---\ntitle: A\n---\n\n';
    expect(frontmatterHeadOf(note('${head}Body\n')), head);
    expect(frontmatterHeadOf(note('---\ntitle: A\n...\nBody')), isNotNull);
  });

  test('a note without a closed block has no head', () {
    expect(frontmatterHeadOf(null), isNull);
    expect(frontmatterHeadOf(note('')), isNull);
    expect(frontmatterHeadOf(note('Body\n---\n')), isNull);
    expect(frontmatterHeadOf(note('---\ntitle: A\n')), isNull);
    // Past the lookahead, an unclosed block is not read to its end.
    final long = 'k: ${'x' * frontmatterLookahead}\n';
    expect(frontmatterHeadOf(note('---\n$long---\n')), isNull);
  });

  test('the head takes a row per line, and none without one', () {
    expect(frontmatterHeadRows(note('---\na: 1\n---\n\nBody')), 4);
    expect(frontmatterHeadRows(note('Body')), 0);
    expect(frontmatterHeadRows(null), 0);
  });

  test('the caret is in the head on its lines only', () {
    final buffer = note('---\na: 1\n---\nBody\n');
    expect(caretInFrontmatterHead(buffer, null), isTrue);
    expect(caretInFrontmatterHead(buffer, 1), isTrue);
    expect(caretInFrontmatterHead(buffer, 3), isTrue);
    expect(caretInFrontmatterHead(buffer, 4), isFalse);
    expect(caretInFrontmatterHead(note('Body'), 1), isFalse);
  });

  test('a field edit replaces the head alone', () {
    final buffer = note('---\na: 1\nb: 2\n---\nBody\n');
    final set = frontmatterFieldEdit(buffer, 'a', '3')!;
    expect(set.end, '---\na: 1\nb: 2\n---\n'.length);
    expect(set.text, '---\na: 3\nb: 2\n---\n');
    final removed = frontmatterFieldEdit(buffer, 'b', null)!;
    expect(removed.text, '---\na: 1\n---\n');
    expect(frontmatterFieldEdit(buffer, 'a', '1'), isNull);
    expect(frontmatterFieldEdit(note('Body'), 'a', '1'), isNull);
  });

  test('the parse error is read off the first lines', () {
    expect(frontmatterErrorOf(note('---\na: 1\n---\nBody')), isNull);
    expect(frontmatterErrorOf(note('---\na: [1\n---\nBody')), isNotNull);
    expect(frontmatterErrorOf(note('')), isNull);
  });
}
