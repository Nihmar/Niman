/// The slivers of the read view's page: the note's blocks, then its
/// footnotes.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/footnote_list.dart';
import 'package:niman/src/markdown/render/markdown_blocks_sliver.dart';
import 'package:niman/src/markdown/render/read_entries.dart';
import 'package:niman/src/markdown/render/read_segments.dart';
import 'package:niman/src/preview/math_cache.dart';

/// The note's blocks of [entries], placed by [heights] and drawn by
/// [blockAt] in [width], then its footnotes, each inset by [padding] —
/// with a bar between them while [head] says the blocks are the top of
/// the note alone.
List<Widget> readSlivers({
  required ReadEntries entries,
  required BlockHeightMap heights,
  required EdgeInsets padding,
  required double width,
  required bool head,
  required ReadParser parser,
  required MathCache mathCache,
  required ReadBlockBuilder blockAt,
}) {
  return <Widget>[
    SliverPadding(
      padding: padding,
      // A sliver that places its children from the height map and
      // measures the ones it lays out: `SliverVariedExtentList` forced
      // every extent and clipped what was taller than its estimate
      // (#250), and `SliverList` measured them all and made a far jump
      // cost the note (#251).
      sliver: entries.hosts.isEmpty
          ? SliverMarkdownBlocks(
              heights: heights,
              delegate: SliverChildBuilderDelegate(
                (context, index) => blockAt(context, index, width),
                childCount: heights.length,
              ),
            )
          : readSegments(
              heights: heights,
              hosts: entries.hosts,
              width: width,
              gap: entries.gap,
              listIndent: entries.theme.listIndentPerLevel,
              blockAt: blockAt,
            ),
    ),
    // The top of the note is all there is yet: said where the reader
    // runs out of it, rather than a page that just ends.
    if (head)
      SliverPadding(
        padding: padding + const EdgeInsets.symmetric(vertical: 16),
        sliver: const SliverToBoxAdapter(
          child: LinearProgressIndicator(key: Key('read-view-reading-rest')),
        ),
      ),
    // The definitions a note ends with. They are not blocks — no block
    // can draw them, because the definitions never reach the block that
    // cites them — so the section is appended, and through a *lazy* list
    // for the same reason the note itself is: a section that lays out
    // every footnote at the top of the frame costs the frame. Measured:
    // appending it whole took first content from 76 ms to 112 ms on the
    // geometry note and the jump from 9 ms to 56.
    //
    // Keyed by the text it was read from: a list kept across a new text
    // kept its children and where they were laid out, and a far offset
    // had it asking the viewport for corrections that never agreed — a
    // layout loop (`read_view_geometry_test`, the fixtures in a row).
    SliverPadding(
      key: ObjectKey(entries.shown),
      padding: padding,
      // The footnotes, one row per sliver child.
      sliver: footnoteSliver(
        footnotes: parser.footnotesOf(entries.shown!),
        theme: entries.theme,
        parser: parser,
        mathCache: mathCache,
        scope: parser.scope,
      ),
    ),
  ];
}
