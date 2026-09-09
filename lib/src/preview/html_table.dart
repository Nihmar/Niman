import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

/// Raw-HTML table support (the preview's "HTML is not injected" gap):
/// `<table>` blocks imported from archives/PDFs parse as plain text with
/// GFM; after the markdown parse they are split here into table elements
/// (`htmlBlock`) and rendered by [HtmlTableBuilder] as a real [Table].
///
/// Scope is deliberately table-focused: rows and cells are extracted with a
/// small scanner (attributes on table/tr/td ignored, cell tags stripped) —
/// that covers the common archive-export shape; other raw HTML stays as
/// text.
List<md.Node> splitHtmlTables(List<md.Node> nodes) {
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
  final children = node.children;
  if (children == null) return [node];
  final mapped = <md.Node>[];
  for (final child in children) {
    mapped.addAll(_transform(child, inCode: inCode || _isCodeLike(node.tag)));
  }
  if (identical(mapped.length, children.length) && _same(mapped, children)) {
    return [node];
  }
  final copy = md.Element(node.tag, mapped)
    ..attributes.addAll(node.attributes)
    ..generatedId = node.generatedId
    ..footnoteLabel = node.footnoteLabel;
  return [copy];
}

bool _same(List<md.Node> a, List<md.Node> b) {
  for (var i = 0; i < a.length; i++) {
    if (!identical(a[i], b[i])) return false;
  }
  return true;
}

bool _isCodeLike(String tag) => tag == 'pre' || tag == 'code';

final RegExp _tableRe = RegExp(
  '<table[^>]*>(.*?)</table>',
  caseSensitive: false,
  dotAll: true,
);
final RegExp _rowRe = RegExp(
  '<tr[^>]*>(.*?)</tr>',
  caseSensitive: false,
  dotAll: true,
);
final RegExp _cellRe = RegExp(
  '<t[dh][^>]*>(.*?)</t[dh]>',
  caseSensitive: false,
  dotAll: true,
);
final RegExp _tagRe = RegExp('<[^>]*>');

List<md.Node> _splitText(String text) {
  if (!text.toLowerCase().contains('<table')) return [md.Text(text)];
  final pieces = <md.Node>[];
  var pos = 0;
  for (final m in _tableRe.allMatches(text)) {
    if (m.start > pos) pieces.add(md.Text(text.substring(pos, m.start)));
    pieces.add(_parseTable(m.group(1)!));
    pos = m.end;
  }
  if (pos < text.length) pieces.add(md.Text(text.substring(pos)));
  return pieces;
}

md.Node _parseTable(String inner) {
  final rows = <md.Node>[];
  for (final rowMatch in _rowRe.allMatches(inner)) {
    final cells = <md.Node>[];
    for (final cellMatch in _cellRe.allMatches(rowMatch.group(1)!)) {
      final text = cellMatch.group(1)!.replaceAll(_tagRe, '').trim();
      cells.add(md.Element.text('htmlcell', _unescape(text)));
    }
    if (cells.isNotEmpty) rows.add(md.Element('htmlrow', cells));
  }
  return md.Element('htmlblock', rows);
}

String _unescape(String s) => s
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'");

/// Renders the `htmlblock` element (from [splitHtmlTables]) as a [Table].
final class HtmlTableBuilder extends MarkdownElementBuilder {
  /// Creates the builder.
  new();

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final rows = <TableRow>[];
    for (final child in element.children ?? const <md.Node>[]) {
      if (child is! md.Element || child.tag != 'htmlrow') continue;
      final cells = <Widget>[];
      for (final cell in child.children ?? const <md.Node>[]) {
        if (cell is! md.Element || cell.tag != 'htmlcell') continue;
        final text = (cell.children ?? const <md.Node>[])
            .map((n) => n is md.Text ? n.text : '')
            .join()
            .trim();
        cells.add(
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text(text.isEmpty ? '' : text, style: preferredStyle),
          ),
        );
      }
      if (cells.isNotEmpty) {
        rows.add(TableRow(children: cells));
      }
    }
    if (rows.isEmpty) {
      return Text(AppStrings.htmlTableFallback, style: preferredStyle);
    }
    return Table(
      border: TableBorder.all(color: Theme.of(context).dividerColor),
      children: rows,
    );
  }
}
