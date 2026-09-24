// `![[…]]` embeds in the read mode: images render inline, other binaries and
// missing targets render as the note's own text, and a plain wikilink beside
// one stays a wikilink.
//
// The same five cases `embed_test.dart` holds for the legacy preview — which is
// where they only existed until now: the read view's embed path was written in
// phase 2 and never verified, so "images render" was a claim rather than a test
// (asked on a device, 2026-09-21).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart' show KatexOptions, renderToBox;
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

/// The transparent 1x1 PNG the test image uses.
const _onePxPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42'
    'mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

void main() {
  late Directory temp;
  late File png;
  late File epub;

  setUpAll(() async {
    temp = await Directory.current.createTemp('niman_read_embed_');
    png = File('${temp.path}/img.png')
      ..writeAsBytesSync(base64Decode(_onePxPng));
    epub = File('${temp.path}/book.epub')..writeAsStringSync('not a zip');
  });

  tearDownAll(() async {
    await temp.delete(recursive: true);
  });

  Future<void> pump(
    WidgetTester tester,
    String data, {
    Future<String?> Function(String target)? resolve,
    void Function(String ref, String? display)? onWikiLink,
  }) async {
    tester.view.physicalSize = const Size(600, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cache = MathCache(
      renderer: (tex, {required displayMode}) =>
          renderToBox(tex, options: KatexOptions(displayMode: displayMode)),
    );
    addTearDown(cache.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownReadView(
            buffer: SourceBuffer.fromText(data),
            parser: BlockParser(),
            mathCache: cache,
            embedResolver: resolve,
            onTapWikiLink: onWikiLink == null
                ? null
                : (span) => onWikiLink(span.text, null),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('an image embed renders inline', (tester) async {
    await pump(
      tester,
      'before ![[img.png]] after\n',
      resolve: (_) async => png.path,
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.textContaining('![[img.png]]'), findsNothing);
  });

  testWidgets("a binary embed renders the note's own text", (tester) async {
    await pump(
      tester,
      'see ![[book.epub]] here\n',
      resolve: (_) async => epub.path,
    );
    expect(find.byType(Image), findsNothing);
    expect(
      find.textContaining('![[book.epub]]', findRichText: true),
      findsWidgets,
    );
  });

  testWidgets('a missing target renders its text (no crash)', (tester) async {
    await pump(tester, 'gone ![[nowhere.jpeg]]\n', resolve: (_) async => null);
    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('![[nowhere.jpeg]]', findRichText: true),
      findsWidgets,
    );
  });

  testWidgets('an alias displays instead of the raw target', (tester) async {
    await pump(
      tester,
      '![[book.epub|The book]]\n',
      resolve: (_) async => epub.path,
    );
    expect(
      find.textContaining('![[The book]]', findRichText: true),
      findsWidgets,
    );
  });

  testWidgets('a plain wikilink beside an embed stays a wikilink', (
    tester,
  ) async {
    final tapped = <String>[];
    await pump(
      tester,
      '![[img.png]] and [[Other]]\n',
      resolve: (_) async => png.path,
      onWikiLink: (ref, display) => tapped.add(ref),
    );
    expect(find.byType(Image), findsOneWidget);
    // Tap the wikilink's own glyphs: the paragraph is a whole line wide, and
    // its centre is not where the word is.
    await tester.tapOnText(find.textRange.ofSubstring('Other'));
    await tester.pump();
    expect(tapped, isNotEmpty, reason: 'the wikilink still follows');
  });
}
