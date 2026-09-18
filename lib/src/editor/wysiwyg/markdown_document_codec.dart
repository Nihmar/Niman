import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/editor/wysiwyg/markdown_blocks.dart';
import 'package:niman/src/editor/wysiwyg/opaque_embed.dart';

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
/// emitted verbatim. See ANALYSIS.md § "WYSIWYG editor" for
/// the measured reasons.
final class MarkdownDocumentCodec {
  /// Creates the codec.
  const new();

  static String get _nl => String.fromCharCode(10);
  static String get _tick => String.fromCharCode(96);

  /// The number an ordered list starts at, carried on the first item's
  /// line. Quill has no attribute for it; ours travels with the
  /// document the way `niman-lang` does for a fence's language.
  static const String _startKey = 'niman-start';

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
      // The parser drops the blank lines between blocks from the AST, but
      // the block's slice carries them: without this the WYSIWYG view ate
      // them, and the next edit wrote the note without them (device report,
      // 2026-09-11).
      ops.addAll(_trailingBlankLines(block.source));
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
    // A fence is a run of consecutive code-block lines: the markers belong
    // to the group, not to a line. One fence per line, or code text let out
    // of it, is the bug the device report hit (2026-09-11).
    var inCode = false;
    var codeLang = '';
    var codeLines = <String>[];
    // Where each open level's content starts, and what number the next
    // ordered item at it takes.
    final lists = _ListWriter();
    // An empty fence carries nothing: the code button on an empty line made
    // pairs of stray markers in the note, and the device report asked for
    // them gone (2026-09-11).
    void closeCode() {
      if (!inCode) return;
      inCode = false;
      final lines = codeLines;
      codeLines = <String>[];
      if (lines.every((line) => line.isEmpty)) return;
      buffer.write('~~~$codeLang$_nl');
      for (final line in lines) {
        buffer
          ..write(line)
          ..write(_nl);
      }
      buffer.write('~~~$_nl');
    }

    void flush(Map<String, dynamic> attrs) {
      final text = runs.map((run) => _renderInline(run.text, run.attrs)).join();
      runs = <({String text, Map<String, dynamic> attrs})>[];
      if (attrs['code-block'] == true) {
        if (!inCode) {
          final lang = attrs['niman-lang'];
          codeLang = lang is String ? lang : '';
          inCode = true;
        }
        codeLines.add(text);
        return;
      }
      closeCode();
      final item = lists.line(attrs, text);
      if (item != null) {
        buffer.write(item);
        return;
      }
      // A blank line between items is what makes a list loose, not what
      // ends it; prose does end it.
      if (text.trim().isNotEmpty) lists.reset();
      buffer.write(_renderLine(text, attrs));
    }

    for (final op in json) {
      final insert = op['insert'];
      final attrs = (op['attributes'] as Map<String, dynamic>?) ?? const {};
      if (insert is Map<String, dynamic> &&
          insert.containsKey(opaqueEmbedKey)) {
        closeCode();
        final value = insert[opaqueEmbedKey];
        final source = value is Map ? value['source'] : null;
        if (source is String) {
          buffer.write(source.endsWith(_nl) ? source : '$source$_nl');
          pendingOpaque = true;
          lists.reset();
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
            flush(attrs);
          }
        }
      }
    }
    if (runs.isNotEmpty) flush(const <String, dynamic>{});
    closeCode();
    return buffer.toString();
  }

  /// The empty lines a block's source carries after its content: the first
  /// newline ends the block's own line, every further one is a blank line.
  static List<Map<String, dynamic>> _trailingBlankLines(String source) {
    var newlines = 0;
    for (var i = source.length - 1; i >= 0 && source[i] == _nl; i--) {
      newlines++;
    }
    final blanks = newlines == 0 ? 0 : newlines - 1;
    return <Map<String, dynamic>>[
      for (var i = 0; i < blanks; i++) <String, dynamic>{'insert': _nl},
    ];
  }

  List<Map<String, dynamic>> _blockOps(MarkdownBlock block) {
    final node = block.node!;
    if (node.tag == 'pre') return _codeOps(node);
    if (node.tag == 'ul' || node.tag == 'ol') {
      return _listOps(node, tag: node.tag, indent: 0, source: block.source);
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
    // Every line inside the fence carries the code-block attribute: Quill's
    // block format lives on the line's newline, and one multi-line insert
    // with no attribute put the code outside the block (device report,
    // 2026-09-11).
    final lines = pre.textContent.split(_nl);
    if (lines.isNotEmpty && lines.last.isEmpty) lines.removeLast();
    if (lines.isEmpty) lines.add('');
    return <Map<String, dynamic>>[
      for (final line in lines) ...<Map<String, dynamic>>[
        <String, dynamic>{'insert': line},
        <String, dynamic>{
          'insert': _nl,
          'attributes': <String, dynamic>{
            'code-block': true,
            if (lang.isNotEmpty) 'niman-lang': lang,
          },
        },
      ],
    ];
  }

  List<Map<String, dynamic>> _listOps(
    md.Element list, {
    required String tag,
    required int indent,
    String? source,
  }) {
    final ops = <Map<String, dynamic>>[];
    final items = <md.Element>[
      for (final item in list.children ?? const <md.Node>[])
        if (item is md.Element && item.tag == 'li') item,
    ];
    final blankBefore = _blankLinesBefore(items.length, source);
    // A list that does not start at 1 says so on its `ol` element, and
    // nowhere in the Delta unless it is put there: a `3.` list came back
    // as `1.` and rendered two numbers lower than it was written.
    final start = tag == 'ol'
        ? int.tryParse(list.attributes['start'] ?? '')
        : null;
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (blankBefore[index]) ops.add(<String, dynamic>{'insert': _nl});
      final inline = <md.Node>[];
      final nested = <md.Element>[];
      var type = tag == 'ol' ? 'ordered' : 'bullet';
      for (final child in _itemChildren(item)) {
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
            if (index == 0 && start != null && start != 1) _startKey: start,
          },
        });
      for (final child in nested) {
        ops.addAll(_listOps(child, tag: child.tag, indent: indent + 1));
      }
    }
    return ops;
  }

  /// A top-level item's marker: `-`, `*`, `+`, `1.` or `1)`, indented by
  /// at most the three spaces that still leave it top level.
  static final RegExp _itemMarker = RegExp(r'^([ \t]*)(?:[-*+]|\d{1,9}[.)])\s');

  /// Which of a list's [count] items are written a blank line below the
  /// one before them, read off [source].
  ///
  /// The blank lines of a *loose* list are the list: without them the
  /// round trip pulled a spaced-out list closed on every save, and a
  /// list a blank line under another one — which CommonMark reads as one
  /// loose list, not two — came back glued to it.
  ///
  /// The AST says whether a list is loose (the item content keeps its
  /// `p` wrapper) but not where its blank lines are, so they are counted
  /// in the text. When the markers found are not the items parsed — an
  /// item holding a fenced block whose content looks like a marker, say
  /// — nothing is claimed rather than a blank line put in the wrong gap.
  static List<bool> _blankLinesBefore(int count, String? source) {
    final none = List<bool>.filled(count, false);
    if (source == null || count == 0) return none;
    final lines = const LineSplitter().convert(source);
    final marks = <({int indent, bool blankAbove})>[];
    for (var i = 0; i < lines.length; i++) {
      final match = _itemMarker.firstMatch(lines[i]);
      if (match == null) continue;
      marks.add((
        indent: match.group(1)!.length,
        blankAbove: i > 0 && lines[i - 1].trim().isEmpty,
      ));
    }
    if (marks.isEmpty) return none;
    // The list's own items are the ones at the indent it starts at;
    // anything deeper belongs to a sublist, which is handed its own
    // slice of nothing when the recursion reaches it.
    final base = marks.first.indent;
    final out = <bool>[
      for (final mark in marks)
        if (mark.indent == base) mark.blankAbove,
    ];
    return out.length == count ? out : none;
  }

  /// A list item's content with one level of `p` flattened.
  ///
  /// A *loose* list — one with a blank line between its items — wraps
  /// each item's content in a `p`, and the task-list checkbox goes
  /// inside that `p` rather than beside it. Scanning only the item's own
  /// children therefore found the box in a tight list and missed it in a
  /// loose one, and a missed box is not a display fault: the line came
  /// back a plain bullet, and saving wrote `- [x] done` back out as
  /// `- done`. Found here for both shapes instead.
  ///
  /// Every other child is passed through untouched, so an item's
  /// paragraphs still become the one Quill line they always did.
  Iterable<md.Node> _itemChildren(md.Element item) sync* {
    for (final child in item.children ?? const <md.Node>[]) {
      if (child is md.Element && child.tag == 'p') {
        yield* child.children ?? const <md.Node>[];
      } else {
        yield child;
      }
    }
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

  /// A line that is not a list item — those go through [_ListWriter],
  /// which is the only thing that knows where a level's content starts.
  String _renderLine(String text, Map<String, dynamic> attrs) {
    var prefix = '';
    final header = attrs['header'];
    if (header is int) prefix = '${'#' * header} ';
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

/// Writes a list's lines: where each open level's content starts, and
/// what number an ordered item at it takes.
///
/// A nested list has to be indented to its parent item's content
/// column, or it is not nested at all — and that column is the parent's
/// own indent plus the width of its marker, which is two for `- `,
/// three for `1. ` and four for `10. `. The Delta records a depth, not a
/// column, so the columns are rebuilt here from the markers as the
/// lines are written. Indenting by some fixed width instead would be
/// wrong under one kind of parent or the other, and this way the
/// indentation comes back exactly as it was written.
final class _ListWriter {
  /// The content column of the last line written at each level.
  final List<int> _columns = <int>[];

  /// The number the next ordered item takes, per level.
  final List<int> _counters = <int>[];

  /// The Markdown for a list item, or null when the line is not one.
  String? line(Map<String, dynamic> attrs, String text) {
    final list = attrs['list'];
    if (list is! String) return null;
    // A depth with no level open above it would not read as nesting
    // anyway, so it is clamped to one below the deepest level open.
    final depth = attrs['indent'];
    final level = (depth is int && depth > 0 ? depth : 0).clamp(
      0,
      _columns.length,
    );
    final indent = level == 0 ? 0 : _columns[level - 1];
    final String marker;
    switch (list) {
      case 'bullet':
        marker = '- ';
      case 'ordered':
        while (_counters.length <= level) {
          _counters.add(1);
        }
        final start = attrs[MarkdownDocumentCodec._startKey];
        if (start is int) _counters[level] = start;
        final number = _counters[level];
        _counters[level] = number + 1;
        marker = '$number. ';
      case 'checked':
        marker = '- [x] ';
      case 'unchecked':
        marker = '- [ ] ';
      default:
        return null;
    }
    while (_columns.length <= level) {
      _columns.add(0);
    }
    _columns[level] = indent + marker.length;
    // A line at this level closes everything under it: a sublist that
    // opens later starts over, at 1 and at its own column.
    _columns.length = level + 1;
    if (_counters.length > level + 1) _counters.length = level + 1;
    return '${' ' * indent}$marker$text\n';
  }

  /// Ends the list; the next one starts over.
  void reset() {
    _columns.clear();
    _counters.clear();
  }
}
