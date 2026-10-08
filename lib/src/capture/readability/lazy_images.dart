/// Pictures that load only with scripts (`_fixLazyImages`): a `data-src`
/// and the like moved to `src` or `srcset`, and a tiny placeholder `src`
/// dropped for it.
///
/// Ported from mozilla/readability (Readability.js 0.6.0, commit 04fd32f),
/// Apache-2.0.
library;

import 'package:html/dom.dart';
import 'package:niman/src/capture/readability/dom.dart';
import 'package:niman/src/capture/readability/patterns.dart';
import 'package:niman/src/capture/readability/run.dart';

/// The lazy pictures.
extension ReadabilityLazyImages on ReadabilityRun {
  /// What a browser's `img.src` is: '' without the attribute, the attribute
  /// resolved otherwise — and the document itself for an empty one. Only
  /// an `img` has it.
  String? _srcProperty(Element element) {
    if (tagNameOf(element) != 'IMG') return null;
    final src = attributeOf(element, 'src');
    if (src == null) return '';
    return src.isEmpty ? documentUri?.toString() ?? '' : src;
  }

  /// Makes the pictures under [root] load without scripts.
  void fixLazyImages(Element root) {
    for (final element in elementsWithTag(root, const [
      'img',
      'picture',
      'figure',
    ])) {
      var src = _srcProperty(element);
      // A one-pixel base64 picture in `src` (Kotaku) is a placeholder, when
      // another attribute names a picture.
      final parts = src == null
          ? null
          : ReadabilityPatterns.b64DataUrl.firstMatch(src);
      if (parts != null) {
        // An SVG says a lot in under 133 bytes.
        if (parts[1] == 'image/svg+xml') continue;
        final srcCouldBeRemoved = element.attributes.entries.any(
          (attribute) =>
              attribute.key.toString() != 'src' &&
              ReadabilityPatterns.imageExtension.hasMatch(attribute.value),
        );
        if (srcCouldBeRemoved && src!.length - parts[0]!.length < 133) {
          element.attributes.remove('src');
          src = '';
        }
      }

      final srcset = tagNameOf(element) == 'IMG'
          ? attributeOf(element, 'srcset') ?? ''
          : null;
      if (((src != null && src.isNotEmpty) ||
              (srcset != null && srcset.isNotEmpty && srcset != 'null')) &&
          !element.className.toLowerCase().contains('lazy')) {
        continue;
      }

      for (final attribute in element.attributes.entries.toList()) {
        final name = attribute.key.toString();
        if (name == 'src' || name == 'srcset' || name == 'alt') continue;
        final value = attribute.value;
        String? copyTo;
        if (RegExp(r'\.(jpg|jpeg|png|webp)\s+\d').hasMatch(value)) {
          copyTo = 'srcset';
        } else if (RegExp(r'^\s*\S+\.(jpg|jpeg|png|webp)\S*\s*$')
            .hasMatch(value)) {
          copyTo = 'src';
        }
        if (copyTo == null) continue;
        final tag = tagNameOf(element);
        if (tag == 'IMG' || tag == 'PICTURE') {
          element.attributes[copyTo] = value;
        } else if (tag == 'FIGURE' &&
            elementsWithTag(element, const ['img', 'picture']).isEmpty) {
          // A figure with no picture in it gets one (nytimes-3).
          element.append(Element.tag('img')..attributes[copyTo] = value);
        }
      }
    }
  }
}
