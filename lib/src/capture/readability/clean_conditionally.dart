/// Cleaning what only looks like the article (`_cleanConditionally`): a
/// block with more pictures than paragraphs, more list items than text,
/// more links than words, inputs, or nothing at all — data tables, and
/// what is in them, kept.
///
/// Ported from mozilla/readability (Readability.js 0.6.0, commit 04fd32f),
/// Apache-2.0.
library;

import 'package:html/dom.dart';
import 'package:niman/src/capture/readability/dom.dart';
import 'package:niman/src/capture/readability/patterns.dart';
import 'package:niman/src/capture/readability/prep.dart';
import 'package:niman/src/capture/readability/run.dart';
import 'package:niman/src/capture/readability/text_metrics.dart';
import 'package:niman/src/capture/readability/traversal.dart';

/// [text] as JavaScript's `parseInt(text, 10)` reads it: its leading
/// digits, null when it has none.
int? _parseInt(String text) {
  final match = RegExp(r'^\s*([+-]?\d+)').firstMatch(text);
  return match == null ? null : int.tryParse(match[1]!);
}

/// The conditional cleaning.
extension ReadabilityCleanConditionally on ReadabilityRun {
  /// How many rows and columns [table] has, spans counted.
  ({int rows, int columns}) _rowAndColumnCount(Element table) {
    var rows = 0;
    var columns = 0;
    for (final tr in elementsWithTag(table, const ['tr'])) {
      final rowspan = _parseInt(attributeOf(tr, 'rowspan') ?? '');
      rows += rowspan == null || rowspan == 0 ? 1 : rowspan;
      var columnsInThisRow = 0;
      for (final cell in elementsWithTag(tr, const ['td'])) {
        final colspan = _parseInt(attributeOf(cell, 'colspan') ?? '');
        columnsInThisRow += colspan == null || colspan == 0 ? 1 : colspan;
      }
      if (columnsInThisRow > columns) columns = columnsInThisRow;
    }
    return (rows: rows, columns: columns);
  }

  /// Marks each table under [root] as data or layout, as Firefox's
  /// accessibility code tells them apart (`_markDataTables`).
  void markDataTables(Element root) {
    for (final table in elementsWithTag(root, const ['table'])) {
      if (attributeOf(table, 'role') == 'presentation' ||
          attributeOf(table, 'datatable') == '0') {
        markDataTable(table, data: false);
        continue;
      }
      final summary = attributeOf(table, 'summary');
      final caption = elementsWithTag(table, const ['caption']).firstOrNull;
      if ((summary != null && summary.isNotEmpty) ||
          (caption != null && caption.nodes.isNotEmpty) ||
          elementsWithTag(table, const [
            'col',
            'colgroup',
            'tfoot',
            'thead',
            'th',
          ]).isNotEmpty) {
        markDataTable(table, data: true);
        continue;
      }
      // A table in it means layout.
      if (elementsWithTag(table, const ['table']).isNotEmpty) {
        markDataTable(table, data: false);
        continue;
      }
      final size = _rowAndColumnCount(table);
      if (size.columns == 1 || size.rows == 1) {
        // One column or one row: page layout, commonly.
        markDataTable(table, data: false);
      } else if (size.rows >= 10 || size.columns > 4) {
        markDataTable(table, data: true);
      } else {
        markDataTable(table, data: size.rows * size.columns > 10);
      }
    }
  }

  /// Removes each [tag] under [element] that looks fishy.
  void cleanConditionally(Element element, String tag) {
    if (!flagIsActive(ReadabilityRun.flagCleanConditionally)) return;
    removeNodes(
      elementsWithTag(element, [tag]),
      (node) => _shouldClean(node, tag),
    );
  }

  bool _shouldClean(Element node, String tag) {
    var isList = tag == 'ul' || tag == 'ol';
    if (!isList) {
      var listLength = 0;
      for (final list in elementsWithTag(node, const ['ul', 'ol'])) {
        listLength += innerText(list).length;
      }
      isList = listLength / innerText(node).length > 0.9;
    }

    // A data table, in one or holding one, stays; and so does code.
    if (tag == 'table' && isDataTable(node)) return false;
    if (hasAncestorTag(node, 'table', maxDepth: -1, filter: isDataTable)) {
      return false;
    }
    if (hasAncestorTag(node, 'code')) return false;
    if (elementsWithTag(node, const ['table']).any(isDataTable)) return false;

    final weight = classWeight(node);
    if (weight < 0) return true;
    if (charCount(node) >= 10) return false;

    // Few commas: more non-paragraphs than paragraphs, or other ominous
    // signs, and it goes.
    final p = elementsWithTag(node, const ['p']).length;
    final img = elementsWithTag(node, const ['img']).length;
    final li = elementsWithTag(node, const ['li']).length - 100;
    final input = elementsWithTag(node, const ['input']).length;
    final headingDensity = textDensity(node, const [
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
    ]);

    var embedCount = 0;
    for (final embed in elementsWithTag(node, const [
      'object',
      'embed',
      'iframe',
    ])) {
      // A video's embed keeps the block. (Upstream also looks inside an
      // `object`, behind a test no HTML document passes; see `clean`.)
      if (embed.attributes.values.any(allowedVideoRegex.hasMatch)) {
        return false;
      }
      embedCount++;
    }

    final text = innerText(node);
    // Nothing but the words of an ad or a loading indicator.
    if (ReadabilityPatterns.adWords.hasMatch(text) ||
        ReadabilityPatterns.loadingWords.hasMatch(text)) {
      return true;
    }

    final contentLength = text.length;
    final density = linkDensity(node);
    final textishTags = [
      'span',
      'li',
      'td',
      for (final tag in divToPElems) tag.toLowerCase(),
    ];
    final textDensityOfNode = textDensity(node, textishTags);
    final isFigureChild = hasAncestorTag(node, 'figure');
    final linkModifier = options.linkDensityModifier;

    final haveToRemove =
        (!isFigureChild && img > 1 && p / img < 0.5) ||
        (!isList && li > p) ||
        (input > p ~/ 3) ||
        (!isList &&
            !isFigureChild &&
            headingDensity < 0.9 &&
            contentLength < 25 &&
            (img == 0 || img > 2) &&
            density > 0) ||
        (!isList && weight < 25 && density > 0.2 + linkModifier) ||
        (weight >= 25 && density > 0.5 + linkModifier) ||
        ((embedCount == 1 && contentLength < 75) || embedCount > 1) ||
        (img == 0 && textDensityOfNode == 0);

    // A simple list of pictures stays: every item one picture.
    if (isList && haveToRemove) {
      for (final child in node.children) {
        if (child.children.length > 1) return haveToRemove;
      }
      if (img == elementsWithTag(node, const ['li']).length) return false;
    }
    return haveToRemove;
  }
}
