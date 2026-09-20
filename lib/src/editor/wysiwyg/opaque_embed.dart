import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// The Delta key of a block the codec keeps verbatim.
const String opaqueEmbedKey = 'niman-opaque';

/// Renders an opaque block read-only, as its own source text.
///
/// The codec cannot represent every Markdown construct in Quill (frontmatter,
/// tables, footnotes, math, wikilinks, raw HTML). Those blocks travel through
/// the document as embeds carrying their original source, and this renders
/// them so the writer can still see them; the source is written back
/// byte for byte.
///
/// A section break is the exception that earns its own shape: Quill has no
/// attribute for one, so `---` travels as an opaque block like the rest —
/// but a writer reading the note wants a line across the page, not a box
/// with three hyphens in it (0.0.8 test round). It stays opaque, so the
/// bytes it was written with come back unchanged.
final class OpaqueEmbedBuilder extends quill.EmbedBuilder {
  /// Creates the builder.
  const new();

  @override
  String get key => opaqueEmbedKey;

  @override
  bool get expanded => true;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final data = embedContext.node.value.data;
    final source = data is Map && data['source'] is String
        ? data['source'] as String
        : '';
    final tag = data is Map && data['tag'] is String
        ? data['tag'] as String
        : '';
    if (tag == 'hr') {
      return Padding(
        key: const Key('wysiwyg-section-break'),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        source,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}
