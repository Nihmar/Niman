// Looking up a selection of a scan's recognized text (#1383): Look up in the
// Text pane's selection menu, in the library's first spelling language, and
// no annotating of the passage with the definition (the pane annotates
// nothing).
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/dictionary/dictionary_installation.dart';
import 'package:niman/src/dictionary/dictionary_providers.dart';
import 'package:niman/src/dictionary/dictionary_service.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/ui/ocr/ocr_text_pane.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../unit/dictionary/fixture_packs.dart';

void main() {
  late Directory dir;
  late DictionaryService service;
  late DictionaryInstallation installation;
  late FakeLibrarySession library;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('niman_ocr_look');
    final packs = Directory(p.join(dir.path, 'dictionary'));
    service = DictionaryService(directory: packs.path);
    await writeFixturePacks(packs.path);
    await service.prepare('it');
    await service.prepare('en');
    installation = DictionaryInstallation(
      directory: () async => packs.path,
      service: () async => service,
      catalog: const [],
    );
    await installation.load();
    library = FakeLibrarySession();
    await library.open('/fake/library', create: true);
  });

  tearDown(() async {
    installation.dispose();
    await service.dispose();
    for (var i = 0; i < 20 && dir.existsSync(); i++) {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(500, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dictionaryServiceProvider.overrideWith((ref) async => service),
          dictionaryInstallationProvider.overrideWithValue(installation),
          librarySessionProvider.overrideWithValue(library),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: OcrTextPane(
              path: 'Scans/page.ocr.md',
              text: 'caminetti nella stanza\n',
              onOpenAsNote: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the selection offers Look up first, and the library\'s first '
      'spelling language is the one it is looked up in', (tester) async {
    await library.setSpellDictionaries(['it_IT', 'en_US']);
    await pump(tester);
    expect(
      [
        for (final action
            in tester
                .widget<MarkdownReadView>(find.byType(MarkdownReadView))
                .selectionActions!)
          action.label,
      ],
      [AppStrings.lookUpAction],
    );

    await tester.longPressAt(
      tester.getTopLeft(find.textContaining('caminetti')) + const Offset(4, 8),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.lookUpAction));
    await tester.pump();
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
      if (find.byKey(const Key('lookup-entries')).evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('lookup-title'))).data,
      'caminetto',
    );
    // A scan's text has no passage to annotate: the icon is there, greyed.
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('lookup-annotate')))
          .onPressed,
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
