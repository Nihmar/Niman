// The user-requested T-M3-07 extension: `![[…]]` links — image embeds
// render inline, other binaries (epub, pdf, …) and missing targets render
// as muted path text, and the parse leaves wikilinks untouched.
import 'dart:convert';
import 'dart:io';

import 'package:copist/src/preview/markdown_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The transparent 1x1 PNG the test image uses.
const _onePxPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42'
    'mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

void main() {
  late Directory temp;
  late File png;
  late File epub;

  setUpAll(() async {
    temp = await Directory.current.createTemp('copist_embed_');
    png = File('${temp.path}/img.png')
      ..writeAsBytesSync(base64Decode(_onePxPng));
    epub = File('${temp.path}/book.epub')..writeAsStringSync('not a zip');
  });

  tearDownAll(() async {
    await temp.delete(recursive: true);
  });

  Widget app({
    required String data,
    Future<String?> Function(String)? resolve,
  }) => MaterialApp(
    home: Scaffold(
      body: MarkdownPreview(
        data: data,
        embedResolver: resolve,
      ),
    ),
  );

  testWidgets('an image embed renders inline', (tester) async {
    await tester.pumpWidget(
      app(
        data: 'before ![[img.png]] after\n',
        resolve: (_) async => png.path,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(find.textContaining('![[img.png]]'), findsNothing);
  });

  testWidgets('a binary embed renders muted path text', (tester) async {
    await tester.pumpWidget(
      app(
        data: 'see ![[book.epub]] here\n',
        resolve: (_) async => epub.path,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(find.text('![[book.epub]]'), findsOneWidget);
  });

  testWidgets('a missing target renders path text (no crash)', (tester) async {
    await tester.pumpWidget(
      app(
        data: 'gone ![[nowhere.jpeg]]\n',
        resolve: (_) async => null,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('![[nowhere.jpeg]]'), findsOneWidget);
  });

  testWidgets('an alias displays instead of the raw target', (tester) async {
    await tester.pumpWidget(
      app(
        data: '![[book.epub|The book]]\n',
        resolve: (_) async => epub.path,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('![[The book]]'), findsOneWidget);
  });

  testWidgets('a plain wikilink next to an embed stays a wikilink', (
    tester,
  ) async {
    var wikiTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownPreview(
            data: '![[img.png]] and [[Other]]\n',
            embedResolver: (_) async => png.path,
            onWikiLink: (ref, display) => wikiTaps++,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    // The wikilink text is rendered by the wikilink builder (no plain
    // '![[img.png]]' text anywhere).
    expect(find.text('![[img.png]]'), findsNothing);
  });
}
