// HighlightDocument.replaceLines: line-granularity edits over the
// incremental tokenizer, including the carried block state (fences, display
// math, YAML frontmatter) across inserts/deletes/edits.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';

List<String> _lines(String text) =>
    text.isEmpty ? <String>[''] : text.split('\n');

HighlightDocument _doc(String text) => HighlightDocument.fromText(text);

/// The token kinds of line [i], for assertions.
List<TokenKind> _kinds(HighlightDocument doc, int i) {
  final tokens = doc.lineAt(i).tokens;
  return <TokenKind>[for (final t in tokens) t.kind];
}

void main() {
  test('empty document grows from a line edit', () {
    final doc = HighlightDocument.empty()
      ..replaceLines(0, 0, _lines('# Hello\nbody'));
    expect(doc.lineCount, 2);
    expect(_kinds(doc, 0), contains(TokenKind.headingMarker));
    expect(doc.lineAt(1).tokens, isEmpty);
  });

  test('append at the end converges immediately', () {
    final doc = _doc('# Hello\nbody')..replaceLines(2, 0, _lines('tail'));
    expect(doc.lineCount, 3);
    expect(doc.lineAt(2).text, 'tail');
    expect(doc.lineAt(0).tokens.first.kind, TokenKind.headingMarker);
  });

  test('a fence is preserved around a line insert', () {
    final doc = _doc('```dart\nvoid main() {}\n```\nplain');
    expect(_kinds(doc, 1), everyElement(TokenKind.codeFence));
    // Insert a line at the start of the fence body (inside the block).
    doc.replaceLines(1, 0, _lines('final x = 1;'));
    expect(doc.lineAt(0).tokens.first.kind, TokenKind.codeFence);
    expect(_kinds(doc, 1), everyElement(TokenKind.codeFence));
    expect(_kinds(doc, 2), everyElement(TokenKind.codeFence));
    // The closing fence line and the line after stay right.
    expect(_kinds(doc, 3), everyElement(TokenKind.codeFence));
    expect(doc.lineAt(4).tokens, isEmpty);
    expect(doc.lineAt(4).text, 'plain');
  });

  test('deleting a fence close re-tokenizes the tail as fence', () {
    final doc = _doc('```rust\nlet a = 1;\n```\n\nnormal')
      ..replaceLines(2, 1, const <String>[]);
    // The close is gone: the empty line and 'normal' are now still in the
    // fence, as a plain free line would keep the block open.
    expect(doc.lineCount, 4);
    expect(_kinds(doc, 2), everyElement(TokenKind.codeFence));
    expect(doc.lineAt(2).text, '');
    expect(_kinds(doc, 3), everyElement(TokenKind.codeFence));
    expect(doc.lineAt(3).text, 'normal');
  });

  test('an edit before an unclosed math block re-tokenizes to EOF', () {
    final doc = _doc('before\n\$\$\nx^2\n\$\$\nafter')
      ..replaceLines(0, 1, _lines('changed'));
    expect(_kinds(doc, 1), everyElement(TokenKind.mathBlock));
    expect(_kinds(doc, 2), everyElement(TokenKind.mathBlock));
    expect(_kinds(doc, 3), everyElement(TokenKind.mathBlock));
    expect(doc.lineAt(4).text, 'after');
  });

  test('frontmatter survives an edit below it (YAML block)', () {
    final doc = _doc('---\ntitle: Note\ntags: [a]\n---\n# Heading\nbody');
    expect(_kinds(doc, 0), everyElement(TokenKind.frontmatter));
    expect(_kinds(doc, 1), everyElement(TokenKind.frontmatter));
    expect(_kinds(doc, 2), everyElement(TokenKind.frontmatter));
    expect(_kinds(doc, 3), everyElement(TokenKind.frontmatter));
    // Edit the heading line right after the block.
    doc.replaceLines(4, 1, _lines('# New heading'));
    expect(_kinds(doc, 0), everyElement(TokenKind.frontmatter));
    expect(doc.lineAt(4).tokens.first.kind, TokenKind.headingMarker);
  });

  test('an edit inside frontmatter keeps the block', () {
    final doc = _doc('---\ntitle: Note\n---\nbody')
      ..replaceLines(1, 1, _lines('title: Changed'));
    expect(_kinds(doc, 0), everyElement(TokenKind.frontmatter));
    expect(_kinds(doc, 1), everyElement(TokenKind.frontmatter));
    expect(_kinds(doc, 2), everyElement(TokenKind.frontmatter));
    expect(doc.lineAt(3).tokens, isEmpty);
  });

  test('an unclosed frontmatter keeps the state to EOF', () {
    final doc = _doc('---\ntitle: Note\nbody')
      ..replaceLines(1, 1, _lines('title: Other'));
    expect(_kinds(doc, 2), everyElement(TokenKind.frontmatter));
  });

  test('far materialized lines refresh after an edit above them', () {
    // Everything below the edit point was previously painted (materialized).
    // The lazy walk must overwrite stale tokens instead of reusing them.
    final doc = _doc('a\nb\n```\ncode\n```\nz');
    expect(doc.lineAt(5).text, 'z');
    doc.replaceLines(0, 1, _lines('a!'));
    expect(doc.lineAt(0).tokens, isEmpty);
    expect(_kinds(doc, 2), everyElement(TokenKind.codeFence));
    expect(_kinds(doc, 4), everyElement(TokenKind.codeFence));
    expect(doc.lineAt(5).text, 'z');
    expect(doc.lineAt(5).tokens, isEmpty);
  });
}
