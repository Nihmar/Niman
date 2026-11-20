/// The pictures and formulas of a page, as Markdown.
library;

import 'package:html/dom.dart';
import 'package:niman/src/markdown/text_escape.dart';

/// A picture as a Markdown image: `![alt](target)`.
String markdownImage(String target, String alt) => '![$alt]($target)';

/// A page's pictures, named by the caller and written as it asks.
final class HtmlPictures {
  /// Pictures named by [picture] and written by [embed].
  const new({required this.picture, required this.embed});

  /// The name a picture's `src` is written under, or null to leave it out.
  final String? Function(String src) picture;

  /// How a picture, named, is written into the note.
  final String Function(String target, String alt) embed;

  /// [element]'s picture as the note writes it, or null when it has none
  /// the caller names. A `data:` source reaches [picture] as it is, for a
  /// caller that keeps the picture to write it down.
  String? of(Element element) {
    final img = element.localName == 'svg'
        ? element.querySelector('image')
        : element;
    if (img == null) return null;
    final src = [
      img.attributes['src'],
      attribute(img, 'xlink:href'),
      img.attributes['href'],
      largestOfSrcset(img.attributes['srcset'] ?? ''),
    ].firstWhere((src) => src != null && src.isNotEmpty, orElse: () => null);
    if (src == null) return null;
    final name = picture(src);
    if (name == null) return null;
    final alt = escapeMarkdownText(
      (img.attributes['alt'] ?? '').replaceAll(RegExp(r'\s+'), ' '),
    );
    return embed(name, alt);
  }

  /// The largest picture a `srcset` offers — the widest, else the densest;
  /// the first when none says — or null when it offers none.
  static String? largestOfSrcset(String srcset) {
    String? best;
    var bestSize = -1.0;
    for (final candidate in srcset.split(RegExp(r',\s+|,$'))) {
      final parts = candidate.trim().split(RegExp(r'\s+'));
      if (parts.first.isEmpty) continue;
      final descriptor = parts.length > 1 ? parts[1] : '1x';
      final size =
          double.tryParse(descriptor.substring(0, descriptor.length - 1)) ?? 1;
      if (size > bestSize) {
        best = parts.first;
        bestSize = size;
      }
    }
    return best;
  }

  /// The TeX a formula's SVG carries in its `aria-label`, as the app's own
  /// math syntax: `$…$` in the line, `$$…$$` for a display formula (the
  /// SVG's `math-display` class). Null when the SVG is not a formula — a
  /// picture's, or one with no source to set again.
  ///
  /// Niman's own exports set every formula that way (#303), and the read
  /// view typesets the TeX itself rather than drawing another page's SVG.
  static String? mathOf(Element element) {
    if (element.localName != 'svg') return null;
    final tex = element.attributes['aria-label']?.trim();
    if (tex == null || tex.isEmpty) return null;
    // A `$` inside the TeX would end the span it is written in.
    final escaped = tex.replaceAllMapped(
      RegExp(r'(?<!\\)\$'),
      (match) => r'\$',
    );
    // One `$` in the line, two on a line of its own for a display formula.
    final sign = element.classes.contains('math-display') ? r'$$' : r'$';
    return '$sign$escaped$sign';
  }

  /// [element]'s attribute [name], looked up by how it prints: inside an
  /// SVG the parser keys `xlink:href` by an `AttributeName`, not a string.
  static String? attribute(Element element, String name) => element
      .attributes
      .entries
      .where((entry) => entry.key.toString() == name)
      .firstOrNull
      ?.value;
}
