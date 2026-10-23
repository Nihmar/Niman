/// What every piece of a rastered kanban board is drawn with (#1170): the
/// export's type and colours, and the note's definitions.
///
/// A card is drawn on its own, from a piece of the note's text, but what it
/// cites is defined anywhere in the note: a reference link in one card, its
/// definition in the prose before the board or in another card, a footnote
/// cited in a title and defined under a column. The board's pieces are read
/// by one [ReadParser] given the note's [DocumentScope] — the read view's own
/// mechanism for resolving a reference across blocks — so a piece resolves
/// what the HTML board resolves, and the footnotes are numbered over the
/// whole note.
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:niman/src/kanban/kanban_board.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/inline/inline_parser.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/inline_spans.dart';
import 'package:niman/src/markdown/render/markdown_export.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

/// The drawing context of one rastered board.
final class BoardRasterContext {
  /// A context for [board], drawn with [theme]: the definitions are
  /// scanned off the board's lines, the settings footer left out.
  factory({
    required KanbanBoard board,
    required MarkdownTheme theme,
    required MathCache mathCache,
    Map<String, ui.Image>? images,
  }) {
    final buffer = SourceBuffer.fromText(
      [
        for (var i = 0; i < board.contentEnd; i++)
          if (board.lines[i].endsWith('\r'))
            board.lines[i].substring(0, board.lines[i].length - 1)
          else
            board.lines[i],
      ].join('\n'),
    );
    return BoardRasterContext._(
      theme: theme,
      mathCache: mathCache,
      images: images,
      scope: DocumentScope.scan(buffer, buffer.revision),
    );
  }

  new _({
    required this.theme,
    required this.mathCache,
    required this.images,
    required this.scope,
  }) : parser = ReadParser()..shared = scope {
    numbers = parser.footnoteNumbersOf(scope);
  }

  /// The export's type and colours.
  final MarkdownTheme theme;

  /// The formulas typeset so far.
  final MathCache mathCache;

  /// The note's pictures, decoded, by the target as written.
  final Map<String, ui.Image>? images;

  /// The note's reference links and footnotes.
  final DocumentScope scope;

  /// Reads every piece with [scope].
  final ReadParser parser;

  /// The number each footnote is cited as, over the whole note.
  late final Map<String, int> numbers;

  /// Inline Markdown as spans in [base]: a link, a wikilink, a formula, a
  /// picture or a footnote mark as the read view draws it, tapping nothing,
  /// its references resolved against the note.
  InlineSpan inline(String text, {required TextStyle base}) => TextSpan(
    style: base,
    children:
        InlineSpans(
          theme: theme,
          base: base,
          mathCache: mathCache,
          footnoteNumbers: numbers,
          taps: (
            onTapLink: null,
            onTapWikiLink: null,
            embedResolver: null,
            embedImages: images,
            deadLinks: null,
            linkPreview: null,
          ),
        ).of(
          ReadInline(
            text: text,
            nodes: text.isEmpty
                ? const []
                : InlineParser(
                    text,
                    references: scope.references,
                    footnotes: scope.footnoteKeys,
                  ).parse(),
          ),
        ),
  );

  /// [text] as the note's blocks, [width] wide, with no padding.
  Widget blocks(String text, double width) => MarkdownExportView(
    buffer: SourceBuffer.fromText(text),
    parser: parser,
    theme: theme,
    mathCache: mathCache,
    width: width,
    padding: EdgeInsets.zero,
    embedImages: images,
  );
}

/// A definition line: a reference link's `[label]: …` or a footnote's
/// `[^label]: …`.
final RegExp _definitionLine = RegExp(r'^ {0,3}\[[^\]]+\]:');

/// Whether [lines] hold nothing but definitions — each drawn as nothing —
/// and the blank lines and the indented lines that go on a footnote's body.
bool onlyDefinitions(List<String> lines) {
  var inside = false;
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    if (_definitionLine.hasMatch(line)) {
      inside = true;
    } else if (!(inside && (line.startsWith(' ') || line.startsWith('\t')))) {
      return false;
    }
  }
  return true;
}
