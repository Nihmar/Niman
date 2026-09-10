import 'dart:convert';

import 'package:copist/src/editor/wysiwyg/markdown_blocks.dart';
import 'package:copist/src/editor/wysiwyg/opaque_embed.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:markdown/markdown.dart' as md;

/// A decoded note: the document the editor edits plus the exact bytes it
/// came from and a snapshot used to detect "no edit".
final class DecodedNote {
  /// Creates a decoded note.
  const new({
    required this.source,
    required this.document,
    required this.snapshot,
  });

  /// The file's exact bytes.
  final String source;

  /// The Quill document for the editor.
  final quill.Document document;

  /// The document's Delta JSON at decode time, to detect "no edit".
  final List<Map<String, dynamic>> snapshot;
}

/// Markdown <-> Quill Delta with opaque preservation.
///
/// Opening a note and saving it without edits returns the original bytes;
/// an edit serializes the document canonically while every opaque block is
/// emitted verbatim. See plan/m-wysiwyg-editor.md for the measured reasons.
final class MarkdownDocumentCodec {
  /// Creates the codec.
  const new();

  static String get _nl => String.fromCharCode(10);
  static String get _tick => String.fromCharCode(96);

  /// Builds the editor document for [source].
  DecodedNote decode(String source) {
    final blocks = splitMarkdownBlocks(source);
    final ops = <Map<String, dynamic>>[];
    for (final block in blocks) {
      if (block.opaque) {
        ops
          ..add(<String, dynamic>{
            'insert': <String, dynamic>{
              opaqueEmbedKey: <String, dynamic>{
                'tag': block.tag,
                'source': block.source,
              },
            },
          })
          ..add(<String, dynamic>{'insert': _nl});
      } else {
        ops.addAll(_blockOps(block));
      }
    }
    // Quill refuses an empty document ("Document Delta cannot be empty"), and
    // an empty note is a note: give it the one empty line every document
    // needs. The no-edit guard still writes the original bytes back.
    if (ops.isEmpty) ops.add(<String, dynamic>{'insert': _nl});
    final document = quill.Document.fromJson(ops);
    return DecodedNote(
      source: source,
      document: document,
      snapshot: document.toDelta().toJson(),
    );
  }

  /// Markdown for [document].
  ///
  /// When [decoded] is given and the document did not change, its original
  /// bytes are returned unchanged (the byte-stability guarantee). Otherwise
  /// the document is serialized canonically; opaque blocks are emitted
  /// verbatim.
  String encode(quill.Document document, {DecodedNote? decoded}) {
    final json = document.toDelta().toJson();
    if (decoded != null && _sameJson(json, decoded.snapshot)) {
      return decoded.source;
    }
    final buffer = StringBuffer();
    var runs = <({String text, Map<String, dynamic> attrs})>[];
    var pendingOpaque = false;
    for (final op in json) {
      final insert = op['insert'];
      final attrs = (op['attributes'] as Map<String, dynamic>?) ?? const {};
      if (insert is Map<String, dynamic> &&
          insert.containsKey(opaqueEmbedKey)) {
        final value = insert[opaqueEmbedKey];
        final source = value is Map ? value['source'] : null;
        if (source is String) {
          buffer.write(source.endsWith(_nl) ? source : '$source$_nl');
          pendingOpaque = true;
        }
        continue;
      }
      if (insert is! String) continue;
      final parts = insert.split(_nl);
      for (var i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) runs.add((text: parts[i], attrs: attrs));
        if (i < parts.length - 1) {
          if (pendingOpaque) {
            pendingOpaque = false;
          } else {
            buffer.write(_renderLine(runs, attrs));
          }
          runs = <({String text, Map<String, dynamic> attrs})>[];
        }
      }
    }
    if (runs.isNotEmpty) {
      buffer.write(_renderLine(runs, const <String, dynamic>{}));
    }
    return buffer.toString();
  }

  List<Map<String, dynamic>> _blockOps(MarkdownBlock block) {
    final node = block.node!;
    if (node.tag == 'pre') return _codeOps(node);
    if (node.tag == 'ul' || node.tag == 'ol') {
      return _listOps(node, tag: node.tag, indent: 0);
    }
    final attrs = _lineAttributes(block);
    return <Map<String, dynamic>>[
      ..._inlineOps(
        node.children ?? const <md.Node>[],
        const <String, dynamic>{},
      ),
      <String, dynamic>{
        'insert': _nl,
        if (attrs.isNotEmpty) 'attributes': attrs,
      },
    ];
  }

  Map<String, dynamic> _lineAttributes(MarkdownBlock block) {
    if (block.level > 0) return <String, dynamic>{'header': block.level};
    if (block.tag == 'blockquote') {
      return <String, dynamic>{'blockquote': true};
    }
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _codeOps(md.Element pre) {
    final children = pre.children ?? const <md.Node>[];
    final code = children.isEmpty ? null : children.first;
    final lang = code is md.Element
        ? (code.attributes['class'] ?? '').replaceFirst('language-', '')
        : '';
    return <Map<String, dynamic>>[
      <String, dynamic>{'insert': pre.textContent},
      <String, dynamic>{
        'insert': _nl,
        'attributes': <String, dynamic>{
          'code-block': true,
          if (lang.isNotEmpty) 'copist-lang': lang,
        },
      },
    ];
  }

  List<Map<String, dynamic>> _listOps(
    md.Element list, {
    required String tag,
    required int indent,
  }) {
    final ops = <Map<String, dynamic>>[];
    for (final item in list.children ?? const <md.Node>[]) {
      if (item is! md.Element || item.tag != 'li') continue;
      final inline = <md.Node>[];
      final nested = <md.Element>[];
      var type = tag == 'ol' ? 'ordered' : 'bullet';
      for (final child in item.children ?? const <md.Node>[]) {
        if (child is md.Element && (child.tag == 'ul' || child.tag == 'ol')) {
          nested.add(child);
        } else if (child is md.Element && child.tag == 'input') {
          type = child.attributes['checked'] != null ? 'checked' : 'unchecked';
        } else {
          inline.add(child);
        }
      }
      ops
        ..addAll(_inlineOps(inline, const <String, dynamic>{}))
        ..add(<String, dynamic>{
          'insert': _nl,
          'attributes': <String, dynamic>{
            'list': type,
            if (indent > 0) 'indent': indent,
          },
        });
      for (final child in nested) {
        ops.addAll(_listOps(child, tag: child.tag, indent: indent + 1));
      }
    }
    return ops;
  }

  List<Map<String, dynamic>> _inlineOps(
    List<md.Node> nodes,
    Map<String, dynamic> style,
  ) {
    final ops = <Map<String, dynamic>>[];
    for (final node in nodes) {
      if (node is md.Text) {
        if (node.text.isNotEmpty) {
          ops.add(<String, dynamic>{
            'insert': node.text,
            if (style.isNotEmpty) 'attributes': style,
          });
        }
        continue;
      }
      if (node is! md.Element) continue;
      final next = Map<String, dynamic>.of(style);
      switch (node.tag) {
        case 'strong':
          next['bold'] = true;
        case 'em':
          next['italic'] = true;
        case 'del':
          next['strike'] = true;
        case 'code':
          next['code'] = true;
        case 'a':
          next['link'] = node.attributes['href'] ?? '';
      }
      ops.addAll(_inlineOps(node.children ?? const <md.Node>[], next));
    }
    return ops;
  }

  String _renderLine(
    List<({String text, Map<String, dynamic> attrs})> runs,
    Map<String, dynamic> attrs,
  ) {
    final text = runs.map((run) => _renderInline(run.text, run.attrs)).join();
    if (attrs['code-block'] == true) {
      final lang = attrs['copist-lang'];
      final body = text.endsWith(_nl) ? text : '$text$_nl';
      return '~~~${lang is String ? lang : ''}$_nl$body~~~$_nl';
    }
    var prefix = '';
    final header = attrs['header'];
    if (header is int) prefix = '${'#' * header} ';
    switch (attrs['list']) {
      case 'bullet':
        prefix = '- ';
      case 'ordered':
        prefix = '1. ';
      case 'checked':
        prefix = '- [x] ';
      case 'unchecked':
        prefix = '- [ ] ';
    }
    if (attrs['blockquote'] == true) prefix = '> ';
    return '$prefix$text$_nl';
  }

  String _renderInline(String text, Map<String, dynamic> attrs) {
    var out = text;
    if (attrs['code'] == true) out = '$_tick$out$_tick';
    if (attrs['bold'] == true) out = '**$out**';
    if (attrs['italic'] == true) out = '*$out*';
    if (attrs['strike'] == true) out = '~~$out~~';
    if (attrs['underline'] == true) out = '<u>$out</u>';
    final link = attrs['link'];
    if (link is String && link.isNotEmpty) out = '[$out]($link)';
    return out;
  }

  bool _sameJson(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    return jsonEncode(a) == jsonEncode(b);
  }
}
