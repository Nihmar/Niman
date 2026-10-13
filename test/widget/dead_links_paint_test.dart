// #847: a link to nothing is drawn muted — in the editor's two modes and in
// the read view — before it is clicked, and goes back to a link's colour when
// what it names comes to exist. The drawing only asks the note's DeadLinks.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/links/dead_links.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/preview/math_cache.dart';

const MarkdownTheme _theme = MarkdownTheme(
  body: TextStyle(fontSize: 14, height: 1.5, fontFamily: 'monospace'),
  heading1: TextStyle(fontSize: 25),
  heading2: TextStyle(fontSize: 21),
  heading3: TextStyle(fontSize: 18),
  heading4: TextStyle(fontSize: 16),
  heading5: TextStyle(fontSize: 14),
  heading6: TextStyle(fontSize: 13),
  code: TextStyle(fontSize: 14, fontFamily: 'monospace'),
  quote: TextStyle(fontSize: 14),
  tableCell: TextStyle(fontSize: 14),
  tableHeader: TextStyle(fontSize: 14),
  link: TextStyle(fontSize: 14, color: Color(0xFF0000FF)),
  wikilink: TextStyle(
    fontSize: 14,
    color: Color(0xFF0000FF),
    decoration: TextDecoration.underline,
  ),
  tag: TextStyle(fontSize: 14),
  marker: TextStyle(fontSize: 14),
  codeHighlight: <String, TextStyle>{},
  rule: Color(0xFF888888),
  codeBackground: Color(0xFFEEEEEE),
  quoteBar: Color(0xFFCCCCCC),
  tableBorder: Color(0xFFCCCCCC),
  markerDim: Color(0xFF999999),
  blockSpacing: 10,
  listIndentPerLevel: 22,
  quoteIndentPerLevel: 12,
  codePadding: 8,
  quoteBarWidth: 3,
  ruleThickness: 1,
  tableCellPadding: EdgeInsets.all(4),
  lineHeight: 21,
);

/// The colour the first span that is [text] — or, with [exact] off, holds
/// it — is drawn in.
Color? _colourOf(WidgetTester tester, String text, {bool exact = true}) {
  Color? found;
  for (final widget in tester.widgetList<RichText>(find.byType(RichText))) {
    widget.text.visitChildren((span) {
      final drawn = span is TextSpan ? span.text : null;
      if (found == null &&
          drawn != null &&
          (exact ? drawn == text : drawn.contains(text))) {
        found = (span as TextSpan).style?.color;
      }
      return true;
    });
  }
  return found;
}

void main() {
  const text =
      'See [[Live]] and [[Gone]] or [web](https://x.y) and '
      '[a](here.md) and [b](missing.md).';

  group('the read view', () {
    Future<ValueNotifier<DeadLinks>> pumpRead(
      WidgetTester tester,
      DeadLinks initial,
    ) async {
      final dead = ValueNotifier<DeadLinks>(initial);
      addTearDown(dead.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownReadView(
              buffer: SourceBuffer.fromText(text),
              parser: ReadParser(),
              mathCache: MathCache(
                renderer: (tex, {required displayMode}) =>
                    throw UnimplementedError(),
              ),
              deadLinks: dead,
            ),
          ),
        ),
      );
      await tester.pump();
      return dead;
    }

    testWidgets('a dead wikilink is muted, a live one is not', (tester) async {
      await pumpRead(tester, const DeadLinks(wiki: {'Gone'}));
      final theme = markdownThemeOf(
        tester.element(find.byType(MarkdownReadView)),
      );

      expect(_colourOf(tester, 'Live'), theme.wikilink.color);
      expect(_colourOf(tester, 'Gone'), theme.deadWikilink.color);
      expect(theme.deadWikilink.color, isNot(theme.wikilink.color));
      expect(
        theme.deadWikilink.decoration,
        theme.wikilink.decoration,
        reason: 'it is still a link, only a quieter one',
      );
    });

    testWidgets('a dead Markdown link is muted, the others are not', (
      tester,
    ) async {
      await pumpRead(tester, const DeadLinks(href: {'missing.md'}));
      final theme = markdownThemeOf(
        tester.element(find.byType(MarkdownReadView)),
      );

      expect(_colourOf(tester, 'b'), theme.deadLink.color);
      expect(_colourOf(tester, 'a'), theme.link.color);
      expect(_colourOf(tester, 'web'), theme.link.color);
    });

    testWidgets('a link goes live when the answer says it exists now', (
      tester,
    ) async {
      final dead = await pumpRead(tester, const DeadLinks(wiki: {'Gone'}));
      final theme = markdownThemeOf(
        tester.element(find.byType(MarkdownReadView)),
      );
      expect(_colourOf(tester, 'Gone'), theme.deadWikilink.color);

      dead.value = DeadLinks.none;
      await tester.pump();
      expect(_colourOf(tester, 'Gone'), theme.wikilink.color);

      dead.value = const DeadLinks(wiki: {'Live'});
      await tester.pump();
      expect(_colourOf(tester, 'Live'), theme.deadWikilink.color);
      expect(_colourOf(tester, 'Gone'), theme.wikilink.color);
    });
  });

  group('the editor', () {
    Future<ValueNotifier<DeadLinks>> pumpEditor(
      WidgetTester tester,
      MarkdownSurfaceMode mode,
      DeadLinks initial,
    ) async {
      final dead = ValueNotifier<DeadLinks>(initial);
      addTearDown(dead.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownSurface(
              buffer: SourceBuffer.fromText('caret\n\n$text\n'),
              mode: mode,
              theme: _theme,
              showLineNumbers: false,
              deadLinks: dead,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return dead;
    }

    for (final mode in MarkdownSurfaceMode.values) {
      testWidgets('$mode draws a dead link muted and a live one not', (
        tester,
      ) async {
        await pumpEditor(
          tester,
          mode,
          const DeadLinks(wiki: {'Gone'}, href: {'missing.md'}),
        );
        final syntax = SyntaxColors.of(
          tester.element(find.byType(MarkdownSourceView)),
        );

        expect(_colourOf(tester, 'Gone', exact: false), syntax.deadLink);
        expect(_colourOf(tester, 'Live', exact: false), syntax.wikilink);
        // `live` hides a link's `](href)`; its text is what is drawn, and
        // `source` shows the link whole.
        final live = mode == MarkdownSurfaceMode.live;
        expect(
          _colourOf(tester, live ? 'b' : 'missing.md', exact: live),
          syntax.deadLink,
        );
        expect(
          _colourOf(tester, live ? 'a' : 'here.md', exact: live),
          syntax.link,
        );
        expect(syntax.deadLink, isNot(syntax.wikilink));
      });
    }

    testWidgets('a link is drawn live again when it comes to exist', (
      tester,
    ) async {
      final dead = await pumpEditor(
        tester,
        MarkdownSurfaceMode.source,
        const DeadLinks(wiki: {'Gone'}),
      );
      final syntax = SyntaxColors.of(
        tester.element(find.byType(MarkdownSourceView)),
      );
      expect(_colourOf(tester, 'Gone', exact: false), syntax.deadLink);

      dead.value = DeadLinks.none;
      await tester.pump();
      expect(_colourOf(tester, 'Gone', exact: false), syntax.wikilink);
    });

    testWidgets('with nothing to say, links are drawn as they always were', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownSurface(
              buffer: SourceBuffer.fromText('caret\n\n$text\n'),
              mode: MarkdownSurfaceMode.source,
              theme: _theme,
              showLineNumbers: false,
            ),
          ),
        ),
      );
      await tester.pump();
      final syntax = SyntaxColors.of(
        tester.element(find.byType(MarkdownSourceView)),
      );
      expect(_colourOf(tester, 'Gone', exact: false), syntax.wikilink);
    });
  });

  group('the dead-link colours of a palette', () {
    test(
      "are the link colour drawn toward the markers' dim, in both modes",
      () {
        for (final colors in [
          SyntaxColors.fallbackLight,
          SyntaxColors.fallbackDark,
        ]) {
          expect(colors.deadLink, isNot(colors.wikilink));
          expect(colors.deadLink, isNot(colors.dim));
          // Closer to the dim than to the link: muted, not merely tinted.
          double distance(Color a, Color b) =>
              (a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs();
          expect(
            distance(colors.deadLink, colors.dim),
            lessThan(distance(colors.deadLink, colors.wikilink)),
          );
        }
      },
    );
  });
}
