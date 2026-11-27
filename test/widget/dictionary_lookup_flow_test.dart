// Looking a selection up (#1383): the panel a phone gets (a sheet at half the
// window's height) and the one a pointer gets (under the selection, above it
// only where there is no room, closing on Esc or a click outside, updated in
// place by the next look-up), and the language the flow finds.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/dictionary/dictionary_installation.dart';
import 'package:niman/src/dictionary/dictionary_providers.dart';
import 'package:niman/src/dictionary/dictionary_service.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/dictionary_lookup_flow.dart';
import 'package:niman/src/ui/dictionary_panel/panel_placement.dart';
import 'package:niman/src/ui/dictionary_panel/panel_popup.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../unit/dictionary/fixture_packs.dart';

void main() {
  group('where the desktop panel sits', () {
    const window = Size(1000, 700);
    const child = Size(380, 300);

    Offset place(Rect anchor, {Size size = child}) =>
        PanelPlacement(anchor).getPositionForChild(window, size);

    test('under the selection, a little in from its start', () {
      const selection = Rect.fromLTWH(400, 200, 60, 20);
      final at = place(selection);
      expect(at.dy, selection.bottom + 6);
      expect(at.dx, selection.left - 24);
    });

    test('never over the line read: above only when there is no room '
        'below', () {
      // Room below for 300: 700 - 440 - 6 - 8 = 246 is not enough.
      const low = Rect.fromLTWH(400, 420, 60, 20);
      final at = place(low);
      expect(at.dy, low.top - 6 - child.height);
      expect(at.dy + child.height, lessThan(low.top));
    });

    test('a panel that fits below stays below however near the bottom half '
        'the selection is', () {
      const middle = Rect.fromLTWH(400, 300, 60, 20);
      expect(place(middle, size: const Size(380, 340)).dy, middle.bottom + 6);
    });

    test('with no room on either side it takes the larger one, cut to '
        'fit', () {
      const middle = Rect.fromLTWH(400, 340, 60, 20);
      const delegate = PanelPlacement(middle);
      final constraints = delegate.getConstraintsForChild(
        BoxConstraints.loose(window),
      );
      // The room above (326) is larger than below (326)? Both are close:
      // whichever it picks, the cut panel fits it.
      expect(constraints.maxHeight, lessThanOrEqualTo(440));
      final cut = Size(380, constraints.maxHeight);
      final at = delegate.getPositionForChild(window, cut);
      expect(at.dy, greaterThanOrEqualTo(0));
      expect(at.dy + cut.height, lessThanOrEqualTo(window.height));
    });

    test('is as wide as its width, less in a narrow window, and stays '
        'inside it', () {
      const delegate = PanelPlacement(Rect.fromLTWH(960, 100, 30, 20));
      expect(
        delegate.getConstraintsForChild(BoxConstraints.loose(window)).maxWidth,
        380,
      );
      expect(
        delegate
            .getConstraintsForChild(BoxConstraints.loose(const Size(300, 700)))
            .maxWidth,
        284,
      );
      final at = delegate.getPositionForChild(window, child);
      expect(at.dx + child.width, lessThanOrEqualTo(window.width - 8));
      expect(
        const PanelPlacement(Rect.fromLTWH(2, 100, 30, 20))
            .getPositionForChild(window, child)
            .dx,
        8,
      );
    });
  });

  group('the flow', () {
    late Directory dir;
    late Directory root;
    late DictionaryService service;
    late DictionaryInstallation installation;
    late FakeLibrarySession library;

    setUp(() async {
      dir = Directory.systemTemp.createTempSync('niman_flow');
      root = Directory(p.join(dir.path, 'dictionary'));
      service = DictionaryService(directory: root.path);
      await writeFixturePacks(root.path);
      await service.prepare('it');
      await service.prepare('en');
      installation = DictionaryInstallation(
        directory: () async => root.path,
        service: () async => service,
      );
      await installation.load();
      library = FakeLibrarySession();
      await library.open('/fake/library', create: true);
      await library.setSpellDictionaries(['it_IT']);
    });

    tearDown(() async {
      DictionaryPopup.current?.close();
      installation.dispose();
      await service.dispose();
      for (var i = 0; i < 20 && dir.existsSync(); i++) {
        try {
          dir.deleteSync(recursive: true);
        } on FileSystemException {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }
      AppLanguages.reset();
    });

    /// A page with a button that looks [word] up in [surface], under a
    /// pointer's density or a thumb's.
    Future<void> pump(
      WidgetTester tester, {
      required bool pointer,
      Size size = const Size(1000, 700),
      Rect anchor = const Rect.fromLTWH(300, 200, 60, 20),
      String word = 'Caminetti,',
      String? language,
      DictionarySurface surface = DictionarySurface.book,
      DictionaryAnnotate? annotate,
      ValueChanged<String>? onLanguage,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dictionaryServiceProvider.overrideWith((ref) async => service),
            dictionaryInstallationProvider.overrideWithValue(installation),
            librarySessionProvider.overrideWithValue(library),
          ],
          child: MaterialApp(
            theme: ThemeData(
              visualDensity: pointer
                  ? VisualDensity.compact
                  : VisualDensity.standard,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    TextButton(
                      key: const Key('look-up'),
                      onPressed: () => unawaited(
                        showDictionaryLookup(
                          context,
                          selection: word,
                          surface: surface,
                          language: language,
                          anchor: anchor,
                          annotate: annotate,
                          onLanguage: onLanguage,
                        ),
                      ),
                      child: const Text('look up'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    /// Opens the panel, and lets the real engine answer.
    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('look-up')));
      for (var i = 0; i < 100; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
        final answered = [
          'lookup-entries',
          'lookup-not-found',
          'lookup-no-pack',
          'lookup-unavailable',
        ].any((key) => find.byKey(Key(key)).evaluate().isNotEmpty);
        if (answered) break;
      }
    }

    Rect panel(WidgetTester tester) =>
        tester.getRect(find.byKey(const Key('lookup-popup')));
    String title(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('lookup-title'))).data!;

    testWidgets('a pointer gets a panel under the selection, as wide as '
        'the design says', (tester) async {
      await pump(tester, pointer: true);
      await open(tester);
      expect(title(tester), 'caminetto');
      final at = panel(tester);
      expect(at.top, 200 + 20 + 6);
      expect(at.left, 300 - 24);
      expect(at.width, 380);
      expect(find.byKey(const Key('lookup-sheet')), findsNothing);
    });

    testWidgets('near the bottom it opens above the selection, not over '
        'it', (tester) async {
      await pump(
        tester,
        pointer: true,
        anchor: const Rect.fromLTWH(300, 560, 60, 20),
      );
      await open(tester);
      final at = panel(tester);
      expect(at.bottom, lessThanOrEqualTo(560 - 6));
      expect(at.top, greaterThanOrEqualTo(0));
    });

    testWidgets('Esc closes it', (tester) async {
      await pump(tester, pointer: true);
      await open(tester);
      expect(find.byKey(const Key('lookup-popup')), findsOne);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byKey(const Key('lookup-popup')), findsNothing);
      expect(DictionaryPopup.current, isNull);
    });

    testWidgets('a click outside closes it, and one inside does not', (
      tester,
    ) async {
      await pump(tester, pointer: true);
      await open(tester);
      final at = panel(tester);
      await tester.tapAt(at.center);
      await tester.pump();
      expect(find.byKey(const Key('lookup-popup')), findsOne);

      await tester.tapAt(const Offset(800, 650));
      await tester.pump();
      expect(find.byKey(const Key('lookup-popup')), findsNothing);
    });

    testWidgets('looking another selection up while it is open restarts the '
        'same panel', (tester) async {
      await pump(tester, pointer: true);
      await open(tester);
      final popup = DictionaryPopup.current!;
      // The press on the button is outside the panel: it closes it first,
      // as a click on the page does. The restart is the keyboard's.
      final context = tester.element(find.byKey(const Key('look-up')));
      unawaited(
        showDictionaryLookup(
          context,
          selection: 'amare',
          surface: DictionarySurface.book,
          language: 'it',
          anchor: const Rect.fromLTWH(500, 300, 40, 20),
        ),
      );
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
        if (title(tester) == 'amare') break;
      }
      expect(DictionaryPopup.current, same(popup));
      expect(title(tester), 'amare');
      expect(panel(tester).top, 300 + 20 + 6);
      expect(find.byKey(const Key('lookup-popup')), findsOne);
    });

    testWidgets('a phone gets a sheet at half the window, draggable higher', (
      tester,
    ) async {
      await pump(tester, pointer: false, size: const Size(400, 800));
      await open(tester);
      // The sheet slides in.
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('lookup-popup')), findsNothing);
      expect(find.byKey(const Key('lookup-sheet')), findsOne);
      expect(title(tester), 'caminetto');
      final sheet = tester.getRect(find.byKey(const Key('lookup-sheet')));
      expect(sheet.height, closeTo(400, 2));
      expect(sheet.bottom, 800);
      expect(find.byType(DraggableScrollableSheet), findsOne);

      await tester.drag(
        find.byKey(const Key('lookup-body')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const Key('lookup-sheet'))).height,
        greaterThan(500),
      );
    });

    testWidgets('a sheet closes with its own back, and Annotate hands the '
        'definition over after closing it', (tester) async {
      final definitions = <String>[];
      await pump(
        tester,
        pointer: false,
        size: const Size(400, 800),
        annotate: (definition) async => definitions.add(definition),
      );
      await open(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lookup-annotate')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('lookup-sheet')), findsNothing);
      expect(definitions.single, startsWith('caminetto'));
    });

    testWidgets('a book is looked up in its own language, whatever the '
        'library spells', (tester) async {
      await library.setSpellDictionaries(['en_US']);
      await pump(tester, pointer: true, language: 'it-IT');
      await open(tester);
      expect(title(tester), 'caminetto');
      expect(find.text('Italiano'), findsOne);
    });

    testWidgets("a book that says none is looked up in the library's first "
        'spelling language', (tester) async {
      await library.setSpellDictionaries(['en_US', 'it_IT']);
      await pump(tester, pointer: true, word: 'polished');
      await open(tester);
      expect(title(tester), 'polish');
      expect(find.text('English'), findsOne);
    });

    testWidgets('a PDF is looked up in the language chosen for it, then the '
        "library's", (tester) async {
      await pump(
        tester,
        pointer: true,
        surface: DictionarySurface.pdf,
        language: 'en',
        word: 'polished',
      );
      await open(tester);
      expect(title(tester), 'polish');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      await pump(tester, pointer: true, surface: DictionarySurface.pdf);
      await open(tester);
      expect(title(tester), 'caminetto');
      expect(find.text('Italiano'), findsOne);
    });

    testWidgets("with nothing else to go by it is the app's language", (
      tester,
    ) async {
      await library.setSpellDictionaries(const []);
      AppLanguages.choice = AppLanguage.english;
      await pump(
        tester,
        pointer: true,
        surface: DictionarySurface.text,
        word: 'polished',
      );
      await open(tester);
      expect(title(tester), 'polish');
    });

    testWidgets('the language the reader picks in the panel is told to '
        'the surface', (tester) async {
      final chosen = <String>[];
      await pump(
        tester,
        pointer: true,
        surface: DictionarySurface.pdf,
        word: 'polish',
        onLanguage: chosen.add,
      );
      await open(tester);
      expect(find.byKey(const Key('lookup-not-found')), findsOne);
      await tester.tap(find.byKey(const Key('lookup-language')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lookup-language-en')));
      for (var i = 0; i < 40 && title(tester) != 'polish'; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
      }
      expect(chosen, ['en']);
      expect(title(tester), 'polish');
    });
  });
}
