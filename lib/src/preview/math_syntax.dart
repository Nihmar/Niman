import 'dart:convert';

import 'package:copist/src/editor/math_rule.dart';
import 'package:markdown/markdown.dart' as md;

/// Display-math block syntax (`$$…$$`, single- or multi-line) for the
/// preview's parser.
///
/// Runs wherever the markdown package runs block syntaxes — top level, and
/// inside list items/blockquotes (the package re-parses item content with
/// the document's syntaxes, dedented), which is why display math also works
/// inside lists with no extra plumbing. Rules are indent-agnostic and match
/// the editor's tokenizer (math_rule.dart).
final class MathBlockSyntax extends md.BlockSyntax {
  /// Creates the syntax.
  const MathBlockSyntax();

  /// The pattern used by [parseChildLines] (not used by [parse]).
  @override
  RegExp get pattern => RegExp(r'^\s*\$\$');

  @override
  bool canParse(md.BlockParser parser) {
    final trimmed = parser.current.content.trim();
    return trimmed.startsWith(r'$$');
  }

  @override
  md.Node? parse(md.BlockParser parser) {
    final first = parser.current.content;
    final trimmed = first.trim();
    final marker = displayMarkerStart(first);
    if (isSingleLineDisplay(trimmed)) {
      parser.advance();
      return _element(tex: trimmed.substring(2, trimmed.length - 2));
    }
    // Multi-line: the tex is the open line's content after the marker plus
    // every line up to (not including) the next `$$` line. Unterminated
    // blocks run to EOF (mirrors the tokenizer).
    final lines = <String>[
      if (marker + 2 <= first.length) first.substring(marker + 2),
    ];
    parser.advance();
    while (!parser.isDone) {
      final line = parser.current.content;
      if (isDisplayClose(line.trim())) {
        parser.advance();
        break;
      }
      lines.add(line);
      parser.advance();
    }
    return _element(tex: lines.join('\n').trim());
  }

  static md.Element _element({required String tex}) => md.Element.text(
        'mathblock',
        tex,
      )..attributes['latex'] = tex
       ..attributes['display'] = 'true';
}

/// Replaces inline math (`$…$`) in parsed inline text with `math` elements,
/// so the preview's math builder can render it inside paragraphs.
///
/// Parser-side inline syntaxes fight the `markdown` package's inline flow
/// (no way to validate the shared rules before consuming), so inline math is
/// extracted post-parse instead: the text of paragraphs, headings, list
/// items, table cells and links is split by [findInlineMath] — the same
/// predicate the editor highlight uses. Text inside inline code and code
/// blocks is untouched.
List<md.Node> splitInlineMath(List<md.Node> nodes) {
  final out = <md.Node>[];
  for (final node in nodes) {
    out.addAll(_transform(node, inCode: false));
  }
  return out;
}

List<md.Node> _transform(md.Node node, {required bool inCode}) {
  if (node is md.Text) {
    if (inCode) return [node];
    return _splitText(node.text);
  }
  if (node is! md.Element) return [node];
  final skipChildren = inCode || _isCodeLike(node.tag);
  final children = node.children;
  if (children == null) return [node];
  final mapped = <md.Node>[];
  for (final child in children) {
    mapped.addAll(_transform(child, inCode: skipChildren));
  }
  if (identical(mapped.length, children.length) &&
      _sameChildren(mapped, children)) {
    return [node];
  }
  final copy = md.Element(node.tag, mapped)
    ..attributes.addAll(node.attributes)
    ..generatedId = node.generatedId
    ..footnoteLabel = node.footnoteLabel;
  return [copy];
}

bool _sameChildren(List<md.Node> a, List<md.Node> b) {
  for (var i = 0; i < a.length; i++) {
    if (!identical(a[i], b[i])) return false;
  }
  return true;
}

List<md.Node> _splitText(String text) {
  if (!text.contains(r'$')) return [md.Text(text)];
  final pieces = <md.Node>[];
  var pos = 0;
  while (pos < text.length) {
    final span = findInlineMath(text, pos);
    if (span == null) break;
    if (span.$1 > pos) pieces.add(md.Text(text.substring(pos, span.$1)));
    final tex = text.substring(span.$1 + 1, span.$2 - 1);
    final element = md.Element.text('math', tex)
      ..attributes['latex'] = tex
      ..attributes['display'] = 'false';
    pieces.add(element);
    pos = span.$2;
  }
  if (pieces.isEmpty) return [md.Text(text)];
  if (pos < text.length) pieces.add(md.Text(text.substring(pos)));
  return pieces;
}

bool _isCodeLike(String tag) => tag == 'pre' || tag == 'code';

/// Strips a leading YAML frontmatter block (`---` … `---`/`...`) from the
/// preview's source: frontmatter is metadata, not prose — math inside it
/// must not parse, and heading rules don't apply.
String stripFrontmatter(String text) {
  final lines = const LineSplitter().convert(text);
  if (lines.isEmpty || lines.first.trim() != '---') return text;
  for (var i = 1; i < lines.length; i++) {
    final trimmed = lines[i].trim();
    if (trimmed == '---' || trimmed == '...') {
      return const LineSplitter().convert(text).skip(i + 1).join('\n');
    }
  }
  return ''; // Unterminated block: metadata only.
}
